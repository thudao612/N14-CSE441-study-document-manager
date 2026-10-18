-- ==============================================================================
-- STUDY DOCUMENT MANAGER - SUPABASE STORAGE SETUP (GÓI MIỄN PHÍ)
-- ==============================================================================
-- Lưu ý: Bảng storage.objects ĐÃ ĐƯỢC Supabase tự động bật sẵn RLS từ hệ thống.
-- Không cần (và không được) chạy lệnh "ALTER TABLE storage.objects" vì Supabase sẽ
-- báo lỗi "ERROR: 42501: must be owner of table objects".
-- ==============================================================================

-- BƯỚC 1: TẠO BUCKET 'documents' (NẾU CHƯA CÓ) VÀ BẬT PUBLIC
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'documents',
  'documents',
  true,
  52428800, -- Giới hạn tối đa 50MB mỗi tệp (phù hợp gói Free)
  ARRAY[
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'text/plain',
    'image/jpeg',
    'image/png',
    'application/octet-stream'
  ]
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 52428800;

-- BƯỚC 2: XÓA CÁC CHÍNH SÁCH CŨ LIÊN QUAN ĐẾN BUCKET 'documents' ĐỂ TRÁNH TRÙNG LẶP
DROP POLICY IF EXISTS "Public Access documents bucket" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own document files" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own document files" ON storage.objects;
DROP POLICY IF EXISTS "Allow upload to documents" ON storage.objects;

-- BƯỚC 3: THIẾT LẬP CÁC CHÍNH SÁCH RLS CHO BUCKET 'documents'

-- 1. Quyền ĐỌC (SELECT): Cho phép mọi người tải và xem tệp từ bucket 'documents'
CREATE POLICY "Public Access documents bucket"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'documents');

-- 2. Quyền TẢI LÊN (INSERT): Cho phép tải tệp lên bucket 'documents'
CREATE POLICY "Authenticated users can upload documents"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'documents');

-- 3. Quyền CẬP NHẬT (UPDATE): Cho phép cập nhật tệp trong bucket 'documents'
CREATE POLICY "Users can update own document files"
ON storage.objects FOR UPDATE
TO public
USING (bucket_id = 'documents');

-- 4. Quyền XÓA (DELETE): Cho phép xóa tệp trong bucket 'documents'
CREATE POLICY "Users can delete own document files"
ON storage.objects FOR DELETE
TO public
USING (bucket_id = 'documents');
