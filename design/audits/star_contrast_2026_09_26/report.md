状态：星级视觉区分已完成；必需验证通过，手机比例截图复看完成；未打包或上传。

# 关卡星级明暗区分

## 修改

- `meta/map/map.gd`：普通/挑战入口的三颗星从30×30增至44×44逻辑像素，间距从2增至6。
- 已获得星保留原生亮金色；未获得星采用原银星贴图并调制为 `(0.30, 0.34, 0.39, 1.0)`，压低金属高光，避免误认为已经点亮。
- 按真实星数决定明暗，不按按钮是否解锁决定。普通1/2/3星、挑战0/2星及锁定状态均复看。
- 双模式按钮206宽，内容区190宽；三颗星加26宽锁标及间距合计176，不撑破按钮。无资产、数值、评分、挑战解锁或存档格式变更。
- `tools/m1_smoke_test.gd`：新增实际星图、明暗、尺寸、间隔、解锁状态独立性及锁标行宽度断言。

## 验证

| 检查 | 结果 |
| --- | --- |
| `python3 tools/validate_asset_pack.py` | PASS（保留项目已记录的生成缓存例外） |
| `python3 tools/validate_data.py` | PASS |
| `python3 tools/check_res_refs.py` | PASS |
| `python3 tools/check_level_pressure.py` | PASS（输出既有 runtime-authoritative topology 提示） |
| `python3 tools/simulate_card_director.py` | PASS，99关每关1000次 |
| `godot --headless --path . --quit` | PASS，独立测试配置下重跑无ERROR |
| `godot --headless --path . --script res://tools/m1_smoke_test.gd` | PASS，独立测试配置下重跑无ERROR |
| `python3 tools/check_runtime_ui_primitives.py` | PASS |
| `python3 tools/check_app_store_ui_polish.py` | PASS |
| `git diff --check` | PASS |

Godot使用4.7。首次沙箱运行的设置文件写入被拒且有系统证书错误，不算干净通过；重跑使用 `/tmp/zf-star-check.98GsQw` 的项目配置副本与源码/资产符号链接，单独指定 `ZFStarCheck_98GsQw` 测试用户数据目录。没有通过修改业务代码规避环境错误。最终日志见 `startup.log`、`smoke.log`。

## 视觉证据与限制

- `iphone_zh.png`：1320×2868，中文版顶部，普通3星/挑战0星，以及普通1/2星。
- `mixed_progress_zh.png`：1320×2868，中文版滚动中段，挑战2星及未通关/未解锁入口。
- `small_en.png`：750×1334，英文小屏，部分星数与锁标均完整。
- 三张为真实Godot离屏渲染，界面审计均为零问题；已逐张人工复看。不是iPhone真机复测，也不代表五主题全组合验收。
- 截图进程正常输出PNG并退出，但退出清理阶段报告 `ObjectDB instances were leaked` / `resources still in use`；保留 `capture_small.log` 原始记录，不宣称截图日志零ERROR。本次不扩大到截图工具资源生命周期修复。
- 本轮不涉及战斗，不做关卡实战通关测试；没有push、TestFlight打包或上传。
