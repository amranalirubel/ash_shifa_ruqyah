# EasyHome

EasyHome now stores building-scoped records in `easy_home_buildings/{homeId}`. The Home launcher opens the existing EasyHome route. There are no demo fallbacks, shared array writes, local role switches, or fixed rent amounts.

## Using the feature

1. Sign in. The landlord creates a home with a name and contact number.
2. Add floors/units and tenant records. A flat gets a permanent code such as `2B-K9X4`. Tenant records contain name, phone, flat, rent, start date and the monthly due day.
3. Share the 12-character home code. Tenants/caretakers submit a request. The landlord links a tenant request to the correct existing tenancy, or approves a caretaker.
4. The landlord opens EasyHome to generate any missing monthly bills. Due amounts, partial payments, payment history and receipts update live. The landlord can make a negative correction with a mandatory reason; receipts remain immutable.
5. Use notices for the whole home, a floor or a flat. A rent reminder targets the tenancy so a replacement occupant cannot see it. Use complaints to report problems, record responses and move through pending/in-progress/resolved.
6. Optional Android reminders run monthly at about 09:00 Asia/Dhaka on a selected day (1–28). Enable notification permission when prompted. These are generic local reminders, not remote push notifications for new notices.

## Permissions

| Action/data | Landlord | Tenant | Caretaker |
| --- | --- | --- | --- |
| Flat codes | Yes | Yes | Yes |
| Other tenants' names/phones | Yes | No | No |
| Rent records and receipts | All | Own tenancy | No |
| Manage flats, tenancies, payments, join requests | Yes | No | No |
| Send notices | Yes | No | Yes |
| Read notices | All | Relevant audiences | All |
| Complaints | All; update status/reply | Own; edit/delete while pending | All; update status/reply |
| Remove member/access | Yes | Leave own home | Leave own home |

The owner UID cannot be changed by clients. A member cannot assign their own role. Ending a tenancy frees the flat and revokes that account's access without deleting historical bills. Removing an account alone does not end its tenancy. Former tenants require landlord approval to reconnect.

## Accounting policy

- Amounts are integer paisa, up to BDT 1,000,000 per monthly bill.
- Start and end months are billed as full calendar months; the form states this before saving. First-month due date cannot precede the move-in date.
- Bill ID is `tenancyId_YYYY-MM`. Transactions and fixed IDs prevent duplicate generation and lost concurrent payment updates.
- Before changing a tenant's rent, outstanding months are generated using the old rate. Existing bills never change; the new rate applies to later unbilled months.
- Missing bills are generated when the landlord opens/resumes EasyHome and when the month changes while the page remains open. No background server scheduler is deployed.
- Writes need an internet connection. Firestore's cached data can be read offline; the page identifies cached data and never reports a failed write as saved.

## Deployment

Merge the PR after all checks pass, then in the project directory:

```powershell
git switch main
git pull --ff-only origin main
flutter pub get
firebase deploy --only firestore:rules --project ash-shifa-ruqyah
flutter run
```

The rules must be deployed before the new EasyHome build is used. CI tests run against disposable `demo-*` Firestore emulators and do not touch production data. No additional composite indexes or new Flutter dependencies are required.

Existing `easy_home/*` prototype documents are preserved but restricted to app admins because they mix unscoped household data. They are not silently assigned to the first landlord; any real legacy records require a verified owner before a deliberate import. The prototype seed code and the unused commented seed file were removed, so running the general seed cannot recreate sample tenants.

## Validation

- Flutter CI: format, fatal-info analysis, full test suite and existing seed validation.
- EasyHome emulator CI: house creation, join requests, role escalation attempts, query-level privacy, tenancy linking, billing, receipt integrity, concurrent payments, notices, complaints, tenant replacement and revocation.
- Existing family shopping rules CI remains a regression gate for the shared rules file.
- Widget tests cover 360px light/dark layouts, keyboard form overflow, stable search subscriptions, failed-save retry, role-specific controls, revocation and empty onboarding.

Real-device acceptance: use separate landlord, tenant and caretaker accounts on the Android phone; verify joins, partial payment and receipt visibility, reconnect/offline behavior, opt-in notifications and reboot scheduling. CI cannot certify physical device notification delivery.
