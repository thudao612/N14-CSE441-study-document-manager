-- ==============================================================================
-- STUDY DOCUMENT MANAGER - SUPABASE POSTGRESQL SCHEMA & ROW LEVEL SECURITY (RLS)
-- Tích hợp Hybrid Cloud: Firebase Authentication + Firebase Storage + Supabase DB
-- ==============================================================================

-- 1. BẬT TIỆN ÍCH MÃ HÓA & UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 2. HÀM TRÍCH XUẤT FIREBASE UID TỪ JWT CLAIMS AN TOÀN
-- Hỗ trợ xác thực người dùng thông qua Firebase ID Token (JWT) được chuyển tiếp tới Supabase.
-- ⚠️ LƯU Ý AN NINH: Đã LOẠI BỎ hoàn toàn việc đọc UID từ header tùy chỉnh 'x-firebase-uid'
-- để loại trừ nguy cơ mạo danh người dùng từ client không được xác thực.
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.current_user_id()
RETURNS text AS $$
DECLARE
  jwt_claims jsonb;
  v_sub text;
BEGIN
  -- 1. Trích xuất từ request.jwt.claim.sub (chuẩn PostgREST khi giải mã Firebase JWT)
  BEGIN
    v_sub := nullif(current_setting('request.jwt.claim.sub', true), '');
  EXCEPTION WHEN OTHERS THEN
    v_sub := NULL;
  END;

  IF v_sub IS NOT NULL AND v_sub <> '' THEN
    RETURN v_sub;
  END IF;

  -- 2. Trích xuất từ đối tượng jsonb request.jwt.claims (sub hoặc user_id của Firebase)
  BEGIN
    jwt_claims := nullif(current_setting('request.jwt.claims', true), '')::jsonb;
    IF jwt_claims IS NOT NULL THEN
      -- Firebase ID Token chứa UID tại claim 'sub'
      v_sub := jwt_claims ->> 'sub';
      IF v_sub IS NOT NULL AND v_sub <> '' THEN
        RETURN v_sub;
      END IF;

      -- Một số cấu hình Firebase đặt UID tại claim 'user_id'
      v_sub := jwt_claims ->> 'user_id';
      IF v_sub IS NOT NULL AND v_sub <> '' THEN
        RETURN v_sub;
      END IF;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    -- Bỏ qua lỗi cú pháp JSON nếu có
  END;

  -- 3. Dự phòng trường hợp dùng auth.uid() chuẩn của Supabase
  BEGIN
    v_sub := auth.uid()::text;
    IF v_sub IS NOT NULL AND v_sub <> '' THEN
      RETURN v_sub;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    -- Bỏ qua
  END;

  -- 4. Dự phòng auth.jwt() ->> 'sub'
  BEGIN
    v_sub := auth.jwt() ->> 'sub';
    IF v_sub IS NOT NULL AND v_sub <> '' THEN
      RETURN v_sub;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    -- Bỏ qua
  END;

  -- TUYỆT ĐỐI KHÔNG đọc từ header 'x-firebase-uid' vì client có thể can thiệp giả mạo.
  RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- ==============================================================================
-- 3. TẠO 3 BẢNG CỐT LÕI: users, documents, permissions
-- ==============================================================================

-- BẢNG 1: users (Quản lý hồ sơ người dùng đồng bộ từ Firebase Auth)
CREATE TABLE IF NOT EXISTS public.users (
  id TEXT PRIMARY KEY,                       -- Firebase UID (chuỗi định danh duy nhất từ Firebase Auth)
  email TEXT NOT NULL UNIQUE,                -- Địa chỉ email của người dùng
  display_name TEXT,                         -- Tên hiển thị
  photo_url TEXT,                            -- Ảnh đại diện
  fcm_token TEXT DEFAULT '',                 -- Firebase Cloud Messaging Device Token (FCM Push Notification)
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS fcm_token TEXT DEFAULT '';

-- BẢNG 2: documents (Thông tin tài liệu học tập & metadata)
CREATE TABLE IF NOT EXISTS public.documents (
  id TEXT PRIMARY KEY,                       -- UUID của tài liệu
  title TEXT NOT NULL,                       -- Tiêu đề tài liệu
  subject TEXT NOT NULL,                     -- Tên môn học
  type TEXT NOT NULL CHECK (type IN ('lecture', 'exercise', 'reference')), -- Phân loại
  description TEXT DEFAULT '',               -- Mô tả chi tiết
  file_url TEXT DEFAULT '',                  -- Đường dẫn tải tệp từ Firebase Storage hoặc Web URL
  file_name TEXT DEFAULT '',                 -- Tên tệp gốc đính kèm
  file_size BIGINT DEFAULT 0,                -- Dung lượng tệp tính bằng bytes
  tags JSONB DEFAULT '[]'::jsonb,            -- Danh sách thẻ từ khóa (mảng JSON)
  is_favorite BOOLEAN DEFAULT FALSE,         -- Đánh dấu yêu thích
  location_name TEXT DEFAULT '',              -- Tên địa điểm lưu tài liệu
  lat DOUBLE PRECISION,                       -- Vĩ độ vị trí trên bản đồ
  "long" DOUBLE PRECISION,                    -- Kinh độ vị trí trên bản đồ
  owner_id TEXT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE, -- Chủ sở hữu tài liệu (Firebase UID)
  author_email TEXT DEFAULT '',              -- Email người tạo tài liệu
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.documents
  ADD COLUMN IF NOT EXISTS location_name TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS lat DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS "long" DOUBLE PRECISION;

-- BẢNG 3: permissions (Quản lý quyền chia sẻ tài liệu giữa các người dùng)
CREATE TABLE IF NOT EXISTS public.permissions (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text, -- Mã định danh quyền
  document_id TEXT NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE, -- Tài liệu được chia sẻ
  user_id TEXT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,         -- Người nhận quyền (Firebase UID)
  role TEXT NOT NULL CHECK (role IN ('viewer', 'editor')),                     -- Quyền: 'viewer' (Chỉ xem) hoặc 'editor' (Biên tập)
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT unique_document_user_permission UNIQUE (document_id, user_id)
);

-- ==============================================================================
-- 4. TẠO INDEXES ĐỂ TỐI ƯU TỐC ĐỘ TRUY VẤN
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_documents_owner ON public.documents(owner_id);
CREATE INDEX IF NOT EXISTS idx_documents_subject ON public.documents(subject);
CREATE INDEX IF NOT EXISTS idx_permissions_doc_user ON public.permissions(document_id, user_id);
CREATE INDEX IF NOT EXISTS idx_permissions_user ON public.permissions(user_id);

-- ==============================================================================
-- 5. CÁC HÀM HỖ TRỢ SCHEMA PRIVATE TRÁNH LỖI ĐỆ QUY RLS
-- ==============================================================================
CREATE SCHEMA IF NOT EXISTS private;
GRANT USAGE ON SCHEMA private TO anon, authenticated, service_role;

DROP FUNCTION IF EXISTS private.is_document_owner(text, text) CASCADE;
DROP FUNCTION IF EXISTS private.has_document_permission(text, text, text) CASCADE;
DROP FUNCTION IF EXISTS private.has_document_permission(text, text) CASCADE;

-- Hàm kiểm tra chủ sở hữu tài liệu (SECURITY DEFINER để tránh đệ quy RLS)
CREATE OR REPLACE FUNCTION private.is_document_owner(doc_id text, check_uid text)
RETURNS boolean AS $$
BEGIN
  IF check_uid IS NULL OR check_uid = '' THEN
    RETURN FALSE;
  END IF;

  RETURN EXISTS (
    SELECT 1 FROM public.documents
    WHERE id = doc_id AND owner_id = check_uid
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Hàm kiểm tra quyền chia sẻ tài liệu (SECURITY DEFINER để tránh đệ quy RLS)
CREATE OR REPLACE FUNCTION private.has_document_permission(doc_id text, check_uid text, check_role text DEFAULT NULL)
RETURNS boolean AS $$
BEGIN
  IF check_uid IS NULL OR check_uid = '' THEN
    RETURN FALSE;
  END IF;

  IF check_role IS NULL THEN
    RETURN EXISTS (
      SELECT 1 FROM public.permissions
      WHERE document_id = doc_id AND user_id = check_uid
    );
  ELSE
    RETURN EXISTS (
      SELECT 1 FROM public.permissions
      WHERE document_id = doc_id AND user_id = check_uid AND role = check_role
    );
  END IF;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION private.is_document_owner(text, text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION private.has_document_permission(text, text, text) TO anon, authenticated;

-- ==============================================================================
-- 6. BẬT ROW LEVEL SECURITY (RLS) VÀ THIẾT LẬP CHÍNH SÁCH BẢO MẬT
-- ==============================================================================

-- BẬT RLS CHO CẢ 3 BẢNG
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.permissions ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------
-- CHÍNH SÁCH RLS CHO BẢNG: users
-- ------------------------------------------------------------------------------

-- SELECT: Cho phép tất cả người dùng đã đăng nhập đọc danh sách/tìm kiếm user (để chia sẻ theo email)
DROP POLICY IF EXISTS "Users can view all registered users" ON public.users;
CREATE POLICY "Users can view all registered users"
ON public.users FOR SELECT
TO anon, authenticated
USING (public.current_user_id() IS NOT NULL);

-- INSERT: Người dùng chỉ được tạo hồ sơ của chính mình
DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
CREATE POLICY "Users can insert own profile"
ON public.users FOR INSERT
TO anon, authenticated
WITH CHECK (
  id = public.current_user_id()
  AND public.current_user_id() IS NOT NULL
);

-- UPDATE: Người dùng chỉ được cập nhật hồ sơ của chính mình
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
CREATE POLICY "Users can update own profile"
ON public.users FOR UPDATE
TO anon, authenticated
USING (id = public.current_user_id())
WITH CHECK (id = public.current_user_id());

-- ------------------------------------------------------------------------------
-- CHÍNH SÁCH RLS CHO BẢNG: documents
-- Phân quyền nghiêm ngặt: Chủ sở hữu vs Người được chia sẻ vs Người ngoài
-- ------------------------------------------------------------------------------

-- 1. SELECT: Chủ sở hữu HOẶC người được cấp quyền trong permissions
DROP POLICY IF EXISTS "View documents owned or shared" ON public.documents;
CREATE POLICY "View documents owned or shared"
ON public.documents FOR SELECT
TO anon, authenticated
USING (
  owner_id = public.current_user_id()
  OR private.has_document_permission(id, public.current_user_id())
);

-- 2. INSERT: Chỉ người dùng đã xác thực mới được tạo tài liệu mới với chính mình là owner
DROP POLICY IF EXISTS "Create document as owner" ON public.documents;
CREATE POLICY "Create document as owner"
ON public.documents FOR INSERT
TO anon, authenticated
WITH CHECK (
  owner_id = public.current_user_id()
  AND public.current_user_id() IS NOT NULL
);

-- 3. UPDATE: Chủ sở hữu hoặc người có role 'editor'
DROP POLICY IF EXISTS "Update document as owner or editor" ON public.documents;
CREATE POLICY "Update document as owner or editor"
ON public.documents FOR UPDATE
TO anon, authenticated
USING (
  owner_id = public.current_user_id()
  OR private.has_document_permission(id, public.current_user_id(), 'editor')
)
WITH CHECK (
  owner_id = public.current_user_id()
  OR private.has_document_permission(id, public.current_user_id(), 'editor')
);

-- 4. DELETE: Duy nhất chủ sở hữu mới có quyền xóa
DROP POLICY IF EXISTS "Delete document only as owner" ON public.documents;
CREATE POLICY "Delete document only as owner"
ON public.documents FOR DELETE
TO anon, authenticated
USING (
  owner_id = public.current_user_id()
);

-- ------------------------------------------------------------------------------
-- CHÍNH SÁCH RLS CHO BẢNG: permissions
-- Kiểm soát quyền chia sẻ và thu hồi quyền chia sẻ
-- ------------------------------------------------------------------------------

-- 1. SELECT: Người nhận quyền HOẶC Chủ sở hữu tài liệu
DROP POLICY IF EXISTS "View permissions for owner or granted user" ON public.permissions;
CREATE POLICY "View permissions for owner or granted user"
ON public.permissions FOR SELECT
TO anon, authenticated
USING (
  user_id = public.current_user_id()
  OR private.is_document_owner(document_id, public.current_user_id())
);

-- 2. INSERT: Duy nhất chủ sở hữu tài liệu mới có quyền chia sẻ
DROP POLICY IF EXISTS "Grant permission only by document owner" ON public.permissions;
CREATE POLICY "Grant permission only by document owner"
ON public.permissions FOR INSERT
TO anon, authenticated
WITH CHECK (
  private.is_document_owner(document_id, public.current_user_id())
);

-- 3. UPDATE: Duy nhất chủ sở hữu tài liệu mới có quyền thay đổi role (viewer <-> editor)
DROP POLICY IF EXISTS "Update permission only by document owner" ON public.permissions;
CREATE POLICY "Update permission only by document owner"
ON public.permissions FOR UPDATE
TO anon, authenticated
USING (
  private.is_document_owner(document_id, public.current_user_id())
)
WITH CHECK (
  private.is_document_owner(document_id, public.current_user_id())
);

-- 4. DELETE: Chủ sở hữu thu hồi quyền HOẶC người được chia sẻ tự hủy quyền của chính mình
DROP POLICY IF EXISTS "Revoke permission by document owner or self" ON public.permissions;
CREATE POLICY "Revoke permission by document owner or self"
ON public.permissions FOR DELETE
TO anon, authenticated
USING (
  user_id = public.current_user_id()
  OR private.is_document_owner(document_id, public.current_user_id())
);

-- ==============================================================================
-- 7. THIẾT LẬP SUPABASE STORAGE BUCKET: documents & BẢO MẬT STORAGE
-- ==============================================================================
-- Tạo bucket 'documents' nếu chưa tồn tại
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', true)
ON CONFLICT (id) DO NOTHING;

-- Cho phép người dùng đã xác thực (có Firebase UID) tải tệp lên bucket documents
DROP POLICY IF EXISTS "Allow authenticated upload to documents bucket" ON storage.objects;
CREATE POLICY "Allow authenticated upload to documents bucket"
ON storage.objects FOR INSERT
TO anon, authenticated
WITH CHECK (
  bucket_id = 'documents'
  AND public.current_user_id() IS NOT NULL
);

-- Cho phép đọc tệp từ bucket documents
DROP POLICY IF EXISTS "Allow read from documents bucket" ON storage.objects;
CREATE POLICY "Allow read from documents bucket"
ON storage.objects FOR SELECT
TO anon, authenticated
USING (bucket_id = 'documents');

-- Cho phép xóa tệp nếu là người sở hữu thư mục {userId}/
DROP POLICY IF EXISTS "Allow owner to delete their files" ON storage.objects;
CREATE POLICY "Allow owner to delete their files"
ON storage.objects FOR DELETE
TO anon, authenticated
USING (
  bucket_id = 'documents'
  AND (storage.foldername(name))[1] = public.current_user_id()
);

-- ==============================================================================
-- HOÀN TẤT THIẾT LẬP CƠ SỞ DỮ LIỆU & STORAGE RLS CHO SUPABASE
-- ==============================================================================
