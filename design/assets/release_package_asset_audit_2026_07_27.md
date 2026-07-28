# 发布包素材审计（2026-07-27）

## 结论

Build 38 的 iPhone 发布包当前为：

- PCK：`603,709,648` bytes（575.7 MiB）
- IPA：`633,091,255` bytes（603.8 MiB）

本轮没有对已验收的角色、僵尸、Boss 或战斗特效做有损压缩、降帧或路径合并。发布前直接批量重编码这批透明序列，会同时引入透明边、颜色、帧时序、Godot 导入缓存和设备显存峰值风险，不适合作为最后关头的无实机监控改动。

## 已确认不会进入 iPhone 包的创作资产

`export_presets.cfg` 和 `tools/release_export_rules.py` 已排除：

- `assets/production/source_refs/`：约 406 MiB、970 个源文件
- `assets/production/video/`：约 38 MiB、16 个 App Preview / 工作视频文件
- `assets/production/contact_sheets/`：约 26 MiB
- `assets/production/flow/`：约 14 MiB
- `assets/production/environment/`：约 114 MiB 的非运行时环境源文件
- 已登记的 VFX 无用尾帧、旧 parts 和设计 / 工具 / 构建目录

这些目录继续留在仓库中用于溯源、再生成和审核，但不应出现在导出的 PCK。

## 运行时主要体积来源

- `assets/production/sprites/animations/`：约 446 MiB，2,022 张 PNG
- `assets/production/sprites/vfx_sequences/`：约 192 MiB，1,022 张 PNG
- `assets/production/sprites/backgrounds/`：约 55 MiB
- `assets/production/sprites/zombies/`：约 33 MiB
- `assets/production/sprites/bosses/`：约 21 MiB

因此，后续真正有意义的包体优化对象是动画与 VFX 的运行时导入格式，而不是继续删除创作源文件。

## 发布前决策

当前候选保持素材质量优先，不做风险较高的批量别名、降采样或有损重编码。若首发后需要缩包，应单开一次“设备监控下的纹理导入优化”：

1. 在至少一台低内存 iPhone 上记录冷启动、章节切换、Boss 战和高密尸潮的内存峰值。
2. 按序列逐组比较无损压缩、Godot iOS 纹理导入和图集方案，而不是直接改源 PNG。
3. 每组改动必须通过透明安全边、语义方向、全量截图、战斗启动和实机显存回归。
4. 只有在包体与内存收益都可测、视觉差异不可见时才进入下一候选。

这保留了当前已经验收的顶级素材质量，也给后续缩包留下了可量化、可回滚的路径。
