<?php
/*
   POST /api/booking.php
   Body: { "user_id": 1, "show_id": 3, "seat_ids": [12, 13, 14] }
   → creates a confirmed booking via stored procedure sp_book_seats
*/
require_once __DIR__ . '/config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') fail('POST required', 405);

$in       = json_input();
$user_id  = isset($in['user_id']) ? (int)$in['user_id'] : 1;  // fall back to demo user
$show_id  = isset($in['show_id']) ? (int)$in['show_id'] : 0;
$seat_ids = $in['seat_ids'] ?? [];

if ($show_id <= 0)                 fail('show_id required');
if (!is_array($seat_ids) || !count($seat_ids)) fail('seat_ids required');

// sanitize
$clean = array_values(array_filter(array_map('intval', $seat_ids), fn($x) => $x > 0));
if (!count($clean)) fail('invalid seat_ids');
$csv = implode(',', $clean);

try {
    $pdo = db();
    $pdo->beginTransaction();

    // Call the stored procedure — atomic + collision-checked
    $stmt = $pdo->prepare("CALL sp_book_seats(:uid, :sid, :csv, @bid)");
    $stmt->execute([
        ':uid' => $user_id,
        ':sid' => $show_id,
        ':csv' => $csv,
    ]);
    $stmt->closeCursor();

    $booking_id = (int)$pdo->query("SELECT @bid AS bid")->fetch()['bid'];

    // fetch the freshly-created booking with joined info
    $row = $pdo->prepare(
        "SELECT b.booking_id, b.total_amount, b.status, b.booking_time,
                v.movie_title, v.show_date, v.show_time, v.theater_name,
                v.screen_name, v.poster_url,
                GROUP_CONCAT(CONCAT(se.seat_row, se.seat_number) ORDER BY se.seat_row, se.seat_number) AS seats
         FROM   bookings b
         JOIN   vw_show_details v ON v.show_id = b.show_id
         JOIN   booking_seats bs ON bs.booking_id = b.booking_id
         JOIN   seats se        ON se.seat_id = bs.seat_id
         WHERE  b.booking_id = :bid
         GROUP BY b.booking_id"
    );
    $row->execute([':bid' => $booking_id]);
    $booking = $row->fetch();

    $pdo->commit();
    ok($booking);
} catch (PDOException $e) {
    if (db()->inTransaction()) db()->rollBack();
    fail($e->getMessage(), 409);
}
