# 方向 A 推荐值 + 留一张翻卡 · 99×10 对账(2026-10-05)

**Owner 决议链**:翻卡定稿 `pre_final_wave_hold_last`(T−1 张波 5 前、1 张波 5 内);推荐值按真实通关线反解(方向 A,表 B = clamp(√(model·P*), [P*, 1.35P*]));资源维持现状;墙关为门(020/076/095 等);挑战曲线 61–99 重解。全部记录在 design/41 §7–§9.1。
**运行输入指纹(5 段)**:`levels=2669c4acdca69fbf weapons=bdd10432c49bebed economy=b7788ff467fa3024 fixture=bc313dff5d8b033d enemies=4055b2260e4ac7b9`(economy 段因翻卡开关 hold_last 变化;`clear_requirement` 不入指纹)。
**归档**:`b2c_main_runtime_solved_001_099_ten_seed_2026_10_04.json`(Codex 分支实跑,990 局,0 超时);旧表存 `b2b_star_table_pre_runtime_solved_2026_10_05.csv`。

## 结果(免费首通夹具,10 种子)
- 胜 **961/990**(此前 pre_final_wave 节奏 977/990)。<9/10 的关全是门/墙:015/017/018/019/020/040/044/076。
- 星级 96×3★/3×2★ → **94×3★/5×2★(292★)**;变化仅 **019 3→2(6/10)、025 3→2(10/10,基地中位 52%)**,是最后一张卡留到波 5 的直接后果。Owner 2026-10-05 签字(D-1)。
- 推荐值真实性:G3 硬合同 R=1.00 → 10 个抽样关全部 ≥9/10(94/100);R=0.85/1.15 为信息项(悬崖区)。
- 终局:099 普通免费满级 10/10;099 挑战免费满级 0/10、黄金律满级 9/10;挑战章节代表点 ch1–6 ≥29/30、ch7 27、ch8 20、ch9 27、ch10 26(带 60–90%);付费门 076 炼狱套 9/10、095 黄金律套 10/10。

## 门禁更新
- `b2b_star_table_old_to_new.csv` 已替换;`report_b2b_star_table.py --check-approved` 通过。
- `data/challenges.json.curve` 61–99 重解(K 锚点至 8.0,逐关压力指数),`check_challenge_curve_runtime.py` 通过;前 60 关不变。
