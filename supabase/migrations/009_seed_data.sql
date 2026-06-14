-- Create master table for Kecamatan and Kelurahan in Kota Binjai
CREATE TABLE public.wilayah_binjai (
    id SERIAL PRIMARY KEY,
    kecamatan VARCHAR(100) NOT NULL,
    kelurahan VARCHAR(100) NOT NULL,
    UNIQUE(kecamatan, kelurahan)
);

-- Seed wilayah Kota Binjai
INSERT INTO public.wilayah_binjai (kecamatan, kelurahan) VALUES
('Binjai Kota', 'Binjai'),
('Binjai Kota', 'Pekan Binjai'),
('Binjai Kota', 'Kartini'),
('Binjai Kota', 'Satria'),
('Binjai Kota', 'Setia'),
('Binjai Kota', 'Tangsi'),
('Binjai Kota', 'Berngam'),

('Binjai Barat', 'Limau Sundai'),
('Binjai Barat', 'Limau Mungkur'),
('Binjai Barat', 'Paya Roba'),
('Binjai Barat', 'Suka Maju'),
('Binjai Barat', 'Suka Ramai'),
('Binjai Barat', 'Bandar Senembah'),

('Binjai Timur', 'Sumber Karya'),
('Binjai Timur', 'Sumber Mulyorejo'),
('Binjai Timur', 'Dataran Tinggi'),
('Binjai Timur', 'Timbang Langkat'),
('Binjai Timur', 'Tunggurono'),
('Binjai Timur', 'Mencirim'),
('Binjai Timur', 'Tanah Tinggi'),

('Binjai Utara', 'Nangka'),
('Binjai Utara', 'Jati Utomo'),
('Binjai Utara', 'Jati Makmur'),
('Binjai Utara', 'Jati Karya'),
('Binjai Utara', 'Kebun Lada'),
('Binjai Utara', 'Damai'),
('Binjai Utara', 'Pahlawan'),
('Binjai Utara', 'Cengkeh Turi'),

('Binjai Selatan', 'Pujidadi'),
('Binjai Selatan', 'Binjai Estate'),
('Binjai Selatan', 'Rambung Barat'),
('Binjai Selatan', 'Rambung Dalam'),
('Binjai Selatan', 'Rambung Timur'),
('Binjai Selatan', 'Tanah Merah'),
('Binjai Selatan', 'Bhakti Karya');

-- Enable RLS for wilayah table
ALTER TABLE public.wilayah_binjai ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read of wilayah" ON public.wilayah_binjai FOR SELECT TO authenticated USING (true);
