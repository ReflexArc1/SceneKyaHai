<?php
/*
   GET /api/seats.php?show_id=7     → seat map + booking status
*/
require_once __DIR__ . '/config.php';

$show_id = isset($_GET['show_id']) ? (int)$_GET['show_id'] : 0;
if ($show_id <= 0) fail('show_id required');

try {
    // show details
    $s = db()->prepare("SELECT * FROM vw_show_details WHERE show_id = :id");
    $s->execute([':id' => $show_id]);
    $show = $s->fetch();
    if (!$show) fail('Show not found', 404);

    // seats with live status
    $s = db()->prepare(
        "SELECT seat_id, seat_row, seat_number, seat_type, status
         FROM   vw_seat_status
         WHERE  show_id = :id
         ORDER  BY seat_row, seat_number"
    );
    $s->execute([':id' => $show_id]);
    $seats = $s->fetchAll();

    ok([
        'show'  => $show,
        'seats' => $seats,
    ]);
} catch (PDOException $e) {
    fail($e->getMessage(), 500);
}
