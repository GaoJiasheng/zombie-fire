# VFX 批次 B3 — 枪口闪光全套(给 Codex)

先读 `design/vfx_overhaul_brief.md` 与 `gameplay/vfx/vfx_lib.gd`(复用 B1/B2 的 VfxLib、glow 着色器、加法混合)。本次**只做 B3**。

## 目标
把**所有枪口/开火瞬间**特效做成大厂级、且**元素可辨**。B1 已把 `_spawn_muzzle_flash` 改成发光核+火星;B3 把整套枪口相关 VFX 补齐并元素化。

## 涉及函数(gameplay/battle/battle.gd,只改视觉)
- `_spawn_muzzle_flash`(在 B1 基础上强化:加短促光锥 + 烟)
- `_spawn_weapon_muzzle_profile_vfx`(按武器 profile:autocannon/rail/scatter/plasma 等差异化)
- `_spawn_short_muzzle_spark`
- `_spawn_salvo_fan_vfx`(多重射击扇形开火)

## 元素识别(必须一眼能分)
- physical=明黄曳光+金属火星;fire=橙红爆焰+热浪扭曲(可用 glow 着色器)+余烬;ice=青蓝寒气喷发+霜晶碎片;lightning=白蓝爆闪+分叉电火花;poison=毒绿喷雾+气泡。

## 技术(硬性)
用 VfxLib 的 `spawn_glow/spawn_burst/spawn_particles` + 加法混合 + WorldEnvironment glow + `Tween` 缓动。**禁止**用 PIL 画平面几何。可复用/扩展 `vfx_glow_core.gdshader` 或新增着色器(放 `gameplay/vfx/shaders/`)。

## 硬约束(违反=打回)
- 只改视觉;不动开火时机/伤害/命中/数值/`data/*.json`。
- 不碰形象 PNG;不改渲染方向(aspect 仍 `expand`)。
- 保留 `res://` 引用/ID/命名规范;粒子数量与存活设上限,受 `_can_spawn_projectile_fx` 门控。

## 自测(贴输出)+ 不要 commit
```bash
godot --headless --import
godot --headless --script tools/m1_smoke_test.gd    # "M1 smoke test passed"
python3 tools/validate_data.py && python3 tools/check_res_refs.py
```
报告见 brief §6,含 §5 逐条自检。
