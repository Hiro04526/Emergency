-- Function to get a username by user ID
CREATE OR REPLACE FUNCTION get_username_by_user(p_uid uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_username text;
BEGIN
    -- Get the username from the profiles table
    SELECT username INTO v_username
    FROM profiles
    WHERE user_id = p_uid;
    
    -- Return the username (will be null if not found)
    RETURN v_username;
END;
$$;

-- Function to get favorite locations by user ID
CREATE OR REPLACE FUNCTION get_favorite_locations_by_user(p_uid uuid)
RETURNS SETOF text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Return the favorite locations
    RETURN QUERY
    SELECT location_text
    FROM favorite_locations
    WHERE user_id = p_uid;
    
    -- If no rows found, return null
    IF NOT FOUND THEN
        RETURN;
    END IF;
END;
$$;

-- Function to update a username
CREATE OR REPLACE FUNCTION update_username(p_uid uuid, p_username text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Update the username in the profiles table
    UPDATE profiles
    SET username = p_username
    WHERE user_id = p_uid;
    
    -- If no row was updated, insert a new row
    IF NOT FOUND THEN
        INSERT INTO profiles (user_id, username)
        VALUES (p_uid, p_username);
    END IF;
END;
$$;

-- These procedures need to be run in your Supabase SQL Editor
