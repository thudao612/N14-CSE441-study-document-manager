# Apply the borrow-request feature changes

This archive contains only the changed/new source files plus the already-created Supabase migration. Extract it into the root of your local checkout:

`D:\CNTT\FlutterProjects\N14-CSE441-study-document-manager-clean`

Keep the folder paths from the archive. Existing files with matching paths will be updated; new files will be added. `ShareDocumentDialog` is intentionally not modified.

Then run from the project root:

```powershell
flutter pub get
flutter analyze
flutter test
```

The migration was applied and verified in Supabase during this conversation, so do not run it again just to apply the Dart code. If you are using a different Supabase project/database, verify the table, RLS policies, and trigger there before testing.

After local verification:

```powershell
git status --short --branch
git diff --check
git diff -- lib/presentation/widgets/share_document_dialog.dart
```

The final command should show no changes to `ShareDocumentDialog`. Keep all work on `feature/borrow-requests`; do not push directly to `master`.
