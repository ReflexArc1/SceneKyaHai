<?php
/*
   POST /api/booking.php
   Body: { "user_id": 1, "show_id": 3, "seat_ids": [12, 13, 14] }

   Atomic booking implemented with a SQL transaction:
     1. BEGIN
     2. Lock requested seats + existing booking_seats rows via SELECT ... FOR UPDATE
     3. If any seat is already taken for this show → ROLLBACK + 409
     4. Insert bookings row
     5. Insert booking_seats rows
     6. COMMIT
   The UNIQUE key on (booking_id, seat_id) plus the FK constraints
   give us a second line of defense at the DB layer.
*/
require_once __DIR__ . '/config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') fail('POST required', 405);

$in       = json_input();
$user_id  = isset($in['user_id']) ? (int)$in['user_id'] : 1;   // fall back to demo user
$show_id  = isset($in['show_id']) ? (int)$in['show_id'] : 0;
$seat_ids = $in['seat_ids'] ?? [];

if ($show_id <= 0)                              fail('show_id required');
if (!is_array($seat_ids) || !count($seat_ids))  fail('seat_ids required');

// sanitize → positive ints only, de-duplicated
$clean = array_values(array_unique(array_filter(
    array_map('intval', $seat_ids),
    fn($x) => $x > 0
)));
if (!count($clean)) fail('invalid seat_ids');

$pdo = db();

try {
    $pdo->beginTransaction();

    // ── 1. resolve show price + screen_id ──────────────────
    $stmt = $pdo->prepare("SELECT price, screen_id FROM shows WHERE show_id = :sid FOR UPDATE");
    $stmt->execute([':sid' => $show_id]);
    $show = $stmt->fetch();
    if (!$show) { $pdo->rollBack(); fail('Show not found', 404); }

    $price    = (float)$show['price'];
    $screenId = (int)$show['screen_id'];

    // ── 2. verify all requested seats belong to this show's screen ──
    $ph  = implode(',', array_fill(0, count($clean), '?'));
    $sql = "SELECT COUNT(*) FROM seats WHERE screen_id = ? AND seat_id IN ($ph)";
    $stmt = $pdo->prepare($sql);
    $stmt->execute(array_merge([$screenId], $clean));
    if ((int)$stmt->fetchColumn() !== count($clean)) {
        $pdo->rollBack();
        fail('One or more seats do not belong to this show', 400);
    }

    // ── 3. collision check ─────────────────────────────────
    $sql = "SELECT bs.seat_id
            FROM   booking_seats bs
            JOIN   bookings b ON b.booking_id = bs.booking_id
            WHERE  b.show_id = ?
              AND  b.status  = 'CONFIRMED'
              AND  bs.seat_id IN ($ph)
            FOR UPDATE";
    $stmt = $pdo->prepare($sql);
    $stmt->execute(array_merge([$show_id], $clean));
    if ($stmt->fetch()) {
        $pdo->rollBack();
        fail('One or more seats are already booked', 409);
    }

    // ── 4. insert booking ──────────────────────────────────
    $total = count($clean) * $price;
    $stmt = $pdo->prepare(
        "INSERT INTO bookings (user_id, show_id, total_amount, status)
         VALUES (:uid, :sid, :amt, 'CONFIRMED')"
    );
    $stmt->execute([
        ':uid' => $user_id,
        ':sid' => $show_id,
        ':amt' => $total,
    ]);
    $booking_id = (int)$pdo->lastInsertId();

    // ── 5. link seats ──────────────────────────────────────
    $stmt = $pdo->prepare("INSERT INTO booking_seats (booking_id, seat_id) VALUES (:bid, :sid)");
    foreach ($clean as $sid) {
        $stmt->execute([':bid' => $booking_id, ':sid' => $sid]);
    }

    // ── 6. fetch the fleshed-out booking for the response ─
    $stmt = $pdo->prepare(
        "SELECT b.booking_id, b.total_amount, b.status, b.booking_time,
                v.movie_title, v.show_date, v.show_time, v.theater_name,
                v.screen_name, v.poster_url,
                GROUP_CONCAT(CONCAT(se.seat_row, se.seat_number)
                             ORDER BY se.seat_row, se.seat_number) AS seats
         FROM   bookings b
         JOIN   vw_show_details v ON v.show_id = b.show_id
         JOIN   booking_seats bs  ON bs.booking_id = b.booking_id
         JOIN   seats se          ON se.seat_id    = bs.seat_id
         WHERE  b.booking_id = :bid
         GROUP  BY b.booking_id"
    );
    $stmt->execute([':bid' => $booking_id]);
    $booking = $stmt->fetch();

    $pdo->commit();
    ok($booking);

} catch (PDOException $e) {
    if ($pdo->inTransaction()) $pdo->rollBack();
    fail($e->getMessage(), 500);
}
