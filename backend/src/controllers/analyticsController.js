import { query } from '../db/index.js';

export const getBandAnalytics = async (req, res) => {
    const { band_id } = req.params;
    const user_id = req.user.id;
    try {
        // Check member
        const mem = await query('SELECT * FROM band_members WHERE band_id = $1 AND user_id = $2', [band_id, user_id]);
        if (mem.rows.length === 0) return res.status(403).json({ message: 'Not authorized for this band' });

        const bandInfo = await query('SELECT total_streams, created_at FROM bands WHERE id = $1', [band_id]);
        
        // Sum song stats directly
        const likes = await query('SELECT COUNT(*) FROM likes l JOIN songs s ON l.song_id = s.id WHERE s.band_id = $1', [band_id]);
        const followers = await query('SELECT COUNT(*) FROM band_follows WHERE band_id = $1', [band_id]);

        const topSongs = await query(`
            SELECT s.id, s.title, s.play_count, s.cover_image,
            (SELECT COUNT(*) FROM likes WHERE song_id = s.id) as like_count
            FROM songs s WHERE s.band_id = $1 ORDER BY s.play_count DESC LIMIT 5
        `, [band_id]);

        // Monthly listeners (unique users who streamed in last 30 days)
        const monthlyListeners = await query(`
            SELECT COUNT(DISTINCT st.user_id) as count 
            FROM streams st 
            JOIN songs s ON st.song_id = s.id 
            WHERE s.band_id = $1 AND st.user_id IS NOT NULL AND st.played_at > NOW() - INTERVAL '30 days'
        `, [band_id]);

        // Recent streams count (last 30 days)
        const recentStreams = await query(`
            SELECT COUNT(*) as count 
            FROM streams st 
            JOIN songs s ON st.song_id = s.id 
            WHERE s.band_id = $1 AND st.played_at > NOW() - INTERVAL '30 days'
        `, [band_id]);

        // Playlist additions
        const playlistAdds = await query(`
            SELECT COUNT(*) as count 
            FROM playlist_songs ps 
            JOIN songs s ON ps.song_id = s.id 
            WHERE s.band_id = $1
        `, [band_id]);

        // Follower growth (last 30 days)
        const newFollowers = await query(`
            SELECT COUNT(*) as count 
            FROM band_follows 
            WHERE band_id = $1 AND created_at > NOW() - INTERVAL '30 days'
        `, [band_id]);

        const streamsOverTime = await query(`
            SELECT DATE_TRUNC('day', st.played_at) AS day, COUNT(*)::int AS stream_count
            FROM streams st
            JOIN songs s ON st.song_id = s.id
            WHERE s.band_id = $1 AND st.played_at > NOW() - INTERVAL '30 days'
            GROUP BY day
            ORDER BY day ASC
        `, [band_id]);

        const listenersPerMonth = await query(`
            SELECT DATE_TRUNC('month', st.played_at) AS month, COUNT(DISTINCT st.user_id)::int AS listeners
            FROM streams st
            JOIN songs s ON st.song_id = s.id
            WHERE s.band_id = $1 AND st.user_id IS NOT NULL AND st.played_at > NOW() - INTERVAL '12 months'
            GROUP BY month
            ORDER BY month ASC
        `, [band_id]);

        const followerGrowth = await query(`
            SELECT DATE_TRUNC('month', bf.created_at) AS month, COUNT(*)::int AS followers
            FROM band_follows bf
            WHERE bf.band_id = $1 AND bf.created_at > NOW() - INTERVAL '12 months'
            GROUP BY month
            ORDER BY month ASC
        `, [band_id]);

        const recentActivity = await query(`
            SELECT 'stream'::text AS type, st.played_at AS created_at, s.title AS song_title
            FROM streams st
            JOIN songs s ON st.song_id = s.id
            WHERE s.band_id = $1
            UNION ALL
            SELECT 'playlist_add'::text AS type, ps.added_at AS created_at, s.title AS song_title
            FROM playlist_songs ps
            JOIN songs s ON ps.song_id = s.id
            WHERE s.band_id = $1
            UNION ALL
            SELECT 'like'::text AS type, l.created_at AS created_at, s.title AS song_title
            FROM likes l
            JOIN songs s ON l.song_id = s.id
            WHERE s.band_id = $1
            ORDER BY created_at DESC
            LIMIT 20
        `, [band_id]);

        res.json({
            total_streams: bandInfo.rows[0]?.total_streams || 0,
            total_likes: parseInt(likes.rows[0].count),
            total_followers: parseInt(followers.rows[0].count),
            monthly_listeners: parseInt(monthlyListeners.rows[0].count),
            recent_streams: parseInt(recentStreams.rows[0].count),
            playlist_additions: parseInt(playlistAdds.rows[0].count),
            new_followers_30d: parseInt(newFollowers.rows[0].count),
            top_songs: topSongs.rows,
            streams_over_time: streamsOverTime.rows,
            listeners_per_month: listenersPerMonth.rows,
            follower_growth: followerGrowth.rows,
            recent_activity: recentActivity.rows
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Analytics error' });
    }
};

export const getSongStats = async (req, res) => {
    const { band_id } = req.params;
    const user_id = req.user.id;
    try {
        const mem = await query('SELECT * FROM band_members WHERE band_id = $1 AND user_id = $2', [band_id, user_id]);
        if (mem.rows.length === 0) return res.status(403).json({ message: 'Not authorized' });

        const result = await query(`
            SELECT s.id, s.title, s.play_count, s.cover_image, s.created_at,
            (SELECT COUNT(*) FROM likes WHERE song_id = s.id) as like_count,
            (SELECT COUNT(*) FROM favorites WHERE song_id = s.id) as favorite_count,
            (SELECT COUNT(*) FROM playlist_songs WHERE song_id = s.id) as playlist_count
            FROM songs s WHERE s.band_id = $1 ORDER BY s.play_count DESC
        `, [band_id]);

        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error fetching song stats' });
    }
};
