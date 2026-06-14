-- Indexes for Keluarga table
CREATE INDEX idx_keluarga_petugas ON public.keluarga(petugas_id);
CREATE INDEX idx_keluarga_status ON public.keluarga(status);
CREATE INDEX idx_keluarga_location ON public.keluarga(kecamatan, kelurahan, lingkungan);

-- Indexes for Individu table
CREATE INDEX idx_individu_keluarga ON public.individu(keluarga_id);
CREATE INDEX idx_individu_suku ON public.individu(suku);
CREATE INDEX idx_individu_agama ON public.individu(agama);
CREATE INDEX idx_individu_tanggal_lahir ON public.individu(tanggal_lahir);
CREATE INDEX idx_individu_filter ON public.individu(kecamatan, kelurahan, lingkungan);

-- Indexes for Chat messages
CREATE INDEX idx_chat_messages_room_time ON public.chat_messages(room_id, created_at DESC);

-- Indexes for Notifications
CREATE INDEX idx_notifications_user_time ON public.notifications(user_id, created_at DESC);
