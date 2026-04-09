/* ═══════════════════════════════════════════════════════════════
   SceneKyaHai · Front-end logic
   Talks to /api/*.php endpoints. Falls back to an in-memory demo
   dataset when the backend isn't reachable (so the UI still works
   from a plain file:// preview).
   ═══════════════════════════════════════════════════════════════ */

// ── Config ─────────────────────────────────────────────────
const API_BASE = 'api';          // relative to index.html
const DEMO_USER_ID = 1;
const CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789#@$%&!';

// ── Demo fallback data (used if API call fails) ─────────────
const DEMO_MOVIES = [
    { movie_id: 1, title: 'Dune: Part Two',  genre: 'Sci-Fi / Epic',          language: 'English', duration_min: 166, certificate: 'UA', imdb_rating: 8.5,
      poster_url: 'https://placehold.co/500x750/050505/ff3333/?font=oswald&text=DUNE%0APART%0ATWO',
      description: 'Paul Atreides unites with Chani and the Fremen while on a warpath of revenge.' },
    { movie_id: 2, title: 'Oppenheimer',     genre: 'Biography / Drama',      language: 'English', duration_min: 180, certificate: 'UA', imdb_rating: 8.3,
      poster_url: 'https://placehold.co/500x750/050505/ff3333/?font=oswald&text=OPPEN-%0AHEIMER',
      description: 'The story of J. Robert Oppenheimer and the atomic bomb.' },
    { movie_id: 3, title: 'Kalki 2898 AD',   genre: 'Sci-Fi / Mythological',  language: 'Hindi',   duration_min: 181, certificate: 'UA', imdb_rating: 7.5,
      poster_url: 'https://placehold.co/500x750/050505/0000ff/?font=oswald&text=KALKI%0A2898+AD',
      description: 'In a dystopian future, a modern avatar comes to save the world.' },
    { movie_id: 4, title: 'Jawan',           genre: 'Action / Thriller',      language: 'Hindi',   duration_min: 169, certificate: 'UA', imdb_rating: 7.0,
      poster_url: 'https://placehold.co/500x750/050505/ff3333/?font=oswald&text=JAWAN',
      description: 'A man driven by vendetta sets out to rectify societal wrongs.' },
    { movie_id: 5, title: 'Interstellar',    genre: 'Sci-Fi / Adventure',     language: 'English', duration_min: 169, certificate: 'UA', imdb_rating: 8.7,
      poster_url: 'https://placehold.co/500x750/050505/0000ff/?font=oswald&text=INTER-%0ASTELLAR',
      description: 'Explorers travel through a wormhole to ensure humanity\'s survival.' },
];

const DEMO_THEATERS = [
    { id: 1, name: 'PVR ICON',                location: 'Phoenix Marketcity, Kurla',  screen: 'AUDI 1 — IMAX' },
    { id: 2, name: 'INOX MEGAPLEX',           location: 'Inorbit Mall, Malad',        screen: 'SCREEN A' },
    { id: 3, name: 'CINEPOLIS FUN REPUBLIC',  location: 'Andheri West',               screen: 'GOLD CLASS' },
];

// ── Runtime state ───────────────────────────────────────────
const state = {
    apiOK: true,
    movies: [],
    currentMovie: null,
    currentShow: null,
    selectedSeats: new Set(),
    seatData: [],
};

// ═══════════════════════════════════════════════════════════
//   API helpers
// ═══════════════════════════════════════════════════════════
async function apiGet(path) {
    const res = await fetch(`${API_BASE}/${path}`);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const j = await res.json();
    if (!j.ok) throw new Error(j.error || 'API error');
    return j.data;
}

async function apiPost(path, body) {
    const res = await fetch(`${API_BASE}/${path}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
    });
    const j = await res.json();
    if (!j.ok) throw new Error(j.error || 'API error');
    return j.data;
}

// ═══════════════════════════════════════════════════════════
//   Text shuffle effect (used on nav + buttons)
// ═══════════════════════════════════════════════════════════
function shuffleText(el, finalText, dur = 480) {
    let start = null;
    function step(ts) {
        if (!start) start = ts;
        const p = Math.min((ts - start) / dur, 1);
        const reveal = Math.floor(p * finalText.length);
        let out = '';
        for (let i = 0; i < finalText.length; i++) {
            if (i < reveal || ' []\'·→?'.indexOf(finalText[i]) > -1) out += finalText[i];
            else out += CHARS[Math.floor(Math.random() * CHARS.length)];
        }
        el.textContent = out;
        if (p < 1) requestAnimationFrame(step);
        else el.textContent = finalText;
    }
    requestAnimationFrame(step);
}

document.querySelectorAll('.nav-item, .btn').forEach(el => {
    el.setAttribute('data-text', el.textContent.trim());
    el.addEventListener('mouseenter', () => shuffleText(el, el.getAttribute('data-text'), 420));
});

// ═══════════════════════════════════════════════════════════
//   Modal helpers
// ═══════════════════════════════════════════════════════════
function openModal(id)  { document.getElementById(id).classList.add('active'); document.body.style.overflow = 'hidden'; }
function closeModal(id) { document.getElementById(id).classList.remove('active'); document.body.style.overflow = ''; }

document.querySelectorAll('[data-close]').forEach(btn =>
    btn.addEventListener('click', () => closeModal(btn.dataset.close)));

document.querySelectorAll('.modal').forEach(modal =>
    modal.addEventListener('click', (e) => {
        if (e.target === modal) closeModal(modal.id);
    }));

document.addEventListener('keydown', e => {
    if (e.key === 'Escape') document.querySelectorAll('.modal.active').forEach(m => closeModal(m.id));
});

// ═══════════════════════════════════════════════════════════
//   1. Load + render movies
// ═══════════════════════════════════════════════════════════
async function loadMovies() {
    const grid = document.getElementById('movies-grid');
    try {
        state.movies = await apiGet('movies.php');
        state.apiOK = true;
    } catch (e) {
        console.warn('API unavailable — using demo data:', e.message);
        state.movies = DEMO_MOVIES;
        state.apiOK = false;
    }
    renderMovies(grid, state.movies);
}

function renderMovies(grid, movies) {
    grid.innerHTML = '';
    movies.forEach((m, i) => {
        const card = document.createElement('div');
        card.className = 'movie-card';
        card.style.animationDelay = `${i * 0.08}s`;
        card.innerHTML = `
            <div class="movie-poster">
                <img src="${m.poster_url}" alt="${m.title}" loading="lazy"
                     onerror="this.src='https://placehold.co/500x750/050505/ff3333/?text=${encodeURIComponent(m.title)}'" />
                <span class="badge-cert">${m.certificate || 'U'}</span>
                <span class="badge-rating">★ ${m.imdb_rating ?? '—'}</span>
                <div class="poster-scan"></div>
            </div>
            <div class="movie-info">
                <div class="movie-title">${m.title}</div>
                <div class="movie-meta">
                    <span>${m.genre}</span>
                    <span class="dot">·</span>
                    <span>${m.language}</span>
                    <span class="dot">·</span>
                    <span>${m.duration_min}m</span>
                </div>
                <div class="book-link">[ SELECT SHOWTIME → ]</div>
            </div>
        `;
        card.addEventListener('click', () => openShowtimes(m));
        grid.appendChild(card);
    });
}

// ═══════════════════════════════════════════════════════════
//   2. Showtime picker
// ═══════════════════════════════════════════════════════════
async function openShowtimes(movie) {
    state.currentMovie = movie;
    document.getElementById('show-movie-title').textContent = movie.title;
    document.getElementById('show-movie-meta').textContent =
        `${movie.genre} · ${movie.language} · ${movie.duration_min}m · ${movie.certificate}`;
    openModal('modal-shows');

    const list = document.getElementById('shows-list');
    list.innerHTML = '<div class="loading-state">LOADING SHOWS...</div>';

    let shows = [];
    if (state.apiOK) {
        try { shows = await apiGet(`shows.php?movie_id=${movie.movie_id}`); }
        catch (e) { console.warn(e); shows = []; }
    }
    if (!shows.length) shows = demoShowsFor(movie);

    renderShowtimes(list, shows);
}

function demoShowsFor(movie) {
    // Build 3 synthetic shows across the demo theaters
    const base = new Date(); base.setHours(0, 0, 0, 0);
    return DEMO_THEATERS.map((t, idx) => ({
        show_id:        `demo-${movie.movie_id}-${t.id}`,
        movie_id:       movie.movie_id,
        movie_title:    movie.title,
        poster_url:     movie.poster_url,
        theater_name:   t.name,
        theater_location: t.location,
        screen_name:    t.screen,
        show_date:      base.toISOString().slice(0, 10),
        show_time:      ['13:30:00', '18:45:00', '22:15:00'][idx],
        price:          [320, 380, 450][idx],
        duration_min:   movie.duration_min,
        total_seats:    60,
        _demo: true,
    }));
}

function fmtTime(t) {
    const [h, m] = t.split(':').map(Number);
    const suf = h >= 12 ? 'PM' : 'AM';
    const hh = ((h + 11) % 12) + 1;
    return `${hh}:${String(m).padStart(2, '0')} ${suf}`;
}

function fmtDate(d) {
    const dt = new Date(d);
    return dt.toLocaleDateString('en-IN', { weekday: 'short', day: '2-digit', month: 'short' }).toUpperCase();
}

function renderShowtimes(list, shows) {
    list.innerHTML = '';
    if (!shows.length) {
        list.innerHTML = '<div class="loading-state">NO SHOWS AVAILABLE</div>';
        return;
    }

    // Group by theater
    const grouped = {};
    shows.forEach(s => {
        const key = `${s.theater_name}||${s.theater_location || ''}`;
        (grouped[key] = grouped[key] || []).push(s);
    });

    Object.entries(grouped).forEach(([key, rows]) => {
        const [name, loc] = key.split('||');
        const div = document.createElement('div');
        div.className = 'showtime-group';
        div.innerHTML = `
            <div class="theater-line">
                <div>
                    <div class="theater-name">${name}</div>
                    <div class="theater-location">${loc}</div>
                </div>
                <div class="theater-location">${fmtDate(rows[0].show_date)}</div>
            </div>
            <div class="showtime-buttons"></div>
        `;
        const btnRow = div.querySelector('.showtime-buttons');
        rows.forEach(s => {
            const btn = document.createElement('button');
            btn.className = 'showtime-btn';
            btn.innerHTML = `${fmtTime(s.show_time)}<span class="price">₹${Number(s.price).toFixed(0)}</span>`;
            btn.addEventListener('click', () => openSeatPicker(s));
            btnRow.appendChild(btn);
        });
        list.appendChild(div);
    });
}

// ═══════════════════════════════════════════════════════════
//   3. Seat picker
// ═══════════════════════════════════════════════════════════
async function openSeatPicker(show) {
    state.currentShow = show;
    state.selectedSeats.clear();

    closeModal('modal-shows');
    openModal('modal-seats');

    document.getElementById('seat-movie-title').textContent = state.currentMovie.title;
    document.getElementById('seat-show-meta').textContent =
        `${show.theater_name} · ${show.screen_name} · ${fmtDate(show.show_date)} · ${fmtTime(show.show_time)} · ₹${Number(show.price).toFixed(0)}/seat`;

    const map = document.getElementById('seat-map');
    map.innerHTML = '<div class="loading-state">LOADING SEATS...</div>';

    let seats = [];
    if (state.apiOK && !show._demo) {
        try { ({ seats } = await apiGet(`seats.php?show_id=${show.show_id}`)); }
        catch (e) { console.warn(e); seats = []; }
    }
    if (!seats.length) seats = buildDemoSeats();

    state.seatData = seats;
    renderSeats(map, seats);
    updateCheckout();
}

function buildDemoSeats() {
    const rows = ['A', 'B', 'C', 'D', 'E', 'F'];
    const types = { A: 'PREMIUM', B: 'PREMIUM', C: 'STANDARD', D: 'STANDARD', E: 'STANDARD', F: 'RECLINER' };
    const seats = [];
    let id = 1;
    // Randomly mark ~20% as booked for realism
    rows.forEach(r => {
        for (let n = 1; n <= 10; n++) {
            seats.push({
                seat_id:     `d-${id++}`,
                seat_row:    r,
                seat_number: n,
                seat_type:   types[r],
                status:      Math.random() < 0.18 ? 'BOOKED' : 'AVAILABLE',
            });
        }
    });
    return seats;
}

function renderSeats(container, seats) {
    container.innerHTML = '';
    const byRow = {};
    seats.forEach(s => (byRow[s.seat_row] = byRow[s.seat_row] || []).push(s));

    Object.keys(byRow).sort().forEach(row => {
        const rowEl = document.createElement('div');
        rowEl.className = 'seat-row';
        rowEl.innerHTML = `<div class="row-label">${row}</div>`;

        byRow[row].sort((a, b) => a.seat_number - b.seat_number).forEach(s => {
            const btn = document.createElement('button');
            btn.className = 'seat';
            btn.textContent = s.seat_number;
            if (s.seat_type === 'PREMIUM')  btn.classList.add('premium');
            if (s.seat_type === 'RECLINER') btn.classList.add('recliner');
            if (s.status === 'BOOKED') {
                btn.classList.add('booked');
                btn.disabled = true;
            } else {
                btn.addEventListener('click', () => toggleSeat(btn, s));
            }
            rowEl.appendChild(btn);
        });

        rowEl.appendChild(Object.assign(document.createElement('div'), { className: 'row-label', textContent: row }));
        container.appendChild(rowEl);
    });
}

function toggleSeat(btn, seat) {
    if (state.selectedSeats.has(seat.seat_id)) {
        state.selectedSeats.delete(seat.seat_id);
        btn.classList.remove('selected');
    } else {
        if (state.selectedSeats.size >= 10) {
            alert('Maximum 10 seats per booking.');
            return;
        }
        state.selectedSeats.add(seat.seat_id);
        btn.classList.add('selected');
    }
    updateCheckout();
}

function updateCheckout() {
    const count = state.selectedSeats.size;
    const price = Number(state.currentShow?.price || 0);
    const total = count * price;

    document.getElementById('selected-count').textContent =
        count === 0 ? '0 SEATS SELECTED' : `${count} SEAT${count > 1 ? 'S' : ''} SELECTED`;
    document.getElementById('checkout-total').textContent = `₹${total.toFixed(0)}`;
    document.getElementById('confirm-booking-btn').disabled = count === 0;
}

// ═══════════════════════════════════════════════════════════
//   4. Confirm booking
// ═══════════════════════════════════════════════════════════
document.getElementById('confirm-booking-btn').addEventListener('click', confirmBooking);

async function confirmBooking() {
    const btn = document.getElementById('confirm-booking-btn');
    btn.disabled = true;
    btn.textContent = 'PROCESSING...';

    const seatIds = Array.from(state.selectedSeats);
    const show = state.currentShow;

    let booking;
    if (state.apiOK && !show._demo) {
        try {
            booking = await apiPost('booking.php', {
                user_id:  DEMO_USER_ID,
                show_id:  show.show_id,
                seat_ids: seatIds,
            });
        } catch (e) {
            alert('Booking failed: ' + e.message);
            btn.disabled = false;
            btn.textContent = 'CONFIRM BOOKING →';
            return;
        }
    } else {
        // Demo mode — synthesize a confirmation
        const seatLabels = state.seatData
            .filter(s => state.selectedSeats.has(s.seat_id))
            .map(s => `${s.seat_row}${s.seat_number}`)
            .join(',');
        booking = {
            booking_id:   Math.floor(Math.random() * 90000) + 10000,
            total_amount: seatIds.length * Number(show.price),
            movie_title:  state.currentMovie.title,
            show_date:    show.show_date,
            show_time:    show.show_time,
            theater_name: show.theater_name,
            screen_name:  show.screen_name,
            seats:        seatLabels,
        };
    }

    closeModal('modal-seats');
    showConfirmation(booking);

    btn.disabled = false;
    btn.textContent = 'CONFIRM BOOKING →';
    state.selectedSeats.clear();
}

function showConfirmation(b) {
    document.getElementById('cf-id').textContent     = '#' + String(b.booking_id).padStart(6, '0');
    document.getElementById('cf-movie').textContent  = b.movie_title;
    document.getElementById('cf-datetime').textContent = `${fmtDate(b.show_date)} · ${fmtTime(b.show_time)}`;
    document.getElementById('cf-theater').textContent = b.theater_name;
    document.getElementById('cf-screen').textContent  = b.screen_name;
    document.getElementById('cf-seats').textContent   = b.seats;
    document.getElementById('cf-amount').textContent  = `₹${Number(b.total_amount).toFixed(0)}`;
    openModal('modal-confirm');

    // dramatic shuffle on the title
    const t = document.getElementById('cf-title');
    shuffleText(t, 'BOOKING CONFIRMED', 900);
}

// ═══════════════════════════════════════════════════════════
//   Kick it off
// ═══════════════════════════════════════════════════════════
loadMovies();
