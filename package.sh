#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h}"
INPUT_DIR="${APP_INPUT_DIR:-$PROJECT_DIR/dist}"
APP_DIR="$INPUT_DIR/MacDuo.app"
OUTPUT_DIR="${PKG_OUTPUT_DIR:-$PROJECT_DIR/dist}"
if [[ ! -d "$APP_DIR" ]]; then
  APP_OUTPUT_DIR="$INPUT_DIR" "$PROJECT_DIR/build.sh"
fi
codesign --verify --strict "$APP_DIR"
APP_VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_DIR/Contents/Info.plist")
mkdir -p "$PROJECT_DIR/.build" "$OUTPUT_DIR"
PKG_WORK_DIR=$(mktemp -d "$PROJECT_DIR/.build/pkg.XXXXXX")
trap 'rm -rf "$PKG_WORK_DIR"' EXIT
mkdir -p "$PKG_WORK_DIR/payload" "$PKG_WORK_DIR/resources"
ditto --norsrc --noextattr --noacl "$APP_DIR" "$PKG_WORK_DIR/payload/MacDuo.app"
cp "$PROJECT_DIR/THIRD_PARTY_NOTICES.md" "$PKG_WORK_DIR/resources/ThirdPartyNotices.txt"

python3 - "$APP_DIR" "$PKG_WORK_DIR" <<'PY'
from pathlib import Path
import plistlib, subprocess, sys, html
app, work = map(Path, sys.argv[1:])
info = plistlib.loads((app/'Contents/Info.plist').read_bytes())
components = [{
    'RootRelativeBundlePath': 'MacDuo.app',
    'BundleIsRelocatable': False,
    'BundleIsVersionChecked': True,
    'BundleHasStrictIdentifier': True,
    'BundleOverwriteAction': 'upgrade'
}]
(work/'components.plist').write_bytes(plistlib.dumps(components))
architectures = subprocess.check_output(['xcrun','lipo','-archs',str(app/'Contents/MacOS'/info['CFBundleExecutable'])],text=True).split()
requirements = {'os': [info.get('LSMinimumSystemVersion','14.0')], 'arch': architectures}
(work/'requirements.plist').write_bytes(plistlib.dumps(requirements))
version = html.escape(info['CFBundleShortVersionString'])
page = f'''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><style>body{{font:14px -apple-system,sans-serif;line-height:1.65;padding:20px}}h1{{font-size:25px}}</style>
<h1>MacDuo {version}</h1><p>让桌面随 MacBook 的开合动作展开。</p>
<p>安装程序会将 MacDuo 安装到“应用程序”文件夹。</p>
<p>安装完成后，从“应用程序”打开 MacDuo。应用在顶部菜单栏运行，不显示程序坞图标；关闭设置窗口后继续在后台运行。内置演示无需录屏授权；启用实时桌面时，请按 macOS 提示允许屏幕录制。</p>
<p>需要停止效果时，点击顶部菜单栏的角度值，选择“开启 / 停止实时效果”或“停止并打开主界面”。</p>
<p>原项目：jlxc2001 / MacBook-Duo（https://github.com/jlxc2001/MacBook-Duo）。其他参考：Atomicx7 / Duo-animation、Elijah Semyonov / DuoLikeAnimation、Sam Gold / LidAngleSensor，以及项目 README 中记录的视觉参考。</p>
<p>完整参考用途与第三方许可见源码中的 README.md 和 THIRD_PARTY_NOTICES.md。</p></html>'''
(work/'resources/welcome.html').write_text(page)
PY

pkgbuild --root "$PKG_WORK_DIR/payload" \
  --component-plist "$PKG_WORK_DIR/components.plist" \
  --identifier studio.macduo.MacDuo.pkg \
  --version "$APP_VERSION" --install-location /Applications --ownership recommended \
  "$PKG_WORK_DIR/MacDuo-component.pkg"
productbuild --synthesize --product "$PKG_WORK_DIR/requirements.plist" \
  --package "$PKG_WORK_DIR/MacDuo-component.pkg" "$PKG_WORK_DIR/Distribution.xml"
python3 - "$PKG_WORK_DIR/Distribution.xml" "$APP_VERSION" <<'PY'
from pathlib import Path
import sys, xml.etree.ElementTree as ET
path=Path(sys.argv[1])
tree=ET.parse(path)
root=tree.getroot()
ET.SubElement(root,'title').text='MacDuo '+sys.argv[2]
options=root.find('options')
if options is None: options=ET.SubElement(root,'options')
options.set('customize','never')
options.set('require-scripts','false')
ET.SubElement(root,'domains',enable_anywhere='false',enable_currentUserHome='false',enable_localSystem='true')
ET.SubElement(root,'welcome',file='welcome.html',**{'mime-type':'text/html'})
ET.SubElement(root,'readme',file='ThirdPartyNotices.txt',**{'mime-type':'text/plain'})
# Remove developer-machine paths from package references.
for ref in root.findall('pkg-ref'):
    if ref.text and '.pkg' in ref.text:
        ref.text='MacDuo-component.pkg'
tree.write(path,encoding='utf-8',xml_declaration=True)
PY
PKG_PATH="$OUTPUT_DIR/MacDuo-$APP_VERSION.pkg"
productbuild --distribution "$PKG_WORK_DIR/Distribution.xml" \
  --package-path "$PKG_WORK_DIR" --resources "$PKG_WORK_DIR/resources" \
  --identifier studio.macduo.MacDuo.installer --version "$APP_VERSION" \
  "$PKG_PATH"
echo "Built installer: $PKG_PATH"
