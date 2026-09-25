Geo-coordinate handling and privacy

- Precise coordinates (latitude/longitude) are treated as sensitive location data.
- The app stores `GeoLocation` objects with a `source` field indicating how the
  coordinates were obtained: `selfReported`, `deviceCaptured`, or `adminVerified`.
- UI and public views must only show the `broadLocation` (`area, subCounty`) by
  default. Precise coordinates must NOT be displayed or exported unless the user
  has explicitly accepted sharing for the current transaction (reveal-on-acceptance).
- Admin and logistics flows may access coordinates for routing, assignment and
  delivery calculation, but must respect the same reveal rule when showing
  details to parties not yet authorized.
- Developers: when passing locations from screens to services, prefer populating
  `GeoLocation` with `lat`/`lng` only when the device captured them or the user
  explicitly provided them. Use `broadLocation` for UI lists and summaries.

See `lib/data/models/geo_location.dart` for the data model and `lib/features/*`
for where to enforce reveal-on-acceptance behavior.
