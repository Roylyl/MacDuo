# 参考来源与第三方许可记录

既有参考核验日期：2026-09-11。MacDuo 由 jlxc2001/MacBook-Duo 派生；本文保留原项目早期原型注明的参考关系及已核验的上游许可。以下许可分别属于对应上游项目；本仓库尚未指定项目级开源许可证。本记录不代表原作者参与、认可或为 MacDuo 提供额外授权。

## 原项目：jlxc2001 / MacBook-Duo

- 来源：[jlxc2001/MacBook-Duo](https://github.com/jlxc2001/MacBook-Duo)。
- 关系：MacDuo 基于该项目继续开发，沿用其 macOS 应用、实时桌面捕获、铰链交互和玻璃渲染的既有实现。
- 当前派生版本使用 MacDuo 名称、独立 Bundle ID 与配置，加入自定义快捷键并调整默认参数。原项目名称作为出处保留。
- 本文不为原项目新增、选择或推定许可证，也不据其公开可见性声称获得额外授权。

## 1. Atomicx7 / Duo-animation：投影模型参考

- 项目：[Atomicx7/Duo-animation](https://github.com/Atomicx7/Duo-animation)。
- 核验版本：[`705b17f47c0f62e7e0432786bcf3300f16893b96`](https://github.com/Atomicx7/Duo-animation/tree/705b17f47c0f62e7e0432786bcf3300f16893b96)。
- 参考内容：[README 中的模型说明](https://github.com/Atomicx7/Duo-animation/blob/705b17f47c0f62e7e0432786bcf3300f16893b96/README.md)及[投影着色器](https://github.com/Atomicx7/Duo-animation/blob/705b17f47c0f62e7e0432786bcf3300f16893b96/app/src/main/res/raw/duo_fold.agsl)。固定内容平面与观察点、屏幕绕铰链旋转、视线投影和随间距变化的模糊是本项目的几何思路参考。
- 该着色器第一行将自身标注为 `DuoLikeAnimation/Shaders/DuoFold.metal` 的 AGSL 移植。这是下一项来源关系的直接依据。
- 该核验版本的完整文件树未找到 LICENSE 或 NOTICE 文件，GitHub 仓库元数据也没有识别到许可证。本文不为其补写许可或推定整仓授权。

MacDuo 的渲染目标是 MacBook 底部水平铰链与 macOS 桌面纹理，相关实现位于 `Sources/GlassRenderer.swift`。本记录说明参考范围，不对全部历史代码作未经核验的逐行来源断言。

## 2. Elijah Semyonov / DuoLikeAnimation：Swift / Metal 模型来源

- 项目：[elijah-semyonov/DuoLikeAnimation](https://github.com/elijah-semyonov/DuoLikeAnimation)。
- 核验版本：[`be927684c8585ce3d90761095284329dfdeff901`](https://github.com/elijah-semyonov/DuoLikeAnimation/tree/be927684c8585ce3d90761095284329dfdeff901)。
- 相关文件：[DuoFold.metal](https://github.com/elijah-semyonov/DuoLikeAnimation/blob/be927684c8585ce3d90761095284329dfdeff901/DuoLikeAnimation/Shaders/DuoFold.metal)。该项目演示以 SwiftUI 着色器和 Core Motion 驱动玻璃折叠效果，也是上述 Android 移植明确标注的来源。
- 许可证：[MIT 原文件](https://github.com/elijah-semyonov/DuoLikeAnimation/blob/be927684c8585ce3d90761095284329dfdeff901/LICENSE)。其版权与许可原文如下，保持原署名。

```text
MIT License

Copyright (c) 2026 Elijah Semyonov

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## 3. Sam Gold / LidAngleSensor：铰链 HID 机制参考

- 项目：[samhenrigold/LidAngleSensor](https://github.com/samhenrigold/LidAngleSensor)。
- 核验版本：[`f7e4e5cb46fe13a518091ce5d47f0ec2e3fecd80`](https://github.com/samhenrigold/LidAngleSensor/tree/f7e4e5cb46fe13a518091ce5d47f0ec2e3fecd80)。
- 相关文件：[LidAngleSensor.swift](https://github.com/samhenrigold/LidAngleSensor/blob/f7e4e5cb46fe13a518091ce5d47f0ec2e3fecd80/LidAngleSensor/LidAngleSensor.swift)。本项目参考其使用 IOKit HID 读取 Feature Report 和取得铰链角度的方法，并在本仓库实现设备发现、数据有效性检查及重新连接。
- 上游源码文件头记载 `Created by Sam on 2026-03-22.`。这里保留来源署名，不补写原文件未提供的版权声明。
- 许可证：[Apache License 2.0 原文件](https://github.com/samhenrigold/LidAngleSensor/blob/f7e4e5cb46fe13a518091ce5d47f0ec2e3fecd80/LICENSE)。该核验版本未找到独立 NOTICE 文件。以下逐字保存 LICENSE，包括上游原有附录占位符。

```text
                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

   1. Definitions.

      "License" shall mean the terms and conditions for use, reproduction,
      and distribution as defined by Sections 1 through 9 of this document.

      "Licensor" shall mean the copyright owner or entity authorized by
      the copyright owner that is granting the License.

      "Legal Entity" shall mean the union of the acting entity and all
      other entities that control, are controlled by, or are under common
      control with that entity. For the purposes of this definition,
      "control" means (i) the power, direct or indirect, to cause the
      direction or management of such entity, whether by contract or
      otherwise, or (ii) ownership of fifty percent (50%) or more of the
      outstanding shares, or (iii) beneficial ownership of such entity.

      "You" (or "Your") shall mean an individual or Legal Entity
      exercising permissions granted by this License.

      "Source" form shall mean the preferred form for making modifications,
      including but not limited to software source code, documentation
      source, and configuration files.

      "Object" form shall mean any form resulting from mechanical
      transformation or translation of a Source form, including but
      not limited to compiled object code, generated documentation,
      and conversions to other media types.

      "Work" shall mean the work of authorship, whether in Source or
      Object form, made available under the License, as indicated by a
      copyright notice that is included in or attached to the work
      (an example is provided in the Appendix below).

      "Derivative Works" shall mean any work, whether in Source or Object
      form, that is based on (or derived from) the Work and for which the
      editorial revisions, annotations, elaborations, or other modifications
      represent, as a whole, an original work of authorship. For the purposes
      of this License, Derivative Works shall not include works that remain
      separable from, or merely link (or bind by name) to the interfaces of,
      the Work and Derivative Works thereof.

      "Contribution" shall mean any work of authorship, including
      the original version of the Work and any modifications or additions
      to that Work or Derivative Works thereof, that is intentionally
      submitted to Licensor for inclusion in the Work by the copyright owner
      or by an individual or Legal Entity authorized to submit on behalf of
      the copyright owner. For the purposes of this definition, "submitted"
      means any form of electronic, verbal, or written communication sent
      to the Licensor or its representatives, including but not limited to
      communication on electronic mailing lists, source code control systems,
      and issue tracking systems that are managed by, or on behalf of, the
      Licensor for the purpose of discussing and improving the Work, but
      excluding communication that is conspicuously marked or otherwise
      designated in writing by the copyright owner as "Not a Contribution."

      "Contributor" shall mean Licensor and any individual or Legal Entity
      on behalf of whom a Contribution has been received by Licensor and
      subsequently incorporated within the Work.

   2. Grant of Copyright License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      copyright license to reproduce, prepare Derivative Works of,
      publicly display, publicly perform, sublicense, and distribute the
      Work and such Derivative Works in Source or Object form.

   3. Grant of Patent License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      (except as stated in this section) patent license to make, have made,
      use, offer to sell, sell, import, and otherwise transfer the Work,
      where such license applies only to those patent claims licensable
      by such Contributor that are necessarily infringed by their
      Contribution(s) alone or by combination of their Contribution(s)
      with the Work to which such Contribution(s) was submitted. If You
      institute patent litigation against any entity (including a
      cross-claim or counterclaim in a lawsuit) alleging that the Work
      or a Contribution incorporated within the Work constitutes direct
      or contributory patent infringement, then any patent licenses
      granted to You under this License for that Work shall terminate
      as of the date such litigation is filed.

   4. Redistribution. You may reproduce and distribute copies of the
      Work or Derivative Works thereof in any medium, with or without
      modifications, and in Source or Object form, provided that You
      meet the following conditions:

      (a) You must give any other recipients of the Work or
          Derivative Works a copy of this License; and

      (b) You must cause any modified files to carry prominent notices
          stating that You changed the files; and

      (c) You must retain, in the Source form of any Derivative Works
          that You distribute, all copyright, patent, trademark, and
          attribution notices from the Source form of the Work,
          excluding those notices that do not pertain to any part of
          the Derivative Works; and

      (d) If the Work includes a "NOTICE" text file as part of its
          distribution, then any Derivative Works that You distribute must
          include a readable copy of the attribution notices contained
          within such NOTICE file, excluding those notices that do not
          pertain to any part of the Derivative Works, in at least one
          of the following places: within a NOTICE text file distributed
          as part of the Derivative Works; within the Source form or
          documentation, if provided along with the Derivative Works; or,
          within a display generated by the Derivative Works, if and
          wherever such third-party notices normally appear. The contents
          of the NOTICE file are for informational purposes only and
          do not modify the License. You may add Your own attribution
          notices within Derivative Works that You distribute, alongside
          or as an addendum to the NOTICE text from the Work, provided
          that such additional attribution notices cannot be construed
          as modifying the License.

      You may add Your own copyright statement to Your modifications and
      may provide additional or different license terms and conditions
      for use, reproduction, or distribution of Your modifications, or
      for any such Derivative Works as a whole, provided Your use,
      reproduction, and distribution of the Work otherwise complies with
      the conditions stated in this License.

   5. Submission of Contributions. Unless You explicitly state otherwise,
      any Contribution intentionally submitted for inclusion in the Work
      by You to the Licensor shall be under the terms and conditions of
      this License, without any additional terms or conditions.
      Notwithstanding the above, nothing herein shall supersede or modify
      the terms of any separate license agreement you may have executed
      with Licensor regarding such Contributions.

   6. Trademarks. This License does not grant permission to use the trade
      names, trademarks, service marks, or product names of the Licensor,
      except as required for reasonable and customary use in describing the
      origin of the Work and reproducing the content of the NOTICE file.

   7. Disclaimer of Warranty. Unless required by applicable law or
      agreed to in writing, Licensor provides the Work (and each
      Contributor provides its Contributions) on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
      implied, including, without limitation, any warranties or conditions
      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
      PARTICULAR PURPOSE. You are solely responsible for determining the
      appropriateness of using or redistributing the Work and assume any
      risks associated with Your exercise of permissions under this License.

   8. Limitation of Liability. In no event and under no legal theory,
      whether in tort (including negligence), contract, or otherwise,
      unless required by applicable law (such as deliberate and grossly
      negligent acts) or agreed to in writing, shall any Contributor be
      liable to You for damages, including any direct, indirect, special,
      incidental, or consequential damages of any character arising as a
      result of this License or out of the use or inability to use the
      Work (including but not limited to damages for loss of goodwill,
      work stoppage, computer failure or malfunction, or any and all
      other commercial damages or losses), even if such Contributor
      has been advised of the possibility of such damages.

   9. Accepting Warranty or Additional Liability. While redistributing
      the Work or Derivative Works thereof, You may choose to offer,
      and charge a fee for, acceptance of support, warranty, indemnity,
      or other liability obligations and/or rights consistent with this
      License. However, in accepting such obligations, You may act only
      on Your own behalf and on Your sole responsibility, not on behalf
      of any other Contributor, and only if You agree to indemnify,
      defend, and hold each Contributor harmless for any liability
      incurred by, or claims asserted against, such Contributor by reason
      of your accepting any such warranty or additional liability.

   END OF TERMS AND CONDITIONS

   APPENDIX: How to apply the Apache License to your work.

      To apply the Apache License to your work, attach the following
      boilerplate notice, with the fields enclosed by brackets "[]"
      replaced with your own identifying information. (Don't include
      the brackets!)  The text should be enclosed in the appropriate
      comment syntax for the file format. We also recommend that a
      file or class name and description of purpose be included on the
      same "printed page" as the copyright notice for easier
      identification within third-party archives.

   Copyright [yyyy] [name of copyright owner]

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
```

## 4. 微博页面：视觉参考

- 来源：[早期原型记录的微博视频页面](https://weibo.com/2/detail/5341559961948752)。
- 用途：开合时的透明感、虚化过渡与展开节奏的视觉参考。
- 核验范围：页面文字可访问；没有对视频作逐帧核验。页面中的产品名称、实拍描述和硬件性能没有被本项目验证。
- 本文保留外部链接，没有重新分发该视频或封面。

## 本仓库的记录范围

MacDuo 的窗口、捕获控制、个人校准、恢复逻辑、设置界面和构建流程位于本仓库。本记录区分原项目派生基础、视觉参考、几何模型来源与 HID 机制来源；这些来源不作为外部运行时依赖加载。本次文档整理不替维护者选择开源许可证；后续引入代码或素材时，应继续记录其具体来源、修改和许可。
