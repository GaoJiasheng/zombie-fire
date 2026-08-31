# 设置页专用开关纹理生成记录

生成日期：2026-08-31
用途：替换设置页开关控件的运行时扁平色块，使整行表面、轨道与旋钮均由纹理支撑，同时保留青色开启态与灰色关闭态的清晰语义。

## ui_switch_track

最终运行时文件：`assets/production/sprites/ui/ui_switch_track.png`（120×48，透明 PNG）
生成母版：`ui_switch_track_master.png`

Prompt:

> Use case: stylized-concept, production game UI texture source. Asset type: a single isolated nine-slice switch track texture, no knob. Primary request: Create one perfectly straight, front-facing horizontal rounded capsule switch rail in a 5:2 silhouette, designed to become a 120 x 48 px runtime texture. Scene/backdrop: genuinely transparent alpha background; the capsule is the only visible object. Style: restrained premium industrial/post-apocalyptic mobile game UI matching a dark metal interface. Composition: orthographic straight-on view, horizontally and vertically centered, fully visible, perfectly symmetrical end caps, generous transparent padding of about 4% around the silhouette. Materials: neutral achromatic gunmetal only; a continuous shallow recessed center, thin light-metal outer rim, subtle inset inner rim. The broad center strip must be visually plain and uniform so it can be stretched with nine-slice margins without artifacts. Lighting: subtle even embossed edge definition, soft neutral highlights, no dramatic directional light. Color palette: strictly grayscale with R=G=B; medium-to-dark neutral gray, enough value separation that cyan or gray runtime modulate remains legible. Constraints: no text, no letters, no icons, no knob, no red, no blue, no cyan, no gold, no colored pixels, no glow, no bloom, no cast shadow beyond the silhouette, no background plate, no checkerboard, no segmented marks, no notches, no ticks, no screws, no watermark. Clean readable silhouette at 40 px height. Preserve genuine transparency.

## ui_switch_knob

最终运行时文件：`assets/production/sprites/ui/ui_switch_knob.png`（48×48，透明 PNG）
生成母版：`ui_switch_knob_master.png`

Prompt:

> Use case: stylized-concept, production game UI texture source. Asset type: a single isolated circular switch knob texture. Primary request: Create one perfectly round shallow metal control puck, designed to become a 48 x 48 px runtime texture. Scene/backdrop: genuinely transparent alpha background; the knob is the only visible object. Style: restrained premium industrial/post-apocalyptic mobile game UI matching a dark metal interface. Composition: orthographic straight-on view, centered, full circle visible, perfectly symmetrical, with about 6% transparent safe padding around the circle. Materials: light neutral silver metal, continuous smooth beveled rim, subtly brushed center disk, one clean readable form. Lighting: even neutral soft light with restrained embossed depth; highlights must remain legible after downsampling to 32–48 px. Color palette: strictly grayscale with R=G=B; light silver and cool-neutral gray values only. Constraints: no text, no letters, no icons, no red, no blue, no cyan, no gold, no colored pixels, no glow, no bloom, no square backing plate, no track, no cast shadow beyond the circle, no background, no checkerboard, no screws, no segmented marks, no watermark. Clean circular silhouette at 32 px. Preserve genuine transparency.

## 导出

- 母版按透明边界完整保留，等比下采样到运行时尺寸。
- 运行时轨道保持中性灰阶，开启态由代码调制为钢青，关闭态调制为中性灰。
- 旋钮在 36×36 的实际显示尺寸下仍保留完整圆形和浅金属明暗。
