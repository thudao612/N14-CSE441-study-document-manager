# Borrow requests feature — verification checklist

Run these commands from the Flutter project root:

```powershell
flutter pub get
flutter analyze
flutter test
```

## Manual Supabase integration checks

Use two different Firebase accounts. Account A owns a document; account B has an existing `viewer` or `editor` permission for that document.

1. As B, open the detail dialog and send a borrow request. Verify a new `borrow_requests` row is created with B's Firebase UID and `pending` status.
2. As A, open **Quản lý yêu cầu mượn**. Verify B's request is listed and can be approved or rejected.
3. As B, verify the status updates. If approved, select **Xác nhận đã trả tài liệu** and verify the row becomes `returned` with `returned_at` populated.
4. Repeat with a rejected request and verify a rejected request cannot be returned.
5. Attempt to approve/reject as B or another non-owner using a direct client call. The update must be denied by Supabase RLS/trigger.
6. Attempt an invalid status transition (such as `pending -> returned` or `rejected -> returned`). The trigger must reject it.
7. Confirm a second active request for the same requester/document is rejected by the unique partial index.
8. Open `ShareDocumentDialog`; verify `viewer`/`editor` grant and revoke behavior remains unchanged.

The automated model tests cover JSON mapping and status helpers. The RLS checks above require the live Supabase project and separate signed-in accounts; they cannot be fully verified from an offline source archive.
