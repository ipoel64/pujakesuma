-- Create keluarga table
CREATE TABLE public.keluarga (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    no_kk VARCHAR(16) UNIQUE NOT NULL,
    nama_kepala_keluarga TEXT NOT NULL,
    nik_kepala_keluarga VARCHAR(16) NOT NULL,
    alamat TEXT NOT NULL,
    lingkungan VARCHAR(50) NOT NULL,
    kelurahan VARCHAR(100) NOT NULL,
    kecamatan VARCHAR(100) NOT NULL,
    kota VARCHAR(100) NOT NULL DEFAULT 'Binjai',
    kode_pos VARCHAR(10),
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    foto_rumah_url TEXT,
    scan_kk_url TEXT,
    petugas_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'pending', 'verified', 'rejected')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE public.keluarga ENABLE ROW LEVEL SECURITY;

-- Enable Realtime
ALTER TABLE public.keluarga REPLICA IDENTITY FULL;

-- Trigger to update keluarga.updated_at
CREATE TRIGGER update_keluarga_timestamp
    BEFORE UPDATE ON public.keluarga
    FOR EACH ROW EXECUTE FUNCTION public.handle_update_timestamp();
