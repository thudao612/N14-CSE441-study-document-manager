-- Borrow requests workflow for N14-CSE441-study-document-manager
-- Apply this as a separate migration. It intentionally does not modify schema.sql.

BEGIN;

CREATE TABLE IF NOT EXISTS public.borrow_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id TEXT NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
  requester_id TEXT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected', 'returned')),
  requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  reviewed_at TIMESTAMPTZ,
  returned_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT borrow_requests_status_timestamps_check CHECK (
    (status = 'pending' AND reviewed_at IS NULL AND returned_at IS NULL)
    OR
    (status IN ('approved', 'rejected') AND reviewed_at IS NOT NULL AND returned_at IS NULL)
    OR
    (status = 'returned' AND reviewed_at IS NOT NULL AND returned_at IS NOT NULL)
  )
);

COMMENT ON TABLE public.borrow_requests IS
  'Requests to borrow a shared study document; transition rules enforced by trigger and RLS.';
COMMENT ON COLUMN public.borrow_requests.status IS
  'Allowed flow: pending -> approved/rejected; approved -> returned.';

CREATE INDEX IF NOT EXISTS idx_borrow_requests_document_status_requested
  ON public.borrow_requests (document_id, status, requested_at DESC);
CREATE INDEX IF NOT EXISTS idx_borrow_requests_requester_status
  ON public.borrow_requests (requester_id, status, requested_at DESC);

-- Prevent duplicate active requests by one borrower for the same document.
-- A rejected or returned request does not prevent making a later request.
CREATE UNIQUE INDEX IF NOT EXISTS uq_borrow_requests_active_requester_document
  ON public.borrow_requests (document_id, requester_id)
  WHERE status IN ('pending', 'approved');

-- Guard inserts and state transitions even if a client sends unexpected columns.
CREATE OR REPLACE FUNCTION public.enforce_borrow_request_transition()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = pg_catalog, public, private
AS $$
DECLARE
  actor_id TEXT := public.current_user_id();
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.status <> 'pending' OR NEW.reviewed_at IS NOT NULL OR NEW.returned_at IS NOT NULL THEN
      RAISE EXCEPTION 'A new borrow request must start in pending status.'
        USING ERRCODE = '22023';
    END IF;

    NEW.requested_at := now();
    NEW.updated_at := now();
    RETURN NEW;
  END IF;

  -- Identity and request creation time are immutable after insertion.
  IF NEW.id IS DISTINCT FROM OLD.id
     OR NEW.document_id IS DISTINCT FROM OLD.document_id
     OR NEW.requester_id IS DISTINCT FROM OLD.requester_id
     OR NEW.requested_at IS DISTINCT FROM OLD.requested_at THEN
    RAISE EXCEPTION 'Borrow request identity fields cannot be changed.'
      USING ERRCODE = '42501';
  END IF;

  IF OLD.status = 'pending' AND NEW.status IN ('approved', 'rejected') THEN
    IF NOT private.is_document_owner(OLD.document_id, actor_id) THEN
      RAISE EXCEPTION 'Only the document owner can approve or reject a borrow request.'
        USING ERRCODE = '42501';
    END IF;
    NEW.reviewed_at := now();
    NEW.returned_at := NULL;
  ELSIF OLD.status = 'approved' AND NEW.status = 'returned' THEN
    IF OLD.requester_id IS DISTINCT FROM actor_id THEN
      RAISE EXCEPTION 'Only the requester can mark an approved borrow request as returned.'
        USING ERRCODE = '42501';
    END IF;
    NEW.reviewed_at := OLD.reviewed_at;
    NEW.returned_at := now();
  ELSE
    RAISE EXCEPTION 'Invalid borrow request status transition: % -> %.', OLD.status, NEW.status
      USING ERRCODE = '22023';
  END IF;

  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_borrow_request_transition ON public.borrow_requests;
CREATE TRIGGER trg_enforce_borrow_request_transition
BEFORE INSERT OR UPDATE ON public.borrow_requests
FOR EACH ROW
EXECUTE FUNCTION public.enforce_borrow_request_transition();

ALTER TABLE public.borrow_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Borrow requests visible to requester or document owner" ON public.borrow_requests;
CREATE POLICY "Borrow requests visible to requester or document owner"
ON public.borrow_requests
FOR SELECT
TO anon, authenticated
USING (
  requester_id = public.current_user_id()
  OR private.is_document_owner(document_id, public.current_user_id())
);

DROP POLICY IF EXISTS "Eligible non-owner can request shared document" ON public.borrow_requests;
CREATE POLICY "Eligible non-owner can request shared document"
ON public.borrow_requests
FOR INSERT
TO anon, authenticated
WITH CHECK (
  requester_id = public.current_user_id()
  AND public.current_user_id() IS NOT NULL
  AND NOT private.is_document_owner(document_id, public.current_user_id())
  AND private.has_document_permission(document_id, public.current_user_id())
);

DROP POLICY IF EXISTS "Document owner reviews pending borrow requests" ON public.borrow_requests;
CREATE POLICY "Document owner reviews pending borrow requests"
ON public.borrow_requests
FOR UPDATE
TO anon, authenticated
USING (
  status = 'pending'
  AND private.is_document_owner(document_id, public.current_user_id())
)
WITH CHECK (
  status IN ('approved', 'rejected')
  AND private.is_document_owner(document_id, public.current_user_id())
);

DROP POLICY IF EXISTS "Requester marks approved request returned" ON public.borrow_requests;
CREATE POLICY "Requester marks approved request returned"
ON public.borrow_requests
FOR UPDATE
TO anon, authenticated
USING (
  requester_id = public.current_user_id()
  AND status = 'approved'
)
WITH CHECK (
  requester_id = public.current_user_id()
  AND status = 'returned'
);

-- Match the project's existing grants/policies for Firebase Third-Party Auth requests.
GRANT SELECT, INSERT, UPDATE ON public.borrow_requests TO anon, authenticated;

COMMIT;
