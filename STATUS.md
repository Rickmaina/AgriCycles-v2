# AgriCycles v2 — Frontend Status

**Date:** 2026-09-25
**Commit:** `44eea2d` — merge-recovery: restore location picker + community gate + listing review
**Phase 0 exit:** Verified. All claims below are backed by pasted command output from this session.

---

## 1. Verified working

Every item below is confirmed by a passing test or by a passed command in this session.

### Domain logic
- **Location integrity** — `GeoLocation` rejects invalid county/sub-county pairs at the model layer. Test: `location_integrity_test.dart` → `GeoLocation rejects Siaya as a sub-county of Nakuru`.
- **Transport estimation** — Haversine formula used when both locations have coordinates; county-centroid fallback when coordinates are missing. Tests: `transport_estimator_test.dart` → `Haversine used when both locations have coordinates`, `Falls back to county centroid when coordinates missing`.
- **Model contracts** — model shapes hold against the current test fixtures. Test: `model_contract_test.dart`.

### Marketplace & order integrity
- **Listing visibility** — only `active` listings appear in public browse. Pending-review and rejected listings are filtered out at the screen level. Test: `location_integrity_test.dart` → `pending-review listings do not appear in marketplace browse results`.
- **Order privacy** — coordinates are masked for non-parties before offer acceptance and revealed after. Test: `privacy_integration_test.dart` → `Coordinates are masked for non-party before acceptance and revealed after`.

### Access control
- **Community pre-order gate** — non-company users are blocked from the community pre-order creation flow, with a friendly wrong-role screen and a redirect to the buy-request flow. Enforced at three layers (FAB menu, screen build(), controller). Test: `location_integrity_test.dart` → `non-company users are blocked from the community pre-order creation flow`.

### Build health
- **`flutter analyze lib`** — No issues found.
- **`flutter test`** — 9 tests passed across 4 test files.
- **`flutter build web --release`** — builds successfully. Total 42 MB (main.dart.js 2.9 MB, canvaskit lazy-loaded).
- **Kenya location asset** — `assets/data/kenya_locations.json` ships in the production build at 28,503 bytes.

### Architecture
- **Layered structure intact** — `core/`, `data/`, `domain/`, `features/`, `routing/`, `shared/` all present and consistent.
- **Location picker migration** — cascading `LocationPicker` on 8 of 8 location-capturing screens.
- **100+ Dart files** with zero analyzer issues.

---

## 2. Implemented but untested

Real code that exists but has no automated coverage. This list matters more than Section 1.

- **Role theme application** — `RoleTheme` exists with 3 palettes × 15 tokens, but is used in only 5 files (mostly AppBar/nav chrome). The three role home screens (`farmer_dashboard.dart`, `company_home.dart`, `admin_home.dart`) use `AppColors` directly. **`AppColors` appears 366 times in features; `RoleTheme` 19 times.** Remove the AppBar and a company user sees the same color palette as a farmer — the "market stall vs cockpit vs console" distinction the plan requires does not exist today.
- **Notification deep-linking** — `NotificationModel` carries `target` and `targetId`, but tapping a notification only marks it read. No navigation.
- **Auto-notify hooks** — Only `orders_controller.advance` and `dispute_controller.raise` fire notifications. Missing: offer received, counter-offer, offer accepted, pre-order contribution accepted/rejected, listing approved/rejected.
- **Admin pending review queue** — screen exists (126 lines) and is wired to `pendingReviewListingsProvider`, but no widget test exercises it.
- **Browse filter** — the fix applied in this session (Phase 0.15) is validated only by the model-layer test; the screen-level filter has no dedicated widget test.
- **Merge recovery** — 7 files restored from `2fce978` to undo the remote merge's regressions. Validated by the 9 existing tests but no test specifically proves the recovery (e.g. no test asserts `_CompanyOnlyBlock` renders).
- **Register screen** — password + confirm password fields re-added and wired to the new `AuthController.register()`. No widget test.

---

## 3. Files exceeding 300 lines (split candidates)

| File | Lines |
|------|-------|
| `lib/features/community/screens/community_order_detail_screen.dart` | 696 |
| `lib/features/orders/order_detail_screen.dart` | 524 |
| `lib/features/buy_requests/screens/buy_request_detail_screen.dart` | 517 |
| `lib/shared/widgets/location_picker.dart` | 475 |
| `lib/features/marketplace/create_listing_screen.dart` | 368 |

Refactor target for Phase 4. Not a Phase 0 blocker.

---

## 4. Deferred to later phases (per plan)

- Driver role UI, logistics assignment UI, weigh-in UI, payment UI (Phase 3B / 3B.5)
- Push notifications via FCM/APNs (v3)
- Dark mode (Phase 4 decision)
- Multi-role switcher, vet-as-farmer identity model (v3)
- Multi-language, offline mutation queue, crash reporting, CI/CD hardening (v3)
- Admin analytics dashboard beyond a "Today" summary (v3)
- Reference-data admin console (v3)
- Animal Health module (v3)

---

## 5. Open product/backend decisions

Pulled from the contract and Phase 0 audit findings:

1. **Money representation** — integer cents (contract §3.3) vs doubles (current frontend). Decision required before Phase 2.6.
2. **Weigh-in discrepancy policy** — what happens when two parties' readings disagree beyond the tolerance flag? Blocks Phase 2.5 gate implementation.
3. **Commission rate and tier values** — placeholders in the contract; not confirmed by product.
4. **Driver role migration** — adding `driver` to `UserRole` is a breaking enum change.
5. **Payment release trigger** — auto on quality_confirmed, or admin-triggered?
6. **Webhook signature scheme** — depends on payment provider choice.
7. **`needsReview` semantics** — currently includes `rejected`. Should it? (Finding 0.10)
8. **Community-order browse for farmers** — farmers contribute to community orders but have no entry point to browse open ones. (Finding 0.11)
9. **Ward field lost at registration** — the merged `AuthController.register()` doesn't accept `area`/ward. Farmer's ward will be null until they edit profile. (Finding 0.15)
10. **Company entry point for creating community orders** — FAB is farmer-only; no company-accessible entry exists for community-order creation. (Finding 0.11)

---

## 6. Known risks

- **Merge regression risk is active.** The remote branch that was integrated in `b674362` forked from a state before the location-picker migration, community gate, and listing-review flow. It overwrote 7 files with regressed versions. Recovered in `44eea2d`. **If the other agent does not `git pull --rebase origin main` before its next push, the same regression will recur.** Branch protection + CI is recommended.
- **Role theme is aspirational.** The plan's P1 principle ("role is the spine") is not implemented at the screen level. Company and admin home screens render farmer-green accents.
- **Auth is half-migrated.** `dio`, `flutter_secure_storage`, and the new network layer (`lib/core/network/`) are in place, but the backend they talk to doesn't exist. `AuthService` currently makes real HTTP calls that will fail against the mock environment.
- **Seed data is thin for demos.** Only 1 farmer, no seed buy requests / pre-orders / disputes / notifications. Admin queues have no demo content.
- **Cross-controller coupling** — `MarketplaceController` reads from buy-request and notification providers directly, creating domain cross-coupling.
- **`DisputeModel.raisedByRole` is a `String`** (`'buyer'` / `'seller'`), not an enum.

---

## 7. Audit trail

Every finding from Phase 0 with its origin:

| # | Finding | From | Status |
|---|---------|------|--------|
| 1 | `UserRole` missing `driver` | 0.6 | Phase 1.5 |
| 2 | `UserModel.tier` missing | 0.7 | Blocked on product |
| 3 | `UserModel.farmScale` is String | 0.7 | Phase 1.5 |
| 4 | `DisputeModel.raisedByRole` is String | 0.7, 0.8a | Phase 4 |
| 5 | `OrderModel.roadDistanceKm` missing | 0.7 | Phase 2 |
| 6 | 4 models missing (WeighIn, Payment, LogisticsAssignment, QuantityDeclaration) | 0.7 | Scheduled |
| 7 | `DriverProfile` not in contract | 0.7 | Fix in 0.17 |
| 8 | `AuthService` missing OTP | 0.8 | Phase 1.5 |
| 9 | `NotificationService` missing push tokens | 0.8, 0.12 | v3 |
| 10 | `MarketplaceController` cross-coupling | 0.8 | Phase 4 |
| 11 | Browse screen missing status filter | 0.10 | **Fixed in 0.15** |
| 12 | Seed listings don't declare explicit status | 0.10 | Phase 1 |
| 13 | `needsReview` includes `rejected` | 0.10 | Decision |
| 14 | Community gate triple-layer enforcement | 0.11 | ✓ Verified |
| 15 | Company has no community-order entry point | 0.11 | Phase 3B.5 |
| 16 | Farmers can't browse community orders | 0.11 | Phase 1 or 3B.5 |
| 17 | Notification deep-linking not wired | 0.12 | Phase 4 |
| 18 | Auto-notify hooks incomplete | 0.12 | Phase 4 |
| 19 | Role theme used in 5/40 screens | 0.13 | Phase 3B |
| 20 | Seed data thin (1 farmer, no verifications/buy-requests/etc.) | 0.14 | Phase 1 |
| 21 | No hardcoded color literals in screens | 0.13 | ✓ Positive |
| 22 | Location fields consistently use `GeoLocation` | 0.7 | ✓ Positive |
| 23 | All 8 services + 9 controllers present | 0.8 | ✓ Positive |
| 24 | Zero legacy `KenyaLocations` usage in screens (pre-merge) | 0.9 | Restored in 0.15 |
| 25 | Merge regression (7 files) | 0.15c | **Fixed in recovery commit `44eea2d`** |
| 26 | Ward field lost at registration | 0.15 | Decision |
| 27 | `lib/core/privacy_coordinates.md` duplicate | 0.1a | **Fixed in 0.15** |

---

## 8. Phase 0 exit checklist

- [x] `flutter analyze lib` → 0 issues
- [x] `flutter test` → 9/9 green
- [x] `flutter build web --release` → succeeds
- [x] `STATUS.md` → this file, accurate to pasted output
- [ ] Contract frozen (Phase 0.17–0.18)

---

*Next phase: Phase 1 — Farmer-simple foundation. See plan v1.0 for phase definitions.*
