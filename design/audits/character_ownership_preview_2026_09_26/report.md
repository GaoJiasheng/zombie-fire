状态：代码修复、桌面回归与截图复核完成；iPhone真机触控待验证，未打包或上传。

# 未购角色升级门禁与全身预览

## 修复内容

普通角色等级升级原本已有归属门禁，专属技能升级却只判断技能等级和经验。现在专属技能也先验证角色存在且已拥有；未购角色的两个升级按钮都禁用，显示「未解锁」。即使直接调用升级接口，也不会扣费或修改等级。已有存档不迁移、不清除历史技能等级。

详情浏览和外观权益保持独立：未购角色可以查看资料，也可以选择已拥有的主题外观；拥有主题不会绕过角色购买要求。

点击头像进入全身立绘，读取当前外观已有原图，完整展示头脚。提供2倍放大、拖动和恢复全身，以及外观入口。放大默认对齐上部，打开预览时隐藏底层详情，避免交互重叠。未生成、替换或伪造高清素材；已检查代表源图为642×962，放大后的细节仍受原素材分辨率限制。

## 变更文件

- core/save/save_manager.gd：专属技能升级归属检查。
- meta/collection/collection.gd：未解锁按钮、头像入口、预览生命周期。
- ui/character_portrait_viewer.gd：主题感知的全身原图查看器。
- tools/m1_smoke_test.gd：购买前后、资源不变、外观与预览回归。
- tools/_shot.gd：预览实拍参数。
- design/m1_todo.md、design/m1_implementation_progress.md：进展记录。

前一任务的星级对比改动保留，本轮没有修改战斗、数值、商品权益数据或素材。

## 验证

| 检查 | 结果 |
| --- | --- |
| python3 tools/validate_asset_pack.py | PASS |
| python3 tools/validate_data.py | PASS |
| python3 tools/check_res_refs.py | PASS |
| python3 tools/check_level_pressure.py | PASS |
| python3 tools/simulate_card_director.py | PASS |
| Godot --headless --path 独立测试工程 --quit | PASS |
| Godot --headless --path 独立测试工程 --script res://tools/m1_smoke_test.gd | PASS，无ERROR |
| python3 tools/check_localization.py | PASS |
| python3 tools/check_release_strings.py | PASS |
| python3 tools/check_runtime_ui_primitives.py | PASS |
| python3 tools/check_app_store_ui_polish.py | PASS |
| 最终预览与归属专项 | PASS，无ERROR；包含最后的放大头部定位调整 |

完整m1先于最后的放大初始定位微调；微调后重新运行同一归属/预览专项。三个未购角色在资源充足时两种升级均被拒绝、存档字典不变；选择已购主题后仍拒绝；正常购买后均可升级。空ID与无效ID不得升级。预览验证完整图边界、2倍尺寸、拖动范围限制、恢复全身与外观入口。没有新增战斗关卡实玩。

## 最终截图

- locked_blaze.png：未购详情，两种升级禁用，外观入口保留。
- vanguard_default_zh_1320.png、blaze_default_zh_1320.png、frost_default_zh_1320.png、volt_default_zh_1320.png：四默认角色全身。
- blaze_neon_tempest_zh_1320.png、blaze_infernal_dominion_zh_1320.png、blaze_polar_aurora_zh_1320.png、blaze_gilded_eclipse_zh_1320.png：四主题代表。
- frost_polar_aurora_en_750.png：750×1334小屏英文。
- zoom_face_final.png：最终放大初始定位。

以上11张最终截图布局审计均无问题；不是所有角色×主题×尺寸的笛卡尔积覆盖。iteration01保留初版交互重叠截图及旧居中放大图，不作最终证据。

## 限制与安全

截图进程成功输出后，退出阶段仍报告ObjectDB/resource未清理提示（包括ERROR行）；不是运行时脚本错误，但本轮未扩大范围修截图工具退出清理。完整m1和最终专项无此ERROR。

测试工程通过独立Godot custom user directory隔离存档，截图启用只读捕获；测试主题权益仅存在测试夹具，无真实用户权益、存档改写。未push、未打包、未上传TestFlight。iPhone真机点击/拖动及实际清晰度待复测。
