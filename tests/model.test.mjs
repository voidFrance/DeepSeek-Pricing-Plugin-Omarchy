import { test } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import vm from "node:vm";
import path from "node:path";
import { fileURLToPath } from "node:url";

process.env.TZ = "America/Sao_Paulo";

const directory = path.dirname(fileURLToPath(import.meta.url));
const source = fs
  .readFileSync(path.join(directory, "..", "Model.js"), "utf8")
  .replace(/^\.pragma library\s*$/m, "");

const context = vm.createContext({ Date, Math, String, Number });
vm.runInContext(source, context);
const Model = context;

const utc = (value) => Date.parse(value + "Z");

test("UTC boundaries flip exactly on the hour", () => {
  assert.equal(Model.isPeak(utc("2026-11-05T00:59:00")), false);
  assert.equal(Model.isPeak(utc("2026-11-05T01:00:00")), true);
  assert.equal(Model.isPeak(utc("2026-11-05T03:59:00")), true);
  assert.equal(Model.isPeak(utc("2026-11-05T04:00:00")), false);
  assert.equal(Model.isPeak(utc("2026-11-05T05:59:00")), false);
  assert.equal(Model.isPeak(utc("2026-11-05T06:00:00")), true);
  assert.equal(Model.isPeak(utc("2026-11-05T09:59:00")), true);
  assert.equal(Model.isPeak(utc("2026-11-05T10:00:00")), false);
});

test("weekends are off-peak", () => {
  assert.equal(Model.isPeak(utc("2026-11-07T02:00:00")), false);
  assert.equal(Model.isPeak(utc("2026-11-08T09:00:00")), false);
});

test("next change crosses the night and the weekend", () => {
  assert.equal(Model.nextChange(utc("2026-11-05T02:00:00")), utc("2026-11-05T04:00:00"));
  assert.equal(Model.nextChange(utc("2026-11-05T04:00:00")), utc("2026-11-05T06:00:00"));
  assert.equal(Model.nextChange(utc("2026-11-06T10:00:00")), utc("2026-11-09T01:00:00"));
  assert.equal(Model.nextChange(utc("2026-11-07T12:00:00")), utc("2026-11-09T01:00:00"));
});

test("Chinese public holidays suppress peak on weekdays", () => {
  // 2027-01-01 is a Friday.
  assert.equal(Model.isPeak(utc("2027-01-01T02:00:00")), false);
  assert.equal(Model.isPeak(utc("2026-12-31T02:00:00")), true);
  assert.equal(Model.holidayCalendarKnown(utc("2026-06-01T00:00:00")), false);
  assert.equal(Model.holidayCalendarKnown(utc("2027-06-01T00:00:00")), true);
  // 2026 is behind the table: no warning. 2027 is partial: warn.
  assert.equal(Model.holidayCalendarMissing(utc("2026-11-05T00:00:00")), false);
  assert.equal(Model.holidayCalendarMissing(utc("2027-06-01T00:00:00")), true);
});

test("local timeline covers the whole day and matches the tier", () => {
  const segments = Model.localSegments(utc("2026-11-04T15:00:00"));
  assert.ok(segments.length >= 3);

  const first = segments[0];
  const last = segments[segments.length - 1];
  assert.equal(first.from, new Date(2026, 10, 4, 0, 0, 0).getTime());
  assert.equal(last.to, new Date(2026, 10, 5, 0, 0, 0).getTime());
  assert.equal(first.peak, true);
  assert.equal(last.peak, true);
  assert.equal(Model.isPeak(first.from + 1000), true);

  let total = 0;
  for (const segment of segments) {
    assert.ok(segment.to > segment.from);
    assert.equal(Model.isPeak(segment.from + 1000), segment.peak);
    total += segment.to - segment.from;
  }
  assert.equal(total, 24 * 3600 * 1000);
});

test("formatters and prices", () => {
  assert.equal(Model.formatDuration(90 * 60000), "1h30");
  assert.equal(Model.formatDuration(4 * 60000), "4min");
  assert.equal(Model.formatUsd(0.003), "$0.003");
  assert.equal(Model.formatUsd(1.2), "$1.20");
  assert.equal(Model.price("flash", "output", "off"), 0.60);
  assert.equal(Model.price("flash", "output", "peak"), 1.20);
  assert.equal(Model.price("pro", "miss", "peak"), 1.32);
});
