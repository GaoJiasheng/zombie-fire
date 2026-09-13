# 基础复拍运行记录

固定产品 HEAD：`722fedc67d1325a8ae1325df659b6b6024766054`。

- `final02.log`：第917张 `stable_result_portrait_zh_default_blaze` 出现25秒进程超时。没有得到产品异常堆栈或布局失败输出，不能据此判断为产品错误。
- `final02_resume.log`：上述样本同配置重拍3.873秒通过；第919张 `stable_result_portrait_zh_default_vanguard` 又出现25秒进程超时。
- `final02_resume02.log`：继续重拍第919张及后续，保留之前已经通过的同HEAD图片。后续遇到仅进程超时最多原配置重试2次，每次失败写入 `final02/verification/capture_retries.json`；非超时错误直接停止。

续拍前必须逐字核对 HEAD、运行时代码差异与全部源码哈希；不调整截图超时值、UI断言、像素断言或任何产品代码。每次重试前确认无其它Godot进程。最终报告只接受exit=0、有原图、哈希一致且无ERROR的记录；基础整批结束还要再次核对源码未变。
