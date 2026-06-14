-- Stored function to get comprehensive dashboard statistics
CREATE OR REPLACE FUNCTION public.get_dashboard_stats()
RETURNS jsonb AS $$
DECLARE
    total_keluarga bigint;
    total_individu bigint;
    total_verified bigint;
    total_pending bigint;
    kecamatan_stats jsonb;
    suku_stats jsonb;
    agama_stats jsonb;
    usia_stats jsonb;
    result jsonb;
BEGIN
    -- 1. General counts
    SELECT count(*) INTO total_keluarga FROM public.keluarga;
    SELECT count(*) INTO total_individu FROM public.individu;
    SELECT count(*) INTO total_verified FROM public.keluarga WHERE status = 'verified';
    SELECT count(*) INTO total_pending FROM public.keluarga WHERE status = 'pending';

    -- 2. Keluarga count grouped by kecamatan
    SELECT jsonb_object_agg(kecamatan, count) INTO kecamatan_stats
    FROM (
        SELECT kecamatan, count(*) as count 
        FROM public.keluarga 
        GROUP BY kecamatan
    ) t;

    -- 3. Individu count grouped by suku
    SELECT jsonb_object_agg(suku, count) INTO suku_stats
    FROM (
        SELECT suku, count(*) as count 
        FROM public.individu 
        GROUP BY suku
    ) t;

    -- 4. Individu count grouped by agama
    SELECT jsonb_object_agg(COALESCE(agama, 'Tidak Diketahui'), count) INTO agama_stats
    FROM (
        SELECT agama, count(*) as count 
        FROM public.individu 
        GROUP BY agama
    ) t;

    -- 5. Individu count grouped by age brackets
    SELECT jsonb_build_object(
        'Anak-Anak (0-12)', count(CASE WHEN usia <= 12 THEN 1 END),
        'Remaja (13-18)', count(CASE WHEN usia >= 13 AND usia <= 18 THEN 1 END),
        'Dewasa (19-59)', count(CASE WHEN usia >= 19 AND usia <= 59 THEN 1 END),
        'Lansia (60+)', count(CASE WHEN usia >= 60 THEN 1 END)
    ) INTO usia_stats
    FROM public.v_individu;

    -- Assemble results
    result := jsonb_build_object(
        'totalKeluarga', total_keluarga,
        'totalIndividu', total_individu,
        'totalVerified', total_verified,
        'totalPending', total_pending,
        'kecamatanDistribution', COALESCE(kecamatan_stats, '{}'::jsonb),
        'sukuDistribution', COALESCE(suku_stats, '{}'::jsonb),
        'agamaDistribution', COALESCE(agama_stats, '{}'::jsonb),
        'usiaDistribution', COALESCE(usia_stats, '{}'::jsonb)
    );

    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
