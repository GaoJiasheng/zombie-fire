状态：1.0.1（76）已上传并通过 Apple 处理，内部 TestFlight 可安装，自动通知已开启。

# 材质特效重做 · TestFlight 发布

- 目标：1.0.1（76），仅 TestFlight；不提交 App Store 正式发布，不 commit/push。
- 包含当前工作区的材质特效重做、全敌人基地反馈修复及出战摘要布局修复；源码有未提交修改，发布 manifest 必须如实记录。
- 复用 `tools/ship_testflight.sh`，重新执行完整非视觉门禁，随后资源导入、iOS 导出、导出 PCK 冒烟、签名/归档、IPA 校验、上传与 Apple 最终状态检查。
- 运行时测试使用已有隔离 HOME 启动器 `/tmp/zf-loadout-layout.slbtM1/godot`，不读写玩家存档；导入与导出使用原模板环境。
- Build 75 的 2.1 GiB 导出目录先保存于 `/tmp/zf-build75-backup.uQBfmc/ios`，上一发布 manifest 单独保存为 `build_75_previous_manifest.json`；流水线只替换已核验的 `build/ios` 生成物。
- 日志：`release.log`。TestFlight 专用预览/倍速功能由既有流水线临时启用，结束后恢复普通 release 配置。
- 最终构建、上传、Apple 处理与内部测试状态已确认；桌面验证不替代 iPhone 视觉/音效/性能验收。

## 已完成的发布验证

- 完整63项源码非视觉RC全部PASS，包含必需七项、材质门禁与5421项全敌人反馈专项。
- 导出PCK的战斗启动、存档完整性、M1与TestFlight功能检查PASS；Xcode签名归档与IPA导出成功，签名及安装包校验PASS。
- 实际IPA：1.0.1（76），898.4MiB。另解析PCK目录和import重定向，确认三张新材质图集的实际ctex均非空，以及两份特效运行时编译脚本已打包；记录 `pck_material_inventory.json`。
- 2026-10-02 19:08:20（Asia/Singapore）上传成功，`UPLOAD SUCCEEDED with no errors`；delivery `729d654a-9aa1-4fa3-b194-3bda640aaa66`，941,994,275 bytes，传输16.03分钟（7.834Mbps）。长时间终端静默时只读检查工具分片日志，字节仍持续增长，未重启或重复上传。
- 发布流水线exit0；Apple `BUILD-STATUS=VALID`、`IMPORT-STATUS=VALID`、`IS-ON-APP-STORE-CONNECT=true`，同一delivery的API确认`processingState=VALID`、`internalBuildState=IN_BETA_TESTING`、`autoNotifyEnabled=true`，版本1.0.1/build76，无需非豁免加密声明。只读证据 `apple_beta_status.json`。
- `release_manifest.json`、`upload.log`、`build_status.log`已从生成目录复制归档。临时iOS feature恢复为`release`，版本保留1.0.1（76）；桌面`/Users/gavin/Desktop/ZombieFire.ipa`与上传IPA逐字节相同。未提交外部Beta审核或App Store正式发布，未commit/push。
- IPA SHA256：`86319cdf4df78ad0db6e87899cd1499ff88f5050e0524fb78554793e0c9609fc`；PCK SHA256：`1e5c7a08b2108d09906e15b04dd8c4662426fff5fa8d8b10a1b95f5b99609066`。manifest如实记录source_dirty；基线commit不是声称本次未提交修改已在该commit中。
- 已清理本轮自动导入产生的两个审计CSV sidecar，并还原一份旧审计sidecar的导入元数据；原CSV和用户修改保留，后续可重新导入生成。

## 必需命令与验收边界

| 检查 | 结果 |
| --- | --- |
| `python3 tools/validate_asset_pack.py` | PASS |
| `python3 tools/validate_data.py` | PASS |
| `python3 tools/check_res_refs.py` | PASS |
| `python3 tools/check_level_pressure.py` | PASS |
| `python3 tools/simulate_card_director.py` | PASS |
| `godot --headless --path . --quit` | PASS，使用隔离HOME启动器 |
| `godot --headless --path . --script res://tools/m1_smoke_test.gd` | PASS，源码及导出PCK均验证 |
| `check_localization` / `check_release_strings` | PASS |
| 完整非视觉RC | 63项全部PASS |

本轮未重跑99关×10种子战斗探针；现有离线合同与冒烟通过不替代全量实战回归。iPhone真机美术、音效、触感与密集尸潮性能仍由Owner试用确认。
