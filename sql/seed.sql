-- ═══════════════════════════════════════════════════════════════
--  SceneKyaHai  ·  Sample data
--  Run AFTER schema.sql, against the same database.
-- ═══════════════════════════════════════════════════════════════

-- Wipe in reverse-FK order so this file is idempotent
DELETE FROM booking_seats;
DELETE FROM bookings;
DELETE FROM shows;
DELETE FROM seats;
DELETE FROM screens;
DELETE FROM theaters;
DELETE FROM movies;
DELETE FROM users;

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

-- ─── SEATS (60 per screen: rows A–F, seats 1–10) ────────────
--  Rows A–B = PREMIUM, C–E = STANDARD, F = RECLINER
--  Plain INSERTs (no procedure) so it runs on any shared host.
INSERT INTO seats (screen_id, seat_row, seat_number, seat_type) VALUES
-- ── Screen 1 ──
(1,'A',1,'PREMIUM'),(1,'A',2,'PREMIUM'),(1,'A',3,'PREMIUM'),(1,'A',4,'PREMIUM'),(1,'A',5,'PREMIUM'),(1,'A',6,'PREMIUM'),(1,'A',7,'PREMIUM'),(1,'A',8,'PREMIUM'),(1,'A',9,'PREMIUM'),(1,'A',10,'PREMIUM'),
(1,'B',1,'PREMIUM'),(1,'B',2,'PREMIUM'),(1,'B',3,'PREMIUM'),(1,'B',4,'PREMIUM'),(1,'B',5,'PREMIUM'),(1,'B',6,'PREMIUM'),(1,'B',7,'PREMIUM'),(1,'B',8,'PREMIUM'),(1,'B',9,'PREMIUM'),(1,'B',10,'PREMIUM'),
(1,'C',1,'STANDARD'),(1,'C',2,'STANDARD'),(1,'C',3,'STANDARD'),(1,'C',4,'STANDARD'),(1,'C',5,'STANDARD'),(1,'C',6,'STANDARD'),(1,'C',7,'STANDARD'),(1,'C',8,'STANDARD'),(1,'C',9,'STANDARD'),(1,'C',10,'STANDARD'),
(1,'D',1,'STANDARD'),(1,'D',2,'STANDARD'),(1,'D',3,'STANDARD'),(1,'D',4,'STANDARD'),(1,'D',5,'STANDARD'),(1,'D',6,'STANDARD'),(1,'D',7,'STANDARD'),(1,'D',8,'STANDARD'),(1,'D',9,'STANDARD'),(1,'D',10,'STANDARD'),
(1,'E',1,'STANDARD'),(1,'E',2,'STANDARD'),(1,'E',3,'STANDARD'),(1,'E',4,'STANDARD'),(1,'E',5,'STANDARD'),(1,'E',6,'STANDARD'),(1,'E',7,'STANDARD'),(1,'E',8,'STANDARD'),(1,'E',9,'STANDARD'),(1,'E',10,'STANDARD'),
(1,'F',1,'RECLINER'),(1,'F',2,'RECLINER'),(1,'F',3,'RECLINER'),(1,'F',4,'RECLINER'),(1,'F',5,'RECLINER'),(1,'F',6,'RECLINER'),(1,'F',7,'RECLINER'),(1,'F',8,'RECLINER'),(1,'F',9,'RECLINER'),(1,'F',10,'RECLINER'),
-- ── Screen 2 ──
(2,'A',1,'PREMIUM'),(2,'A',2,'PREMIUM'),(2,'A',3,'PREMIUM'),(2,'A',4,'PREMIUM'),(2,'A',5,'PREMIUM'),(2,'A',6,'PREMIUM'),(2,'A',7,'PREMIUM'),(2,'A',8,'PREMIUM'),(2,'A',9,'PREMIUM'),(2,'A',10,'PREMIUM'),
(2,'B',1,'PREMIUM'),(2,'B',2,'PREMIUM'),(2,'B',3,'PREMIUM'),(2,'B',4,'PREMIUM'),(2,'B',5,'PREMIUM'),(2,'B',6,'PREMIUM'),(2,'B',7,'PREMIUM'),(2,'B',8,'PREMIUM'),(2,'B',9,'PREMIUM'),(2,'B',10,'PREMIUM'),
(2,'C',1,'STANDARD'),(2,'C',2,'STANDARD'),(2,'C',3,'STANDARD'),(2,'C',4,'STANDARD'),(2,'C',5,'STANDARD'),(2,'C',6,'STANDARD'),(2,'C',7,'STANDARD'),(2,'C',8,'STANDARD'),(2,'C',9,'STANDARD'),(2,'C',10,'STANDARD'),
(2,'D',1,'STANDARD'),(2,'D',2,'STANDARD'),(2,'D',3,'STANDARD'),(2,'D',4,'STANDARD'),(2,'D',5,'STANDARD'),(2,'D',6,'STANDARD'),(2,'D',7,'STANDARD'),(2,'D',8,'STANDARD'),(2,'D',9,'STANDARD'),(2,'D',10,'STANDARD'),
(2,'E',1,'STANDARD'),(2,'E',2,'STANDARD'),(2,'E',3,'STANDARD'),(2,'E',4,'STANDARD'),(2,'E',5,'STANDARD'),(2,'E',6,'STANDARD'),(2,'E',7,'STANDARD'),(2,'E',8,'STANDARD'),(2,'E',9,'STANDARD'),(2,'E',10,'STANDARD'),
(2,'F',1,'RECLINER'),(2,'F',2,'RECLINER'),(2,'F',3,'RECLINER'),(2,'F',4,'RECLINER'),(2,'F',5,'RECLINER'),(2,'F',6,'RECLINER'),(2,'F',7,'RECLINER'),(2,'F',8,'RECLINER'),(2,'F',9,'RECLINER'),(2,'F',10,'RECLINER'),
-- ── Screen 3 ──
(3,'A',1,'PREMIUM'),(3,'A',2,'PREMIUM'),(3,'A',3,'PREMIUM'),(3,'A',4,'PREMIUM'),(3,'A',5,'PREMIUM'),(3,'A',6,'PREMIUM'),(3,'A',7,'PREMIUM'),(3,'A',8,'PREMIUM'),(3,'A',9,'PREMIUM'),(3,'A',10,'PREMIUM'),
(3,'B',1,'PREMIUM'),(3,'B',2,'PREMIUM'),(3,'B',3,'PREMIUM'),(3,'B',4,'PREMIUM'),(3,'B',5,'PREMIUM'),(3,'B',6,'PREMIUM'),(3,'B',7,'PREMIUM'),(3,'B',8,'PREMIUM'),(3,'B',9,'PREMIUM'),(3,'B',10,'PREMIUM'),
(3,'C',1,'STANDARD'),(3,'C',2,'STANDARD'),(3,'C',3,'STANDARD'),(3,'C',4,'STANDARD'),(3,'C',5,'STANDARD'),(3,'C',6,'STANDARD'),(3,'C',7,'STANDARD'),(3,'C',8,'STANDARD'),(3,'C',9,'STANDARD'),(3,'C',10,'STANDARD'),
(3,'D',1,'STANDARD'),(3,'D',2,'STANDARD'),(3,'D',3,'STANDARD'),(3,'D',4,'STANDARD'),(3,'D',5,'STANDARD'),(3,'D',6,'STANDARD'),(3,'D',7,'STANDARD'),(3,'D',8,'STANDARD'),(3,'D',9,'STANDARD'),(3,'D',10,'STANDARD'),
(3,'E',1,'STANDARD'),(3,'E',2,'STANDARD'),(3,'E',3,'STANDARD'),(3,'E',4,'STANDARD'),(3,'E',5,'STANDARD'),(3,'E',6,'STANDARD'),(3,'E',7,'STANDARD'),(3,'E',8,'STANDARD'),(3,'E',9,'STANDARD'),(3,'E',10,'STANDARD'),
(3,'F',1,'RECLINER'),(3,'F',2,'RECLINER'),(3,'F',3,'RECLINER'),(3,'F',4,'RECLINER'),(3,'F',5,'RECLINER'),(3,'F',6,'RECLINER'),(3,'F',7,'RECLINER'),(3,'F',8,'RECLINER'),(3,'F',9,'RECLINER'),(3,'F',10,'RECLINER'),
-- ── Screen 4 ──
(4,'A',1,'PREMIUM'),(4,'A',2,'PREMIUM'),(4,'A',3,'PREMIUM'),(4,'A',4,'PREMIUM'),(4,'A',5,'PREMIUM'),(4,'A',6,'PREMIUM'),(4,'A',7,'PREMIUM'),(4,'A',8,'PREMIUM'),(4,'A',9,'PREMIUM'),(4,'A',10,'PREMIUM'),
(4,'B',1,'PREMIUM'),(4,'B',2,'PREMIUM'),(4,'B',3,'PREMIUM'),(4,'B',4,'PREMIUM'),(4,'B',5,'PREMIUM'),(4,'B',6,'PREMIUM'),(4,'B',7,'PREMIUM'),(4,'B',8,'PREMIUM'),(4,'B',9,'PREMIUM'),(4,'B',10,'PREMIUM'),
(4,'C',1,'STANDARD'),(4,'C',2,'STANDARD'),(4,'C',3,'STANDARD'),(4,'C',4,'STANDARD'),(4,'C',5,'STANDARD'),(4,'C',6,'STANDARD'),(4,'C',7,'STANDARD'),(4,'C',8,'STANDARD'),(4,'C',9,'STANDARD'),(4,'C',10,'STANDARD'),
(4,'D',1,'STANDARD'),(4,'D',2,'STANDARD'),(4,'D',3,'STANDARD'),(4,'D',4,'STANDARD'),(4,'D',5,'STANDARD'),(4,'D',6,'STANDARD'),(4,'D',7,'STANDARD'),(4,'D',8,'STANDARD'),(4,'D',9,'STANDARD'),(4,'D',10,'STANDARD'),
(4,'E',1,'STANDARD'),(4,'E',2,'STANDARD'),(4,'E',3,'STANDARD'),(4,'E',4,'STANDARD'),(4,'E',5,'STANDARD'),(4,'E',6,'STANDARD'),(4,'E',7,'STANDARD'),(4,'E',8,'STANDARD'),(4,'E',9,'STANDARD'),(4,'E',10,'STANDARD'),
(4,'F',1,'RECLINER'),(4,'F',2,'RECLINER'),(4,'F',3,'RECLINER'),(4,'F',4,'RECLINER'),(4,'F',5,'RECLINER'),(4,'F',6,'RECLINER'),(4,'F',7,'RECLINER'),(4,'F',8,'RECLINER'),(4,'F',9,'RECLINER'),(4,'F',10,'RECLINER');

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
