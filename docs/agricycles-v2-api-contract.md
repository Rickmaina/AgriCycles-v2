# AgriCycles v2 API Contract

## 1. Farmer onboarding

This contract keeps onboarding open-ended and reviewable.

- `farmer_type`: confirmed field used for core onboarding classification.
- `crop_details`: confirmed free-text field capturing what the farmer grows, keeps, or raises.
- `farm_scale`: optional field, proposed pending review, values may be `small_scale`, `large_scale`, or `not_specified`.
- The UI should allow quick-select chips, free-text entry, and a final “what you can do now” screen before the user lands in the marketplace.

## 3. Listing quality control

- New marketplace listings are created as `pendingReview` by default in the app flow; they are not automatically published to the public browse list.
- Existing seed/live data is intentionally left as-is unless the app explicitly updates a listing status through admin moderation.
- Moderators may then approve the listing to `active` or reject it, and the public marketplace browse path filters out any listing that is not `active`.

## 4. GeoLocation and privacy

### 4.15 GeoLocation capture is already implemented

The repo already contains a privacy-safe `GeoLocation` data model at [lib/data/models/geo_location.dart](../lib/data/models/geo_location.dart), with `source` values `selfReported`, `deviceCaptured`, and `adminVerified`.

- `lat` / `lng` are treated as sensitive coordinates.
- The UI should display only `broadLocation` (`area, subCounty`) in public-facing listings and summaries.
- Exact coordinates are revealed only after explicit acceptance for a transaction.

### 4.16 Transport estimator

The repo already includes [lib/domain/transport_estimator.dart](../lib/domain/transport_estimator.dart), using county centroid estimates for distance and cost calculations in the current app flow.

## 5. Listing and user models

### 5.3 Listing status enum

Supported values for `listing.status` in the repo are:

- `active`
- `paused`
- `sold`
- `expired`
- `pendingReview`
- `rejected`

Implemented note: the controller creates new listings in `pendingReview`, and browse results only expose listings with `status == active`.

### 5.15 User model notes

The current repo already includes `farmer_type` and `crop_details` in the app’s `UserModel` implementation. A new optional `farm_scale` field is present but remains a loosely typed value until product review is complete.

### 5.16 Farm scale field

```json
{
  "farm_scale": "small_scale"
}
```

This is a proposed field and intentionally lightweight so onboarding can stay flexible while product review continues.

## 6. Moderation and workflow

- `pendingReview` listings sit in a moderation queue before they appear in the main marketplace.
- The moderation queue mirrors the existing approval/rejection pattern used for verification requests.
- The repo currently exposes the queue UI and the controller update flow; the app-level process is implemented, but not every admin action path has dedicated automated coverage.

## Changelog

### 2026-09-21

- Synced the contract with the implemented listing-review gate: new listings default to `pendingReview`, and browse results hide any non-`active` listing.
- Confirmed the validation fix for invalid county/sub-county pairs is enforced in `GeoLocation` and validated by the regression suite.
- Recorded the current frontend-only status: the remaining product/backend decisions stay open while the app continues to ship front-end behavior without a full backend contract implementation.

## Appendix: implemented repo sources

- GeoLocation model: [lib/data/models/geo_location.dart](../lib/data/models/geo_location.dart)
- Privacy doc: [lib/core/privacy_coordinates.md](../lib/core/privacy_coordinates.md)
- Transport estimator: [lib/domain/transport_estimator.dart](../lib/domain/transport_estimator.dart)
- Notification center: [lib/features/notifications/screens/notifications_screen.dart](../lib/features/notifications/screens/notifications_screen.dart)
- Notification controller: [lib/features/notifications/controllers/notification_controller.dart](../lib/features/notifications/controllers/notification_controller.dart)
