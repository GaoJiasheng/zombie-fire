# VFX 批次 B2 — 子弹/投射物(给 Codex 的作业单)

先读 `design/vfx_overhaul_brief.md`(权威说明+验收标准)与 `gameplay/vfx/vfx_lib.gd`(B1 已建的库,直接复用)。本次**只做 B2**。

## 目标
把投射物从"PIL 平面箭头/矩形"升级为**发光能量弹**:亮核 + 加法光晕 + 元素化拖尾(+ 飞行中细粒子)。复用 B1 的 `VfxLib` 与 WorldEnvironment glow。

## 交付物(改 `gameplay/projectile/projectile.gd` 的视觉层)
1. **发光核 + 光晕**:每颗子弹 = 明亮核心 + 柔和加法光晕(用 `vfx_input_radial_glow` 输入 + BLEND_MODE_ADD),依赖 bloom 自然发光。可保留原 `Sprite` 作为核心但改成加法发光,叠一层光晕。
2. **元素化拖尾**:飞行时用 `VfxLib.spawn_trail` 或 trail 粒子,颜色/形态按元素:
   - fire=橙红余烬拖尾;ice=青蓝结晶碎屑;lightning=白蓝电弧闪烁;poison=毒绿气泡滴落;physical=明黄曳光。
3. **profile 差异化**保留并强化:`rail`=细长高速曳光(长拖尾);`scatter`=多颗小光点;`plasma`=大能量球+强光晕;`split`=小型分裂弹。
4. 飞行中可发少量细粒子(火星/碎屑),数量设上限,受 `_can_spawn_projectile_fx` 预算门控。

## 硬约束(违反任一=打回)
- **只改视觉**:不动 `setup()` 的碰撞体 `CollisionShape2D.radius`、`velocity`、伤害/穿透/命中判定逻辑。视觉缩放可调,但**碰撞与玩法数值不变**。
- 不碰形象 PNG;不改渲染方向(aspect 仍 `expand`);不改 `data/*.json`。
- 不用 PIL 画平面几何当特效;用 B1 的 VfxLib + 加法 + glow + 粒子。
- 保留所有 `res://` 引用/ID/命名规范。性能:粒子上限、对象及时释放。

## 完成前自测(贴输出)
```bash
godot --headless --import
godot --headless --script tools/m1_smoke_test.gd     # 需 "M1 smoke test passed"
python3 tools/validate_data.py && python3 tools/check_res_refs.py
```

## 报告格式见 brief §6 + **不要 commit**,留给 Claude 验收。
