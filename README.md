# MacDuo 1.0.1701

<img src="Assets/MacDuo.png" width="112" height="112" alt="MacDuo 黑白双屏图标">

让 MacBook 的开合动作带出有透视、磨砂和深度的桌面玻璃效果。MacDuo 由 [jlxc2001/MacBook-Duo](https://github.com/jlxc2001/MacBook-Duo) 派生，使用新的应用名称与独立配置。

默认的**日常模式**在移动屏幕时展示效果，停稳后恢复清晰桌面；**持续展示**则按铰链角度保持效果。没有兼容传感器或尚未授权录屏时，也可以用内置示例或导入截图进行手动预览。

本版保留 Finder 应用与主界面中的**黑白图标**。顶部菜单栏只显示当前角度，例如 `106°`，不显示图标；未启用效果时也持续显示，传感器未就绪时显示 `—°`。MacDuo 在后台运行，运行时不显示 Dock 图标。

## 安装与开始使用

1. 打开 **MacDuo-1.0.1701.pkg**，按 macOS 安装器提示完成安装。
2. 从“应用程序”打开 **MacDuo**，检查传感器和屏幕录制状态。
3. 先用内置示例调节效果，或把屏幕打开到舒适角度，保存自己的展开终点。
4. 启用实时桌面，按系统提示允许屏幕录制；系统要求退出重开时，请完成后再次启用。
5. 缓慢改变开合角度，保持头部大致不动、正对屏幕观察效果。
6. 需要结束时，点击顶部菜单栏的角度值，选择“开启 / 停止实时效果”；选择“停止并打开主界面”可同时返回主界面。

当前安装包适用于 **Apple Silicon（arm64）、macOS 14.0 及以上**，安装到 `/Applications/MacDuo.app`。安装后由用户自行打开应用；安装过程不请求录屏权限，不安装特权辅助程序或启动项。当前 `.pkg` 未签名，应用为 ad-hoc 本地签名，未进行 Apple 公证。

## 后台运行与退出

打开应用后先显示主界面，其中包含效果参数与快捷键设置，不自动启用实时桌面效果。关闭主界面后，MacDuo 继续在后台运行，并保留当前效果状态；可点击顶部菜单栏的角度值，选择“停止并打开主界面”返回窗口。

“开启 / 停止实时效果”只切换效果。要结束后台进程，请点击顶部菜单栏的角度值，选择“退出 MacDuo”，或使用自己绑定的退出快捷键。应用不会自动设置开机启动。

## 设置与默认值

| 设置 | 新安装默认值 |
| --- | --- |
| 使用方式 | 日常 |
| 展开终点 | 105° |
| 观察距离 | 2.0× 屏幕高度 |
| 磨砂程度 | 15% |
| 深度强度 | 1.0× |
| 画质 | 均衡 |
| 应用快捷键 | 全部未绑定 |

参数和个人校准会保存。MacDuo 使用独立配置，不读取旧应用的设置；截图预览与实时桌面共用效果参数。

**停止与返回主界面：**点击顶部菜单栏的角度值，选择“开启 / 停止实时效果”或“停止并打开主界面”。无需先绑定快捷键，也能从菜单栏停止效果。主界面可见时，也可以点击“停止实时效果”。

持续展示会改变按钮的视觉位置，真实点击仍落在系统原坐标。需要精确操作时，请先停止效果，或按住自己设置的“临时显示原桌面”快捷键。

## 自定义快捷键

应用功能**没有预设按键**。在设置的快捷键区域选择动作、录制组合键即可保存；可清除绑定，并会检查组合冲突。普通 macOS 文本编辑操作继续使用系统行为。

可配置的七个动作：开关实时效果、停止并打开主界面、保存展开终点、临时显示原桌面（按住生效）、隐藏或显示预览控制、切换原图对比、退出应用。需要快速结束动画时，可以为“停止并打开主界面”录制自己的组合键。快捷键通过系统热键机制注册，无需辅助功能或输入监控权限。

## 使用边界

- 实时效果只作用于 MacBook 内建屏幕，要求系统提供兼容的铰链 HID 数据。以应用检测结果为准；内置示例与导入图片的手动预览可独立使用。
- 画面通过 ScreenCaptureKit 在本机捕获，再由 Metal 处理；不保存录像、不采集音频、不上传桌面内容。启动时只检查录屏权限，不自动重置授权。
- 隐藏效果时以 2 fps 目标频率保持捕获就绪，仍有能耗；停止实时效果才会停止捕获。
- 捕获或传感器异常、睡眠及会话切换时先隐藏效果，恢复后等待有效新画面。
- 当前使用固定观察点和一个内容平面，没有头部跟踪或逐窗口空间分层。全屏应用、Spaces、睡眠唤醒和受保护视频仍需更广泛实机验证。

MacDuo 是现有 MacBook 上的软件视觉实验，项目名称和参考资料不表示 Apple 官方产品、双屏硬件或实体透明屏幕。更多细节见 [实时桌面说明](GLOBAL-README.md) 和 [权限说明](PERMISSIONS.md)。

## 参考来源与致谢

MacDuo 保留原项目及其早期原型注明的来源，按用途列出。感谢原作者和以下项目对视觉模型、应用实现及传感器机制的公开分享。

| 来源 | 在本项目中的参考用途 | 上游许可记录 |
| --- | --- | --- |
| [jlxc2001 / MacBook-Duo](https://github.com/jlxc2001/MacBook-Duo) | MacDuo 的原项目与派生基础，包含 macOS 应用、桌面捕获、铰链交互和玻璃效果的已有实现 | 本文不为原项目指定或推定许可证 |
| [Atomicx7 / Duo-animation](https://github.com/Atomicx7/Duo-animation) | 固定内容平面、观察点、旋转玻璃与视线投影的公开模型；本项目将运动轴适配为 MacBook 底部水平铰链 | 2026-09-11 检查该版本时未找到 LICENSE 文件 |
| [Elijah Semyonov / DuoLikeAnimation](https://github.com/elijah-semyonov/DuoLikeAnimation) | SwiftUI / Metal 折叠玻璃示例；[Atomicx7 的着色器](https://github.com/Atomicx7/Duo-animation/blob/705b17f47c0f62e7e0432786bcf3300f16893b96/app/src/main/res/raw/duo_fold.agsl) 明确标注其为该项目着色器的 AGSL 移植 | [MIT](https://github.com/elijah-semyonov/DuoLikeAnimation/blob/be927684c8585ce3d90761095284329dfdeff901/LICENSE) |
| [Sam Gold / LidAngleSensor](https://github.com/samhenrigold/LidAngleSensor) | 通过 IOKit HID 发现及读取 MacBook 铰链角度的实现参考 | [Apache-2.0](https://github.com/samhenrigold/LidAngleSensor/blob/f7e4e5cb46fe13a518091ce5d47f0ec2e3fecd80/LICENSE) |
| [早期原型记录的微博视频页面](https://weibo.com/2/detail/5341559961948752) | 开合、透明感和虚化过渡的视觉参考 | 仅保留出处链接；视频未逐帧核验，不据此确认其中的硬件描述 |

固定核验版本、来源范围及上游许可原文见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。各上游许可分别对应其项目；MacDuo 尚未指定自己的项目级开源许可证。

## 从源码构建安装包

在安装 Apple Command Line Tools 的 Mac 上进入项目目录：

```sh
./test.sh
./build.sh
./package.sh
open "dist/MacDuo-1.0.1701.pkg"
```

`build.sh` 生成 `dist/MacDuo.app`；`package.sh` 复用该应用，缺少应用时才调用构建。修改源码后应先重新构建，再生成安装包。脚本使用 Apple 框架，无需下载第三方代码依赖。

```sh
APP_OUTPUT_DIR="$PWD/dist" MACOSX_DEPLOYMENT_TARGET=14.0 ./build.sh
APP_INPUT_DIR="$PWD/dist" PKG_OUTPUT_DIR="$PWD/dist" ./package.sh
```

`APP_INPUT_DIR` 指定包含 `MacDuo.app` 的目录，`PKG_OUTPUT_DIR` 指定安装包输出目录。`CODE_SIGN_IDENTITY` 可指定已有证书签署应用，不会为 `.pkg` 签名，也不会执行公证。

可选运行 `RUN_GPU_TESTS=1 ./test.sh` 做本机 GPU 与渲染生命周期检查。测试使用合成内容；真实桌面捕获、权限和物理开合效果仍需单独实测，不能由纯逻辑或 GPU 测试代替。源码结构与验证边界见 [源码说明.md](源码说明.md)。
