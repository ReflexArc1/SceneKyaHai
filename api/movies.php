<?php
/*
   GET /api/movies.php              → list all movies
   GET /api/movies.php?id=3         → single movie
*/
require_once __DIR__ . '/config.php';

try {
    if (isset($_GET['id'])) {
        $stmt = db()->prepare("SELECT * FROM movies WHERE movie_id = :id");
        $stmt->execute([':id' => (int)$_GET['id']]);
        $movie = $stmt->fetch();
        if (!$movie) fail('Movie not found', 404);
        ok($movie);
    } else {
        $rows = db()->query("SELECT * FROM movies ORDER BY movie_id")->fetchAll();
        ok($rows);
    }
} catch (PDOException $e) {
    fail($e->getMessage(), 500);
}
