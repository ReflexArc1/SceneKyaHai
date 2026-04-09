-- ═══════════════════════════════════════════════════════════════
--  SceneKyaHai  ·  Sample data
--  Run AFTER schema.sql
-- ═══════════════════════════════════════════════════════════════
USE scenekyahai;

-- ─── USERS ───────────────────────────────────────────────────
INSERT INTO users (name, email, phone, password) VALUES
('Demo User', 'demo@scenekyahai.in', '9999000011', 'demo123'),
('Aarav Mehta', 'aarav@example.com',  '9999000012', 'pass123');

-- ─── MOVIES (5) ──────────────────────────────────────────────
-- Poster placeholders use placehold.co so the project works offline.
-- Swap poster_url with real TMDB/IMDb URLs anytime.
INSERT INTO movies
(title, genre, language, duration_min, certificate, imdb_rating, release_date, poster_url, description) VALUES
('Dune: Part Two',
 'Sci-Fi / Epic', 'English', 166, 'UA', 8.5, '2024-03-01',
 'https://placehold.co/500x750/050505/ff3333/?font=oswald&text=DUNE%0APART%0ATWO',
 'Paul Atreides unites with Chani and the Fremen while on a warpath of revenge against the conspirators who destroyed his family.'),

('Oppenheimer',
 'Biography / Drama', 'English', 180, 'UA', 8.3, '2023-07-21',
 'https://placehold.co/500x750/050505/ff3333/?font=oswald&text=OPPEN-%0AHEIMER',
 'The story of American scientist J. Robert Oppenheimer and his role in the development of the atomic bomb.'),

('Kalki 2898 AD',
 'Sci-Fi / Mythological', 'Hindi', 181, 'UA', 7.5, '2024-06-27',
 'https://placehold.co/500x750/050505/0000ff/?font=oswald&text=KALKI%0A2898+AD',
 'In a dystopian future, a modern avatar of a Hindu god, Vishnu, comes to save the world from evil forces.'),

('Jawan',
 'Action / Thriller', 'Hindi', 169, 'UA', 7.0, '2023-09-07',
 'https://placehold.co/500x750/050505/ff3333/?font=oswald&text=JAWAN',
 'A man driven by a personal vendetta sets out to rectify the wrongs in society while keeping a promise made years ago.'),

('Interstellar',
 'Sci-Fi / Adventure', 'English', 169, 'UA', 8.7, '2014-11-07',
 'https://placehold.co/500x750/050505/0000ff/?font=oswald&text=INTER-%0ASTELLAR',
 'A team of explorers travel through a wormhole in space in an attempt to ensure humanity''s survival.');

-- ─── THEATERS ────────────────────────────────────────────────
INSERT INTO theaters (name, location, city) VALUES
('PVR ICON',            'Phoenix Marketcity, Kurla',   'Mumbai'),
('INOX Megaplex',       'Inorbit Mall, Malad',         'Mumbai'),
('Cinepolis Fun Republic','Andheri West',              'Mumbai');

-- ─── SCREENS ─────────────────────────────────────────────────
INSERT INTO screens (theater_id, screen_name, total_seats) VALUES
(1, 'AUDI 1 — IMAX', 60),
(1, 'AUDI 2',        60),
(2, 'SCREEN A',      60),
(3, 'GOLD CLASS',    60);

-- ─── SEATS (auto-populate 60 per screen: rows A–F, 1–10) ────
--  Rows A–B = PREMIUM, C–E = STANDARD, F = RECLINER
DELIMITER //
CREATE PROCEDURE sp_fill_seats()
BEGIN
    DECLARE s INT DEFAULT 1;
    DECLARE n INT;
    WHILE s <= (SELECT MAX(screen_id) FROM screens) DO
        SET n = 1;
        WHILE n <= 10 DO
            INSERT IGNORE INTO seats (screen_id, seat_row, seat_number, seat_type)
            VALUES
                (s, 'A', n, 'PREMIUM'),
                (s, 'B', n, 'PREMIUM'),
                (s, 'C', n, 'STANDARD'),
                (s, 'D', n, 'STANDARD'),
                (s, 'E', n, 'STANDARD'),
                (s, 'F', n, 'RECLINER');
            SET n = n + 1;
        END WHILE;
        SET s = s + 1;
    END WHILE;
END //
DELIMITER ;

CALL sp_fill_seats();
DROP PROCEDURE sp_fill_seats;

-- ─── SHOWS (3 per movie across different screens) ───────────
INSERT INTO shows (movie_id, screen_id, show_date, show_time, price) VALUES
-- Dune: Part Two
(1, 1, CURDATE(),                   '13:30:00', 380.00),
(1, 2, CURDATE(),                   '19:45:00', 320.00),
(1, 3, DATE_ADD(CURDATE(), INTERVAL 1 DAY), '22:15:00', 340.00),
-- Oppenheimer
(2, 2, CURDATE(),                   '14:00:00', 300.00),
(2, 4, CURDATE(),                   '21:00:00', 450.00),
(2, 1, DATE_ADD(CURDATE(), INTERVAL 1 DAY), '17:30:00', 380.00),
-- Kalki 2898 AD
(3, 3, CURDATE(),                   '12:15:00', 280.00),
(3, 1, CURDATE(),                   '18:00:00', 360.00),
(3, 2, DATE_ADD(CURDATE(), INTERVAL 1 DAY), '20:30:00', 320.00),
-- Jawan
(4, 4, CURDATE(),                   '16:30:00', 420.00),
(4, 3, CURDATE(),                   '22:45:00', 300.00),
(4, 2, DATE_ADD(CURDATE(), INTERVAL 1 DAY), '13:00:00', 280.00),
-- Interstellar
(5, 1, CURDATE(),                   '15:45:00', 380.00),
(5, 4, CURDATE(),                   '19:00:00', 450.00),
(5, 3, DATE_ADD(CURDATE(), INTERVAL 1 DAY), '21:30:00', 340.00);

-- ─── Sample booking so reports are non-empty ────────────────
INSERT INTO bookings (user_id, show_id, total_amount, status) VALUES
(1, 1, 760.00, 'CONFIRMED');

INSERT INTO booking_seats (booking_id, seat_id) VALUES
(1, 1),   -- A1 in screen 1
(1, 2);   -- B1 in screen 1
