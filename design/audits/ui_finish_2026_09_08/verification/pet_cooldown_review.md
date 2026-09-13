# 宠物冷却显示精度（UI-27 补充）

目视样本：`final02/screenshots/after/owned_detail_pets_pet_apocalypse_skyfalcon_en_scroll0.png`。
核心属性写 `10s Cooldown`，同页战术说明写 `Every 10.5 seconds`。

原因：`meta/collection/collection.gd:_pet_skill_cooldown_text` 使用 `%.0f`，把已有浮点冷却显示为整数。
修复范围：仅该函数的中英格式化，保留精度；不改变 `pet_skill.cooldown`、实际触发逻辑、波次触发或分层维修描述。

验收：整数、小数冷却与中英文断言；天隼原生截图核对 `10.5s Cooldown`；全92个收藏宠物用例补拍。
与商店203张一起构成295张补验，替换基础复拍中的对应用例。其它界面的源码与函数调用范围须保持等价，由报告脚本硬校验。

当前状态：基础批次已暂停、源码封存后实施，提交 `c944da99`。pilot08原生图已确认 `10.5s Cooldown` 与正文一致，整数/小数中英文断言零失败。全部92个宠物场景纳入最新1441张续拍。
