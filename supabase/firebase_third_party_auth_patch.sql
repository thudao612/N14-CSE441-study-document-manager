-- ==============================================================================
-- STUDY DOCUMENT MANAGER - SUPABASE RLS & FIREBASE THIRD-PARTY AUTH PATCH
-- ==============================================================================
-- Mục đích của file này:
-- 1. Cập nhật hàm `public.current_user_id()` nhằm trích xuất Firebase UID duy nhất
--    từ các JWT claim đã được Supabase Third-Party Auth ký và xác thực (sub, user_id).
--    Đã LOẠI BỎ hoàn toàn việc đọc UID từ header tùy chỉnh `x-firebase-uid` để bảo đảm
--    an ninh, ngăn chặn nguy cơ mạo danh định danh người dùng.
-- 2. Tài liệu hóa và đồng bộ các hàm hỗ trợ trong schema `private` chạy dưới quyền
--    `SECURITY DEFINER` để loại bỏ triệt để lỗi đệ quy chính sách RLS giữa 2 bảng
--    `documents` và `permissions`.
-- 3. Cập nhật các chính sách RLS cho `users`, `documents`, `permissions` tương thích
--    hoàn toàn với Firebase Third-Party Auth (cả role anon và authenticated).
-- ==============================================================================

-- BƯỚC 1: CẬP NHẬT HÀM TRÍCH XUẤT ĐỊNH DANH FIREBASE UID AN TOÀN
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

      -- Một số cấu hình Firebase còn đặt UID tại claim 'user_id'
      v_sub := jwt_claims ->> 'user_id';
      IF v_sub IS NOT NULL AND v_sub <> '' THEN
        RETURN v_sub;
      END IF;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    -- Bỏ qua lỗi cú pháp JSON nếu có
  END;

  -- 3. Dự phòng trường hợp auth.uid() chuẩn của Supabase
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

-- BƯỚC 2: CÁC HÀM HỖ TRỢ TRONG SCHEMA `private` TRÁNH LỖI ĐỆ QUY RLS
CREATE SCHEMA IF NOT EXISTS private;

-- Cấp quyền sử dụng schema private cho các role truy vấn
GRANT USAGE ON SCHEMA private TO anon, authenticated, service_role;

-- Hủy các hàm cũ nếu đã tồn tại (dùng CASCADE) để tránh lỗi PostgreSQL 42P13 khi đổi tên tham số
DROP FUNCTION IF EXISTS private.is_document_owner(text, text) CASCADE;
DROP FUNCTION IF EXISTS private.has_document_permission(text, text, text) CASCADE;
DROP FUNCTION IF EXISTS private.has_document_permission(text, text) CASCADE;

-- Hàm kiểm tra người dùng có phải là chủ sở hữu tài liệu (Chạy SECURITY DEFINER để bypass RLS documents)
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

-- Hàm kiểm tra quyền của người dùng trong bảng permissions (Chạy SECURITY DEFINER để bypass RLS permissions)
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

-- Cấp quyền thực thi 2 hàm hỗ trợ cho anon và authenticated
GRANT EXECUTE ON FUNCTION private.is_document_owner(text, text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION private.has_document_permission(text, text, text) TO anon, authenticated;

-- BƯỚC 3: CẬP NHẬT CHÍNH SÁCH RLS SỬ DỤNG HÀM PRIVATE ĐỂ KHÔNG BAO GIỜ BỊ ĐỆ QUY

-- ------------------------------------------------------------------------------
-- CHÍNH SÁCH RLS CHO BẢNG: documents
-- ------------------------------------------------------------------------------
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;

-- 1. SELECT: Chủ sở hữu hoặc người được cấp quyền trong permissions
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
-- ------------------------------------------------------------------------------
ALTER TABLE public.permissions ENABLE ROW LEVEL SECURITY;

-- 1. SELECT: Người nhận quyền HOẶC Chủ sở hữu tài liệu (sử dụng private.is_document_owner để tránh đệ quy)
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

-- ------------------------------------------------------------------------------
-- CHÍNH SÁCH RLS CHO BẢNG: users
-- ------------------------------------------------------------------------------
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view all registered users" ON public.users;
CREATE POLICY "Users can view all registered users"
ON public.users FOR SELECT
TO anon, authenticated
USING (public.current_user_id() IS NOT NULL);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
CREATE POLICY "Users can insert own profile"
ON public.users FOR INSERT
TO anon, authenticated
WITH CHECK (
  id = public.current_user_id()
  AND public.current_user_id() IS NOT NULL
);

DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
CREATE POLICY "Users can update own profile"
ON public.users FOR UPDATE
TO anon, authenticated
USING (id = public.current_user_id())
WITH CHECK (id = public.current_user_id());
