# Minis 基础版（OpenMinis 二次开发工程）

> **版本定位：基础版** —— 这是基于开源 [OpenMinis](https://github.com/OpenMinis/OpenMinis) 从源码二次开发的**私有地基版本**。后续所有功能迭代、二次开发都在此基础之上**另外命名交付**（见下「命名规范」），不与基础版混淆，保证每一阶段的成果可追溯、可回滚。

---

## 一、这是什么

`Minis 基础版` 是一套 **iOS 端私有 AI 智能助手（Agent）App**，自带设备端 Linux 沙盒（iSH / Alpine）、浏览器自动化、可扩展技能（Skills）、持久化记忆（Memory）、工作区（Workspace），并深度接入 Health / 日历 / 提醒 / HomeKit / 剪贴板 / 媒体 / 闹钟等系统能力。模型按你自带 Key 接入（Claude / GPT / Gemini 等，BYOK）。

本工程是在 OpenMinis 官方源码基础上，**按私有需求改造、并针对侧载/多开做了工程化加固**的国内私有部署版。

---

## 二、功能特性

### 官方继承的能力
- **设备端真实 Linux 沙盒**：iSH 内核 + Alpine，可安装包 / 跑脚本 / 操作真实文件
- **BYOK 多模型接入**：任意 Provider 自带 API Key
- **浏览器自动化**：Agent 可替你浏览与操作网页
- **Skills / Memory / Workspaces**：可扩展技能、跨会话持久记忆、多工作区
- **系统深度集成**：Health / Calendar / Reminders / Contacts / HomeKit / Bluetooth / Clipboard / Media / Alarms
- **原生 Offloads**：重任务交给原生代码而非沙盒

### 本工程新增 / 加固（私有化定制）
1. **会话上下文占用提示**：输入栏下方实时显示当前上下文占比（进度条 + 百分比 + 已用/窗口 Token，超 70% 橙 / 80% 红警示）
2. **实时 Token 速度**：AI 流式回复时右下角实时显示 **输出 Token 量 × tok/s 速率**（不依赖 Provider 上报，基于流式文本估算，任何模型可用）
3. **多开独立 BundleID**：BundleID `com.cuicsi.openminis`（主 App + 3 扩展全对齐），可与官方 or 其他版本**同机并存**，数据/沙盒/记忆天然隔离
4. **侧载启动修复**：消除源码对 App Group 容器的启动期强依赖（无 App Group 时回退自身沙盒），解决侧载“秒退”问题
5. **精简侧载高危 Entitlement**：去掉 iCloud/HealthKit/HomeKit/NFC/WeatherKit 等侧载易崩的高权项，仅保留 App Group / 网络 / 推送

---

## 三、命名规范（重要）

| 场景 | 命名规则 | 示例 |
|------|---------|------|
| 基础版系列 | 固定名 **Minis_基础版** | App 显示名 = `Minis_基础版`，交付文件 = `Minis_基础版_V{n}.ipa` |
| 版本号 | 对应 git tag `V1 / V2 / V3 …`（整数递进） | tag `V5` ↔ `Minis_基础版_V5.ipa` |
| 二次开发 | **另起名称**，不混入基础版 | 如 `Minis_Pro / Minis_Plus / <功能名>_V{n}` |
| 仓库 | 基础版仓库 `cuicsi/openminis` | 二次开发建议新建独立仓库 |

> 原则：**基础版永远保持“地基”不变名，持续打补丁；新功能、新方向另行命名立项**，避免版本混战。

---

## 四、技术栈与架构

- **语言**：Swift / SwiftUI（iOS 原生）+ Objective-C（iSH 内核桥接）
- **系统**：iOS 26.2+，Xcode 26.x / Swift 6.0
- **沙盒**：iSH 定制内核（OpenMinis/ish-arm64）+ Alpine Linux aarch64 + 自带 rootfs
- **媒体/备份**：FFmpeg 6.1.2、LAME、rclone（SMB/WebDAV/S3/FTP）
- **数据**：SQLite（消息/会话）+ App Group / 沙盒持久化 + iCloud（官方能力）

### 关键目录
```
src/ios/             iOS App（Swift/SwiftUI）+ Share/Widget/FileProvider 扩展
deps/                原生依赖构建脚本（lame→ffmpeg→ish→alpine rootfs→rclone）
.github/workflows/   macOS 云构建 CI（iSH 全链路编译 → IPA）
```

---

## 五、构建方式

完整原生依赖从源码编译（首次约 30-60 分钟，详见上游 `BUILDING.md`），CI 已配置 `.github/workflows/build-ios.yml`：

```sh
./deps/build_lame.sh && ./deps/build_ffmpeg.sh
./deps/build_ish.sh && ./deps/prepare_alpine_rootfs.sh && ./deps/build_rclone_ios.sh
xcodebuild -project src/ios/Minis.xcodeproj -scheme Minis -configuration Release \
           -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

> 侧载安装：AltStore / 全能签自签（需付费开发者证书），装完即独立第二套 Minis。

---

## 六、版本记录

| 版本 | 内容 |
|------|------|
| **V5** | ✅ Token 实时速度：流式 `↓输出token × tok/s`，不依赖 Provider 上报；上下文占比 + 实时速度双显示 |
| **V4** | ✅ 侧载启动真修复：消除 App Group 容器强解 nil（日志定位） |
| **V3** | ✅ Entitlement 内嵌：LIEF 注入精简 Entitlement 进 Mach-O |
| **V2** | ✅ 多开集体修复：全前缀 com.openminis→com.cuicsi，AppGroup 对齐 |
| **V1** | ✅ iOS 云构建打通 + 多开改名初版 |

---

## 七、交付物

- **`Minis_基础版_V5.ipa`**（70.5MB）：当前最新基础版安装包，见本仓库 [Releases](/cuicsi/openminis/releases)
- BundleID `com.cuicsi.openminis` ｜ 显示名 `Minis_基础版` ｜ 版本 1.14

---

## 八、说明与限制

- 本仓库为**私有**工程，含私有配置 / 命名规范；源码与产物仅限内部使用
- 拆除 iCloud/HealthKit 等高权 Capability 后，对应系统能力在多开侧载版中**不工作**（隔离优先）；需要时在正式签名环境下另起版本启用
- 上游官方功能持续跟进，基础版只做稳定收口，不做激进实验