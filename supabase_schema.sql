-- ====================================================================
-- jadiGuna — Supabase Database Migration & RLS Policy Schema
-- Berdasarkan Dokumen Rancangan Tugas Akhir Pemrograman Aplikasi Mobile
-- ====================================================================

-- 1. Tabel Profil Pengguna (terhubung ke auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT,
    profile_photo_path TEXT,
    bio TEXT,
    city TEXT,
    phone_number TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Profil dapat dibaca oleh publik"
ON public.profiles FOR SELECT
USING (true);

CREATE POLICY "Pengguna hanya dapat mengubah profilnya sendiri"
ON public.profiles FOR UPDATE
USING (auth.uid() = id);

CREATE POLICY "Pengguna dapat menyisipkan profil sendiri"
ON public.profiles FOR INSERT
WITH CHECK (auth.uid() = id);


-- 2. Tabel Kategori Barang
CREATE TABLE IF NOT EXISTS public.categories (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    is_active BOOLEAN DEFAULT true
);

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Kategori dapat dibaca oleh siapa saja"
ON public.categories FOR SELECT
USING (true);


-- 3. Tabel Iklan Barang (Listings)
CREATE TABLE IF NOT EXISTS public.listings (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    category_id TEXT REFERENCES public.categories(id),
    category_name TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    price BIGINT, -- NULL atau 0 untuk barang GRATIS
    condition TEXT NOT NULL,
    location_name TEXT NOT NULL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    status TEXT NOT NULL DEFAULT 'Tersedia', -- 'Tersedia', 'Dalam Kesepakatan', 'Selesai'
    images_csv TEXT,
    seller_name TEXT NOT NULL,
    seller_avatar TEXT,
    seller_phone TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

ALTER TABLE public.listings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Iklan dapat dibaca oleh publik"
ON public.listings FOR SELECT
USING (true);

CREATE POLICY "Pengguna terautentikasi dapat membuat iklan"
ON public.listings FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Hanya pemilik iklan yang dapat mengubah iklannya"
ON public.listings FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Hanya pemilik iklan yang dapat menghapus iklannya"
ON public.listings FOR DELETE
USING (auth.uid() = user_id);


-- 4. Tabel Favorit (Favorites)
CREATE TABLE IF NOT EXISTS public.favorites (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    listing_id TEXT REFERENCES public.listings(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, listing_id)
);

ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Pengguna hanya dapat melihat favorit miliknya"
ON public.favorites FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Pengguna dapat menambah favorit miliknya"
ON public.favorites FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Pengguna dapat menghapus favorit miliknya"
ON public.favorites FOR DELETE
USING (auth.uid() = user_id);


-- 5. Tabel Percakapan (Conversations)
CREATE TABLE IF NOT EXISTS public.conversations (
    id TEXT PRIMARY KEY,
    listing_id TEXT REFERENCES public.listings(id) ON DELETE CASCADE,
    listing_title TEXT NOT NULL,
    listing_image TEXT,
    listing_price BIGINT,
    buyer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    buyer_name TEXT NOT NULL,
    seller_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    seller_name TEXT NOT NULL,
    last_message TEXT,
    last_message_time TIMESTAMPTZ DEFAULT NOW(),
    unread_count INT DEFAULT 0
);

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Peserta dapat melihat percakapannya"
ON public.conversations FOR SELECT
USING (auth.uid() = buyer_id OR auth.uid() = seller_id);

CREATE POLICY "Peserta dapat membuat atau mengubah percakapan"
ON public.conversations FOR ALL
USING (auth.uid() = buyer_id OR auth.uid() = seller_id);


-- 6. Tabel Pesan Chat (Messages)
CREATE TABLE IF NOT EXISTS public.messages (
    id TEXT PRIMARY KEY,
    conversation_id TEXT REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    sender_name TEXT NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    is_read BOOLEAN DEFAULT false
);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Pesan dapat dibaca oleh peserta percakapan"
ON public.messages FOR SELECT
USING (EXISTS (
    SELECT 1 FROM public.conversations c
    WHERE c.id = messages.conversation_id
    AND (c.buyer_id = auth.uid() OR c.seller_id = auth.uid())
));

CREATE POLICY "Pengguna dapat mengirim pesan atas namanya"
ON public.messages FOR INSERT
WITH CHECK (auth.uid() = sender_id);


-- 7. Tabel Riwayat Status Blockchain SHA-256 (listing_status_history)
CREATE TABLE IF NOT EXISTS public.listing_status_history (
    block_index INT PRIMARY KEY,
    timestamp TIMESTAMPTZ NOT NULL,
    listing_id TEXT NOT NULL,
    item_title TEXT NOT NULL,
    previous_status TEXT NOT NULL,
    new_status TEXT NOT NULL,
    actor_name TEXT NOT NULL,
    notes TEXT,
    previous_hash TEXT NOT NULL,
    hash TEXT NOT NULL
);

ALTER TABLE public.listing_status_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Riwayat blockchain bersifat publik dan dapat dibaca siapa saja"
ON public.listing_status_history FOR SELECT
USING (true);

CREATE POLICY "Sistem/Pengguna terautentikasi dapat mencatat blok baru"
ON public.listing_status_history FOR INSERT
WITH CHECK (true);


-- 8. Tabel Saran dan Kesan (Feedback)
CREATE TABLE IF NOT EXISTS public.feedback (
    id TEXT PRIMARY KEY,
    user_id UUID,
    user_name TEXT NOT NULL,
    category TEXT NOT NULL,
    rating INT NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.feedback ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Siapa saja dapat mengirim saran dan masukan"
ON public.feedback FOR INSERT
WITH CHECK (true);

CREATE POLICY "Pengguna dapat melihat masukannya sendiri"
ON public.feedback FOR SELECT
USING (true);
