-- ==========================================
-- PROFILES POLICIES
-- ==========================================

CREATE POLICY "Allow public read of profiles" ON public.profiles
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow users to update own profile" ON public.profiles
    FOR UPDATE TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

CREATE POLICY "Allow admin full profile access" ON public.profiles
    FOR ALL TO authenticated USING (
        (auth.jwt() ->> 'user_role') = 'admin'
    );

-- ==========================================
-- KELUARGA POLICIES
-- ==========================================

CREATE POLICY "Petugas can read own keluarga records" ON public.keluarga
    FOR SELECT TO authenticated USING (
        (auth.jwt() ->> 'user_role') = 'petugas' AND petugas_id = auth.uid()
    );

CREATE POLICY "Petugas can insert keluarga records" ON public.keluarga
    FOR INSERT TO authenticated WITH CHECK (
        (auth.jwt() ->> 'user_role') = 'petugas' AND petugas_id = auth.uid()
    );

CREATE POLICY "Petugas can update own draft keluarga records" ON public.keluarga
    FOR UPDATE TO authenticated USING (
        (auth.jwt() ->> 'user_role') = 'petugas' AND petugas_id = auth.uid() AND status = 'draft'
    ) WITH CHECK (
        (auth.jwt() ->> 'user_role') = 'petugas' AND petugas_id = auth.uid() AND status IN ('draft', 'pending')
    );

CREATE POLICY "Pengawas can read all keluarga records" ON public.keluarga
    FOR SELECT TO authenticated USING (
        (auth.jwt() ->> 'user_role') = 'pengawas'
    );

CREATE POLICY "Pengawas can update status/review keluarga records" ON public.keluarga
    FOR UPDATE TO authenticated USING (
        (auth.jwt() ->> 'user_role') = 'pengawas'
    ) WITH CHECK (
        (auth.jwt() ->> 'user_role') = 'pengawas'
    );

CREATE POLICY "Admin can perform any action on keluarga" ON public.keluarga
    FOR ALL TO authenticated USING (
        (auth.jwt() ->> 'user_role') = 'admin'
    );

-- ==========================================
-- INDIVIDU POLICIES
-- ==========================================

CREATE POLICY "Petugas can read own individu records" ON public.individu
    FOR SELECT TO authenticated USING (
        (auth.jwt() ->> 'user_role') = 'petugas' AND petugas_id = auth.uid()
    );

CREATE POLICY "Petugas can insert individu records" ON public.individu
    FOR INSERT TO authenticated WITH CHECK (
        (auth.jwt() ->> 'user_role') = 'petugas' AND petugas_id = auth.uid()
    );

CREATE POLICY "Petugas can update own individu records" ON public.individu
    FOR UPDATE TO authenticated USING (
        (auth.jwt() ->> 'user_role') = 'petugas' AND petugas_id = auth.uid()
    ) WITH CHECK (
        (auth.jwt() ->> 'user_role') = 'petugas' AND petugas_id = auth.uid()
    );

CREATE POLICY "Pengawas can read all individu records" ON public.individu
    FOR SELECT TO authenticated USING (
        (auth.jwt() ->> 'user_role') = 'pengawas'
    );

CREATE POLICY "Admin can perform any action on individu" ON public.individu
    FOR ALL TO authenticated USING (
        (auth.jwt() ->> 'user_role') = 'admin'
    );

-- ==========================================
-- CHAT ROOMS & PARTICIPANTS POLICIES
-- ==========================================

CREATE POLICY "Users can read chat rooms they participate in" ON public.chat_rooms
    FOR SELECT TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.chat_participants 
            WHERE room_id = public.chat_rooms.id AND user_id = auth.uid()
        ) OR (auth.jwt() ->> 'user_role') = 'admin'
    );

CREATE POLICY "Users can create rooms" ON public.chat_rooms
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Admin full chat room access" ON public.chat_rooms
    FOR ALL TO authenticated USING (
        (auth.jwt() ->> 'user_role') = 'admin'
    );

CREATE POLICY "Users can view participants in their rooms" ON public.chat_participants
    FOR SELECT TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.chat_participants cp 
            WHERE cp.room_id = public.chat_participants.room_id AND cp.user_id = auth.uid()
        ) OR (auth.jwt() ->> 'user_role') = 'admin'
    );

CREATE POLICY "Users can add participants" ON public.chat_participants
    FOR INSERT TO authenticated WITH CHECK (true);

-- ==========================================
-- CHAT MESSAGES POLICIES
-- ==========================================

CREATE POLICY "Users can read messages in their rooms" ON public.chat_messages
    FOR SELECT TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.chat_participants 
            WHERE room_id = public.chat_messages.room_id AND user_id = auth.uid()
        ) OR (auth.jwt() ->> 'user_role') = 'admin'
    );

CREATE POLICY "Users can insert messages in their rooms" ON public.chat_messages
    FOR INSERT TO authenticated WITH CHECK (
        sender_id = auth.uid() AND (
            EXISTS (
                SELECT 1 FROM public.chat_participants 
                WHERE room_id = public.chat_messages.room_id AND user_id = auth.uid()
            ) OR (auth.jwt() ->> 'user_role') = 'admin'
        )
    );

-- ==========================================
-- NOTIFICATIONS POLICIES
-- ==========================================

CREATE POLICY "Users can manage own tokens" ON public.user_tokens
    FOR ALL TO authenticated USING (user_id = auth.uid());

CREATE POLICY "Users can view own notifications" ON public.notifications
    FOR SELECT TO authenticated USING (user_id = auth.uid());

CREATE POLICY "Users can update own notifications" ON public.notifications
    FOR UPDATE TO authenticated USING (user_id = auth.uid());
