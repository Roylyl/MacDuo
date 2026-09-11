#!/bin/zsh
set -euo pipefail
PROJECT_DIR="${0:A:h}"
TEST_DIR="$PROJECT_DIR/.build/tests"
mkdir -p "$TEST_DIR"
xcrun swiftc -parse-as-library -framework Combine \
  "$PROJECT_DIR/Sources/MenuBarAngle.swift" "$PROJECT_DIR/Tests/MenuBarAngleTests.swift" \
  -o "$TEST_DIR/menu-bar-angle"
"$TEST_DIR/menu-bar-angle"
xcrun swiftc -parse-as-library -framework IOKit -framework QuartzCore \
  "$PROJECT_DIR/Sources/EffectSettings.swift" "$PROJECT_DIR/Sources/LidAngleSensor.swift" \
  "$PROJECT_DIR/Tests/SettingsAndSensorTests.swift" -o "$TEST_DIR/settings"
"$TEST_DIR/settings"
xcrun swiftc -parse-as-library "$PROJECT_DIR/Sources/ScreenCapturePermissionPreparation.swift" \
  "$PROJECT_DIR/Tests/PermissionPreparationTests.swift" -o "$TEST_DIR/permissions"
"$TEST_DIR/permissions"
xcrun swiftc -parse-as-library -framework AppKit -framework Carbon \
  "$PROJECT_DIR/Sources/ShortcutSettings.swift" "$PROJECT_DIR/Tests/ShortcutSettingsTests.swift" \
  -o "$TEST_DIR/shortcuts"
"$TEST_DIR/shortcuts"
xcrun swiftc -parse-as-library -framework AppKit -framework Carbon \
  "$PROJECT_DIR/Sources/ShortcutSettings.swift" "$PROJECT_DIR/Sources/ShortcutController.swift" \
  "$PROJECT_DIR/Tests/ShortcutLifecycleTests.swift" -o "$TEST_DIR/shortcut-lifecycle"
"$TEST_DIR/shortcut-lifecycle"
xcrun swiftc -parse-as-library -framework AppKit -framework Carbon \
  "$PROJECT_DIR/Sources/ShortcutSettings.swift" "$PROJECT_DIR/Sources/ShortcutController.swift" \
  "$PROJECT_DIR/Tests/ShortcutCarbonTests.swift" -o "$TEST_DIR/shortcut-carbon"
"$TEST_DIR/shortcut-carbon"
xcrun swiftc -parse-as-library "$PROJECT_DIR/Sources/EffectSettings.swift" \
  "$PROJECT_DIR/Sources/RuntimePolicy.swift" "$PROJECT_DIR/Tests/RuntimePolicyTests.swift" -o "$TEST_DIR/runtime"
"$TEST_DIR/runtime"
if [[ "${RUN_GPU_TESTS:-0}" == 1 ]]; then
  xcrun swiftc -parse-as-library -framework SwiftUI -framework AppKit -framework MetalKit -framework QuartzCore \
    "$PROJECT_DIR/Sources/GlassRenderer.swift" "$PROJECT_DIR/Tests/RendererSmokeTests.swift" -o "$TEST_DIR/renderer"
  "$TEST_DIR/renderer"
  xcrun swiftc -parse-as-library -framework SwiftUI -framework AppKit -framework MetalKit -framework QuartzCore \
    "$PROJECT_DIR/Sources/GlassRenderer.swift" "$PROJECT_DIR/Tests/RendererLifecycleTests.swift" -o "$TEST_DIR/lifecycle"
  "$TEST_DIR/lifecycle"
fi
