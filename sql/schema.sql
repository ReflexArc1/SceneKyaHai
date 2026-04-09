-- ═══════════════════════════════════════════════════════════════
--  SceneKyaHai  ·  Movie Ticket Booking System
--  Database Schema (MySQL 8+)
-- ═══════════════════════════════════════════════════════════════

DROP DATABASE IF EXISTS scenekyahai;
CREATE DATABASE scenekyahai CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE scenekyahai;

-- ─── 1. USERS ────────────────────────────────────────────────
CREATE TABLE users (
    user_id      INT AUTO_INCREMENT PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    email        VARCHAR(120) NOT NULL UNIQUE,
    phone        VARCHAR(15),
    password     VARCHAR(255) NOT NULL,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ─── 2. MOVIES ───────────────────────────────────────────────
CREATE TABLE movies (
    movie_id      INT AUTO_INCREMENT PRIMARY KEY,
    title         VARCHAR(200) NOT NULL,
    genre         VARCHAR(60),
    language      VARCHAR(40),
    duration_min  INT,                     -- runtime in minutes
    certificate   VARCHAR(10),             -- U, UA, A
    imdb_rating   DECIMAL(3,1),
    release_date  DATE,
    poster_url    TEXT,
    description   TEXT
);

-- ─── 3. THEATERS & SCREENS ───────────────────────────────────
CREATE TABLE theaters (
    theater_id   INT AUTO_INCREMENT PRIMARY KEY,
    name         VARCHAR(120) NOT NULL,
    location     VARCHAR(150),
    city         VARCHAR(60)
);

CREATE TABLE screens (
    screen_id    INT AUTO_INCREMENT PRIMARY KEY,
    theater_id   INT NOT NULL,
    screen_name  VARCHAR(40),
    total_seats  INT DEFAULT 60,
    FOREIGN KEY (theater_id) REFERENCES theaters(theater_id) ON DELETE CASCADE
);

-- ─── 4. SEATS (fixed per screen) ─────────────────────────────
CREATE TABLE seats (
    seat_id      INT AUTO_INCREMENT PRIMARY KEY,
    screen_id    INT NOT NULL,
    seat_row     CHAR(1) NOT NULL,
    seat_number  INT NOT NULL,
    seat_type    ENUM('STANDARD','PREMIUM','RECLINER') DEFAULT 'STANDARD',
    FOREIGN KEY (screen_id) REFERENCES screens(screen_id) ON DELETE CASCADE,
    UNIQUE KEY uq_seat (screen_id, seat_row, seat_number)
);

-- ─── 5. SHOWS (movie × screen × datetime) ────────────────────
CREATE TABLE shows (
    show_id      INT AUTO_INCREMENT PRIMARY KEY,
    movie_id     INT NOT NULL,
    screen_id    INT NOT NULL,
    show_date    DATE NOT NULL,
    show_time    TIME NOT NULL,
    price        DECIMAL(8,2) NOT NULL,
    FOREIGN KEY (movie_id)  REFERENCES movies(movie_id)  ON DELETE CASCADE,
    FOREIGN KEY (screen_id) REFERENCES screens(screen_id) ON DELETE CASCADE,
    UNIQUE KEY uq_show (screen_id, show_date, show_time)
);

-- ─── 6. BOOKINGS ─────────────────────────────────────────────
CREATE TABLE bookings (
    booking_id    INT AUTO_INCREMENT PRIMARY KEY,
    user_id       INT,
    show_id       INT NOT NULL,
    booking_time  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount  DECIMAL(10,2) NOT NULL,
    status        ENUM('CONFIRMED','CANCELLED') DEFAULT 'CONFIRMED',
    FOREIGN KEY (user_id) REFERENCES users(user_id)  ON DELETE SET NULL,
    FOREIGN KEY (show_id) REFERENCES shows(show_id)  ON DELETE CASCADE
);

-- ─── 7. BOOKING_SEATS (M:N bridge) ───────────────────────────
CREATE TABLE booking_seats (
    booking_seat_id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id      INT NOT NULL,
    seat_id         INT NOT NULL,
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) ON DELETE CASCADE,
    FOREIGN KEY (seat_id)    REFERENCES seats(seat_id)       ON DELETE CASCADE,
    UNIQUE KEY uq_booked (booking_id, seat_id)
);

-- ═══════════════════════════════════════════════════════════════
--  VIEWS  — handy for the frontend
-- ═══════════════════════════════════════════════════════════════

-- Shows enriched with movie + theater info
CREATE OR REPLACE VIEW vw_show_details AS
SELECT  s.show_id,
        s.show_date,
        s.show_time,
        s.price,
        m.movie_id,
        m.title           AS movie_title,
        m.poster_url,
        m.duration_min,
        m.certificate,
        m.language,
        t.theater_id,
        t.name            AS theater_name,
        t.location        AS theater_location,
        t.city,
        sc.screen_id,
        sc.screen_name,
        sc.total_seats
FROM    shows s
JOIN    movies  m  ON m.movie_id  = s.movie_id
JOIN    screens sc ON sc.screen_id = s.screen_id
JOIN    theaters t ON t.theater_id = sc.theater_id;

-- Seats with their booking status for a given show
-- (use: SELECT * FROM vw_seat_status WHERE show_id = ?)
CREATE OR REPLACE VIEW vw_seat_status AS
SELECT  sh.show_id,
        se.seat_id,
        se.seat_row,
        se.seat_number,
        se.seat_type,
        CASE
            WHEN bs.seat_id IS NOT NULL THEN 'BOOKED'
            ELSE 'AVAILABLE'
        END AS status
FROM    shows sh
JOIN    seats se ON se.screen_id = sh.screen_id
LEFT JOIN bookings b
       ON b.show_id = sh.show_id
      AND b.status  = 'CONFIRMED'
LEFT JOIN booking_seats bs
       ON bs.booking_id = b.booking_id
      AND bs.seat_id    = se.seat_id;

-- ═══════════════════════════════════════════════════════════════
--  STORED PROCEDURE — atomic seat booking
-- ═══════════════════════════════════════════════════════════════
DELIMITER //

DROP PROCEDURE IF EXISTS sp_book_seats //

CREATE PROCEDURE sp_book_seats (
    IN  p_user_id  INT,
    IN  p_show_id  INT,
    IN  p_seat_csv VARCHAR(500),     -- comma-separated seat_ids
    OUT p_booking_id INT
)
BEGIN
    DECLARE v_price      DECIMAL(8,2);
    DECLARE v_count      INT;
    DECLARE v_total      DECIMAL(10,2);
    DECLARE v_conflicts  INT DEFAULT 0;

    -- resolve show price
    SELECT price INTO v_price FROM shows WHERE show_id = p_show_id;

    -- temp table of requested seat_ids
    DROP TEMPORARY TABLE IF EXISTS tmp_seats;
    CREATE TEMPORARY TABLE tmp_seats (seat_id INT PRIMARY KEY);

    SET @s = p_seat_csv;
    WHILE LENGTH(@s) > 0 DO
        SET @one = SUBSTRING_INDEX(@s, ',', 1);
        INSERT IGNORE INTO tmp_seats VALUES (CAST(@one AS UNSIGNED));
        IF LOCATE(',', @s) = 0 THEN SET @s = '';
        ELSE SET @s = SUBSTRING(@s, LOCATE(',', @s) + 1);
        END IF;
    END WHILE;

    -- check for collisions
    SELECT COUNT(*) INTO v_conflicts
    FROM   booking_seats bs
    JOIN   bookings b ON b.booking_id = bs.booking_id
    WHERE  b.show_id = p_show_id
      AND  b.status  = 'CONFIRMED'
      AND  bs.seat_id IN (SELECT seat_id FROM tmp_seats);

    IF v_conflicts > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'One or more seats are already booked';
    END IF;

    SELECT COUNT(*) INTO v_count FROM tmp_seats;
    SET v_total = v_count * v_price;

    -- create booking
    INSERT INTO bookings (user_id, show_id, total_amount, status)
    VALUES (p_user_id, p_show_id, v_total, 'CONFIRMED');

    SET p_booking_id = LAST_INSERT_ID();

    -- link seats
    INSERT INTO booking_seats (booking_id, seat_id)
    SELECT p_booking_id, seat_id FROM tmp_seats;

    DROP TEMPORARY TABLE tmp_seats;
END //

DELIMITER ;
