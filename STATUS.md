# AgriCycles v2 frontend status

## 1. Verified working

- Location invariant enforcement: the app rejects invalid county/sub-county combinations like Nakuru → Siaya at the model layer, and the regression test confirms it.
- Marketplace listing visibility: pending-review listings do not appear in public browse results; only active listings are returned.
- Community-order access gating: non-company users are redirected away from the company-only pre-order flow instead of being allowed to create that record.
- Privacy-safe location handling: GeoLocation keeps broad public location data separate from sensitive coordinates, and the order privacy regression test remains green.
- Core order flow: the privacy/order integration tests that cover masking and reveal logic still pass.
- Transport estimation: centroid fallback and Haversine distance logic remain passing under the focused regression suite.

## 2. Implemented but untested

- Admin moderation queue flows for listing review and verification review are present in the repo, but the full coverage is not comprehensive enough to treat them as deeply verified in automation.
- The home shell and dashboard flows include several role-based UI screens and status summaries, but they are not all backed by isolated automated coverage.
- The broader verification and driver/logistics edge cases are implemented in code paths but remain informal rather than fully exercised in the test suite.
- Some legacy string-based location fields remain in parts of the model/service layer as compatibility shims even though the primary data model now uses GeoLocation.

## 3. Deferred to next phase

- Driver UI and driver assignment workflow
- Logistics assignment UI and orchestration flow
- Weigh-in UI and status handling
- Payment UI and release workflow
- Dark mode decision
- Localization
- Road-distance routing
- Full backend contract integration

## 4. Open product/backend decisions

- Money format and settlement policy remain a product decision.
- Weigh-in discrepancy and acceptance policy remains a product/backend decision.
- Commission and tier values remain open.
- Driver role migration remains an open product decision.
- Payment release trigger remains an open backend decision.
- Any full server-side enforcement for role/access checks remains outside the current frontend-only scope.

## 5. Known risks

- The frontend has several role-specific screens and workflows that are implemented but not fully consolidated under a single tested contract.
- The repo still mixes legacy compatibility parameters with the newer GeoLocation pattern, which is manageable but requires caution when adding new location-based code.
- The contract doc is now aligned to the implemented behavior, but several product decisions remain open and should not be silently assumed in future UX work.
- Coverage is strongest around the data-integrity and privacy regressions, while a number of richer operational flows are still partly untested.
