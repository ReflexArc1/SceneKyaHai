# SCENE KYA HAI? — DBMS Movie Ticket Booking System

A brutalist / cyberpunk movie-ticket booking site built as a **DBMS course project**.
Front-end is plain **HTML / CSS / JS**. Backend is **MySQL + PHP (PDO)**.

---

## Stack

| Layer       | Tech                               |
|-------------|------------------------------------|
| Database    | MySQL 8 (7 tables, 2 views, 1 proc) |
| Backend     | PHP 7.4+ (PDO, JSON REST)          |
| Frontend    | HTML5, CSS3, vanilla JS (fetch)    |

No frameworks, no bundlers — drop it into `htdocs/` and run.

---

## Folder structure

```
SceneKyaHai/
├── index.html           # Main page (hero + movies + modals)
├── styles.css           # Global stylesheet
├── script.js            # All frontend logic
├── assets/
│   ├── logo.svg         # Hero wordmark
│   └── logo-mark.svg    # Square monogram for nav + favicon
├── api/
│   ├── config.php       # DB connection + JSON helpers
│   ├── movies.php       # GET all / single movie
│   ├── shows.php        # GET shows for a movie
│   ├── seats.php        # GET seat map + live status
│   ├── booking.php      # POST create booking (atomic)
│   └── bookings_list.php# GET a user's bookings
├── sql/
│   ├── schema.sql       # Database + tables + views + stored proc
│   └── seed.sql         # 5 movies, 3 theaters, 4 screens, 15 shows
└── README.md
```

---

## Database design

### Tables (3NF normalized)

| # | Table            | Purpose                                       |
|---|------------------|-----------------------------------------------|
| 1 | `users`          | Registered customers                          |
| 2 | `movies`         | Master list of movies                         |
| 3 | `theaters`       | Theater chains / locations                    |
| 4 | `screens`        | Individual auditoriums inside a theater       |
| 5 | `seats`          | Fixed seat grid per screen                    |
| 6 | `shows`          | A movie playing on a screen at a datetime     |
| 7 | `bookings`       | Confirmed bookings                            |
| 8 | `booking_seats`  | M:N bridge — which seats are on which booking |

### Views

- `vw_show_details` — shows joined with movie + theater + screen
- `vw_seat_status`  — live `AVAILABLE / BOOKED` status per seat per show

### Stored procedure

- `sp_book_seats(user_id, show_id, seat_csv, OUT booking_id)`
  atomic seat reservation with collision-check (raises `SQLSTATE 45000` if any seat is already taken).

### ER relationships

```
users ──┐
        └──< bookings >── booking_seats >── seats
                │                              │
                └──< shows >── screens >── theaters
                        │
                        └── movies
```

---

## Setup (XAMPP on Windows)

1. **Install XAMPP** and start Apache + MySQL.

2. **Copy the project** into your web root:
   ```
   C:\xampp\htdocs\SceneKyaHai\
   ```

3. **Create the database**. Open phpMyAdmin (`http://localhost/phpmyadmin`) → **Import** → pick `sql/schema.sql` → Go.
   Then import `sql/seed.sql` the same way.

   Or from the command line:
   ```bash
   mysql -u root -p < sql/schema.sql
   mysql -u root -p < sql/seed.sql
   ```

4. **Configure credentials** (if needed). Edit `api/config.php`:
   ```php
   define('DB_HOST', 'localhost');
   define('DB_NAME', 'scenekyahai');
   define('DB_USER', 'root');
   define('DB_PASS', '');     // XAMPP default is empty
   ```

5. **Open** `http://localhost/SceneKyaHai/` in your browser.

> **Demo mode:** if you open `index.html` directly (without PHP running),
> the site still works — it falls back to an in-memory dataset so you can
> present the UI anywhere.

---

## API reference

All endpoints return `{ ok: true, data: ... }` or `{ ok: false, error: ... }`.

| Method | Endpoint                           | Description                         |
|--------|------------------------------------|-------------------------------------|
| GET    | `api/movies.php`                   | List all movies                     |
| GET    | `api/movies.php?id=3`              | Single movie                        |
| GET    | `api/shows.php?movie_id=1`         | Upcoming shows for a movie          |
| GET    | `api/seats.php?show_id=7`          | Seat map with live status           |
| POST   | `api/booking.php`                  | Create a booking                    |
| GET    | `api/bookings_list.php?user_id=1`  | A user's booking history            |

**Booking request body:**
```json
{
  "user_id": 1,
  "show_id": 3,
  "seat_ids": [12, 13, 14]
}
```

---

## Example SQL queries (useful for the project report)

```sql
-- 1. All currently-running movies
SELECT title, genre, language, imdb_rating FROM movies;

-- 2. Today's shows with theater details
SELECT movie_title, theater_name, screen_name, show_time, price
FROM   vw_show_details
WHERE  show_date = CURDATE()
ORDER  BY show_time;

-- 3. Seat occupancy for a specific show
SELECT seat_row, seat_number, seat_type, status
FROM   vw_seat_status
WHERE  show_id = 1;

-- 4. Top-grossing movie so far
SELECT m.title, SUM(b.total_amount) AS revenue
FROM   bookings b
JOIN   shows  s ON s.show_id  = b.show_id
JOIN   movies m ON m.movie_id = s.movie_id
WHERE  b.status = 'CONFIRMED'
GROUP  BY m.movie_id
ORDER  BY revenue DESC;

-- 5. A user's full booking history
SELECT b.booking_id, m.title, s.show_date, s.show_time, b.total_amount
FROM   bookings b
JOIN   shows  s ON s.show_id  = b.show_id
JOIN   movies m ON m.movie_id = s.movie_id
WHERE  b.user_id = 1
ORDER  BY b.booking_time DESC;
```

---

## Features

- 5 movies with posters, genre, language, runtime, rating
- 3 theaters × 4 screens × 60 seats each
- Real-time seat map (greyed-out for booked seats)
- Atomic booking via stored procedure — no double-booking possible
- Brutalist UI: scanlines, noise, shuffle-text hover, scanning lasers
- Fully responsive (mobile / tablet / desktop)
- Offline demo-mode fallback

---

## Deploy to InfinityFree (free PHP + MySQL host)

1. Sign up at **[infinityfree.com](https://infinityfree.com)** → create an account → create a new hosting account (gives you a free `*.infinityfreeapp.com` subdomain).
2. Open **Control Panel → MySQL Databases** → create a database. Note the **host**, **database name**, **username**, and **password**.
3. Open **phpMyAdmin** (link in the control panel) → pick your new DB → **Import** → upload `sql/schema.sql` → **Go** → then import `sql/seed.sql` the same way.
   > Note: InfinityFree ignores the `CREATE DATABASE / USE scenekyahai;` lines — just run the file anyway, it'll create tables inside the DB you already selected.
4. Open **Online File Manager** (or connect via FTP) → go into `htdocs/` → upload the entire contents of this project.
5. Inside `htdocs/api/`, **create a new file `config.local.php`** with your real credentials:
   ```php
   <?php
   define('DB_HOST', 'sqlXXX.infinityfree.com');
   define('DB_NAME', 'if0_12345678_scenekyahai');
   define('DB_USER', 'if0_12345678');
   define('DB_PASS', 'your-password');
   ```
   This file is gitignored so your password never hits GitHub.
6. Visit `https://<your-subdomain>.infinityfreeapp.com/` — done.

---

## Swap in real movie posters

The seed data uses `placehold.co` placeholders so the project works offline.
Replace the `poster_url` in `sql/seed.sql` with real TMDB / IMDb URLs, e.g.:

```sql
UPDATE movies SET poster_url = 'https://image.tmdb.org/t/p/w500/<hash>.jpg'
WHERE movie_id = 1;
```
