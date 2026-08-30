# Map weather-overlay shading (lib/view/map.dart)

The three OpenWeatherMap raster overlays (clouds / wind / temperature) are
recoloured with `ColorFilter.matrix` so they display nuptial-flight
**suitability** rather than raw weather: BLUE-GREEN/teal = favourable,
RED = unfavourable, tinted per the daily model's partial-dependence (PD)
distribution (see `docs/model_training_findings.md` and the `_PdCurve`
gauges in `lib/controller/nuptials.dart`).

Rules of thumb encoded in the matrices — read before "fixing" the colours:

- Per-layer opacity is weighted by each feature's PD span
  (temp 1.00, wind 0.61, cloud 0.19).
- Temperature is bidirectional. The OWM temp palette has high red across
  yellow/orange/red, so the favourable-green gate is `R-G-B` (only *pure
  red* / hottest passes; yellow/orange/green/cyan reject), **not** `R-B`
  (which lit green almost everywhere). Cold maps to red via `B-R`.
- Favourable green/blue is deliberately DAMPED (`G=(R-G-B)/2`,
  `B=(R-G-B)/5`) because green reads ~3x brighter than red at equal alpha —
  keep it below the red channel or it dominates the map.
- Clouds render faint teal (overcast is weakly favourable); wind renders
  red only (calm has no signal to paint).
