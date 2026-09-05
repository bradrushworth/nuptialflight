# lib/responses/ — OpenWeatherMap JSON models

Hand-written response models. No code generation — edit the `fromJson`
directly.

| File | Covers |
|---|---|
| `onecall_response.dart` | One Call 4.0 timeline (`OneCallResponse`, `Current`, `Hourly`, `Daily`, `Temp`, `Rain`, …) |
| `weather_response.dart` | Current Weather 2.5 (used only for the place `name`) |
| `reverse_geocoding_response.dart` | Geocoding 1.0 reverse lookup |

## Parse defensively — the live API disagrees with its docs

This is the single most important thing about this folder. Every one of these
was a shipped bug:

| Reality | Handling |
|---|---|
| `/timeline/1day` **never** sends `dew_point` | estimated via `estimateDewPoint()` in `nuptials.dart` |
| `pop` absent on today/past daily records | defaults to `0` (matches training `fillna(0)`) |
| Int-typed fields (`pressure`, …) arrive as doubles | coerced through `_asInt` |
| Timeline pages come back short or empty | kind-aware parsing yields empty lists, never null-both |

`OneCallResponse.fromTimelineJson(json, TimelineKind)` is kind-aware so an
empty hourly page cannot be mistaken for an empty daily one.

**A new field must not become a hard requirement.** A `!` on a field the live
API omits crashes the app for every user in a region where that field is
missing. Default it, or estimate it, and say why in a comment.

## Pagination URLs are deliberately not modelled

The `next`/`prev` links embed the API key. Modelling them invites logging
them. Don't add them.

## Tests

`test/onecall_v4_parse_test.dart` covers the awkward shapes; `weather_test.dart`
covers the fetch paths. Add a fixture whenever you handle a new API quirk —
these are cheap tests that prevent expensive field reports.
