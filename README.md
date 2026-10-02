<p align="center">
  <img src="Assets/MacDuo.png" width="120" height="120" alt="MacDuo黑白双屏图标">
</p>

<h1 align="center">MacDuo</h1>

<p align="center">让MacBook的开合动作带出透视、磨砂与深度变化。</p>
<p align="center">实时桌面玻璃效果 · 菜单栏后台运行 · 自定义快捷键</p>

<p align="center">
  <a href="https://github.com/Roylyl/MacDuo/releases/latest"><img src="https://img.shields.io/github/v/release/Roylyl/MacDuo?style=flat-square&amp;display_name=tag&amp;color=242424" alt="最新发行版本"></a>
  <a href="#运行要求"><img src="https://img.shields.io/badge/macOS-14.0%2B-242424?style=flat-square" alt="macOS14.0及以上"></a>
  <a href="#运行要求"><img src="https://img.shields.io/badge/Apple_Silicon-arm64-555555?style=flat-square" alt="Apple Silicon arm64"></a>
  <a href="#从源码构建"><img src="https://img.shields.io/badge/语言-Swift-555555?style=flat-square" alt="使用Swift开发"></a>
  <a href="#主要功能"><img src="https://img.shields.io/badge/渲染-Metal-555555?style=flat-square" alt="Metal图形渲染"></a>
</p>

<p align="center">
  <a href="https://github.com/Roylyl/MacDuo/releases"><img src="https://img.shields.io/github/downloads/Roylyl/MacDuo/total?style=flat-square&amp;color=242424" alt="发行附件累计下载量"></a>
  <a href="https://github.com/Roylyl/MacDuo/stargazers"><img src="https://img.shields.io/github/stars/Roylyl/MacDuo?style=flat-square&amp;color=555555" alt="GitHub Stars"></a>
  <a href="https://github.com/Roylyl/MacDuo/issues"><img src="https://img.shields.io/github/issues/Roylyl/MacDuo?style=flat-square&amp;color=555555" alt="GitHub开放问题"></a>
  <a href="https://github.com/Roylyl/MacDuo/commits/main"><img src="https://img.shields.io/github/last-commit/Roylyl/MacDuo?style=flat-square&amp;color=555555" alt="最近提交时间"></a>
</p>

<p align="center">
  <a href="https://github.com/Roylyl/MacDuo/releases/latest">下载安装包</a> ·
  <a href="#快速开始">快速开始</a> ·
  <a href="#主要功能">主要功能</a> ·
  <a href="#设置与快捷键">设置与快捷键</a> ·
  <a href="#上游参考来源与许可">来源与许可</a>
</p>

## 项目介绍

MacDuo是一款运行在MacBook上的菜单栏应用。它读取兼容设备的铰链角度，通过ScreenCaptureKit捕获内建屏幕，再用Metal生成随开合动作变化的桌面玻璃效果。

日常模式在移动屏幕时展示效果，停稳后恢复清晰桌面；持续展示模式按当前角度保持效果。你也可以使用内置示例或导入截图，手动调整透视、磨砂和深度参数。

本项目由[jlxc2001/MacBook-Duo](https://github.com/jlxc2001/MacBook-Duo)派生，使用独立的MacDuo名称、应用标识与配置。原项目和其他参考来源见[来源与许可](#上游参考来源与许可)。

## 快速开始

1. 从[最新发行页](https://github.com/Roylyl/MacDuo/releases/latest)下载PKG安装包。当前版本可直接下载[MacDuo-1.0.1701.pkg](https://github.com/Roylyl/MacDuo/releases/download/v1.0.1701/MacDuo-1.0.1701.pkg)。
2. 打开安装包，按macOS安装器提示安装，然后从“应用程序”打开MacDuo。
3. 在主界面使用内置示例调整效果，或将屏幕打开到舒适角度，保存自己的展开终点。
4. 启用实时桌面效果，按系统提示授予屏幕录制权限；如果系统要求退出重开，重开后再次启用。
5. 缓慢改变屏幕角度，保持头部大致不动、正对屏幕观察效果。

点击顶部菜单栏的角度值，可切换“开启 / 停止实时效果”；选择“停止并打开主界面”可停止效果并返回参数设置。主界面中也提供停止入口。

安装位置为`/Applications/MacDuo.app`。当前发行包未签名，应用采用ad-hoc本地签名，未完成Apple公证。

### 运行要求

| 项目 | 要求 |
| --- | --- |
| 系统 | macOS14.0及以上 |
| 当前发行包架构 | Apple Silicon（arm64） |
| 实时效果 | MacBook内建屏幕、兼容的铰链角度传感器 |
| 系统权限 | 屏幕录制，仅在主动启用实时效果时请求 |
| 手动预览 | 内置示例或导入图片，无需屏幕录制权限 |

传感器是否可用，以应用检测结果为准。MacDuo是软件视觉效果应用，不代表Apple官方产品或实体双屏硬件。

## 主要功能

| 功能 | 使用体验 |
| --- | --- |
| 实时桌面玻璃效果 | 根据屏幕开合角度改变透视、磨砂与深度 |
| 日常模式 | 开合期间展示效果，屏幕停稳后恢复清晰桌面 |
| 持续展示 | 在校准角度范围内持续显示效果 |
| 手动预览 | 使用内置示例或导入截图调整视觉参数 |
| 菜单栏角度 | 只显示角度值，例如`106°`；传感器未就绪时显示`—°` |
| 后台运行 | 隐藏Dock图标，关闭主界面后继续运行 |
| 自定义快捷键 | 七项动作可自行绑定、修改或清除，并检查组合冲突 |

菜单栏角度在未启用效果时也持续更新。效果运行时没有右上角悬浮停止按钮，可通过菜单栏或自己绑定的快捷键控制。

关闭主界面会保留当前效果状态；结束后台进程请选择菜单中的“退出MacDuo”。应用不会自动设置开机启动，打开应用也不会自动启用实时桌面效果。

## 设置与快捷键

### 默认参数

| 设置 | 新安装默认值 |
| --- | --- |
| 使用方式 | 日常 |
| 展开终点 | 105° |
| 观察距离 | 2.0×屏幕高度 |
| 磨砂程度 | 15% |
| 深度强度 | 1.0× |
| 画质 | 均衡 |
| 应用快捷键 | 全部未绑定 |

参数与个人校准会自动保存。观察距离表示虚拟观察点到屏幕的距离相对于屏幕高度的倍数；截图预览与实时桌面共用效果参数。

### 自定义快捷键

在主界面的快捷键区域选择动作，录制组合键即可保存；可以随时修改或清除绑定。以下七项动作均没有默认按键：

- 开关实时效果
- 停止并打开主界面
- 保存展开终点
- 临时显示原桌面，按住生效
- 隐藏或显示预览控制
- 切换原图对比
- 退出应用

快捷键使用系统热键机制，无需辅助功能或输入监控权限。需要快速返回桌面时，可以为“停止并打开主界面”或“临时显示原桌面”设置方便的组合键。

## 隐私与使用说明

屏幕画面通过ScreenCaptureKit在本机捕获，由Metal处理，不保存录像、不采集音频、不上传桌面内容。安装过程不请求录屏权限，也不安装特权辅助程序或启动项。

持续展示会改变按钮的视觉位置，实际点击仍落在系统原坐标。需要精确操作时，请先停止效果，或按住自己设置的“临时显示原桌面”快捷键。

日常模式隐藏效果时，以2fps目标频率保持捕获就绪，仍有能耗；停止实时效果会停止捕获。当前效果采用固定观察点和单个内容平面，没有头部跟踪或逐窗口空间分层。

详细操作见[实时桌面说明](GLOBAL-README.md)，系统授权问题见[权限说明](PERMISSIONS.md)。

## 从源码构建

在安装Apple Command Line Tools的Mac上，进入仓库目录执行：

```sh
./build.sh
./package.sh
open "dist/MacDuo-1.0.1701.pkg"
```

`build.sh`生成`dist/MacDuo.app`；`package.sh`复用该应用，缺少应用时会调用构建。修改源码后先重新构建，再生成安装包。项目使用Apple系统框架，无需下载第三方代码依赖。

需要指定输出目录时：

```sh
APP_OUTPUT_DIR="$PWD/dist" MACOSX_DEPLOYMENT_TARGET=14.0 ./build.sh
APP_INPUT_DIR="$PWD/dist" PKG_OUTPUT_DIR="$PWD/dist" ./package.sh
```

`APP_INPUT_DIR`指定包含`MacDuo.app`的目录，`PKG_OUTPUT_DIR`指定安装包输出目录。`CODE_SIGN_IDENTITY`可指定已有证书签署应用；该选项不为PKG签名，也不执行公证。

核心实现采用SwiftUI/AppKit、ScreenCaptureKit、Metal、IOKit HID与Carbon热键。源码结构与开发资料见[源码说明](源码说明.md)。`.gitignore`排除构建产物、安装包、编辑器缓存与签名凭据。

## 上游、参考来源与许可

MacDuo保留原项目及其早期原型注明的来源，按用途列出。感谢原作者和以下项目对视觉模型、应用实现及传感器机制的公开分享。

| 来源 | 在本项目中的参考用途 | 上游许可记录 |
| --- | --- | --- |
| [jlxc2001/MacBook-Duo](https://github.com/jlxc2001/MacBook-Duo) | MacDuo的原项目与派生基础，包含macOS应用、桌面捕获、铰链交互和玻璃效果的已有实现 | 本文不为原项目指定或推定许可证 |
| [Atomicx7/Duo-animation](https://github.com/Atomicx7/Duo-animation) | 固定内容平面、观察点、旋转玻璃与视线投影的公开模型；本项目将运动轴适配为MacBook底部水平铰链 | 2026-09-11检查该版本时未找到LICENSE文件 |
| [Elijah Semyonov/DuoLikeAnimation](https://github.com/elijah-semyonov/DuoLikeAnimation) | SwiftUI/Metal折叠玻璃示例；[Atomicx7的着色器](https://github.com/Atomicx7/Duo-animation/blob/705b17f47c0f62e7e0432786bcf3300f16893b96/app/src/main/res/raw/duo_fold.agsl) 明确标注其为该项目着色器的AGSL移植 | [MIT](https://github.com/elijah-semyonov/DuoLikeAnimation/blob/be927684c8585ce3d90761095284329dfdeff901/LICENSE) |
| [Sam Gold/LidAngleSensor](https://github.com/samhenrigold/LidAngleSensor) | 通过IOKit HID发现及读取MacBook铰链角度的实现参考 | [Apache-2.0](https://github.com/samhenrigold/LidAngleSensor/blob/f7e4e5cb46fe13a518091ce5d47f0ec2e3fecd80/LICENSE) |
| [早期原型记录的微博视频页面](https://weibo.com/2/detail/5341559961948752) | 开合、透明感和虚化过渡的视觉参考 | 仅保留出处链接；视频未逐帧核验，不据此确认其中的硬件描述 |

固定核验版本、来源范围及上游许可原文见[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。各上游许可分别对应其项目；MacDuo尚未指定自己的项目级开源许可证。

## 反馈与贡献

使用问题或功能建议可以提交到[Issues](https://github.com/Roylyl/MacDuo/issues)。请说明系统版本、设备型号、操作步骤与具体表现；涉及桌面画面时，先移除私人信息。

提交改进前请先阅读[第三方来源与许可记录](THIRD_PARTY_NOTICES.md)。MacDuo尚未指定项目级开源许可证，贡献与再分发条款需与维护者确认。不要提交录屏内容、私人截图、签名证书或编译产物。
