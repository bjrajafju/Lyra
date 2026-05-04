-- Migration: Rename settings to config in band_widgets
-- This fixes Issue 4: DATABASE ERROR

DO $$ 
BEGIN 
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'band_widgets' AND column_name = 'settings'
    ) THEN
        ALTER TABLE band_widgets RENAME COLUMN settings TO config;
    END IF;
END $$;
