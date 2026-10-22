-- ====================================================================
-- jadiGuna — Supabase Database Migration, Schema, RLS & Seed Data
-- Siap dijalankan langsung di Supabase SQL Editor
-- ====================================================================

-- 0. Ekstensi yang Dibutuhkan
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- ====================================================================
-- 1. TABEL PROFIL PENGGUNA (public.profiles)
-- Terhubung langsung ke tabel bawaan Supabase: auth.users
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT,
    profile_photo_path TEXT,
    bio TEXT,
    city TEXT DEFAULT 'Sleman, D.I. Yogyakarta',
    phone_number TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Profil dapat dibaca oleh publik" ON public.profiles;
CREATE POLICY "Profil dapat dibaca oleh publik"
    ON public.profiles FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Pengguna dapat menyisipkan profil sendiri" ON public.profiles;
CREATE POLICY "Pengguna dapat menyisipkan profil sendiri"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Pengguna hanya dapat mengubah profilnya sendiri" ON public.profiles;
CREATE POLICY "Pengguna hanya dapat mengubah profilnya sendiri"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);


-- Trigger otomatis: Saat pengguna mendaftar lewat Auth, buatkan profilnya di public.profiles
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, name, email, created_at)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
        NEW.email,
        NOW()
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- ====================================================================
-- 2. TABEL KATEGORI BARANG (public.categories)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.categories (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    is_active BOOLEAN NOT NULL DEFAULT true
);

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Kategori dapat dibaca oleh siapa saja" ON public.categories;
CREATE POLICY "Kategori dapat dibaca oleh siapa saja"
    ON public.categories FOR SELECT
    USING (true);


-- ====================================================================
-- 3. TABEL IKLAN BARANG (public.listings)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.listings (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    category_id TEXT REFERENCES public.categories(id) ON DELETE RESTRICT,
    category_name TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    price BIGINT DEFAULT 0, -- 0 atau NULL menandakan barang GRATIS
    condition TEXT NOT NULL, -- 'Baru', 'Sangat Baik (Mulus)', 'Baik (Layak Pakai)', dll.
    location_name TEXT NOT NULL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    status TEXT NOT NULL DEFAULT 'Tersedia', -- 'Tersedia', 'Dalam Kesepakatan', 'Selesai'
    images_csv TEXT, -- URL gambar dipisahkan koma
    seller_name TEXT NOT NULL,
    seller_avatar TEXT,
    seller_phone TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.listings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Iklan dapat dibaca oleh publik" ON public.listings;
CREATE POLICY "Iklan dapat dibaca oleh publik"
    ON public.listings FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Pengguna terautentikasi dapat membuat iklan" ON public.listings;
CREATE POLICY "Pengguna terautentikasi dapat membuat iklan"
    ON public.listings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Hanya pemilik iklan yang dapat mengubah iklannya" ON public.listings;
CREATE POLICY "Hanya pemilik iklan yang dapat mengubah iklannya"
    ON public.listings FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Hanya pemilik iklan yang dapat menghapus iklannya" ON public.listings;
CREATE POLICY "Hanya pemilik iklan yang dapat menghapus iklannya"
    ON public.listings FOR DELETE
    USING (auth.uid() = user_id);

-- Index untuk mempercepat query pencarian, filter kategori, dan status
CREATE INDEX IF NOT EXISTS idx_listings_category ON public.listings(category_id);
CREATE INDEX IF NOT EXISTS idx_listings_user ON public.listings(user_id);
CREATE INDEX IF NOT EXISTS idx_listings_status ON public.listings(status);
CREATE INDEX IF NOT EXISTS idx_listings_created_at ON public.listings(created_at DESC);


-- ====================================================================
-- 4. TABEL FAVORIT (public.favorites)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.favorites (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    listing_id TEXT REFERENCES public.listings(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, listing_id)
);

ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Pengguna hanya dapat melihat favorit miliknya" ON public.favorites;
CREATE POLICY "Pengguna hanya dapat melihat favorit miliknya"
    ON public.favorites FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Pengguna dapat menambah favorit miliknya" ON public.favorites;
CREATE POLICY "Pengguna dapat menambah favorit miliknya"
    ON public.favorites FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Pengguna dapat menghapus favorit miliknya" ON public.favorites;
CREATE POLICY "Pengguna dapat menghapus favorit miliknya"
    ON public.favorites FOR DELETE
    USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_favorites_user ON public.favorites(user_id);


-- ====================================================================
-- 5. TABEL PERCAKAPAN (public.conversations)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.conversations (
    id TEXT PRIMARY KEY,
    listing_id TEXT REFERENCES public.listings(id) ON DELETE SET NULL,
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

DROP POLICY IF EXISTS "Peserta dapat melihat percakapannya" ON public.conversations;
CREATE POLICY "Peserta dapat melihat percakapannya"
    ON public.conversations FOR SELECT
    USING (auth.uid() = buyer_id OR auth.uid() = seller_id);

DROP POLICY IF EXISTS "Peserta dapat membuat atau mengubah percakapan" ON public.conversations;
CREATE POLICY "Peserta dapat membuat atau mengubah percakapan"
    ON public.conversations FOR ALL
    USING (auth.uid() = buyer_id OR auth.uid() = seller_id);

CREATE INDEX IF NOT EXISTS idx_conversations_buyer ON public.conversations(buyer_id);
CREATE INDEX IF NOT EXISTS idx_conversations_seller ON public.conversations(seller_id);


-- ====================================================================
-- 6. TABEL PESAN CHAT (public.messages)
-- ====================================================================
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

DROP POLICY IF EXISTS "Pesan dapat dibaca oleh peserta percakapan" ON public.messages;
CREATE POLICY "Pesan dapat dibaca oleh peserta percakapan"
    ON public.messages FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = messages.conversation_id
        AND (c.buyer_id = auth.uid() OR c.seller_id = auth.uid())
    ));

DROP POLICY IF EXISTS "Pengguna dapat mengirim pesan atas namanya" ON public.messages;
CREATE POLICY "Pengguna dapat mengirim pesan atas namanya"
    ON public.messages FOR INSERT
    WITH CHECK (auth.uid() = sender_id);

CREATE INDEX IF NOT EXISTS idx_messages_conversation ON public.messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at ASC);


-- ====================================================================
-- 7. TABEL RIWAYAT STATUS BLOCKCHAIN SHA-256 (public.listing_status_history)
-- Menyimpan jejak audit perubahan status barang secara terdesentralisasi
-- ====================================================================
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

DROP POLICY IF EXISTS "Riwayat blockchain bersifat publik dan dapat dibaca siapa saja" ON public.listing_status_history;
CREATE POLICY "Riwayat blockchain bersifat publik dan dapat dibaca siapa saja"
    ON public.listing_status_history FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Sistem/Pengguna terautentikasi dapat mencatat blok baru" ON public.listing_status_history;
CREATE POLICY "Sistem/Pengguna terautentikasi dapat mencatat blok baru"
    ON public.listing_status_history FOR INSERT
    WITH CHECK (true);

CREATE INDEX IF NOT EXISTS idx_blockchain_listing ON public.listing_status_history(listing_id);


-- ====================================================================
-- 8. TABEL SARAN DAN KESAN (public.feedback)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.feedback (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    user_name TEXT NOT NULL,
    category TEXT NOT NULL, -- 'Fitur', 'Tampilan', 'Kendala/Bug', 'Lainnya'
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.feedback ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Siapa saja dapat mengirim saran dan masukan" ON public.feedback;
CREATE POLICY "Siapa saja dapat mengirim saran dan masukan"
    ON public.feedback FOR INSERT
    WITH CHECK (true);

DROP POLICY IF EXISTS "Pengguna dapat melihat masukannya sendiri atau publik" ON public.feedback;
CREATE POLICY "Pengguna dapat melihat masukannya sendiri atau publik"
    ON public.feedback FOR SELECT
    USING (true);


-- ====================================================================
-- 9. TABEL LAPORAN BARANG (public.reports)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.reports (
    id TEXT PRIMARY KEY,
    listing_id TEXT REFERENCES public.listings(id) ON DELETE CASCADE,
    reporter_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    reason TEXT NOT NULL,
    details TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Pengguna dapat mengirim laporan" ON public.reports;
CREATE POLICY "Pengguna dapat mengirim laporan"
    ON public.reports FOR INSERT
    WITH CHECK (true);

DROP POLICY IF EXISTS "Hanya pelapor yang dapat melihat laporannya" ON public.reports;
CREATE POLICY "Hanya pelapor yang dapat melihat laporannya"
    ON public.reports FOR SELECT
    USING (auth.uid() = reporter_id);


-- ====================================================================
-- 10. SUPABASE STORAGE BUCKETS (listing-images & avatars)
-- ====================================================================
INSERT INTO storage.buckets (id, name, public)
VALUES 
    ('listing-images', 'listing-images', true),
    ('avatars', 'avatars', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Storage Policy: Siapa saja dapat melihat gambar
DROP POLICY IF EXISTS "Publik dapat melihat foto barang" ON storage.objects;
CREATE POLICY "Publik dapat melihat foto barang"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'listing-images' OR bucket_id = 'avatars');

-- Storage Policy: Pengguna terautentikasi dapat mengunggah gambar
DROP POLICY IF EXISTS "Pengguna terautentikasi dapat upload gambar" ON storage.objects;
CREATE POLICY "Pengguna terautentikasi dapat upload gambar"
    ON storage.objects FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- Storage Policy: Pemilik dapat menghapus/mengubah gambar unggahannya
DROP POLICY IF EXISTS "Pengguna dapat mengelola gambarnya sendiri" ON storage.objects;
CREATE POLICY "Pengguna dapat mengelola gambarnya sendiri"
    ON storage.objects FOR ALL
    USING (auth.uid()::text = (storage.foldername(name))[1]);


-- ====================================================================
-- 11. SUPABASE REALTIME
-- Mengaktifkan update realtime untuk Chat dan Listing
-- ====================================================================
DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.listings;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;


-- ====================================================================
-- 12. DATA AWAL (SEED DATA)
-- Mengisi kategori bawaan dan genesis block blockchain
-- ====================================================================

-- 12.1. Seed Kategori (Sesuai CategoryModel.defaultCategories di Flutter)
INSERT INTO public.categories (id, name, slug, is_active)
VALUES
    ('cat_all', 'Semua', 'semua', true),
    ('cat_1', 'Furnitur', 'furnitur', true),
    ('cat_2', 'Elektronik', 'elektronik', true),
    ('cat_3', 'Buku', 'buku', true),
    ('cat_4', 'Pakaian', 'pakaian', true),
    ('cat_5', 'Perlengkapan Rumah', 'perlengkapan-rumah', true),
    ('cat_6', 'Alat Olahraga', 'alat-olahraga', true),
    ('cat_7', 'Hobi & Mainan', 'hobi-mainan', true)
ON CONFLICT (id) DO UPDATE 
SET name = EXCLUDED.name, slug = EXCLUDED.slug, is_active = EXCLUDED.is_active;

-- 12.2. Seed Genesis Block Blockchain (Index 0)
INSERT INTO public.listing_status_history (
    block_index,
    timestamp,
    listing_id,
    item_title,
    previous_status,
    new_status,
    actor_name,
    notes,
    previous_hash,
    hash
)
VALUES (
    0,
    NOW() - INTERVAL '3 days',
    'genesis-000',
    'Genesis Block - jadiGuna Network Init',
    'None',
    'Initialized',
    'System',
    'Initial block for jadiGuna immutable item provenance ledger',
    '0000000000000000000000000000000000000000000000000000000000000000',
    'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'
)
ON CONFLICT (block_index) DO NOTHING;
