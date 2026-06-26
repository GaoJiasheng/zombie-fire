# Zombie Fire（向僵尸开炮·改进版）— 设计方案总目录

> 一款竖版 Roguelike 塔防/自动射击游戏。对标《向僵尸开炮》，在数值清晰度、技能可控性、关卡公平性上做改进。
> 引擎 **Godot 4 (GDScript)**，一套代码导出 iOS / macOS，预留 Web / Windows / Android。
> 纯单机、无氪金、无内购、无体力。

## v1 设计刷新重点

这套方案不追求复刻《向僵尸开炮》的商业化节奏，而是保留它最有效的体验内核：**低门槛、尸潮爽感、随机成型、长线变强**。所有改进围绕 5 条原则：

1. **可控随机**：玩家出门有核心 build，局内仍有加权随机、刷新、锁定与惊喜牌，避免"全靠脸"也避免"完全按表执行"。
2. **前期喂爽**：前 20 关逐层开放系统，先让玩家感到弹幕、击杀、选卡、质变技能的快乐，再逐步要求配装和克制。
3. **推荐解而非唯一解**：弱点/抗性用于鼓励更优策略，普通关不做"带错元素就没戏"；硬免疫只给 Boss，且必须有明确提示和替代准备路径。
4. **目标锁定清楚可信**：默认目标选择要聪明，手动锁定要强反馈，让玩家相信炮塔在打该打的东西。
5. **无氪也有长线**：用挑战关、变异尸潮、无限尸潮、外观收集替代付费压力，长期目标来自 build 深度与自我挑战。

---

## 怎么用这套文档

- **策划/设计**：读 `00`~`09`，是玩法、数值、内容的全部定义。
- **美术/AI 出图**：读 `11_art_bible.md`（风格圣经）+ `assets/`（清单与逐条 prompt）。
- **音频/AI 配乐**：读 `12_audio_design.md` + `assets/prompts_audio.md`。
- **程序/工程**：读 `13_tech_architecture.md` + `data/`（命名规范与 JSON Schema）。
- **所有人**：`data/naming_convention.md` 是唯一命名真源，任何文件名/ID 以它为准。

## 文档清单

| 文件 | 内容 |
|---|---|
| `00_overview.md` | 项目愿景、目标平台、技术选型、设计支柱、里程碑 |
| `01_core_gameplay.md` | 核心循环、操作、战场、波次、胜负、三星制 |
| `02_stats_economy.md` | 攻/血两基础属性派生、货币（金币/经验/星）、兑换 |
| `03_progression.md` | 角色养成、天赋点、**技能两层升级逻辑**、装备强化 |
| `04_characters.md` | 4 个角色（定位 / 专属天赋技 / 数值） |
| `05_skills.md` | 16 通用技能 + 8 专属技能，成长分支、synergy、携带规则 |
| `06_equipment.md` | 主炮 / 护甲 / 芯片 / 宝宝（宠物），稀有度、强化曲线 |
| `07_elements_enemies.md` | 元素克制系统、20 普通僵尸、8 Boss、抗性/弱点 |
| `08_levels.md` | 99 关：章节、建议等级、波次脚本、难度曲线、三星标准 |
| `09_balance.md` | 数值公式、成长曲线、经济产出/消耗、可过性验证 |
| `10_ui_ux.md` | 竖屏 UI、点击/鼠标适配、窗口缩放、界面流程图 |
| `11_art_bible.md` | 2.5D 美术风格圣经：色板、光影、统一规范 |
| `12_audio_design.md` | BGM / SFX 清单与情绪描述 |
| `13_tech_architecture.md` | Godot 工程结构、存档、跨平台导出、性能预算 |
| `14_roadmap.md` | v1 范围 + Web/Win/Android 迁移路线、里程碑 |
| `15_app_production_plan.md` | 整个 App 的产品边界、里程碑、验收与上架计划 |
| `16_outsourcing_brief.md` | 给 Godot 外包团队的执行说明、任务包与禁止事项 |
| `17_asset_audio_generation_plan.md` | 图片、音乐、音效、视频/镜头素材的生成与交付计划 |
| `18_full_app_backlog.md` | M1-M5 全量 backlog，便于拆任务给外包 |
| `assets/asset_manifest.md` | **全部素材清单**（文件名 ↔ 用途 ↔ 类型 ↔ 尺寸） |
| `assets/full_asset_pack_status.md` | 外包可接入素材包状态与校验说明 |
| `assets/prompts_visual.md` | 每个视觉素材的 GPT/DALL·E 生成 prompt |
| `assets/prompts_audio.md` | 每个音频素材的生成 prompt / 描述 |
| `data/naming_convention.md` | 命名规范总表（唯一真源） |
| `data/schema.md` | 数据驱动 JSON 结构定义（关卡/技能/怪物/装备等） |

## 阅读顺序建议（第一次）

`00` → `01` → `02` → `03` → `04`/`05`/`06` → `07` → `08` → `09`，其余按需查阅。

## 版本

- 文档版本：v1 草案（首次开工）
- 目标产品版本：v1.0（99 关 / 4 角色 / 24 技能 / 20 僵尸 / 8 Boss）
