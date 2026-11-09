.pragma library

// DeepSeek API peak/off-peak logic.
//
// Prices are the official ones (USD per 1M tokens). Off-peak costs exactly
// half of peak. Peak hours are 01:00-04:00 and 06:00-10:00 UTC, Monday to
// Friday, except Chinese public holidays.
//
// https://api-docs.deepseek.com/quick_start/pricing
//
// Keep this file free of Qt/QML imports: it is plain JavaScript so the same
// code runs in the shell and in `node --test`.

var PRICING = {
  effectiveFrom: "2026-08-17",
  source: "https://api-docs.deepseek.com/quick_start/pricing",
  // [off-peak, peak]
  models: [
    {
      id: "flash",
      name: "deepseek-flash",
      hit: [0.003, 0.006],
      miss: [0.15, 0.30],
      output: [0.60, 1.20]
    },
    {
      id: "pro",
      name: "deepseek-v4-pro",
      hit: [0.022, 0.044],
      miss: [0.66, 1.32],
      output: [1.98, 3.96]
    }
  ]
};

var TIER_OFF = "off";
var TIER_PEAK = "peak";

// [start, end) in UTC hours.
var PEAK_WINDOWS = [[1, 4], [6, 10]];

// Chinese public holidays on weekdays. Weekends are always off-peak, so only
// weekday dates need to be listed. The State Council publishes one calendar
// per year; add the next year as soon as it is announced. A missing date only
// makes the plugin claim peak when it is actually off-peak, never the reverse.
var HOLIDAYS = [
  "2027-01-01"
];

// Years the table above knows anything about, and the years whose calendar is
// complete. 2027 has only the fixed New Year date so far: the State Council
// has not published the rest. Keep both lists in step when it does.
var HOLIDAY_YEARS = [2027];
var COMPLETE_HOLIDAY_YEARS = [];

function pad2(value) {
  return value < 10 ? "0" + value : String(value);
}

// The holiday calendar is Chinese, so a date is looked up in Beijing time,
// not in UTC or in the user's local time.
function dateKey(ms) {
  var beijing = new Date(ms + 8 * 3600 * 1000);
  return beijing.getUTCFullYear() + "-" + pad2(beijing.getUTCMonth() + 1) + "-" + pad2(beijing.getUTCDate());
}

function isHoliday(ms) {
  var key = dateKey(ms);
  for (var i = 0; i < HOLIDAYS.length; i++) {
    if (HOLIDAYS[i] === key) return true;
  }
  return false;
}

function beijingYear(ms) {
  return new Date(ms + 8 * 3600 * 1000).getUTCFullYear();
}

function holidayCalendarKnown(ms) {
  return HOLIDAY_YEARS.indexOf(beijingYear(ms)) !== -1;
}

// True when the current Beijing year needs a calendar the plugin cannot
// vouch for. Years before the table starts are in the past, so there is
// nothing to warn about; a partial year (2027) does warn.
function holidayCalendarMissing(ms) {
  var year = beijingYear(ms);
  if (year < Math.min.apply(null, HOLIDAY_YEARS)) return false;
  return COMPLETE_HOLIDAY_YEARS.indexOf(year) === -1;
}

function isPeak(ms) {
  var day = new Date(ms);
  var weekday = day.getUTCDay();
  if (weekday === 0 || weekday === 6) return false;
  if (isHoliday(ms)) return false;

  var hour = day.getUTCHours();
  for (var i = 0; i < PEAK_WINDOWS.length; i++) {
    var window = PEAK_WINDOWS[i];
    if (hour >= window[0] && hour < window[1]) return true;
  }
  return false;
}

function tier(ms) {
  return isPeak(ms) ? TIER_PEAK : TIER_OFF;
}

// First instant after `ms` whose tier differs from the tier at `ms`, or 0.
// Scanning a few days of boundary instants is cheap and exact: the tier only
// ever changes on one of these UTC hours.
function nextChange(ms) {
  var current = tier(ms);
  var best = 0;
  var day = new Date(ms);

  for (var offset = -1; offset <= 4; offset++) {
    var probe = Date.UTC(day.getUTCFullYear(), day.getUTCMonth(), day.getUTCDate() + offset);
    for (var i = 0; i < PEAK_WINDOWS.length; i++) {
      for (var edge = 0; edge < 2; edge++) {
        var candidate = probe + PEAK_WINDOWS[i][edge] * 3600 * 1000;
        if (candidate <= ms) continue;
        if (tier(candidate) === current) continue;
        if (best === 0 || candidate < best) best = candidate;
      }
    }
  }
  return best;
}

// The local day split into tier segments, for the timeline. Boundaries come
// from the UTC edges, so this is exact in every time zone (including ones
// offset by :30 or with DST).
function localSegments(ms) {
  var now = new Date(ms);
  var start = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
  var end = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1).getTime();

  var bounds = [start, end];
  for (var offset = -1; offset <= 1; offset++) {
    var base = Date.UTC(now.getFullYear(), now.getMonth(), now.getDate() + offset);
    for (var i = 0; i < PEAK_WINDOWS.length; i++) {
      for (var edge = 0; edge < 2; edge++) {
        var candidate = base + PEAK_WINDOWS[i][edge] * 3600 * 1000;
        if (candidate > start && candidate < end) bounds.push(candidate);
      }
    }
  }

  bounds.sort(function(a, b) { return a - b; });

  var segments = [];
  for (var index = 0; index < bounds.length - 1; index++) {
    var from = bounds[index];
    var to = bounds[index + 1];
    if (to <= from) continue;
    var peak = isPeak(from + (to - from) / 2);
    var previous = segments.length > 0 ? segments[segments.length - 1] : null;
    if (previous && previous.peak === peak) previous.to = to;
    else segments.push({ from: from, to: to, peak: peak });
  }
  return segments;
}

function dayProgress(ms) {
  var now = new Date(ms);
  var start = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
  var end = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1).getTime();
  return Math.min(1, Math.max(0, (ms - start) / (end - start)));
}

function formatClock(ms) {
  var date = new Date(ms);
  return pad2(date.getHours()) + ":" + pad2(date.getMinutes());
}

function formatDuration(ms) {
  var minutes = Math.max(0, Math.ceil(ms / 60000));
  var hours = Math.floor(minutes / 60);
  if (hours <= 0) return minutes + "min";
  return hours + "h" + pad2(minutes % 60);
}

// 2026-08-17 reads as 17/08/2026 in the footer.
function formatIsoDate(iso) {
  var parts = String(iso).split("-");
  return parts.length === 3 ? parts[2] + "/" + parts[1] + "/" + parts[0] : String(iso);
}

// $0.003 needs three decimals; $1.20 reads better with two.
function formatUsd(value) {
  var decimals = value < 0.01 ? 3 : 2;
  return "$" + value.toFixed(decimals);
}

function price(modelId, kind, tierName) {
  var models = PRICING.models;
  for (var i = 0; i < models.length; i++) {
    if (models[i].id !== modelId) continue;
    var pair = models[i][kind];
    if (!pair) return 0;
    return tierName === TIER_PEAK ? pair[1] : pair[0];
  }
  return 0;
}

// 0 = interactive use is fine now; 1 = a batch is worth waiting for.
function waitingPayoff(ms) {
  var change = nextChange(ms);
  if (change === 0) return 0;
  return Math.ceil((change - ms) / 60000);
}
