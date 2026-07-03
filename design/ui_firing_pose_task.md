# UI 任务书 — 角色开火姿态重做 + UI 一致性收尾(给 Codex)

先读 `AGENTS.md`(黄金规则)。本任务书分两部分：**§1 主任务(角色开火姿态)是重点**，**§2 是次要收尾**。
只做视觉/姿态/UI 层面的事；**不要碰**任何数值/平衡/关卡/技能逻辑/存档逻辑 —— 那些由项目 owner 自己处理，不在本任务范围内。

---

## §1 主任务：角色开火姿态重做

### 问题（已用截图核实，不是猜测）

当前 `assets/production/sprites/animations/character_weapon_combos/<char>/<char>_weapon_<weapon>_attack_NN.png`
这批帧，4 个角色 × 8 把武器抽查下来**全部是同一个问题**：

- **单手端枪**，另一只手是一个**闲置的攥拳**，什么都没做，物理上不合理（尤其是机炮/轨道炮/等离子炮这种重型武器，单手端着显得假）。
- **站姿呆板**——双脚基本并拢站立，没有战斗蓄力感，没有承受后坐力的重心前倾。
- 武器和握持手的位置有时对不上，像是"贴"上去的。

上一轮改动（commit a2ff79c / 88a0368）**渲染质感确实提升了**（材质、光影、修了个别帧武器闪烁/透明的 bug），但**没有触碰姿态本身**——所有帧的核心姿态问题原样保留。这次要专门解决姿态，不是继续打磨渲染质感。

### 目标姿态规范（两手握持 + 战斗蓄力站姿）

统一视角：3/4 顶视**背视角**（角色背对镜头、面朝上方战场，和现有 idle/walk 帧一致的机位）。

- **双手都在握枪**：前手（离身体较远那只）扶在护木/枪管护罩上，肘部弯曲约 100-120°，前臂明显承重；后手握在扳机握把/枪托附近、贴近髋部/肋侧，肘部向后收，像是在扛后坐力。
- 武器斜跨身体前方，枪管越过肩线向前/向上延伸——**不能悬空、不能像端手枪一样单手伸直**。
- **宽而稳的战斗站位**：双脚间距明显大于肩宽，前脚朝瞄准方向略微靠前，重心低、扎实——**不能双脚并拢、立正站姿**。
- 躯干略向武器方向前倾，肩膀转向开火方向，要有明显的"扛后坐力"的肌肉张力感。
- 这是**开火瞬间**（peak fire）的姿态：武器完全托住、前倾到位。
- **不要在角色素材里画任何枪口火光/烟雾/曳光弹/爆炸**——这些由游戏引擎单独生成叠加（`VfxLib` / `_spawn_muzzle_flash`），画在角色图里会和引擎特效重复/错位。角色图只画角色和武器本体。
- 武器和双手的握持点要解剖学对齐，不能有缝隙、不能像贴图一样浮在手上。

### 7 帧序列的动作弧线（attack_01~07，以及 attack_left/attack_right 变体）

- 1-2 帧：微收蓄力，武器向开火位收拢，手臂开始绷紧。
- 3-5 帧：动作顶点，武器完全托住托稳，前倾最大（这是开火中段，仍然**不画火光/烟雾**）。
- 6-7 帧：后坐回落，手臂放松回到接近第 1 帧的姿态，方便循环播放。
- 全程角色比例、盔甲配色、轮廓保持逐帧一致，只有关节角度在变。

### 分阶段执行（避免像上次 VFX 一样返工一整批才发现问题）

1. **先只做 2 组验证**：`char_vanguard + weapon_autocannon`、`char_blaze + weapon_flamethrower`（各出 attack_04 这张顶点帧即可，不用先出全套 7 帧）。
2. 我（Claude）会直接检查这 2 张实际文件（不是参考图/contact sheet），确认姿态问题真正解决了，再决定是否放行铺开到剩余 4 角色 × 8 武器 × 21 帧（attack + attack_left + attack_right）全套。
3. **不要**跳过第 1 步直接批量重做全部素材。

### 硬约束（违反 = 打回重做）

- 只改角色开火姿态相关的帧图 + 必要的 `CHARACTER_WEAPON_COMBO_MUZZLE` / `CHARACTER_WEAPON_COMBO_MUZZLE_LEFT` / `CHARACTER_WEAPON_COMBO_MUZZLE_RIGHT` 等枪口坐标常量（因为握持姿势变了，枪口位置要跟着重新校准，这个可以改）。
- **不碰**任何战斗数值/伤害/技能逻辑/`data/*.json` 里的数值字段。
- **不改**角色种族设定/配色主题（`char_vanguard` 壮汉钢灰橙、`char_blaze` 少年火红、`char_frost` 高冷女术士冰蓝白、`char_volt` 灵巧女游侠紫黄电——见 `design/04_characters.md`）。
- **不要**只更新 `source_refs/generated/` 或 `contact_sheets/` 里的参考图/展示图就算完成——**交付物是实际会被游戏加载的帧文件本身**（`assets/production/sprites/animations/character_weapon_combos/...`），验收只认这些真实文件。
- 渲染方向仍是 `aspect=expand`，不要改。

---

## §2 次要任务：UI 一致性收尾检查

这两轮你已经把不少界面从纯色 `ColorRect` 换成了贴图 `TextureRect`（战斗横幅、护线警示、暂停遮罩、技能冷却填充、僵尸血条等），这个方向是对的，且这次的类型转换写得很规范（用 `get_node_or_null(...) as CanvasItem/Control` 安全转换，没有再出现类型不匹配崩溃）。请继续保持这个安全模式。

请自查一遍：
- 全项目 `.tscn` 里还有没有明显该换成贴图皮肤、但还没换的 `ColorRect`（纯色块观感的地方）。
- 每处类型转换（`ColorRect`→`TextureRect`）都要在对应 `.gd` 里同步用安全的 `get_node_or_null(...) as CanvasItem/Control`，**不要**用会崩溃的死板 `as ColorRect` 强转换。
- 有疑问 / 不确定某个节点该不该换，就报告出来，不要自己猜。

---

## 自测（贴输出）+ 不要 commit

```bash
godot --headless --import
godot --headless --script tools/m1_smoke_test.gd    # 必须看到 "M1 smoke test passed"，且没有 SCRIPT ERROR
python3 tools/validate_data.py && python3 tools/check_res_refs.py
```

## 报告格式

```
Completed: …
Changed files: …
Verification: <每条自测命令> pass/fail
§1 阶段: 仅完成2组验证 / 已铺开全部32组合（说明当前处于哪一步）
Risks / blockers: …
```
