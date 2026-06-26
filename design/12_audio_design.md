# 12 · 音频设计

> 音频与视觉同等重要，决定"爽感"。所有音频文件遵守命名规范（`bgm_` / `sfx_`），逐条生成 prompt 见 `assets/prompts_audio.md`。
> 格式：BGM 用 `.ogg`（循环，体积小）；SFX 用 `.ogg` 或 `.wav`（短促）。采样率 44.1kHz。

## 1. 音频基调

- 整体：**末日紧张感 + 战斗爽快感**。BGM 推进战斗节奏，SFX 提供清脆有力的打击反馈。
- 风格关键词：`dark electronic, industrial, hybrid orchestral percussion, driving beat, tension build, post-apocalyptic`。
- 元素音效有**统一音色家族**（火=轰燃、冰=脆裂、雷=噼啪电鸣、毒=咕嘟腐蚀、物理=金属撞击），玩家闭眼也能听出属性。
- 目标锁定、精英出现、质变选卡、免疫无效都要有短促可辨的提示音，帮助玩家相信系统反馈。

## 2. BGM 清单

| ID | 用途 | 情绪 |
|---|---|---|
| `bgm_main_menu` | 主菜单 | 沉稳、悬念、蓄势待发 |
| `bgm_battle_city` | 第一章 城市废墟 | 紧张但有希望，中速推进 |
| `bgm_battle_subway` | 第二章 地铁隧道 | 幽闭、压抑、回声感 |
| `bgm_battle_military` | 第三章 军事基地 | 硬核工业、节奏加快 |
| `bgm_battle_biolab` | 第四章 生化实验室 | 诡异、失控、高压 |
| `bgm_boss` | 通用 Boss 战 | 史诗、压迫、鼓点密集 |
| `bgm_boss_final` | 终焉霸主（L99） | 终局史诗、多段递进 |
| `bgm_victory` | 结算胜利 | 短促高昂（3~5s stinger） |
| `bgm_defeat` | 结算失败 | 短促低沉（3~5s stinger） |

- 每首 BGM 设计为**可无缝循环**，1.5~2.5 分钟。
- Boss wave 触发时从章节 BGM **平滑切到** `bgm_boss`。

## 3. SFX 清单（按类别）

### 武器开火 `sfx_shot_*`
- `sfx_shot_autocannon`（连射哒哒）、`sfx_shot_railgun`（蓄能轰）、`sfx_shot_scattergun`（霰弹砰）、
  `sfx_shot_flamethrower`（持续呼啸火舌·循环）、`sfx_shot_cryocannon`（冰晶发射）、
  `sfx_shot_teslacoil`（电流噼啪）、`sfx_shot_venomlauncher`（黏液抛射）、`sfx_shot_plasma`（等离子充能·过热警告）。

### 命中/元素 `sfx_hit_*`
- `sfx_hit_physical`（金属钝击）、`sfx_hit_fire`（轰燃）、`sfx_hit_ice`（脆裂）、`sfx_hit_lightning`（电爆）、`sfx_hit_poison`（腐蚀咕嘟）、`sfx_hit_crit`（暴击·更脆更亮）。

### 敌人 `sfx_zombie_*`
- 通用：`sfx_zombie_groan`（低吼）、`sfx_zombie_death`（倒地）、`sfx_zombie_breach`（越线警报）。
- 特色：`sfx_bomber_explode`（自爆者爆炸）、`sfx_screamer_scream`（尖啸）、`sfx_charger_charge`（冲锋蓄力）、`sfx_necromancer_revive`（复活诡音）、`sfx_splitter_split`（分裂黏腻）。

### Boss `sfx_boss_*`
- `sfx_boss_roar`（登场咆哮，通用）、各 Boss 专属机制音（如 `sfx_frost_warden_freeze` 冻塔、`sfx_void_phantom_phase` 相位）。

### 技能/系统 `sfx_skill_* / sfx_ui_*`
- `sfx_skill_cast`（主动技释放·通用）、各专属技标志音（齐射/凝固汽油/冰川/雷暴等）。
- `sfx_levelup_card`（三选一弹出）、`sfx_card_select`（选卡确认）、`sfx_card_reroll`（刷新）、`sfx_card_pin`（锁定）。
- `sfx_elite_spawn`（精英出现警示）、`sfx_target_lock`（锁定目标）、`sfx_target_strategy`（切换目标策略）、`sfx_hit_immune`（元素无效提示）。
- `sfx_gold_pickup`（金币吸入·清脆叮）、`sfx_star_earn`（结算得星·珍贵感）、
  `sfx_ui_click`、`sfx_ui_confirm`、`sfx_ui_cancel`、`sfx_upgrade_success`（强化成功）。

## 4. 音频反馈与玩法的咬合

- **暴击/击杀**音效区别于普通命中（更脆亮），强化打击感（配合 `10` 的顿帧/闪白）。
- **越线警报** `sfx_zombie_breach` 提醒玩家"漏怪了，基地在掉血"。
- **节奏高点**：精英出现、三选一、Boss 登场都有专属音画，与 `bgm` 配合形成张弛。
- **目标反馈**：锁定/切策略声音必须短，不盖过战斗音；免疫提示要明显但限频，避免 Boss 免疫阶段刷屏刺耳。
- **质变反馈**：Lv3 分支、Lv5 终极和第一次清屏应有更亮的 UI/技能音效，强化"这局成型了"。
- **得星音** `sfx_star_earn` 做得"珍贵"，强化星 > 金币的价值层级。

## 5. 混音与设置

- 三条总线：`BGM` / `SFX` / `UI`，设置界面分别可调（见 `10`）。
- SFX 设并发上限 + 同音去重（避免百怪同屏时音爆），优先播放高优先级音（Boss/越线/暴击）。
- 全局可一键静音；进入后台自动静音（移动端礼貌处理）。
- 响度统一到目标 LUFS，避免某些音效突兀过响。

## 6. 生产管线

- **BGM**：AI 音乐工具（如 Suno）按 `assets/prompts_audio.md` 的情绪 prompt 生成 → 剪辑为无缝循环 → 转 `.ogg`。
- **SFX**：AI 音效工具 / 音效库 + 轻处理；元素家族音色保持一致。
- GPT 不擅长直接产高质量音乐/音效，故音频 prompt 以"喂给专门音频 AI / 在音效库检索"的描述形式给出（见 `assets/prompts_audio.md` 说明）。
