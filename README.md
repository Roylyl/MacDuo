<p align="center">
  <img src="Assets/MacDuo.png" width="120" height="120" alt="MacDuo黑白双屏图标">
</p>

<h1 align="center">MacDuo</h1>

<p align="center">
  让MacBook的开合动作带出具有透视、磨砂与深度的实时桌面玻璃效果。
</p>

<p align="center">
  <a href="https://github.com/Roylyl/MacDuo/releases"><img alt="GitHub Release" src="https://img.shields.io/github/v/release/Roylyl/MacDuo?display_name=tag&amp;include_prereleases&amp;sort=semver"></a>
  <a href="https://github.com/Roylyl/MacDuo/releases"><img alt="GitHub Release Downloads" src="https://img.shields.io/github/downloads/Roylyl/MacDuo/total"></a>
  <a href="https://github.com/Roylyl/MacDuo/stargazers"><img alt="GitHub Stars" src="https://img.shields.io/github/stars/Roylyl/MacDuo?style=flat"></a>
  <a href="https://github.com/Roylyl/MacDuo/commits/main"><img alt="GitHub Last Commit" src="https://img.shields.io/github/last-commit/Roylyl/MacDuo"></a>
  <img alt="Platform" src="https://img.shields.io/badge/platform-macOS%2014%2B-000000">
  <img alt="Architecture" src="https://img.shields.io/badge/architecture-Apple%20Silicon-555555">
</p>

<p align="center">
  <a href="https://github.com/Roylyl/MacDuo/releases">下载</a> ·
  <a href="#安装与开始使用">安装</a> ·
  <a href="#功能亮点">功能</a> ·
  <a href="#从源码构建安装包">构建</a> ·
  <a href="#隐私权限与使用边界">隐私与权限</a>
</p>

> [!WARNING]
> 当前文档对应的 `.pkg` 未签名，应用采用ad-hoc本地签名，且未完成Apple公证。MacDuo目前也没有项目级开源许可证；公开源码不等于自动授予复制、修改或再分发权限。安装、构建或分发前请先阅读下方签名、上游与许可说明。

## 项目概览

MacDuo由 [jlxc2001/MacBook-Duo](https://github.com/jlxc2001/MacBook-Duo) 派生，使用新的应用名称、Bundle ID与独立配置。它读取兼容MacBook的铰链角度，通过ScreenCaptureKit捕获内建屏幕，并使用Metal在本机生成固定观察点下的玻璃透视效果。

默认的**日常模式**只在移动屏幕时展示效果，停稳后恢复清晰桌面；**持续展示**按铰链角度保持效果。没有兼容传感器或尚未授权录屏时，也可以使用内置示例或导入截图进行手动预览。

| 项目 | 当前值 |
| --- | --- |
| 对外版本／内部构建 | `1.0.1701` / `1705` |
| Git标签 | `v1.0.1701` |
| Bundle ID | `studio.macduo.MacDuo` |
| 平台 | Apple Silicon（arm64），macOS 14.0及以上 |
| 应用类型 | 菜单栏后台应用，运行时不显示Dock图标 |
| 安装位置 | `/Applications/MacDuo.app` |

## 功能亮点

- **实时桌面玻璃效果：**按真实铰链角度驱动透视、深度与磨砂渲染。
- **日常与持续两种模式：**在开合动作期间短暂显示，或在校准角度范围内持续展示。
- **无权限手动预览：**使用内置示例或导入图片调整角度与视觉参数。
- **菜单栏控制：**持续显示当前角度；传感器未就绪时显示 `—°`。
- **七项可配置快捷键：**默认全部未绑定，由用户自行录制并进行冲突检查。
- **故障优先恢复桌面：**捕获、传感器、睡眠或会话异常时先隐藏覆盖效果。

本版保留Finder应用与主界面中的黑白图标。顶部菜单栏只显示角度值，不显示图标；未启用效果时也持续更新。MacDuo是软件视觉实验，不是Apple官方产品、双屏硬件或实体透明屏幕。

## 产品预览

<p align="center">
  <img src="Assets/MacDuo.png" width="192" height="192" alt="MacDuo应用图标预览">
</p>

仓库目前只包含实际应用图标，没有维护可公开复核的界面截图或效果录屏，因此README不使用合成图冒充运行画面。真实效果取决于屏幕角度、观察位置、录屏权限和设备传感器；可通过应用内置示例先行预览。

## 安装与开始使用

1. 从 [GitHub Releases](https://github.com/Roylyl/MacDuo/releases) 获取维护者实际附带的安装包；如发布页没有 `.pkg` 附件，请按本文的源码构建流程生成。打开 **MacDuo-1.0.1701.pkg**，按macOS安装器提示完成安装。
2. 从“应用程序”打开 **MacDuo**，检查传感器和屏幕录制状态。
3. 先用内置示例调节效果，或把屏幕打开到舒适角度，保存自己的展开终点。
4. 启用实时桌面，按系统提示允许屏幕录制；系统要求退出重开时，请完成后再次启用。
5. 缓慢改变开合角度，保持头部大致不动、正对屏幕观察效果。
6. 需要结束时，点击顶部菜单栏的角度值，选择“开启 / 停止实时效果”；选择“停止并打开主界面”可同时返回主界面。

当前文档对应的安装包适用于 **Apple Silicon（arm64）、macOS 14.0及以上**，安装到 `/Applications/MacDuo.app`。安装后由用户自行打开应用；安装过程不请求录屏权限，不安装特权辅助程序或启动项。当前 `.pkg` 未签名，应用为ad-hoc本地签名，未进行Apple公证。下载量徽章只统计GitHub Release附件，不统计源码ZIP、克隆或本地构建。

## 后台运行与退出

打开应用后先显示主界面，其中包含效果参数与快捷键设置，不自动启用实时桌面效果。关闭主界面后，MacDuo继续在后台运行，并保留当前效果状态；可点击顶部菜单栏的角度值，选择“停止并打开主界面”返回窗口。

“开启 / 停止实时效果”只切换效果。要结束后台进程，请点击顶部菜单栏的角度值，选择“退出MacDuo”，或使用自己绑定的退出快捷键。应用不会自动设置开机启动。

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

参数和个人校准会保存。MacDuo使用独立配置，不读取旧应用的设置；截图预览与实时桌面共用效果参数。

**停止与返回主界面：**点击顶部菜单栏的角度值，选择“开启 / 停止实时效果”或“停止并打开主界面”。无需先绑定快捷键，也能从菜单栏停止效果。主界面可见时，也可以点击“停止实时效果”。

持续展示会改变按钮的视觉位置，真实点击仍落在系统原坐标。需要精确操作时，请先停止效果，或按住自己设置的“临时显示原桌面”快捷键。

## 自定义快捷键

应用功能**没有预设按键**。在设置的快捷键区域选择动作、录制组合键即可保存；可清除绑定，并会检查组合冲突。普通macOS文本编辑操作继续使用系统行为。

可配置的七个动作：开关实时效果、停止并打开主界面、保存展开终点、临时显示原桌面（按住生效）、隐藏或显示预览控制、切换原图对比、退出应用。需要快速结束动画时，可以为“停止并打开主界面”录制自己的组合键。快捷键通过系统热键机制注册，无需辅助功能或输入监控权限。

## 隐私、权限与使用边界

- 实时效果只作用于MacBook内建屏幕，要求系统提供兼容的铰链HID数据。以应用检测结果为准；内置示例与导入图片的手动预览可独立使用。
- 画面通过ScreenCaptureKit在本机捕获，再由Metal处理；不保存录像、不采集音频、不上传桌面内容。启动时只检查录屏权限，不自动重置授权。
- 隐藏效果时以2 fps目标频率保持捕获就绪，仍有能耗；停止实时效果才会停止捕获。
- 捕获或传感器异常、睡眠及会话切换时先隐藏效果，恢复后等待有效新画面。
- 当前使用固定观察点和一个内容平面，没有头部跟踪或逐窗口空间分层。全屏应用、Spaces、睡眠唤醒和受保护视频仍需更广泛实机验证。

MacDuo是现有MacBook上的软件视觉实验，项目名称和参考资料不表示Apple官方产品、双屏硬件或实体透明屏幕。更多细节见 [实时桌面说明](GLOBAL-README.md) 和 [权限说明](PERMISSIONS.md)。

应用请求的关键系统能力只有屏幕录制：用户主动启用实时效果时，由macOS管理授权。MacDuo不需要辅助功能或输入监控权限，不安装特权辅助程序或启动项，也不会自动执行 `tccutil`。重编译或改变签名可能让macOS将其识别为新的代码身份，并要求重新确认录屏权限。

屏幕内容、导入图片和校准参数均应视为用户本地数据。源码表明画面在本机处理、不写入录像、不采集音频、不上传桌面内容；这项说明只覆盖当前仓库源码和文档所描述的构建，不能替代对第三方修改版或重新打包二进制的审计。

## 技术信息

| 组件 | 实现 |
| --- | --- |
| UI与应用生命周期 | SwiftUI/AppKit |
| 桌面捕获 | ScreenCaptureKit，仅内建屏幕 |
| 图形渲染 | Metal，内嵌着色器在运行时编译 |
| 铰链角度 | IOKit HID读取与有效性检查 |
| 快捷键 | Carbon热键注册，不合成桌面键盘输入 |
| 设置 | 独立Bundle ID下的本地持久化配置 |
| 构建 | Apple Command Line Tools、仓库内shell脚本 |

模块职责、测试覆盖与当前验证边界见 [源码说明.md](源码说明.md)。实时捕获、物理开合、睡眠唤醒、锁屏、Spaces、外接屏和全屏应用仍需在目标机器上单独验证。

## 项目状态

当前源码与文档对应 `1.0.1701`。仓库提供可复现的编译、测试和打包脚本，但没有完整跨机型兼容矩阵、标准化功耗数据或Apple公证发布流程。GitHub Release是否包含可安装附件，以发布页的实际内容为准；版本标签本身不证明二进制已经签名、公证或完成实机验收。

已提供的测试使用逻辑夹具和合成图像；只有启用 `RUN_GPU_TESTS=1` 才运行额外GPU检查。任何自动化结果都不能替代真实ScreenCaptureKit权限、物理铰链、显示配置和睡眠恢复测试。

## 上游、参考来源与许可

MacDuo保留原项目及其早期原型注明的来源，按用途列出。感谢原作者和以下项目对视觉模型、应用实现及传感器机制的公开分享。

| 来源 | 在本项目中的参考用途 | 上游许可记录 |
| --- | --- | --- |
| [jlxc2001 / MacBook-Duo](https://github.com/jlxc2001/MacBook-Duo) | MacDuo的原项目与派生基础，包含macOS应用、桌面捕获、铰链交互和玻璃效果的已有实现 | 本文不为原项目指定或推定许可证 |
| [Atomicx7 / Duo-animation](https://github.com/Atomicx7/Duo-animation) | 固定内容平面、观察点、旋转玻璃与视线投影的公开模型；本项目将运动轴适配为MacBook底部水平铰链 | 2026-09-11检查该版本时未找到LICENSE文件 |
| [Elijah Semyonov / DuoLikeAnimation](https://github.com/elijah-semyonov/DuoLikeAnimation) | SwiftUI/Metal折叠玻璃示例；[Atomicx7 的着色器](https://github.com/Atomicx7/Duo-animation/blob/705b17f47c0f62e7e0432786bcf3300f16893b96/app/src/main/res/raw/duo_fold.agsl) 明确标注其为该项目着色器的AGSL移植 | [MIT](https://github.com/elijah-semyonov/DuoLikeAnimation/blob/be927684c8585ce3d90761095284329dfdeff901/LICENSE) |
| [Sam Gold / LidAngleSensor](https://github.com/samhenrigold/LidAngleSensor) | 通过IOKit HID发现及读取MacBook铰链角度的实现参考 | [Apache-2.0](https://github.com/samhenrigold/LidAngleSensor/blob/f7e4e5cb46fe13a518091ce5d47f0ec2e3fecd80/LICENSE) |
| [早期原型记录的微博视频页面](https://weibo.com/2/detail/5341559961948752) | 开合、透明感和虚化过渡的视觉参考 | 仅保留出处链接；视频未逐帧核验，不据此确认其中的硬件描述 |

固定核验版本、来源范围及上游许可原文见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。各上游许可分别对应其项目；MacDuo尚未指定自己的项目级开源许可证。

## 从源码构建安装包

在安装Apple Command Line Tools的Mac上进入项目目录：

```sh
./test.sh
./build.sh
./package.sh
open "dist/MacDuo-1.0.1701.pkg"
```

`build.sh` 生成 `dist/MacDuo.app`；`package.sh` 复用该应用，缺少应用时才调用构建。修改源码后应先重新构建，再生成安装包。脚本使用Apple框架，无需下载第三方代码依赖。

```sh
APP_OUTPUT_DIR="$PWD/dist" MACOSX_DEPLOYMENT_TARGET=14.0 ./build.sh
APP_INPUT_DIR="$PWD/dist" PKG_OUTPUT_DIR="$PWD/dist" ./package.sh
```

`APP_INPUT_DIR` 指定包含 `MacDuo.app` 的目录，`PKG_OUTPUT_DIR` 指定安装包输出目录。`CODE_SIGN_IDENTITY` 可指定已有证书签署应用，不会为 `.pkg` 签名，也不会执行公证。

可选运行 `RUN_GPU_TESTS=1 ./test.sh` 做本机GPU与渲染生命周期检查。测试使用合成内容；真实桌面捕获、权限和物理开合效果仍需单独实测，不能由纯逻辑或GPU测试代替。源码结构与验证边界见 [源码说明.md](源码说明.md)。

## 产物与仓库维护

| 脚本 | 默认输出 | 用途 |
| --- | --- | --- |
| `test.sh` | `.build/tests/` | 可重新编译的测试可执行程序 |
| `build.sh` | `dist/MacDuo.app` | 本机应用构建；默认ad-hoc签名 |
| `package.sh` | `dist/MacDuo-<版本>.pkg`、临时 `.build/pkg.*` | 安装包与打包中间文件；临时目录由脚本退出清理 |

`.build/`、`dist/`、Swift/Xcode缓存、安装包和签名凭据均由 `.gitignore` 排除。保留 `Sources/`、`Tests/`、`Assets/`、`Info.plist`、脚本与第三方来源记录；测试源码和应用图标不是编译缓存。使用自定义输出目录时，需要另外确认该目录的忽略与归档方式。

提交前从仓库根目录检查：

```sh
git status --short
git diff --check
git ls-files -ci --exclude-standard
git check-ignore -v --no-index .build/tests/runtime dist/MacDuo.app/Contents/MacOS/MacDuo
```

`git ls-files -ci` 通常应无输出；新增忽略规则不会自动移除已经追踪的文件。需要重建时，先确认没有要保留的发布包，并用以下命令预览默认产物目录中的可清理文件：

```sh
git clean -ndX -- .build/ dist/
```

这条命令只预览，不删除文件。确认后可清理这两个产物目录，再依次运行 `./test.sh`、`./build.sh` 和 `./package.sh`；不要把清理范围扩大到整个仓库，以免删除本地环境或签名材料。清理与重建不会使 `.pkg` 获得安装器签名或Apple公证。

## 参与贡献

欢迎提交范围清晰、能够复现且附验证说明的问题与改进。Pull Request请说明变更动机、影响模块、实际执行的测试，以及是否触及屏幕捕获、HID、系统权限、签名、公证、持久化设置或真实设备行为。

涉及上游来源不清、许可证缺失或大范围重写的问题，应先通过Issue讨论。提交者需要理解并验证自己提交的每一项修改；不要提交录屏内容、私人截图、签名证书、Apple凭据、未脱敏诊断信息或生成产物。

在项目级许可证明确之前，贡献与再分发的授权边界并不完整。提交代码前应先向维护者确认贡献条款；README、Issue或Pull Request讨论不能替代正式许可证或书面授权。
