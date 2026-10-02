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

The speech recognizer is the device's speech service. The app explicitly
requests Bengali even if the service omits Bengali from its locale list or
cannot return that list. Online recognition is allowed; a separate Bengali
language-pack installation is not an app prerequisite. If one Bengali locale
is rejected, the other Bengali locale is tried once (bn-BD / bn-IN). The app
never silently switches to English or the phone's default language. Actual
recognition still requires microphone permission and a working service, and
may need internet. Accuracy and offline support depend on the device service.
One spoken sentence is split into separate products and quantities, including
`আধা কেজি`, `হাফ কেজি` and `৫০০ গ্রাম`. Every recognized item must be
reviewed and can be edited or omitted before it is shared. Unknown fragments
are shown explicitly instead of being guessed.

Tap the family card or the top-right family icon to open family information.
The owner and active delegated Admins open member management. Ordinary
members can see and copy the family's invite code, see whether joining is
enabled, and inspect their current name, role and Normal/Secure information.
The code comes from the family document they already have permission to read;
the admin-only member directory and management permissions are unchanged.
The joining state and role remain live while the page is open: a newly promoted
Admin gets a working management button, while a removed member loses access.
If the card says "পরিবারের সদস্য", that account is a member, not the family's
creator. Only the actual owner or an existing Admin can grant Admin access.

## Daily notes, prices and faster voice

Deploy the updated `firestore.rules` before using this version. New items
include `noteDate`, `clientCreatedAt` and nullable integer `pricePaisa`; older
items without these fields remain readable and editable. No data migration or
seeding is needed. `createdAt` remains a server timestamp for auditing.
Bangladesh calendar dates (UTC+06) define a family note. Offline items retain
their original note date and ordering when a later server timestamp arrives.

Each compact item row offers Tk 10/20/30/40/50/100/200, +5 and Reset in one
horizontal line. They fit a standard 360px phone; with larger accessibility text
or a narrower viewport the same line scrolls horizontally instead of wrapping.
+5 adds Tk 5 to the latest displayed amount (20 then +5 is 25), including rapid
taps while writes are pending. Reset sets an explicit zero. Tap the item's
amount to enter a custom price, including paisa, or clear an unset price.
This is the total price for that item's whole quantity, not a per-kg rate.
Tapping a preset replaces the price; repeated taps do not add it again. Authors
and Admins may set or clear prices; unrelated members cannot edit them.
An optimistic total is displayed immediately and rejected writes roll back.
Missing prices are shown separately from zero-price items.

Within each date, items are grouped by shop and sorted oldest first, with a
stable ID tie-break. Rows show only their own amount. One grand total and Save
button end each daily note. That total includes the full accessible day across
shops and bought/pending tabs, even when a search or store filter is active;
a short scope label explains this. Secure items contribute only for users who
already have permission to read them. Bought/undo does not change this total.

### Saved monthly expenses

Only active family Admins (including the original owner) finalize the family
expense snapshot. All items in that day must have a price, including explicit
zero where appropriate, and pending price/item writes must finish first.
Save writes two documents atomically, using the date as the document ID:

- `shopping_families/{familyId}/expenses/{yyyy-MM-dd}` contains only normal
  items' total and count; active members may read it.
- `shopping_families/{familyId}/admin_expenses/{yyyy-MM-dd}` contains the day's
  full normal-plus-secure total and count; only active Admins may read it.

Neither document contains product names. Rules validate bounded integer paisa,
counts, matching document dates, the saving Admin and server timestamps, and
require the shared/private pair to be saved together. Deploy this version's
`firestore.rules` before using Save. Existing shopping data needs no migration.

The receipt icon in the shopping AppBar opens **মাসিক খরচ**. The separate page
shows a month selector, that month's saved total, and each saved date and amount.
Admin revocation immediately replaces the private history with the normal one;
removed members lose the page's data. Each month query uses a single indexed
`day` field, so no composite Firestore index is required.

Saving a day again replaces its prior snapshot rather than adding spending
again. Editing/resetting/deleting current items does not silently rewrite a saved
expense: press Save again to finalize the new total. Unsaved days do not appear
in the monthly amount. The app displays an in-progress save until Firestore
acknowledges it, reports failures, and allows a retry. Keep an internet connection
for confirmation. A zero-item shared snapshot is hidden from normal history,
so a private-only shopping day is not displayed as an empty shared receipt.

Voice parsing now uses quantity/unit endings as product boundaries, including
unknown multiword products: `রসুন ১ কেজি আদা ১ কেজি` produces two items.
Ambiguous amounts still require review. Explicit stop opens review immediately
from the displayed partial text. Automatic stop keeps only a 350ms grace period
for a late final result; the recognizer receives a two-second silence hint.
Locale discovery is cached and capped at 500ms; a working Bengali locale is
remembered. Actual microphone/network recognition speed depends on the phone.
Both bought/pending tabs share two subscriptions, and adding items returns to
the pending list with search/store filters cleared so the new entries appear.

After the voice/navigation update, fully stop and run the app again (hot
reload cannot apply AndroidManifest.xml or Info.plist changes). On Android
the manifest declares internet access and the RecognitionService query.
On iOS the microphone and speech permission descriptions are included.
Regression tests cover missing/erroring locale lists, Bengali-only retry,
stop/final-result delivery, reopening, microphone denial, member/owner card
navigation, search/filter rebuilds, and a small phone with keyboard insets.
These tests use a fake recognizer and do not certify recognition on a real
phone. Test "আলু আধা কেজি তেল এক লিটার", stop/reopen, and both account roles
on the intended device before distributing the update.

Before merge, review the Flutter and disposable security-rules CI checks.
After merging and deploying rules to the intended Firebase project, test on
two different signed-in phones: create and join a family, search while the
keyboard is open, expand and type a new item, tap every store filter, rename
and promote a member, switch their Secure/Normal mode, confirm only Admin and
author can see their secure items, edit/delete an authored item, buy and undo
a swipe, disconnect a member's phone, add an item and reconnect. Test dark
and light mode before distributing the app.
