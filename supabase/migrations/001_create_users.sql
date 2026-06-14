-- Create custom role type
CREATE TYPE user_role AS ENUM ('petugas', 'pengawas', 'admin');

-- Create profiles table linked to auth.users
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    role user_role NOT NULL DEFAULT 'petugas',
    phone TEXT,
    avatar_url TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Enable Realtime
ALTER TABLE public.profiles REPLICA IDENTITY FULL;

-- Trigger to automatically insert a profile when a new user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, role, phone, avatar_url, is_active)
    VALUES (
        new.id,
        COALESCE(new.raw_user_meta_data->>'full_name', 'User Baru'),
        COALESCE((new.raw_user_meta_data->>'role')::user_role, 'petugas'),
        new.raw_user_meta_data->>'phone',
        new.raw_user_meta_data->>'avatar_url',
        true
    );
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Trigger to update profiles.updated_at
CREATE OR REPLACE FUNCTION public.handle_update_timestamp()
RETURNS trigger AS $$
BEGIN
    new.updated_at = now();
    RETURN new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_timestamp
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_update_timestamp();

-- Create custom JWT access token hook to embed the user's role
CREATE OR REPLACE FUNCTION public.custom_access_token_hook(event jsonb)
RETURNS jsonb AS $$
DECLARE
    claims jsonb;
    user_role public.user_role;
BEGIN
    -- Fetch the user role from profiles
    SELECT role INTO user_role FROM public.profiles WHERE id = (event->>'user_id')::uuid;

    -- Get claims from event
    claims := event->'claims';

    -- Embed the role into the claims
    claims := jsonb_set(claims, '{user_role}', to_jsonb(user_role::text));

    -- Set claims in the event and return
    event := jsonb_set(event, '{claims}', claims);
    RETURN event;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions for custom hook
GRANT USAGE ON SCHEMA public TO supabase_auth_admin;
GRANT EXECUTE ON FUNCTION public.custom_access_token_hook(jsonb) TO supabase_auth_admin;
