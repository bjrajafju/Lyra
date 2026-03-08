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
        const result = await query('SELECT * FROM bands ORDER BY created_at DESC');
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
            (SELECT json_agg(json_build_object('user_id', u.id, 'username', u.username, 'role', bm.role_in_band))
             FROM band_members bm JOIN users u ON bm.user_id = u.id WHERE bm.band_id = b.id) as members
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
