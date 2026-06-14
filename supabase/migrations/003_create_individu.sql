-- Create individu table
CREATE TABLE public.individu (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    keluarga_id UUID REFERENCES public.keluarga(id) ON DELETE CASCADE,
    no_kk VARCHAR(16) NOT NULL,
    nik VARCHAR(16) UNIQUE NOT NULL,
    nama_lengkap TEXT NOT NULL,
    nama_panggilan VARCHAR(100),
    alamat TEXT NOT NULL,
    lingkungan VARCHAR(50) NOT NULL,
    kelurahan VARCHAR(100) NOT NULL,
    kecamatan VARCHAR(100) NOT NULL,
    kota VARCHAR(100) NOT NULL DEFAULT 'Binjai',
    pekerjaan VARCHAR(100),
    tempat_lahir VARCHAR(100),
    tanggal_lahir DATE NOT NULL,
    agama VARCHAR(50),
    status_perkawinan VARCHAR(50),
    status_hubungan_keluarga VARCHAR(100),
    jenis_kelamin VARCHAR(20) CHECK (jenis_kelamin IN ('Laki-laki', 'Perempuan')),
    suku VARCHAR(100) NOT NULL DEFAULT 'Jawa',
    anggota_pujakesuma BOOLEAN NOT NULL DEFAULT false,
    foto_ktp_url TEXT,
    petugas_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE public.individu ENABLE ROW LEVEL SECURITY;

-- Enable Realtime
ALTER TABLE public.individu REPLICA IDENTITY FULL;

-- Trigger to update individu.updated_at
CREATE TRIGGER update_individu_timestamp
    BEFORE UPDATE ON public.individu
    FOR EACH ROW EXECUTE FUNCTION public.handle_update_timestamp();

-- Create a view that automatically calculates age ('usia')
CREATE OR REPLACE VIEW public.v_individu AS
SELECT 
    *,
    EXTRACT(YEAR FROM age(tanggal_lahir))::INTEGER AS usia
FROM 
    public.individu;
