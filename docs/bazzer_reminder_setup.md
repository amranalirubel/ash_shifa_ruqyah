# Bazzer Reminder: family shopping setup

This is an authenticated, private Firestore family list. The older top-level
`bazzer_reminder` public configuration remains untouched; no existing
Firestore document is deleted or silently migrated.

## After merging this pull request

1. In the VS Code project directory run `git status`. Only pull when the
   working tree is clean: `git switch main`, `git pull --ff-only origin main`,
   `flutter pub get`, `flutter analyze`, `flutter test`.
2. Deploy the repository's new security rules to the **correct project**:
   `firebase use ash-shifa-ruqyah` then
   `firebase deploy --only firestore:rules`. Verify the deploy output says
   `ash-shifa-ruqyah`. Merging GitHub code does **not** deploy live rules.
3. Log in as the family owner and open Bazzer Reminder. Tap **Create family**;
   an online connection is required. Copy the 12-character code from
   **Family management** and share it only with trusted relatives.
4. Every member logs in to their own account, enters the code and taps
   **Join** while online. The owner can disable new joining, deactivate a
   member or reactivate a previously removed member. Deactivated members
   cannot rejoin the same family with the old code themselves.
5. Grocery and vegetable shop lists are grouped separately. Members may add
   items; only the owner may swipe/mark an item bought or undo it. Bought
   items remain in Firestore and appear in the **Bought** tab.

Private data layout:

```text
shopping_invites/{12-character-code}       # get by exact code, not listable
shopping_families/{familyId}                 # owner + join setting
shopping_families/{familyId}/members/{uid}   # active/inactive, never deleted
shopping_families/{familyId}/items/{itemId}  # pending/bought, never deleted
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
two different signed-in phones: create and join a family, disable joining,
remove and restore a member, add a grocery and a vegetable by voice, buy and
undo a swipe, disconnect a member's phone, add an item and reconnect. Test
dark and light mode and verify no overflow before distributing the app.
