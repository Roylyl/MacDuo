# MacDuo 黑白图标

应用图标使用内置 imagegen 工具生成，打包时只做标准尺寸缩放与 ICNS 转换。`MacDuo.png` 为 1024 × 1024，`MacDuo.icns` 包含 16–1024 像素的 macOS 图标规格。

设计：黑色圆角方形底，白色双屏线框，后方屏幕向左上偏移，前方屏幕向右下偏移；不使用文字、彩色、渐变或立体效果。

Finder 中的应用与主界面统一使用这张黑白图标；应用包保留完整 PNG 与 ICNS 资源。MacDuo 在后台运行，运行时不显示 Dock 图标。顶部菜单栏仅显示当前角度，不使用图标；效果停止时仍更新角度，传感器未就绪时显示 `—°`。

打开应用后先显示包含设置的主界面，不自动启用实时效果；关闭主界面后继续后台运行。用户点击顶部菜单栏的角度值，可停止效果、选择“停止并打开主界面”或退出进程；应用不会自动设置开机启动。

## 生成提示词

Use case: logo-brand. Asset type: production macOS application icon for MacDuo, 1024x1024 PNG, not a mockup. Design a NEW premium minimalist black-and-white identity about two screens unfolding. One pure black rounded-square tile with a modest 8% transparent exterior margin, generous rounded corners. Center a large bold pure-white geometric mark made from exactly TWO offset rounded-rectangular screen outlines, the rear screen shifted to the upper left and the front screen shifted to the lower right. Both screens are empty black inside, with thick uniform white borders, softly rounded corners. Where the front screen overlaps the rear, its black interior cleanly occludes the rear frame; the front frame is complete and the visible rear frame reads as a second screen. Balanced diagonal movement from upper left to lower right, optically centered, bold enough to identify at 16px. Pure #000000 and #FFFFFF only with antialiasing at edges. Flat precise 2D vector-like design, no gradients, no shadows, no 3D, no shine, no textures, no letters, no text, no device details, no dots, no extra shapes, no blue or any other hue. A genuinely transparent background outside the tile, no checkerboard baked in. Output a single finished icon only.
