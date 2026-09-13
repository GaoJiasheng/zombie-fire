# UI-26 · 黄金法则图标清理

内置 imagegen 编辑，上轮候选保留。2026-09-13 Owner 明确批准常规透明化和原生尺寸整理。

## 芯片 · precise-object-edit

Edit target: existing chip_apocalypse_golden_law_icon. Keep the main black-metal octagonal chip, diamond corner insets, luminous golden orbital filaments, material texture and lighting. Remove only the small duplicate preview and partial GOLDEN LA text below it, plus detached dark wisps. Center the main object with transparent padding; main subject about 85% of canvas. Genuine transparent RGBA background. No extra backdrop, preview, words, watermark, or added objects. Preserve design identity and sharp gold/black metal edges.

原提示曾误写 360×368，工具返回 1240×1269 RGBA；没有直接采用错误尺寸。最终读取原运行时档位，等比缩放并留透明边至 384×384。

## 天隼 · precise-object-edit

Edit target: existing pet_apocalypse_skyfalcon_icon. Retain the black-and-gold robotic falcon, wing pose, metal materials and cinematic lighting. Remove the small duplicate preview. Repair clipped wing tips, head and talons so the whole bird fits. Full bird about 84% of canvas with clear padding. Target 384×384, genuinely transparent RGBA. No checkerboard, words, watermark, background, second bird, or new equipment. Preserve the accepted falcon identity and gold energy feathers.

工具返回 1254×1254 RGB，错误地烧录棋盘背景；后续仅要求移除背景的一次内置编辑同样失败。两张假透明候选均未直接接入运行时。

## Owner 批准的后处理

使用本机已有 u2net 模型，只对天隼分离背景并进行边缘 alpha matting；芯片保留已有真透明 alpha。两图等比缩到最多 336×336 主体，置于 384×384 真透明画布中心。保存源图、RGBA master、逐像素 alpha/哈希记录和深浅背景 100% 对照。程序见本轮 audits/verification/prepare_golden_icons.py。不下载模型，不修改战斗素材。

提取器遗留在金色拖尾空隙中的棋盘格，通过限定拖尾空域的低彩度背景蒙版清除；蒙版排除金属主体，保留金色细丝。原生深/浅背景复看通过，无第二张预览、残字或棋盘格。

运行时同路径替换前，原始两图归档至 source_refs/rejected_ui26_2026_09_13/。不删除旧图。
