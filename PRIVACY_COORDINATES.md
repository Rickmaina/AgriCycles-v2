# Coordinate Privacy Policy

## Why this exists

AgriCycles handles farm locations. For smallholder farmers, the exact GPS
coordinates of a farm are sensitive: they reveal property boundaries,
livestock counts, and household presence. This document defines how
coordinates are captured, stored, shared, and revealed — and by whom.

The overarching rule: **precise coordinates are private by default and
revealed only when strictly necessary for an active transaction.**

---

## Location source types

Every location on the platform carries a `LocationSource` tag:

| Source | Meaning | Privacy class |
|--------|---------|---------------|
| `self_reported` | User typed a county / sub-county / area from the picker | **Approximate** — safe to display broadly |
| `device_captured` | GPS pin from the device (`geolocator`) | **Precise** — never displayed publicly |
| `verified` | Admin confirmed the exact location during a physical visit | **Precise** — never displayed publicly |

The frontend shows the source subtly to the user (a small "approximate"
or "precise" hint) so it is always honest about what was captured. It is
never used as a marketing label or a ranking signal.

---

## Visibility rules

Extending Section 8.1 of the design brief:

| Information | Public marketplace | Farmer↔farmer after acceptance | Verified company after acceptance | Admin |
|-------------|-------------------|--------------------------------|-----------------------------------|-------|
| Broad location (county, sub-county, area) | Yes | Yes | Yes | Yes |
| Exact pickup coordinates | No | Only the counterparty, only for the duration of the active order | Only when required for pickup coordination | Yes, authorized use only |
| Route history / cluster of pickup points | No | No | Aggregated for their own orders only | Yes |

Coordinates are **never** returned in list responses — only in detail
responses, and only to parties to the transaction.

---

## Storage rules

- Coordinates are stored as `(lat: double, lng: double)` with 6-decimal
  precision (≈ 11 cm).
- The datastore must support field-level access control so coordinates can
  be read by the API's authorization layer without leaking into generic
  object serialization.
- Audit-log entries record who read a coordinate and when. Every access to
  exact coordinates is logged (see NFR-08 in the design brief).

---

## API enforcement (server-side)

The API never relies on the client to withhold coordinates.

- `GET /listings/:id` returns coordinates only when the requester is a
  party to an accepted offer on that listing.
- `GET /orders/:id` returns exact pickup coordinates to the buyer and seller
  only. Admin access requires an explicit `reason` parameter and is audited.
- `GET /orders/:id/route` (company view) returns the ordered list of
  pickup points but **only** for orders the requesting company is party to.
- Webhook handlers and internal services never receive coordinates in
  payloads unless they need them for that specific operation.

Returning `null` for a coordinate the requester is not entitled to is
correct; returning a rounded coordinate is not — rounding still leaks
the farm's approximate location.

---

## Client behaviour

- The picker defaults to the **broad area** (county/sub-county) unless the
  user explicitly taps "Use my current location."
- Requesting GPS permission is deferred until the user taps that button.
  Never request permission on app launch.
- On permission denial, the flow falls back to the manual picker with no
  blocking error. The user should never be stuck because they declined
  a permission.
- The captured `LocationSource` is shown to the user ("Precise location"
  or "Approximate area") so they know what will be shared.

---

## What this document does not cover

- Legal compliance (Kenya Data Protection Act 2019, GDPR-equivalent
  transfers). Consult a qualified advisor.
- Aggregation / anonymization for analytics. If coordinates are used for
  aggregate reporting, they must be binned to at least sub-county level
  before storage.
- Reverse geocoding of coordinates to a street address — the platform
  uses the county/sub-county hierarchy only; it does not store street
  addresses.

---

## Change log

| Date | Change |
|------|--------|
| 2026-09-21 | Initial policy, aligned with Section 8.1 of the design brief and the frontend's LocationSource model. |
