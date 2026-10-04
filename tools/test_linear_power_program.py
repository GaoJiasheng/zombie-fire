#!/usr/bin/env python3
"""Offline regression tests for T1/T2/T3; no Godot and no data mutation."""
from __future__ import annotations

import copy
import contextlib
import io
import json
import math
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest import mock

import audit_campaign_frontline as campaign
import audit_progression_linearity as linear
import progression_closure as closure
import solve_runtime_clear_lines as solver
import run_frontline_sweep as sweep


class LinearProgramTests(unittest.TestCase):
    def test_direction_a_g1_bounds(self):
        def level(n, boss=False):
            return {"id": f"level_{n:03d}", "clear_requirement": {"power_contract": {"recommended_power": 50}}, "waves": [{"wave": 1, **({"boss": "boss_tank_titan"} if boss else {})}]}
        self.assertEqual(closure.g1_bounds(level(1), True, 65), (.95, 1.43))
        self.assertEqual(closure.g1_bounds(level(7), True, 76), (1, 1.6720000000000002))
        self.assertEqual(closure.g1_bounds(level(5, True), True, 50), (1, 1.1))
        self.assertEqual(closure.g1_bounds(level(1), False), (.95, 1.1))
        with self.assertRaises(ValueError):
            closure.g1_bounds(level(1), True)

    def test_concurrency_trial_requires_explicit_opt_in(self):
        for arguments in (["--jobs", "8"], ["--jobs", "9", "--allow-concurrency-trial"]):
            with mock.patch.object(solver.sys, "argv", ["solver", *arguments]), contextlib.redirect_stderr(io.StringIO()):
                with self.assertRaises(SystemExit) as raised:
                    solver.main()
                self.assertEqual(raised.exception.code, 2)

    def exercise_solver(self, threshold, interrupt_after=None, resume=False, wall_extension=False):
        """Fake probe runner checks the real binary-search/checkpoint path."""
        with tempfile.TemporaryDirectory(prefix="zf_linear_solver_test_") as folder:
            root = Path(folder)
            row = {"level": 1, "level_id": "level_001", "build": {"weapon_level": 100}}
            tables = {"levels": [{"id": "level_001", "clear_requirement": {"power_contract": {"recommended_power": 100}}}]}
            if wall_extension:
                for identity, table in (("character", "characters"), ("weapon", "weapons"), ("armor", "armors"), ("chip", "chips"), ("pet", "pets")):
                    row["build"][identity] = identity
                    tables[table] = {identity: {"max_level": 180}}
                tables.update(economy={"sig_skill_xp_costs": [1] * 5}, skills={})
            state = {"level": 1, "steps": []}
            payload = {"rows": [state], "combat_input_fingerprint": {"test": "fixture"}}
            options = SimpleNamespace(evidence_dir=root / "evidence", jobs=6, wall_extension=wall_extension)
            calls = []
            def run(command, **kwargs):
                if interrupt_after is not None and len(calls) == interrupt_after:
                    raise RuntimeError("injected interruption")
                fixture = root / command[command.index("--fixture") + 1].removeprefix("res://")
                build = json.loads(fixture.read_text())["rows"][0]["build"]
                calls.append(build)
                success = build["weapon_level"] >= threshold
                raw = {"combat_input_fingerprint": payload["combat_input_fingerprint"], "profile": "tier_b", "card_policy": "v2", "simulation_step_seconds": 1 / 60,
                       "runs": [{"level": 1, "seed": seed, "build": build, "victory": success, "base_ratio": int(success), "elapsed_seconds": 100} for seed in solver.SEEDS]}
                Path(command[command.index("--output") + 1]).write_text(json.dumps(raw))
                logs = Path(command[command.index("--log-dir") + 1])
                logs.mkdir(parents=True)
                for seed in solver.SEEDS:
                    (logs / f"{seed}.log").write_text("Godot fake offline evidence\n")
                return __import__("subprocess").CompletedProcess(command, 0)
            with mock.patch.object(solver, "ROOT", root), mock.patch.object(solver, "power", side_effect=lambda _l, b, _t: {"power": b["weapon_level"]}), mock.patch.object(solver.subprocess, "run", side_effect=run):
                if interrupt_after is not None:
                    with self.assertRaisesRegex(RuntimeError, "injected interruption"):
                        solver.solve_level(row, state, payload, options, tables, root / "checkpoint.json")
                    cached = len(state["steps"])
                    self.assertEqual(cached, interrupt_after)
                    self.assertFalse(list(root.glob("design/audits/_tmp*.json")))
                    if resume:
                        # Resume must keep valid steps, not rerun endpoint evidence.
                        interrupt_after = None
                        solver.solve_level(row, state, payload, options, tables, root / "checkpoint.json")
                        self.assertEqual(sum(b["weapon_level"] == 100 for b in calls), 1)
                else:
                    solver.solve_level(row, state, payload, options, tables, root / "checkpoint.json")
                self.assertFalse(list(root.glob("design/audits/_tmp*.json")))
                return state, calls

    def test_solver_binary_search_and_resume(self):
        state, calls = self.exercise_solver(80, interrupt_after=3, resume=True)
        self.assertEqual(state["status"], "complete")
        self.assertLessEqual(state["bracket"][1] - state["bracket"][0], .02 + 1e-12)
        self.assertGreaterEqual(state["p_star"], 80)
        self.assertEqual(len({b["weapon_level"] for b in calls}), len(calls))

    def test_solver_censored_bounds_are_not_P_star(self):
        for threshold, expected in ((101, "upper_bound_fails"), (20, "lower_bound_passes")):
            state, _ = self.exercise_solver(threshold)
            self.assertEqual(state["status"], expected)
            self.assertIsNone(state["p_star"])
            self.assertIsNone(state["r_star"])

    def test_scaling_minima_and_immutability(self):
        build = {key: 1 for key in solver.LEVEL_FIELDS}
        build.update(character="vanguard", weapon="weapon_autocannon", signature_level=1,
                     skill_base_levels={"skill_multishot": 5, "skill_homing": 1})
        original = copy.deepcopy(build)
        scaled = solver.scaled_build(build, .3)
        self.assertTrue(all(scaled[key] == 1 for key in solver.LEVEL_FIELDS))
        self.assertEqual(scaled["signature_level"], 0)
        self.assertEqual(scaled["skill_base_levels"], {"skill_multishot": 2, "skill_homing": 0})
        self.assertEqual(build, original)

    def test_wall_extension_resume_and_upper_censor(self):
        state, calls = self.exercise_solver(145, interrupt_after=2, resume=True, wall_extension=True)
        self.assertEqual(state["status"], "complete")
        self.assertEqual(state["extension_method"]["scale_bounds"], [1.0, 1.8])
        self.assertEqual(sum(b["weapon_level"] == 180 for b in calls), 1)
        self.assertTrue(all(100 <= b["weapon_level"] <= 180 for b in calls))
        state, _ = self.exercise_solver(181, wall_extension=True)
        self.assertEqual(state["status"], "upper_bound_fails")
        self.assertIsNone(state["p_star"])
        self.assertEqual(state["steps"][0]["scale"], 1.8)

    def test_real_catalog_caps_and_golden_law_65(self):
        tables = solver.load_tables()
        fixture = json.loads(solver.FIXTURE.read_text())
        for row in fixture["rows"]:
            for scale in (1.0, 1.8):
                build = solver.scaled_build(row["build"], scale, tables)
                for field, table, identity in (("character_level", "characters", "character"), ("weapon_level", "weapons", "weapon"), ("armor_level", "armors", "armor"), ("chip_level", "chips", "chip"), ("pet_level", "pets", "pet")):
                    if build.get(identity):
                        self.assertLessEqual(build[field], tables[table][build[identity]]["max_level"])
                    else:
                        self.assertEqual(build[field], 1)
                self.assertLessEqual(build["signature_level"], 5)
                self.assertTrue(all(v <= solver.ruler.skill_max_level(tables["skills"][k]) for k, v in build["skill_base_levels"].items()))
                if scale == 1.0:
                    self.assertEqual(build, solver.scaled_build(row["build"], scale))
        golden = next(key for key, value in tables["weapons"].items() if value["max_level"] == 65)
        build = dict(fixture["rows"][-1]["build"], weapon=golden, weapon_level=65)
        self.assertEqual(solver.scaled_build(build, 1.8, tables)["weapon_level"], 65)

    def test_wall_extension_is_guarded(self):
        for arguments in (["--wall-extension", "--levels", "15"], ["--wall-extension", "--resume", "--levels", "5"], ["--wall-extension", "--resume", "--levels", "15", "--jobs", "8", "--allow-concurrency-trial"]):
            with mock.patch.object(solver.sys, "argv", ["solver", *arguments]), contextlib.redirect_stderr(io.StringIO()):
                with self.assertRaises(SystemExit) as raised:
                    solver.main()
                self.assertEqual(raised.exception.code, 2)

    def test_bracket_non_monotonic_rejected(self):
        lo, hi = solver.derive_bracket([{"scale": .3, "wins": 0, "R": .4}, {"scale": 1, "wins": 9, "R": 1.1}])
        self.assertEqual((lo["R"], hi["R"]), (.4, 1.1))
        with self.assertRaises(RuntimeError):
            solver.derive_bracket([{"scale": .4, "wins": 9, "R": .5}, {"scale": .5, "wins": 8, "R": .6}])
        with self.assertRaises(RuntimeError):
            solver.derive_bracket([{"scale": .3, "wins": 0, "R": 1.2}, {"scale": 1, "wins": 9, "R": 1.1}])

    def test_runtime_evidence_rejects_timeout_wrong_build_seed_profile(self):
        payload = {"profile": "tier_b", "card_policy": "v2", "simulation_step_seconds": 1 / 60,
                   "runs": [{"level": 5, "seed": seed, "build": {"weapon_level": 1}, "victory": True,
                             "base_ratio": 1, "elapsed_seconds": 100} for seed in solver.SEEDS]}
        self.assertEqual(len(solver.validate_runs(payload, 5, {"weapon_level": 1})), 10)
        for mutation in ("timeout", "build", "seed", "profile", "nan"):
            broken = copy.deepcopy(payload)
            if mutation == "profile":
                broken["profile"] = "control"
            elif mutation == "timeout":
                broken["runs"][0]["timeout"] = True
            elif mutation == "build":
                broken["runs"][0]["build"] = {"weapon_level": 2}
            elif mutation == "nan":
                broken["runs"][0]["base_ratio"] = float("nan")
            else:
                broken["runs"][0]["seed"] = 2207
            with self.assertRaises(RuntimeError):
                solver.validate_runs(broken, 5, {"weapon_level": 1})

    def test_atomic_checkpoint(self):
        with tempfile.TemporaryDirectory(prefix="zf_linear_test_") as folder:
            path = Path(folder) / "checkpoint.json"
            solver.atomic_write(path, {"rows": [{"level": 1, "status": "complete"}]})
            self.assertEqual(json.loads(path.read_text())["rows"][0]["status"], "complete")
            self.assertFalse(path.with_suffix(".json.pending").exists())

    def test_sweep_preserves_script_error_and_raises_even_exit_zero(self):
        with tempfile.TemporaryDirectory(prefix="zf_linear_test_") as folder:
            root = Path(folder)
            completed = __import__("subprocess").CompletedProcess([], 0, "SCRIPT ERROR: injected")
            with mock.patch.object(sweep.subprocess, "run", return_value=completed):
                with self.assertRaisesRegex(RuntimeError, "SCRIPT ERROR"):
                    sweep.run_batch(5, [1103], "tier_b", "v2", 60, False, False, False, False,
                                    360, root, root, "res://fixture.json", root / "logs")
            self.assertIn("SCRIPT ERROR", next((root / "logs").glob("*.log")).read_text())

    def test_statistics_and_isotonic_predictions(self):
        self.assertAlmostEqual(linear.geometric_slope([(n, 10 * 1.047 ** n) for n in range(10)]), .047)
        self.assertAlmostEqual(linear.pearson([(1, 10), (2, 20), (3, 30)]), 1)
        self.assertIsNone(linear.pearson([(1, 10), (1, 20), (1, 30)]))
        fit = linear.isotonic_fit([(.8, 5), (.9, 4), (1, 9), (1.2, 10)])
        self.assertEqual(fit[0]["rate"], .45)
        self.assertEqual(fit[1]["rate"], .45)
        self.assertTrue(linear.predict(fit, 1)["supported"])
        self.assertEqual(linear.predict(fit, 1)["deviation_wins"], 0)
        self.assertFalse(linear.predict(linear.isotonic_fit([(1, 9)]), .85)["supported"])

    def test_support_is_only_counted_on_boss_waves(self):
        wave = {"spawns": [{"type": "a"}], "support": [{"type": "b"}]}
        self.assertEqual(len(closure.runtime_groups(wave)), 1)
        self.assertEqual(len(closure.runtime_groups({**wave, "boss": "boss_x"})), 2)

    def test_repeat_rewards_do_not_remint_stars_or_bonus(self):
        level = campaign.TABLES["levels"][29]
        first = closure.rewards(level)
        repeat = closure.rewards(level, first_clear=False)
        self.assertEqual(first["stars"], 3)
        self.assertEqual(repeat["stars"], 0)
        self.assertEqual(first["gold"] - repeat["gold"], level["first_clear_reward"]["gold"])
        self.assertEqual(first["xp"], repeat["xp"])

    def test_closure_accounting_and_frozen_inputs(self):
        before = solver.input_hashes()
        payload = closure.generate()
        self.assertEqual([row["level"] for row in payload["rows"]], list(range(1, 100)))
        self.assertEqual(payload["rows"][0]["cumulative_earned_before"], {"gold": 0, "xp": 0, "stars": 0})
        for previous, current in zip(payload["rows"], payload["rows"][1:]):
            after = previous["progression_after_clear"]["resources_after"]
            if current['farming']['events']:
                after = current['farming']['events'][-1]['resources_after']
            self.assertEqual(after, current["account_before"])
            income = previous["progression_after_clear"]["income"]
            farm_gold = sum(e['income']['gold'] for e in current['farming']['events'])
            self.assertEqual(current["cumulative_earned_before"]["gold"], previous["cumulative_earned_before"]["gold"] + income["gold"] + farm_gold)
            self.assertEqual(current["cumulative_earned_before"]["stars"], (current["level"] - 1) * 3)
        self.assertTrue(all(row["build"]["weapon_level"] <= 50 for row in payload["rows"]))
        self.assertEqual(before, solver.input_hashes())

    def test_legacy_fixture_not_regenerated_by_closure(self):
        expected = campaign.BUILD_REPORT.read_bytes()
        closure.generate()
        self.assertEqual(campaign.BUILD_REPORT.read_bytes(), expected)


if __name__ == "__main__":
    unittest.main(verbosity=2)
