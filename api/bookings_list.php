<?php
/*
   GET /api/bookings_list.php?user_id=1   → a user's booking history
*/
require_once __DIR__ . '/config.php';

$user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 1;

try {
    $stmt = db()->prepare(
        "SELECT  b.booking_id, b.booking_time, b.total_amount, b.status,
                 v.movie_title, v.poster_url, v.show_date, v.show_time,
                 v.theater_name, v.screen_name,
                 GROUP_CONCAT(CONCAT(se.seat_row, se.seat_number) ORDER BY se.seat_row, se.seat_number) AS seats
         FROM    bookings b
         JOIN    vw_show_details v ON v.show_id = b.show_id
         JOIN    booking_seats bs  ON bs.booking_id = b.booking_id
         JOIN    seats se          ON se.seat_id = bs.seat_id
         WHERE   b.user_id = :uid
         GROUP   BY b.booking_id
         ORDER   BY b.booking_time DESC"
    );
    $stmt->execute([':uid' => $user_id]);
    ok($stmt->fetchAll());
} catch (PDOException $e) {
    fail($e->getMessage(), 500);
}
