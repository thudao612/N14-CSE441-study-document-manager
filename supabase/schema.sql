-- ==============================================================================
-- STUDY DOCUMENT MANAGER - SUPABASE POSTGRESQL SCHEMA & ROW LEVEL SECURITY (RLS)
-- Tích hợp Hybrid Cloud: Firebase Authentication + Firebase Storage + Supabase DB
-- ==============================================================================

-- 1. BẬT TIỆN ÍCH MÃ HÓA & UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 2. HÀM TRÍCH XUẤT FIREBASE UID TỪ JWT CLAIMS HOẶC HEADERS
-- Hỗ trợ xác thực người dùng thông qua Firebase ID Token được chuyển tiếp tới Supabase
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.current_user_id()
RETURNS text AS $$
DECLARE
  jwt_claims jsonb;
  v_sub text;
BEGIN
  -- 1. Trích xuất từ request.jwt.claim.sub (chuẩn PostgREST khi giải mã JWT)
  BEGIN
    v_sub := nullif(current_setting('request.jwt.claim.sub', true), '');
  EXCEPTION WHEN OTHERS THEN
    v_sub := NULL;
  END;

  IF v_sub IS NOT NULL AND v_sub <> '' THEN
    RETURN v_sub;
  END IF;

  -- 2. Trích xuất từ đối tượng jsonb request.jwt.claims
  BEGIN
    jwt_claims := nullif(current_setting('request.jwt.claims', true), '')::jsonb;
    IF jwt_claims IS NOT NULL THEN
      v_sub := jwt_claims ->> 'sub';
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

  -- 4. Trích xuất từ header tùy chỉnh 'x-firebase-uid' (khi truyền kèm qua client)
  BEGIN
    v_sub := nullif(current_setting('request.headers', true)::jsonb ->> 'x-firebase-uid', '');
    IF v_sub IS NOT NULL AND v_sub <> '' THEN
      RETURN v_sub;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    -- Bỏ qua
  END;

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
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

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
  owner_id TEXT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE, -- Chủ sở hữu tài liệu (Firebase UID)
  author_email TEXT DEFAULT '',              -- Email người tạo tài liệu
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

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
-- 5. BẬT ROW LEVEL SECURITY (RLS) VÀ THIẾT LẬP CHÍNH SÁCH BẢO MẬT
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
WITH CHECK (id = public.current_user_id());

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

-- 1. SELECT: Người dùng chỉ được xem tài liệu nếu là CHỦ SỞ HỮU hoặc ĐƯỢC CHIA SẺ
DROP POLICY IF EXISTS "View documents owned or shared" ON public.documents;
CREATE POLICY "View documents owned or shared"
ON public.documents FOR SELECT
TO anon, authenticated
USING (
  owner_id = public.current_user_id()
  OR EXISTS (
    SELECT 1 FROM public.permissions p
    WHERE p.document_id = public.documents.id
      AND p.user_id = public.current_user_id()
  )
);

-- 2. INSERT: Người dùng chỉ được tạo tài liệu mới với chính mình là chủ sở hữu
DROP POLICY IF EXISTS "Create document as owner" ON public.documents;
CREATE POLICY "Create document as owner"
ON public.documents FOR INSERT
TO anon, authenticated
WITH CHECK (
  owner_id = public.current_user_id()
);

-- 3. UPDATE: CHỦ SỞ HỮU hoặc NGƯỜI CÓ QUYỀN 'editor' mới được cập nhật metadata
-- NGƯỜI CÓ QUYỀN 'viewer' VÀ NGƯỜI NGOÀI BỊ TỪ CHỐI TUYỆT ĐỐI!
DROP POLICY IF EXISTS "Update document as owner or editor" ON public.documents;
CREATE POLICY "Update document as owner or editor"
ON public.documents FOR UPDATE
TO anon, authenticated
USING (
  owner_id = public.current_user_id()
  OR EXISTS (
    SELECT 1 FROM public.permissions p
    WHERE p.document_id = public.documents.id
      AND p.user_id = public.current_user_id()
      AND p.role = 'editor'
  )
)
WITH CHECK (
  owner_id = public.current_user_id()
  OR EXISTS (
    SELECT 1 FROM public.permissions p
    WHERE p.document_id = public.documents.id
      AND p.user_id = public.current_user_id()
      AND p.role = 'editor'
  )
);

-- 4. DELETE: DUY NHẤT CHỦ SỞ HỮU mới có quyền xóa tài liệu
-- Editor và Viewer KHÔNG THỂ XÓA!
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

-- 1. SELECT: Chủ sở hữu tài liệu HOẶC chính người được chia sẻ mới được xem quyền
DROP POLICY IF EXISTS "View permissions for owner or granted user" ON public.permissions;
CREATE POLICY "View permissions for owner or granted user"
ON public.permissions FOR SELECT
TO anon, authenticated
USING (
  user_id = public.current_user_id()
  OR EXISTS (
    SELECT 1 FROM public.documents d
    WHERE d.id = public.permissions.document_id
      AND d.owner_id = public.current_user_id()
  )
);

-- 2. INSERT: DUY NHẤT CHỦ SỞ HỮU tài liệu mới có quyền cấp chia sẻ cho người khác
DROP POLICY IF EXISTS "Grant permission only by document owner" ON public.permissions;
CREATE POLICY "Grant permission only by document owner"
ON public.permissions FOR INSERT
TO anon, authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.documents d
    WHERE d.id = public.permissions.document_id
      AND d.owner_id = public.current_user_id()
  )
);

-- 3. UPDATE: DUY NHẤT CHỦ SỞ HỮU tài liệu mới có quyền sửa đổi quyền (viewer <-> editor)
DROP POLICY IF EXISTS "Update permission only by document owner" ON public.permissions;
CREATE POLICY "Update permission only by document owner"
ON public.permissions FOR UPDATE
TO anon, authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.documents d
    WHERE d.id = public.permissions.document_id
      AND d.owner_id = public.current_user_id()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.documents d
    WHERE d.id = public.permissions.document_id
      AND d.owner_id = public.current_user_id()
  )
);

-- 4. DELETE: DUY NHẤT CHỦ SỞ HỮU mới có quyền thu hồi chia sẻ (hoặc người được chia sẻ tự rời khỏi)
DROP POLICY IF EXISTS "Revoke permission by document owner or self" ON public.permissions;
CREATE POLICY "Revoke permission by document owner or self"
ON public.permissions FOR DELETE
TO anon, authenticated
USING (
  user_id = public.current_user_id()
  OR EXISTS (
    SELECT 1 FROM public.documents d
    WHERE d.id = public.permissions.document_id
      AND d.owner_id = public.current_user_id()
  )
);

-- ==============================================================================
-- HOÀN TẤT THIẾT LẬP CƠ SỞ DỮ LIỆU & RLS CHO SUPABASE
-- ==============================================================================
