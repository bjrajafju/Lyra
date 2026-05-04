import { query } from '../db/index.js';

export const getBandMembers = async (req, res) => {
    const { bandId } = req.params;

    try {
        const result = await query(`
            SELECT bm.user_id, u.username, u.profile_picture, bm.role_in_band as role, bm.created_at
            FROM band_members bm
            JOIN users u ON bm.user_id = u.id
            WHERE bm.band_id = $1
            ORDER BY 
                CASE bm.role_in_band 
                    WHEN 'admin' THEN 1 
                    WHEN 'editor' THEN 2 
                    WHEN 'member' THEN 3 
                END, 
                u.username ASC
        `, [bandId]);

        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error fetching members' });
    }
};

export const updateMemberRole = async (req, res) => {
    const { bandId, userId } = req.params;
    const { role } = req.body; // new role
    const inviterRole = req.bandRole; // From checkBandRole middleware

    if (!['admin', 'editor', 'member'].includes(role)) {
        return res.status(400).json({ message: 'Invalid role' });
    }

    try {
        // Fetch target member current role
        const targetResult = await query(
            'SELECT role_in_band FROM band_members WHERE band_id = $1 AND user_id = $2',
            [bandId, userId]
        );

        if (targetResult.rows.length === 0) {
            return res.status(404).json({ message: 'Member not found' });
        }

        const currentRole = targetResult.rows[0].role_in_band;

        // PERMISSION LOGIC
        // Admins can do anything
        // Editors can only manage 'member' role (cannot promote to admin, cannot demote admins/editors)
        if (inviterRole === 'editor') {
            if (currentRole !== 'member' || (role !== 'member' && role !== 'editor')) {
                return res.status(403).json({ message: 'Editors can only manage member roles' });
            }
            if (role === 'admin') {
                return res.status(403).json({ message: 'Editors cannot promote members to Admin' });
            }
        }

        await query(
            'UPDATE band_members SET role_in_band = $1, updated_at = CURRENT_TIMESTAMP WHERE band_id = $2 AND user_id = $3',
            [role, bandId, userId]
        );

        res.json({ message: 'Member role updated' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error updating role' });
    }
};

export const removeMember = async (req, res) => {
    const { bandId, userId } = req.params;
    const inviterRole = req.bandRole;

    try {
        const targetResult = await query(
            'SELECT role_in_band FROM band_members WHERE band_id = $1 AND user_id = $2',
            [bandId, userId]
        );

        if (targetResult.rows.length === 0) {
            return res.status(404).json({ message: 'Member not found' });
        }

        const currentRole = targetResult.rows[0].role_in_band;

        // PERMISSION LOGIC
        if (inviterRole === 'editor') {
            if (currentRole !== 'member') {
                return res.status(403).json({ message: 'Editors can only remove members' });
            }
        }

        // Check if removing the last admin
        if (currentRole === 'admin') {
            const adminCount = await query(
                "SELECT COUNT(*) FROM band_members WHERE band_id = $1 AND role_in_band = 'admin'",
                [bandId]
            );
            if (parseInt(adminCount.rows[0].count) <= 1) {
                return res.status(400).json({ message: 'Cannot remove the last Admin' });
            }
        }

        await query('DELETE FROM band_members WHERE band_id = $1 AND user_id = $2', [bandId, userId]);

        res.json({ message: 'Member removed' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error removing member' });
    }
};

export const leaveBand = async (req, res) => {
    const { bandId } = req.params;
    const userId = req.user.id;

    try {
        const targetResult = await query(
            'SELECT role_in_band FROM band_members WHERE band_id = $1 AND user_id = $2',
            [bandId, userId]
        );

        if (targetResult.rows.length === 0) {
            return res.status(404).json({ message: 'You are not a member of this band' });
        }

        const currentRole = targetResult.rows[0].role_in_band;

        // Check if last admin
        if (currentRole === 'admin') {
            const adminCount = await query(
                "SELECT COUNT(*) FROM band_members WHERE band_id = $1 AND role_in_band = 'admin'",
                [bandId]
            );
            if (parseInt(adminCount.rows[0].count) <= 1) {
                return res.status(400).json({ message: 'The last Admin cannot leave the band' });
            }
        }

        await query('DELETE FROM band_members WHERE band_id = $1 AND user_id = $2', [bandId, userId]);

        res.json({ message: 'You have left the band' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error leaving band' });
    }
};
