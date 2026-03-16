import { query } from '../db/index.js';

export const createBand = async (req, res) => {
    const { name, description } = req.body;
    try {
        const creator_id = req.user.id;
        
        let profile_image = null;
        let banner_image = null;
        
        if (req.files) {
            if (req.files.profile_image) profile_image = `/uploads/images/${req.files.profile_image[0].filename}`;
            if (req.files.banner_image) banner_image = `/uploads/images/${req.files.banner_image[0].filename}`;
        }

        const newBand = await query(
            'INSERT INTO bands (creator_id, name, description, profile_image, banner_image) VALUES ($1, $2, $3, $4, $5) RETURNING *',
            [creator_id, name, description, profile_image, banner_image]
        );

        const band = newBand.rows[0];

        // Add creator as band member automatically
        await query(
            'INSERT INTO band_members (band_id, user_id, role_in_band) VALUES ($1, $2, $3)',
            [band.id, creator_id, 'Admin/Creator']
        );

        res.status(201).json(band);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error creating band' });
    }
};

export const getBands = async (req, res) => {
    try {
        const result = await query(`
            SELECT b.*, 
            (SELECT COUNT(*) FROM band_follows WHERE band_id = b.id) as follower_count
            FROM bands b ORDER BY b.created_at DESC
        `);
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

export const getBandById = async (req, res) => {
    try {
        const result = await query(`
            SELECT b.*, 
            (SELECT json_agg(json_build_object('user_id', u.id, 'username', u.username, 'role', bm.role_in_band, 'profile_picture', u.profile_picture))
             FROM band_members bm JOIN users u ON bm.user_id = u.id WHERE bm.band_id = b.id) as members,
            (SELECT COUNT(*) FROM band_follows WHERE band_id = b.id) as follower_count
            FROM bands b WHERE b.id = $1
        `, [req.params.id]);

        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'Band not found' });
        }
        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

export const updateBand = async (req, res) => {
    const { name, description } = req.body;
    const bandId = req.params.id;
    const userId = req.user.id;

    try {
        // Check ownership
        const band = await query('SELECT * FROM bands WHERE id = $1', [bandId]);
        if (band.rows.length === 0) return res.status(404).json({ message: 'Band not found' });
        if (band.rows[0].creator_id !== userId) return res.status(403).json({ message: 'Not authorized' });

        let updateFields = [];
        let values = [];
        let paramIndex = 1;

        if (name) { updateFields.push(`name = $${paramIndex++}`); values.push(name); }
        if (description !== undefined) { updateFields.push(`description = $${paramIndex++}`); values.push(description); }

        if (req.files) {
            if (req.files.profile_image) {
                updateFields.push(`profile_image = $${paramIndex++}`);
                values.push(`/uploads/images/${req.files.profile_image[0].filename}`);
            }
            if (req.files.banner_image) {
                updateFields.push(`banner_image = $${paramIndex++}`);
                values.push(`/uploads/images/${req.files.banner_image[0].filename}`);
            }
        }

        if (updateFields.length === 0) return res.status(400).json({ message: 'No fields to update' });

        values.push(bandId);
        const result = await query(
            `UPDATE bands SET ${updateFields.join(', ')} WHERE id = $${paramIndex} RETURNING *`,
            values
        );
        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error updating band' });
    }
};

export const deleteBand = async (req, res) => {
    const bandId = req.params.id;
    const userId = req.user.id;
    try {
        const band = await query('SELECT * FROM bands WHERE id = $1', [bandId]);
        if (band.rows.length === 0) return res.status(404).json({ message: 'Band not found' });
        if (band.rows[0].creator_id !== userId) return res.status(403).json({ message: 'Not authorized' });

        await query('DELETE FROM bands WHERE id = $1', [bandId]);
        res.json({ message: 'Band deleted successfully' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error deleting band' });
    }
};

export const getUserBands = async (req, res) => {
    const userId = req.user.id;
    try {
        const result = await query(`
            SELECT b.*, bm.role_in_band,
            (SELECT COUNT(*) FROM band_follows WHERE band_id = b.id) as follower_count,
            (SELECT COUNT(*) FROM songs WHERE band_id = b.id) as song_count
            FROM bands b 
            JOIN band_members bm ON b.id = bm.band_id 
            WHERE bm.user_id = $1 
            ORDER BY b.created_at DESC
        `, [userId]);
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

export const addBandMember = async (req, res) => {
    const { user_id, role_in_band } = req.body;
    const bandId = req.params.id;
    const userId = req.user.id;
    try {
        const band = await query('SELECT * FROM bands WHERE id = $1', [bandId]);
        if (band.rows.length === 0) return res.status(404).json({ message: 'Band not found' });
        if (band.rows[0].creator_id !== userId) return res.status(403).json({ message: 'Only the band creator can add members' });

        await query(
            'INSERT INTO band_members (band_id, user_id, role_in_band) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING',
            [bandId, user_id, role_in_band || 'Member']
        );
        res.json({ message: 'Member added' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

export const removeBandMember = async (req, res) => {
    const bandId = req.params.id;
    const memberId = req.params.userId;
    const userId = req.user.id;
    try {
        const band = await query('SELECT * FROM bands WHERE id = $1', [bandId]);
        if (band.rows.length === 0) return res.status(404).json({ message: 'Band not found' });
        if (band.rows[0].creator_id !== userId) return res.status(403).json({ message: 'Only the band creator can remove members' });
        if (parseInt(memberId) === userId) return res.status(400).json({ message: 'Cannot remove yourself as creator' });

        await query('DELETE FROM band_members WHERE band_id = $1 AND user_id = $2', [bandId, memberId]);
        res.json({ message: 'Member removed' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};
