import unittest
import backfill_leadup as bl

class TestBackfill(unittest.TestCase):
    def test_precip(self):
        self.assertEqual(bl.precip(0.4), 0.4)
        self.assertEqual(bl.precip({"1h": 0.7}), 0.7)
        self.assertIsNone(bl.precip(None))
        self.assertIsNone(bl.precip("x"))

    def test_normalize_daily_record(self):
        raw = {"dt": 1700000000, "temp": {"day": 20.0}, "rain": {"1h": 0.42},
               "snow": 1.2, "wind_speed": 3.0}
        out = bl.normalize_daily_record(raw)
        self.assertEqual(out["rain"], 0.42)          # object -> bare number
        self.assertNotIn("snow", out)                # clamped to Dart key set
        self.assertEqual(out["wind_speed"], 3.0)

    def test_leadup_window_floors_midday_anchor(self):
        report_dt = 5 * 86400 + 13 * 3600            # 13:00 on day 5
        start, end = bl.leadup_window(report_dt, 2)
        self.assertEqual(end, 5 * 86400)             # report DAY floor
        self.assertEqual(start, 3 * 86400)           # D-2

    def test_filter_leadup_excludes_report_day(self):
        end = 5 * 86400
        recs = [{"dt": 3 * 86400}, {"dt": 4 * 86400}, {"dt": 5 * 86400}, {"dt": None}]
        kept = bl.filter_leadup(recs, end)
        self.assertEqual([r["dt"] for r in kept], [3 * 86400, 4 * 86400])

    def test_build_leadup_doc_is_keyed_and_marked(self):
        row = {"key": "abc123", "flight": "yes", "size": "small", "version": "1",
               "device_id": "d", "install_id": "i", "lat": -35.0, "lon": 149.0,
               "forecast": {"daily": []}}
        doc = bl.build_leadup_doc(row, [{"dt": 1, "temp": {"day": 1.0}}], 2)
        self.assertEqual(doc["_key"], "abc123")      # idempotent rerun (#25)
        self.assertEqual(doc["source"], "backfill")
        self.assertNotIn("current", doc["weather"])  # never-existed field (#27)
        self.assertEqual(doc["lead_up_days"], 2)

    def test_default_rps_matches_subscription_limit(self):
        self.assertLessEqual(bl.DEFAULT_RPS, 1.0)    # 60/min (#26)

if __name__ == "__main__":
    unittest.main()
