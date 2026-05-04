-- Controlled list of genres
INSERT INTO genres (name) VALUES 
('Pop'),
('Rock'),
('Metal'),
('Jazz'),
('Blues'),
('Classical'),
('Electronic'),
('Hip Hop'),
('R&B'),
('Country'),
('Reggae'),
('Folk'),
('Punk'),
('Indie'),
('Latin'),
('World'),
('Soul'),
('Funk'),
('Techno'),
('House')
ON CONFLICT (name) DO NOTHING;
