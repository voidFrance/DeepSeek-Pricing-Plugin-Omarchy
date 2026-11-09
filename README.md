# DeepSeek Pricing

A status-bar widget for [Omarchy](https://omarchy.org) that answers one
question: **is DeepSeek cheap right now?**

The API bills in two tiers. Off-peak costs exactly half of peak, and peak is
01:00–04:00 and 06:00–10:00 UTC, Monday to Friday, excluding Chinese public
holidays. In São Paulo that lands at 22:00–01:00 and 03:00–07:00, which is
easy to get wrong by hand.

- The bar pill shows the DeepSeek mark and the active tier: `½` off-peak,
  `2×` at peak. While off-peak, a soft ring pulses around the logo.
- The tooltip carries the countdown to the next switch and the current
  input/output price per 1M tokens.
- Left click opens the panel: the local day with peak windows shaded, the
  current prices for both models, and a spend-now-or-wait hint.
- Right click opens the official price page.

## Install

```bash
omarchy plugin enable teteu.deepseek-pricing --section right --after omarchy.tray
```

Settings (bar settings UI or the `shell.json` entry): `showPro` and `animate`.

## Data

- Prices live in `Model.js` (`PRICING`). They are the official USD per 1M
  token rates, effective 2026-08-17:
  <https://api-docs.deepseek.com/quick_start/pricing>
- Peak windows are in UTC. Never compare a local hour against them: the
  plugin converts, and the local timeline is built from the UTC edges, so it
  stays correct in time zones with :30 offsets and DST.
- Chinese holidays are in `Model.js` (`HOLIDAYS`). Weekends are always
  off-peak, so only weekday dates need listing. A missing date makes the
  widget claim peak when it is actually off-peak — never the other way
  around, which is the safe direction.
- The State Council publishes one holiday calendar per year. Add the next
  year's dates as soon as they are announced and list the year in
  `COMPLETE_HOLIDAY_YEARS`. Until then the panel shows a warning saying peak
  is being assumed.

## Tests

`Model.js` is plain JavaScript with no Qt imports, so it runs in Node. It is
loaded through `vm` with `.pragma library` stripped.

```bash
node --test tests/
```

The suite covers the UTC boundaries, the weekend gap, the next-change scan,
a Chinese holiday, and the local-day segmentation (whole day, no gaps,
segment tiers matching their own midpoints).

## Notes

- The logo is the official mark, painted through its alpha with a
  `MultiEffect` mask so it follows the theme's foreground/accent colour.
- Motion uses `Style.duration()` and stops with Omarchy's animations toggle;
  the panel's one-second countdown only runs while it is open.
- No network access. Prices ship with the plugin; the panel footer names the
  date they took effect.
