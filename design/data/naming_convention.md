# 命名规范（唯一真源）

> 任何地方出现文件名、资源 ID、数据键，**一律以本表为准**。素材、数据、代码三处必须一致。
> 这份文档就是你说的「文件定义」——美术按这里的文件名出图，程序按这里的 ID 读数据，工具按这里连接两端。

## 0. 总原则

1. **全小写**，单词用下划线 `snake_case`，**英文**（不用拼音、不用空格、不用大写）。
2. **分类前缀** + 语义名 + 可选编号/状态后缀。例：`zombie_brute_walk_01.png`。
3. **ID = 去掉扩展名与状态后缀的"主名"**。例：僵尸 `zombie_brute` 是它在所有数据/代码里的唯一 ID。
4. 编号统一 **两位零填充**：`01`、`02` … `12`。
5. 一个逻辑对象的所有素材共享同一主名，只换"部位/动作/状态/尺寸"后缀。

## 1. 资源类型前缀表

| 前缀 | 类别 | 示例 |
|---|---|---|
| `bg_` | 战斗/界面背景 | `bg_city_ruins.png` |
| `char_` | 玩家角色（主角） | `char_vanguard_body.png` |
| `zombie_` | 普通僵尸 | `zombie_runner_walk_01.png` |
| `boss_` | Boss | `boss_tank_titan_idle_01.png` |
| `weapon_` | 主炮 | `weapon_railgun_icon.png` |
| `armor_` | 护甲 | `armor_kevlar_icon.png` |
| `chip_` | 芯片 | `chip_crit_icon.png` |
| `pet_` | 宝宝/宠物（辅助槽） | `pet_turret_drone_idle_01.png` |
| `skill_` | 通用技能（图标/特效） | `skill_split_shot_icon.png` |
| `sig_` | 角色专属天赋技能 | `sig_blaze_napalm_icon.png` |
| `vfx_` | 视觉特效（粒子/序列帧） | `vfx_explosion_fire_01.png` |
| `proj_` | 子弹/投射物 | `proj_bullet_physical.png` |
| `ui_` | UI 控件/面板 | `ui_button_primary.png` |
| `icon_` | 通用小图标（货币/属性等） | `icon_currency_gold.png` |
| `bgm_` | 背景音乐 | `bgm_battle_city.ogg` |
| `sfx_` | 音效 | `sfx_shot_railgun.ogg` |
| `vid_` | 视频（开场/过场/Boss 登场） | `vid_boss_intro_titan.mp4` |
| `font_` | 字体 | `font_main.ttf` |

## 2. 状态/动作后缀（用于角色、僵尸、Boss、宝宝的动画）

| 后缀 | 含义 |
|---|---|
| `_idle` | 待机 |
| `_walk` | 移动 |
| `_attack` | 攻击 |
| `_hurt` | 受击 |
| `_death` | 死亡 |
| `_special` | 特殊技/机制动作 |
| `_icon` | 图标（立绘缩略/选择界面用） |
| `_portrait` | 大立绘（角色选择/剧情用） |
| `_body` / `_head` / `_arm_l` / `_arm_r` / `_leg_l` / `_leg_r` / `_weapon` | **骨骼分件**（用于引擎骨骼动画，见 §4） |

序列帧动画再加两位帧号：`zombie_runner_walk_01.png` … `_06.png`。

## 3. 尺寸/分辨率后缀（可选）

逻辑分辨率基准 **1080×1920（9:16 竖屏）**。导出按 `@1x/@2x/@3x`：
- 文件不带倍率后缀 = `@1x` 源图（按 1080 宽设计）。
- 高清版：`zombie_brute_walk_01@2x.png`。
- **出图时统一出最高清一档（@3x，即 3240 宽基准的等比）**，引擎自动降采样，省得反复生成。

## 4. 骨骼动画分件规范（2.5D 动效核心）

AI 出**单张整图**做不出逐帧一致动画，所以采用「AI 出分件图 → 引擎骨骼绑定」：
- 每个会动的角色/僵尸/Boss/宝宝，出一套**分件 PNG（透明背景）**：`{主名}_{部位}.png`。
- 标准部位：`head, body, arm_l, arm_r, hand_l, hand_r, leg_l, leg_r, weapon`（按需增减）。
- 同时出一张**合体预览图** `{主名}_portrait.png` 供美术对照比例。
- 引擎里用 Godot `Skeleton2D` + `Polygon2D` 或 AnimationPlayer 驱动这些分件做 walk/attack/hurt/death。
- 详见 `11_art_bible.md` §骨骼分件 与 `assets/prompts_visual.md`。

## 5. 数据文件命名（`design/data/` 与运行时 `res://data/`）

全部用复数名词 `.json`：
`characters.json`, `skills.json`, `zombies.json`, `bosses.json`, `weapons.json`,
`armors.json`, `chips.json`, `pets.json`, `elements.json`, `environments.json`, `levels.json`, `economy.json`,
`challenges.json`, `localization_zh.json`

ID 即第 6~7 节登记的主名，数据用它做主键、互相引用。

## 6. 全局 ID 登记表（规范化主名，详见各设计文档）

### 元素 `elements`
`physical` 物理 ｜ `fire` 火 ｜ `ice` 冰 ｜ `lightning` 雷 ｜ `poison` 毒

### 角色 `characters`（4）
`vanguard` 钢铁先锋 ｜ `blaze` 烈焰技师 ｜ `frost` 寒霜术士 ｜ `volt` 电能游侠

### 专属天赋技 `sig`（8 = 4 角色 × 2）
`sig_vanguard_railvolley`, `sig_vanguard_overload`,
`sig_blaze_napalm`, `sig_blaze_meltdown`,
`sig_frost_glacier`, `sig_frost_shatter`,
`sig_volt_chain`, `sig_volt_storm`

### 通用技能 `skill`（16）
`skill_split_shot`, `skill_pierce`, `skill_ricochet`, `skill_multishot`,
`skill_homing`, `skill_salvo`, `skill_critical`, `skill_charge_shot`,
`skill_incendiary`, `skill_cryo`, `skill_tesla`, `skill_venom`,
`skill_barrier`, `skill_slow_field`, `skill_gold_rush`, `skill_recycle`

### 主炮 `weapon`（8）
`weapon_autocannon`, `weapon_railgun`, `weapon_flamethrower`, `weapon_cryocannon`,
`weapon_teslacoil`, `weapon_venomlauncher`, `weapon_scattergun`, `weapon_plasmacannon`

### 护甲 `armor`（6）
`armor_kevlar`, `armor_reactive`, `armor_thermal`, `armor_cryo`, `armor_faraday`, `armor_hazmat`

### 芯片 `chip`（8）
`chip_attack`, `chip_health`, `chip_crit`, `chip_haste`, `chip_pierce`, `chip_element`, `chip_greed`, `chip_guardian`

### 宝宝 `pet`（6）
`pet_turret_drone`, `pet_fire_imp`, `pet_frost_wisp`, `pet_volt_orb`, `pet_medic_drone`, `pet_collector`

### 普通僵尸 `zombie`（20）
T1: `zombie_shambler`, `zombie_runner`, `zombie_brute`, `zombie_spitter`, `zombie_crawler`
T2: `zombie_armored`, `zombie_bomber`, `zombie_shielder`, `zombie_hopper`, `zombie_screamer`
T3: `zombie_juggernaut`, `zombie_phantom`, `zombie_necromancer`, `zombie_toxic`, `zombie_charger`
T4: `zombie_regenerator`, `zombie_splitter`, `zombie_warden`, `zombie_mutant`, `zombie_berserker`

### Boss `boss`（8）
`boss_tank_titan`(L12), `boss_inferno_maw`(L24), `boss_frost_warden`(L36), `boss_storm_caller`(L48),
`boss_plague_mother`(L60), `boss_void_phantom`(L72), `boss_necrotitan`(L84), `boss_apex_overlord`(L99)

### 场景章节 `env`（10）
`env_lava_foundry`(L1-10) ｜ `env_glacier_pass`(L11-20) ｜ `env_abandoned_factory`(L21-30) ｜ `env_toxic_biolab`(L31-40) ｜
`env_storm_substation`(L41-50) ｜ `env_flooded_subway`(L51-60) ｜ `env_desert_refinery`(L61-70) ｜ `env_void_cathedral`(L71-80) ｜
`env_orbital_ruins`(L81-90) ｜ `env_apex_core`(L91-99)

Legacy compatibility env IDs remain accepted in `environments.json` as fallbacks only:
`env_city_ruins`, `env_subway`, `env_military`, `env_biolab`.

### 货币/资源 `currency`
`gold` 金币 ｜ `xp` 经验 ｜ `star` 星 ｜ （派生）`talent_point` 天赋点

### 局内资源 / 目标策略
`reroll_charge` 刷新点

目标策略：`nearest`, `breach`, `elite`, `low_hp`

卡牌标签：`projectile`, `element`, `control`, `defense`, `economy`, `tempo`, `boss`, `anti_swarm`, `anti_armor`, `execute`

## 7. 代码命名（GDScript）

- 文件：`snake_case.gd`，与场景同名（`enemy.tscn` ↔ `enemy.gd`）。
- 类名 `class_name`：`PascalCase`（`class_name EnemySpawner`）。
- 变量/函数：`snake_case`；常量：`UPPER_SNAKE_CASE`；私有：前缀 `_`。
- 信号：`snake_case` 过去式（`signal wave_cleared`）。
- 节点路径与场景目录见 `13_tech_architecture.md`。
