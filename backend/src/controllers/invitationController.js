import { query } from '../db/index.js';

export const createInvitation = async (req, res) => {
    const { bandId } = req.params;
    const { inviteeId, role } = req.body;
    const inviterId = req.user.id;
    const inviterRole = req.bandRole; // From checkBandRole middleware

    if (!inviteeId || !role) {
        return res.status(400).json({ message: 'Invitee ID and role are required' });
    }

    try {
        // Validation: Editors cannot invite Admins
        if (inviterRole === 'editor' && role === 'admin') {
            return res.status(403).json({ message: 'Editors cannot invite Admins' });
        }

        // Validation: Only 1 pending invite per user/band
        const pendingCheck = await query(
            "SELECT id FROM invitations WHERE band_id = $1 AND invitee_id = $2 AND status = 'pending'",
            [bandId, inviteeId]
        );

        if (pendingCheck.rows.length > 0) {
            return res.status(400).json({ message: 'A pending invitation already exists for this user' });
        }

        // Check if user is already a member
        const memberCheck = await query(
            "SELECT role_in_band FROM band_members WHERE band_id = $1 AND user_id = $2",
            [bandId, inviteeId]
        );

        if (memberCheck.rows.length > 0) {
            return res.status(400).json({ message: 'User is already a member of this band' });
        }

        const result = await query(
            'INSERT INTO invitations (band_id, inviter_id, invitee_id, role) VALUES ($1, $2, $3, $4) RETURNING *',
            [bandId, inviterId, inviteeId, role]
        );

        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error creating invitation' });
    }
};

export const getBandInvitations = async (req, res) => {
    const { bandId } = req.params;

    try {
        const result = await query(
            `SELECT i.*, u.username as invitee_name, u.profile_picture as invitee_image 
             FROM invitations i 
             JOIN users u ON i.invitee_id = u.id 
             WHERE i.band_id = $1 
             ORDER BY i.created_at DESC`,
            [bandId]
        );

        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error fetching invitations' });
    }
};

export const getUserInvitations = async (req, res) => {
    const userId = req.user.id;

    try {
        const result = await query(
            `SELECT i.*, b.name as band_name, b.profile_image as band_image, u.username as inviter_name 
             FROM invitations i 
             JOIN bands b ON i.band_id = b.id 
             JOIN users u ON i.inviter_id = u.id 
             WHERE i.invitee_id = $1 AND i.status = 'pending' AND i.expires_at > CURRENT_TIMESTAMP
             ORDER BY i.created_at DESC`,
            [userId]
        );

        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error fetching invitations' });
    }
};

export const respondToInvitation = async (req, res) => {
    const { invitationId } = req.params;
    const { status } = req.body; // 'accepted' or 'rejected'
    const userId = req.user.id;

    if (!['accepted', 'rejected'].includes(status)) {
        return res.status(400).json({ message: 'Invalid status' });
    }

    try {
        const inviteResult = await query(
            "SELECT * FROM invitations WHERE id = $1 AND invitee_id = $2 AND status = 'pending' AND expires_at > CURRENT_TIMESTAMP",
            [invitationId, userId]
        );

        if (inviteResult.rows.length === 0) {
            return res.status(404).json({ message: 'Invitation not found or expired' });
        }

        const invite = inviteResult.rows[0];

        // Update invitation status
        await query('UPDATE invitations SET status = $1 WHERE id = $2', [status, invitationId]);

        if (status === 'accepted') {
            // Add to band members
            await query(
                'INSERT INTO band_members (band_id, user_id, role_in_band) VALUES ($1, $2, $3)',
                [invite.band_id, userId, invite.role]
            );
        }

        res.json({ message: `Invitation ${status}` });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error responding to invitation' });
    }
};
