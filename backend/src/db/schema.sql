DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS artist_monthly_stats CASCADE;
DROP TABLE IF EXISTS listening_history CASCADE;
DROP TABLE IF EXISTS streams CASCADE;
DROP TABLE IF EXISTS comments CASCADE;
DROP TABLE IF EXISTS band_follows CASCADE;
DROP TABLE IF EXISTS user_follows CASCADE;
DROP TABLE IF EXISTS favorites CASCADE;
DROP TABLE IF EXISTS likes CASCADE;
DROP TABLE IF EXISTS playlist_songs CASCADE;
DROP TABLE IF EXISTS playlists CASCADE;
DROP TABLE IF EXISTS songs_genres CASCADE;
DROP TABLE IF EXISTS genres CASCADE;
DROP TABLE IF EXISTS album_songs CASCADE;
DROP TABLE IF EXISTS songs CASCADE;
DROP TABLE IF EXISTS albums CASCADE;
DROP TABLE IF EXISTS band_widgets CASCADE;
DROP TABLE IF EXISTS invitations CASCADE;
DROP TABLE IF EXISTS band_members CASCADE;
DROP TABLE IF EXISTS bands CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TYPE IF EXISTS band_role CASCADE;

CREATE TYPE band_role AS ENUM ('admin', 'editor', 'member');

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    profile_picture VARCHAR(255),
    bio TEXT,
    role VARCHAR(20) DEFAULT 'listener' CHECK (role IN ('listener', 'artist')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE bands (
    id SERIAL PRIMARY KEY,
    creator_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    profile_image VARCHAR(255),
    banner_image VARCHAR(255),
    total_streams INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE band_members (
    band_id INTEGER REFERENCES bands(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    role_in_band band_role NOT NULL DEFAULT 'member',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY(band_id, user_id)
);

CREATE TABLE invitations (
    id SERIAL PRIMARY KEY,
    band_id INTEGER REFERENCES bands(id) ON DELETE CASCADE,
    inviter_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    invitee_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    role band_role NOT NULL DEFAULT 'member',
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP + INTERVAL '7 days')
);

CREATE UNIQUE INDEX unique_pending_invite ON invitations (band_id, invitee_id) WHERE status = 'pending';

CREATE TABLE albums (
    id SERIAL PRIMARY KEY,
    band_id INTEGER REFERENCES bands(id) ON DELETE CASCADE,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    cover_image VARCHAR(255),
    release_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE songs (
    id SERIAL PRIMARY KEY,
    band_id INTEGER REFERENCES bands(id) ON DELETE CASCADE,
    uploaded_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    audio_url VARCHAR(255) NOT NULL,
    cover_image VARCHAR(255),
    duration INTEGER NOT NULL DEFAULT 0,
    release_date DATE,
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'published')),
    tags JSONB,
    play_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE genres (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE songs_genres (
    song_id INTEGER REFERENCES songs(id) ON DELETE CASCADE,
    genre_id INTEGER REFERENCES genres(id) ON DELETE CASCADE,
    PRIMARY KEY(song_id, genre_id)
);

CREATE TABLE album_songs (
    album_id INTEGER REFERENCES albums(id) ON DELETE CASCADE,
    song_id INTEGER REFERENCES songs(id) ON DELETE CASCADE,
    position INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY(album_id, song_id)
);

CREATE TABLE band_widgets (
    id SERIAL PRIMARY KEY,
    band_id INTEGER REFERENCES bands(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('latest_release', 'bio', 'social_links', 'featured_video', 'merch', 'popular_songs', 'albums', 'playlists', 'custom')),
    title VARCHAR(100),
    position INTEGER NOT NULL DEFAULT 0,
    settings JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE playlists (
    id SERIAL PRIMARY KEY,
    creator_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    cover_image VARCHAR(255),
    is_public BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE playlist_songs (
    playlist_id INTEGER REFERENCES playlists(id) ON DELETE CASCADE,
    song_id INTEGER REFERENCES songs(id) ON DELETE CASCADE,
    position INTEGER NOT NULL DEFAULT 0,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY(playlist_id, song_id)
);

CREATE TABLE likes (
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    song_id INTEGER REFERENCES songs(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY(user_id, song_id)
);

CREATE TABLE favorites (
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    song_id INTEGER REFERENCES songs(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY(user_id, song_id)
);

CREATE TABLE user_follows (
    follower_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    followed_user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY(follower_id, followed_user_id)
);

CREATE TABLE band_follows (
    follower_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    band_id INTEGER REFERENCES bands(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY(follower_id, band_id)
);

CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    song_id INTEGER REFERENCES songs(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE streams (
    id SERIAL PRIMARY KEY,
    song_id INTEGER REFERENCES songs(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    played_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE listening_history (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    song_id INTEGER REFERENCES songs(id) ON DELETE CASCADE,
    listened_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE artist_monthly_stats (
    id SERIAL PRIMARY KEY,
    band_id INTEGER REFERENCES bands(id) ON DELETE CASCADE,
    month DATE NOT NULL,
    monthly_listeners INTEGER DEFAULT 0,
    total_streams INTEGER DEFAULT 0,
    playlist_additions INTEGER DEFAULT 0,
    likes INTEGER DEFAULT 0,
    followers_growth INTEGER DEFAULT 0,
    UNIQUE(band_id, month)
);

CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('like', 'comment', 'user_follow', 'band_follow', 'invitation')),
    actor_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    reference_id INTEGER,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_songs_band_status ON songs(band_id, status);
CREATE INDEX idx_songs_created_at ON songs(created_at DESC);
CREATE INDEX idx_playlist_songs_playlist_position ON playlist_songs(playlist_id, position);
CREATE INDEX idx_album_songs_album_position ON album_songs(album_id, position);
CREATE INDEX idx_streams_song_played_at ON streams(song_id, played_at DESC);
CREATE INDEX idx_band_follows_band_created_at ON band_follows(band_id, created_at DESC);
CREATE INDEX idx_band_widgets_band_position ON band_widgets(band_id, position);
