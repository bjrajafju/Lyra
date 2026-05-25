import { query } from "../db/index.js";

export const getBandWidgets = async (req, res) => {
    const { bandId } = req.params;
    try {
        const result = await query(
            "SELECT * FROM band_widgets WHERE band_id = $1 ORDER BY position ASC",
            [bandId],
        );
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Error fetching widgets" });
    }
};

export const getPublicBandLayout = async (req, res) => {
    const { bandId } = req.params;
    try {
        // Publicly we only return active/valid widgets. 
        // We might want to filter out draft or specific types if needed in the future.
        // For now, return all widgets but exclude internal editor-only metadata if any.
        const result = await query(
            "SELECT id, type, settings, position FROM band_widgets WHERE band_id = $1 ORDER BY position ASC",
            [bandId],
        );
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Error fetching public layout" });
    }
};

export const createWidget = async (req, res) => {
    const { bandId } = req.params;
    const { type, settings } = req.body;

    try {
        const posResult = await query(
            "SELECT COALESCE(MAX(position), 0) + 1 as next_pos FROM band_widgets WHERE band_id = $1",
            [bandId],
        );

        const result = await query(
            "INSERT INTO band_widgets (band_id, type, settings, position) VALUES ($1, $2, $3, $4) RETURNING *",
            [bandId, type, settings || {}, posResult.rows[0].next_pos],
        );
        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Error creating widget" });
    }
};

export const updateWidget = async (req, res) => {
    const { widgetId } = req.params;
    const { settings, position } = req.body;

    try {
        let updateFields = ["updated_at = CURRENT_TIMESTAMP"];
        let params = [widgetId];
        let pIndex = 2;

        if (settings !== undefined) {
            updateFields.push(`settings = $${pIndex++}`);
            params.push(JSON.stringify(settings));
        }
        if (position !== undefined) {
            updateFields.push(`position = $${pIndex++}`);
            params.push(position);
        }

        const result = await query(
            `UPDATE band_widgets SET ${updateFields.join(", ")} WHERE id = $1 RETURNING *`,
            params,
        );

        if (result.rows.length === 0)
            return res.status(404).json({ message: "Widget not found" });
        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Error updating widget" });
    }
};

export const deleteWidget = async (req, res) => {
    const { widgetId } = req.params;
    try {
        const result = await query(
            "DELETE FROM band_widgets WHERE id = $1 RETURNING *",
            [widgetId],
        );
        if (result.rows.length === 0)
            return res.status(404).json({ message: "Widget not found" });
        res.json({ message: "Widget deleted" });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Error deleting widget" });
    }
};

export const reorderWidgets = async (req, res) => {
    const { bandId } = req.params;
    const { widgetOrders } = req.body; // Array of { id, position }

    if (!widgetOrders || !Array.isArray(widgetOrders)) {
        return res
            .status(400)
            .json({ message: "widgetOrders array is required" });
    }

    try {
        for (const order of widgetOrders) {
            await query(
                "UPDATE band_widgets SET position = $1 WHERE id = $2 AND band_id = $3",
                [order.position, order.id, bandId],
            );
        }
        res.json({ message: "Widgets reordered" });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Error reordering widgets" });
    }
};
