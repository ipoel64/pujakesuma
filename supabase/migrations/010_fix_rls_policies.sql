-- Drop old policies that check auth.jwt() ->> 'user_role' or query profiles directly
DROP POLICY IF EXISTS "Allow admin full profile access" ON public.profiles;
DROP POLICY IF EXISTS "Petugas can read own keluarga records" ON public.keluarga;
DROP POLICY IF EXISTS "Petugas can insert keluarga records" ON public.keluarga;
DROP POLICY IF EXISTS "Petugas can update own draft keluarga records" ON public.keluarga;
DROP POLICY IF EXISTS "Pengawas can read all keluarga records" ON public.keluarga;
DROP POLICY IF EXISTS "Pengawas can update status/review keluarga records" ON public.keluarga;
DROP POLICY IF EXISTS "Admin can perform any action on keluarga" ON public.keluarga;
DROP POLICY IF EXISTS "Petugas can read own individu records" ON public.individu;
DROP POLICY IF EXISTS "Petugas can insert individu records" ON public.individu;
DROP POLICY IF EXISTS "Petugas can update own individu records" ON public.individu;
DROP POLICY IF EXISTS "Pengawas can read all individu records" ON public.individu;
DROP POLICY IF EXISTS "Admin can perform any action on individu" ON public.individu;
DROP POLICY IF EXISTS "Users can read chat rooms they participate in" ON public.chat_rooms;
DROP POLICY IF EXISTS "Admin full chat room access" ON public.chat_rooms;
DROP POLICY IF EXISTS "Users can view participants in their rooms" ON public.chat_participants;
DROP POLICY IF EXISTS "Users can read messages in their rooms" ON public.chat_messages;
DROP POLICY IF EXISTS "Users can insert messages in their rooms" ON public.chat_messages;

-- Also drop the previous temporary ones if they exist
DROP POLICY IF EXISTS "Allow authenticated users to read chat rooms" ON public.chat_rooms;
DROP POLICY IF EXISTS "Allow authenticated users to insert chat rooms" ON public.chat_rooms;
DROP POLICY IF EXISTS "Allow admin full access to chat rooms" ON public.chat_rooms;
DROP POLICY IF EXISTS "Allow authenticated users to read chat participants" ON public.chat_participants;
DROP POLICY IF EXISTS "Allow authenticated users to insert chat participants" ON public.chat_participants;
DROP POLICY IF EXISTS "Allow admin full access to chat participants" ON public.chat_participants;
DROP POLICY IF EXISTS "Allow authenticated users to read chat messages" ON public.chat_messages;
DROP POLICY IF EXISTS "Allow authenticated users to insert chat messages" ON public.chat_messages;
DROP POLICY IF EXISTS "Allow admin full access to chat messages" ON public.chat_messages;

-- ==========================================
-- SECURITY DEFINER helper function to get user role
-- This bypasses RLS checking on the profiles table, preventing infinite recursion
-- ==========================================
CREATE OR REPLACE FUNCTION public.get_user_role(user_id UUID)
RETURNS text AS $$
DECLARE
    user_role text;
BEGIN
    SELECT role::text INTO user_role FROM public.profiles WHERE id = user_id;
    RETURN COALESCE(user_role, 'petugas');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==========================================
-- NEW PROFILES POLICIES
-- ==========================================
CREATE POLICY "Allow admin full profile access" ON public.profiles
    FOR ALL TO authenticated USING (
        public.get_user_role(auth.uid()) = 'admin'
    );

-- ==========================================
-- NEW KELUARGA POLICIES
-- ==========================================
CREATE POLICY "Petugas can read own keluarga records" ON public.keluarga
    FOR SELECT TO authenticated USING (
        petugas_id = auth.uid() 
        AND public.get_user_role(auth.uid()) = 'petugas'
    );

CREATE POLICY "Petugas can insert keluarga records" ON public.keluarga
    FOR INSERT TO authenticated WITH CHECK (
        petugas_id = auth.uid() 
        AND public.get_user_role(auth.uid()) = 'petugas'
    );

CREATE POLICY "Petugas can update own draft keluarga records" ON public.keluarga
    FOR UPDATE TO authenticated USING (
        petugas_id = auth.uid() 
        AND status = 'draft'
        AND public.get_user_role(auth.uid()) = 'petugas'
    ) WITH CHECK (
        petugas_id = auth.uid() 
        AND status IN ('draft', 'pending')
        AND public.get_user_role(auth.uid()) = 'petugas'
    );

CREATE POLICY "Pengawas can read all keluarga records" ON public.keluarga
    FOR SELECT TO authenticated USING (
        public.get_user_role(auth.uid()) = 'pengawas'
    );

CREATE POLICY "Pengawas can update status/review keluarga records" ON public.keluarga
    FOR UPDATE TO authenticated USING (
        public.get_user_role(auth.uid()) = 'pengawas'
    ) WITH CHECK (
        public.get_user_role(auth.uid()) = 'pengawas'
    );

CREATE POLICY "Admin can perform any action on keluarga" ON public.keluarga
    FOR ALL TO authenticated USING (
        public.get_user_role(auth.uid()) = 'admin'
    );

-- ==========================================
-- NEW INDIVIDU POLICIES
-- ==========================================
CREATE POLICY "Petugas can read own individu records" ON public.individu
    FOR SELECT TO authenticated USING (
        petugas_id = auth.uid() 
        AND public.get_user_role(auth.uid()) = 'petugas'
    );

CREATE POLICY "Petugas can insert individu records" ON public.individu
    FOR INSERT TO authenticated WITH CHECK (
        petugas_id = auth.uid() 
        AND public.get_user_role(auth.uid()) = 'petugas'
    );

CREATE POLICY "Petugas can update own individu records" ON public.individu
    FOR UPDATE TO authenticated USING (
        petugas_id = auth.uid() 
        AND public.get_user_role(auth.uid()) = 'petugas'
    ) WITH CHECK (
        petugas_id = auth.uid() 
        AND public.get_user_role(auth.uid()) = 'petugas'
    );

CREATE POLICY "Pengawas can read all individu records" ON public.individu
    FOR SELECT TO authenticated USING (
        public.get_user_role(auth.uid()) = 'pengawas'
    );

CREATE POLICY "Admin can perform any action on individu" ON public.individu
    FOR ALL TO authenticated USING (
        public.get_user_role(auth.uid()) = 'admin'
    );

-- ==========================================
-- NEW CHAT ROOMS POLICIES (Allow all auth users for public/group org chat)
-- ==========================================
CREATE POLICY "Allow authenticated users to read chat rooms" ON public.chat_rooms
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated users to insert chat rooms" ON public.chat_rooms
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Allow admin full access to chat rooms" ON public.chat_rooms
    FOR ALL TO authenticated USING (
        public.get_user_role(auth.uid()) = 'admin'
    );

-- ==========================================
-- NEW CHAT PARTICIPANTS POLICIES
-- ==========================================
CREATE POLICY "Allow authenticated users to read chat participants" ON public.chat_participants
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated users to insert chat participants" ON public.chat_participants
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Allow admin full access to chat participants" ON public.chat_participants
    FOR ALL TO authenticated USING (
        public.get_user_role(auth.uid()) = 'admin'
    );

-- ==========================================
-- NEW CHAT MESSAGES POLICIES
-- ==========================================
CREATE POLICY "Allow authenticated users to read chat messages" ON public.chat_messages
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated users to insert chat messages" ON public.chat_messages
    FOR INSERT TO authenticated WITH CHECK (sender_id = auth.uid());

CREATE POLICY "Allow admin full access to chat messages" ON public.chat_messages
    FOR ALL TO authenticated USING (
        public.get_user_role(auth.uid()) = 'admin'
    );
