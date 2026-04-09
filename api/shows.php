<?php
/*
   GET /api/shows.php?movie_id=1    → all upcoming shows for a movie
*/
require_once __DIR__ . '/config.php';

$movie_id = isset($_GET['movie_id']) ? (int)$_GET['movie_id'] : 0;
if ($movie_id <= 0) fail('movie_id required');

try {
    $stmt = db()->prepare(
        "SELECT *
         FROM   vw_show_details
         WHERE  movie_id = :mid
           AND  (show_date > CURDATE()
                 OR (show_date = CURDATE() AND show_time >= CURTIME()))
         ORDER  BY show_date, show_time"
    );
    $stmt->execute([':mid' => $movie_id]);
    ok($stmt->fetchAll());
} catch (PDOException $e) {
    fail($e->getMessage(), 500);
}
