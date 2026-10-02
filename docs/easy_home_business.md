# EasyHome: paid-value property management, no advertising

## Delivered in this change

- Android system and toolbar back from an EasyHome tab return to its summary;
  summary back returns to app home; app home asks before exiting.
- Rent summary shows current invoice-month collection progress and all-month
  overdue balances. Rent lists support all months, overdue and partial filters,
  oldest due dates first, and copying a monthly statement.
- Owner-only cloud expense ledger: paid maintenance, utilities, caretaker/security
  salary, cleaning and other operating costs, with date, receipt reference and note.
  An entry is immutable. Void mistakes with a reason, then enter the correction;
  voided originals remain available in history and are excluded from totals.
- Monthly reports separate invoice-month rent balances from date-based actual
  expenses, summarize categories, and copy Bangla text or share an Excel-compatible
  UTF-8 CSV. CSV neutralizes formula-like user text. No tenant names/phones exported.
- Utility/service-charge calculator splits a total among selected flats either
  equally or by integer usage weights, preserving every paisa with deterministic
  largest-remainder rounding. Empty flats may be included or excluded. A draft
  can be copied; it does NOT create tenant bills, post notices or record payments.
- Report routes clear their private content on logout, revocation or data errors.
  Tenants and caretakers never subscribe to the owner's expense ledger.

## Accounting boundaries

Rent paid balances belong to the bill's month, not the receipt's payment date.
Do not subtract expenses and call the result cash profit. This change deliberately
labels these separately, including copied/CSV reports. It is not a tax statement.
Expenses record money already paid, not commitments, supplier debts or tenant fees.
All writes require internet. Firestore rules must be deployed before the new client
because an owner now subscribes to the expenses collection. Existing records are
preserved, no migration or deletion required. The expense date is an ISO local
calendar day; UI/repository reject impossible or future dates. Rules validate its
shape; only the immutable home owner can create entries.

Reports reflect current synchronized data, not signed immutable statements. Cache
warnings carry into exports. Export intentionally shares the selected report with
an app chosen by the owner. Copied/exported data is outside app revocation control.
Utility drafts are local and are lost on leaving the tool; no background billing.
The app loads each home's history in memory, so large-portfolio pagination and
multi-building management remain future work.

## Commercial model

The paying customer to validate is the landlord/property manager: reducing manual
expense entry, missed dues, receipt searches and bill-allocation disputes. Keep
existing tenants' access to their own balances, notices and receipts available.
Pilot these workflows with actual owners before choosing a subscription price.
No revenue, willingness to pay, price or sales result is guaranteed.

This PR delivers useful workflows, NOT a live subscription checkout or paywall.
No ads, fake premium purchase buttons, local unlock flags or client-writable paid
status exist. Existing accounts retain their current functionality.

To activate a paid subscription, the owner still needs to decide pricing and plan
limits and configure real store products in their Play Console/merchant account.
Then implement purchase/restore through Play Billing with server-side purchase
verification, a protected entitlement tied to account/building, renewal/cancel/
refund/expiry handling, and backend enforcement of paid writes. Test purchase,
restore, pending, grace period, refund and account switching using licensed test
accounts before charging customers. Subscription cancellation must not delete
historic accounts or receipts. Physical rent payments are distinct from purchasing
this app's digital management service. Review country/distribution-specific billing
requirements when choosing the payment channel.

Primary references consulted 2026-10-02:
- https://developer.android.com/google/play/billing
- https://developer.android.com/google/play/billing/subscriptions
- https://support.google.com/googleplay/android-developer/answer/9858738

## Release

Merge the reviewed PR, update main and run:

```powershell
git switch main
git pull --ff-only origin main
flutter pub get
firebase deploy --only firestore:rules --project ash-shifa-ruqyah
flutter run
```

Device checks: hardware and gesture back through tabs, tool, form and summary;
confirm/cancel app exit; expense retry/void/history; CSV opening and Bangla text;
utility rounding and editing; tenant/caretaker permissions; light/dark/large text.
No production deployment, store publishing or real-device verification is implied.
