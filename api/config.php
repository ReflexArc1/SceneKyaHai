<?php
/*
 ═══════════════════════════════════════════════════════════════
   SceneKyaHai · Database connection + JSON helpers
 ═══════════════════════════════════════════════════════════════
*/

// ── CORS / JSON headers (so the front-end can fetch freely) ──
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json; charset=utf-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

// ── DB credentials ───────────────────────────────────────────
// Defaults are for local XAMPP. On the production server, create a
// file named `config.local.php` next to this one (it's gitignored)
// which re-defines these constants. Example inside config.local.php:
//     <?php
//     define('DB_HOST', 'sqlXXX.infinityfree.com');
//     define('DB_NAME', 'if0_12345678_scenekyahai');
//     define('DB_USER', 'if0_12345678');
//     define('DB_PASS', 'your-password');
if (file_exists(__DIR__ . '/config.local.php')) {
    require_once __DIR__ . '/config.local.php';
}
if (!defined('DB_HOST')) define('DB_HOST', 'localhost');
if (!defined('DB_NAME')) define('DB_NAME', 'scenekyahai');
if (!defined('DB_USER')) define('DB_USER', 'root');
if (!defined('DB_PASS')) define('DB_PASS', '');   // XAMPP default is empty

function db() {
    static $pdo = null;
    if ($pdo === null) {
        try {
            $pdo = new PDO(
                'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8mb4',
                DB_USER,
                DB_PASS,
                [
                    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                    PDO::ATTR_EMULATE_PREPARES   => false,
                ]
            );
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['ok' => false, 'error' => 'DB connection failed: ' . $e->getMessage()]);
            exit;
        }
    }
    return $pdo;
}

function ok($data)   { echo json_encode(['ok' => true,  'data' => $data]);   exit; }
function fail($msg, $code = 400) {
    http_response_code($code);
    echo json_encode(['ok' => false, 'error' => $msg]);
    exit;
}

function json_input() {
    $raw = file_get_contents('php://input');
    if (!$raw) return [];
    $j = json_decode($raw, true);
    return is_array($j) ? $j : [];
}
