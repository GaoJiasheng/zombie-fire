# VFX 批次 B1 — 光感地基(给 Codex 的作业单)

先读 `design/vfx_overhaul_brief.md`(权威说明 + 验收标准)。本次**只做 B1**,不要碰 B2–B7。

## 交付物

1. **WorldEnvironment + Glow(bloom)**:给 `gameplay/battle/battle.tscn` 加一个 `WorldEnvironment` 节点,`Environment` 开启 Glow 并调好——
   - `glow_enabled = true`,开若干 `glow_levels/*`,`glow_intensity`、`glow_bloom`、`glow_hdr_threshold ≈ 1.0`,`glow_blend_mode = Additive`(或 Screen)。
   - 目标:高亮特效自然发光、明亮但不过曝。这是后续所有特效的光感底座。

2. **可复用 VFX 库** `gameplay/vfx/vfx_lib.gd`(静态函数,至少):
   - `spawn_glow(parent, pos, color, size, duration) -> Node` — 加法发光精灵(亮核+柔光晕),`Tween` EASE_OUT 淡出。
   - `spawn_burst(parent, pos, color, amount, speed, spread_deg, lifetime) -> Node` — `GPUParticles2D` 一次性火星爆发,`ParticleProcessMaterial`(发射角度/初速/重力/缩放曲线/颜色渐变),加法混合。
   - `spawn_trail(target, color, width) -> Node` — 跟随目标的渐隐拖尾(`Line2D` 或 trail 粒子)。
   - `screen_shake(intensity, duration)` — 轻微镜头/HUD 抖动(复用现有 hit_stop 手感)。
   - 所有视觉层用 `CanvasItemMaterial` ADD 混合,依赖上面的 Environment glow。

3. **输入贴图**(放 `assets/production/sprites/vfx/`):柔和 radial glow、streak、spark 各一张小图。**这些只是喂给粒子/着色器的输入,不是最终平面特效**(此处允许 PIL 生成 radial/noise)。

4. **验证样板(只改这一个)**:把 `vfx_lib` 接进 `gameplay/battle/battle.gd` 的 **`_spawn_muzzle_flash`**,让枪口闪光变成"发光 + 火星爆发粒子"。**其它特效一律不动**(留给 B2+)。给我一个能对比"旧平面 vs 新粒子发光"的样板。

## 硬约束(违反任一 = 打回)

- **只加视觉表现层**;**不许改**玩法逻辑、命中/伤害代码、`data/*.json` 数值。
- **不许碰**角色/僵尸/Boss/武器的形象 PNG。
- **不许改**渲染方向:保持 `stretch=canvas_items`、`aspect=expand`、`orientation=1`、ETC2 ASTC 开。**绝不把 aspect 改回 keep。**
- **不许**用 PIL 画平面几何特效;用 Godot 粒子/着色器/glow。PIL 只用于第 3 点的小输入贴图。
- 保留所有 `res://` 引用、ID、文件名、`design/data/naming_convention.md` 规范。
- 性能:粒子数量与存活时间设上限。

## 完成前必须自测通过(贴命令输出)

```bash
godot --headless --import                                  # 无脚本错误
godot --headless --script tools/m1_smoke_test.gd           # 打印 "M1 smoke test passed"
python3 tools/validate_data.py
python3 tools/check_res_refs.py
```

## 报告格式(见 brief §6)+ **不要 commit**,改动留给 Claude 验收。
