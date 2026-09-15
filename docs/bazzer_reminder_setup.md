# Bazzer Reminder: family shopping setup

This is an authenticated, private Firestore family list. The older top-level
`bazzer_reminder` public configuration remains untouched; no existing
Firestore document is deleted or silently migrated.

## After merging this pull request

1. In the VS Code project directory run `git status`. With a clean working
   tree, run `git switch main`, `git fetch origin`,
   `git merge --ff-only origin/main`, then `flutter pub get`,
   `flutter analyze`, `flutter test`. Use the separate fetch/merge commands
   if your local `git pull` reports `Cannot fast-forward to multiple branches`.
2. Deploy the repository's new security rules to the **correct project**:
   `firebase use ash-shifa-ruqyah` then
   `firebase deploy --only firestore:rules`. Verify the deploy output says
   `ash-shifa-ruqyah`. Merging GitHub code does **not** deploy live rules.
3. Log in as the family owner and open Bazzer Reminder. Tap **Create family**;
   an online connection is required. Copy the 12-character code from
   **Family management** and share it only with trusted relatives.
4. Every member logs in to their own account, enters the code and taps
   **Join** while online. The original owner is always an Admin and may
   disable joining, change member names, grant/revoke Admin, toggle a member
   between Normal/Secure, remove or restore a member. Active delegated Admins
   have the same family-management and bought-item permissions. Removed
   members cannot rejoin the same family with the old code themselves.
5. Grocery and vegetable shop lists are grouped separately. Members may add
   items; Admins may swipe/mark an item bought or undo it. Only the author of
   an item may edit or delete it. Deleted items are removed from the shared
   list after a confirmation prompt.
6. A Secure member's **new** entries go to the separate secure collection;
   they are visible only to Admins and to the author for their own edit/delete.
   Normal family members cannot query someone else's secure entries. Changing
   the member back to Normal does not publish earlier secure entries. An Admin
   can also choose Secure for their next manual or voice entry. Previously
   created normal items stay normal.

Private data layout:

```text
shopping_invites/{12-character-code}       # get by exact code, not listable
shopping_families/{familyId}                 # owner + join setting
shopping_families/{familyId}/members/{uid}   # role, secure mode, active/inactive
shopping_families/{familyId}/items/{itemId}  # shared pending/bought items
shopping_families/{familyId}/secure_items/{itemId} # admin + author only
users/{uid}/bazzer_reminder/family            # private family link
```

Android/iOS Firestore caches previously used documents by default. A shopping
item added without internet appears locally as pending and is uploaded once
the device reconnects and the server accepts the membership rules. Creation,
joining, disabling invites and changing member access require internet. A
removed member's previously downloaded cache cannot be erased remotely;
queued offline writes made after removal may appear temporarily on that phone
and then be rejected when connectivity returns.

The speech recognizer is the device's Bengali recognizer. Bengali must be
installed as an available locale; its quality and offline ability vary by
device. The app never silently switches to another recognition language.
One spoken sentence is split into separate products and quantities, including
`আধা কেজি`, `হাফ কেজি` and `৫০০ গ্রাম`. Every recognized item must be
reviewed and can be edited or omitted before it is shared. Unknown fragments
are shown explicitly instead of being guessed.

Before merge, review the Flutter and disposable security-rules CI checks.
After merging and deploying rules to the intended Firebase project, test on
two different signed-in phones: create and join a family, search while the
keyboard is open, expand and type a new item, tap every store filter, rename
and promote a member, switch their Secure/Normal mode, confirm only Admin and
author can see their secure items, edit/delete an authored item, buy and undo
a swipe, disconnect a member's phone, add an item and reconnect. Test dark
and light mode before distributing the app.
