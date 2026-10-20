[![🌐 访问官网](https://img.shields.io/badge/%E2%9C%82%E8%AE%BF%E9%97%AE%E5%AE%98%E7%BD%91-%E7%82%B9%E5%87%BB%E6%89%93%E5%BC%80-2F6BFF?style=for-the-badge&logo=internetexplorer&logoColor=white)](https://hzdavy.github.io/MiOpention/)

# <img src="apps/windows/rc003/src/ovb_rc003/assets/icons/remote-mic-connected.svg" width="30" height="30" alt="logo"> MiOpention

[![Release](https://img.shields.io/github/v/release/HZDavy/MiOpention?color=%232F6BFF&label=Release&logo=github)](https://github.com/HZDavy/MiOpention/releases) [![License](https://img.shields.io/github/license/HZDavy/MiOpention?color=blue&label=License)](LICENSE.md) [![Downloads](https://img.shields.io/github/downloads/HZDavy/MiOpention/latest/total?color=blueviolet&label=Downloads)](https://github.com/HZDavy/MiOpention/releases/latest) [![Last-Release](https://img.shields.io/github/release-date/HZDavy/MiOpention?color=green&label=Last-Release)](https://github.com/HZDavy/MiOpention/releases/latest) ![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11%20x64-0078D6) [![Website](https://img.shields.io/website?up_color=2F6BFF&up_message=online&label=%E5%AE%98%E7%BD%91&url=https%3A%2F%2Fhzdavy.github.io%2FMiOpention%2F)](https://hzdavy.github.io/MiOpention/)

> 把蓝牙语音遥控器，变成 Windows 的快捷键和麦克风。

MiOpention 是一个开源的 Windows 小工具：把小米蓝牙语音遥控器 2 Pro（RC003）的按键和麦克风接进电脑，远距离控制应用、按住说话输入文字、触发快捷键或 Quicker 动作。按键支持单击、双击和长按分别映射，语音可配合搜狗、微信、豆包等输入法使用。

程序常驻通知区域，全部在本机运行，不上传遥控器地址、按键记录、录音或个人数据。

---

## 界面预览

![MiOpention 设备界面](docs/screenshots/device-overview.jpg)

![小米遥控器按键设置界面](docs/screenshots/xiaomi-buttons.jpg)

---

## 能做什么

- **按键映射**：方向、确认、返回、音量、菜单键可设为方向键、快捷键、鼠标操作、打开应用或 Quicker 动作；同一按键的单击、双击、长按可以各设一个动作。
- **语音输入**：用遥控器话筒键说话，文字直接进当前输入框；支持遥控器自带麦克风和电脑本机麦克风两种模式。
- **按应用切换**：为不同前台应用保存不同按键布局，切到该应用时自动生效，未配置的按键回落到全局映射。
- **驱动级注入**：每个按键可单独选择 `SendInput` 或 Interception 驱动级注入，长按和组合键更接近真实键盘。
- **配置管理**：复制、应用、重命名、删除配置副本，支持导出／导入；当前映射自动保存。

---

## 下载与安装

到 [Releases](https://github.com/HZDavy/MiOpention/releases) 下载最新的 `MiOpentionSetup-<版本号>-unsigned.exe`，也可以先在 [官网](https://hzdavy.github.io/MiOpention/) 查看当前版本。

当前正式版为 **0.1.0**。直接下载 [MiOpentionSetup-0.1.0-unsigned.exe](https://github.com/HZDavy/MiOpention/releases/download/v0.1.0/MiOpentionSetup-0.1.0-unsigned.exe)，或查看 [v0.1.0 版本说明](https://github.com/HZDavy/MiOpention/releases/tag/v0.1.0)。发布页同时提供 `SHA256SUMS.txt`，可用 `Get-FileHash -Algorithm SHA256` 核对下载文件。

- 系统要求：64 位 Windows 10 1809 或更高版本。
- 双击安装包按提示安装，默认装到 `%LOCALAPPDATA%\MiOpention`，并创建开始菜单与桌面快捷方式；之后从 Windows 设置 → 应用 → MiOpention 卸载。
- 程序未签名，Windows 首次运行可能弹出 SmartScreen 提示，选择“更多信息 → 仍要运行”。请从本仓库或官网下载。
- 完整的使用说明见 [使用说明](apps/windows/rc003/README.md)。

---

## 第一次使用

### 1. 连接遥控器

1. 先在 Windows 蓝牙设置里配对遥控器，再打开 MiOpention。
2. 在“设备”页点“选择设备”，选中刚配对的遥控器并点“使用此设备”，然后点“启动服务”。
3. 按页面提示处理未就绪的项目，直到显示已连接。

### 2. 设置按键

在“按键”页选中遥控器上的按键，分别设置单击、双击或长按动作，点“完成”即保存。改完后按一次实体按键确认效果。

### 3. 设置语音输入

1. 在“语音”页安装音频组件。MiOpention 的“输出端点”选 `CABLE Input`，输入法的麦克风选 `CABLE Output`。
2. 选择搜狗、微信或豆包，核对 MiOpention 的「语音按键」与输入法里的快捷键一致；自动读取失败时可以手动录入。
3. 先在**记事本**里用电脑键盘试一次这个快捷键，确认能打开语音输入；再把光标留在输入框里，用遥控器说话。

`CABLE Input` 是 MiOpention 写入声音的一侧，`CABLE Output` 是输入法读取麦克风的一侧，两边不要选反。

---

## 从源码运行

需要 Python 3.12（Windows x64）。

```powershell
Set-Location apps/windows/rc003
py -3.12 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements-dev.txt
$env:PYTHONPATH = Join-Path (Get-Location) 'src'
.\.venv\Scripts\python.exe -m ovb_rc003 --settings
```

构建、测试和发布流程见 [开发者文档](apps/windows/rc003/README.md) 与 [TESTING.md](apps/windows/rc003/TESTING.md)。

---

## 检查更新

“设备”页的“检查更新”只查询本仓库 [HZDavy/MiOpention](https://github.com/HZDavy/MiOpention) 的 GitHub Releases，不访问原作者的仓库。启动后每天最多自动检查一次；下载由你手动触发，**不会自动运行下载文件或覆盖当前安装**，保存到桌面后请先完全退出 MiOpention，再手动运行新下载的安装包。

---

## 隐私与安全

- 遥控器地址、按键记录、录音、配置和日志都只保存在本机 `%LOCALAPPDATA%\RemoteMic\RC003`，不会上传到项目服务器。
- 检查更新只向 GitHub 请求公开发布信息，不发送本机数据。
- 关闭设置窗口默认只是隐藏到通知区域；需要结束时右键通知区域图标并选择“完全退出”。
- 自定义按键映射需要一次管理员授权安装本机权限助手；取消后自定义映射不会生效。普通按键和语音不受影响。

---

## 命名寓意

**MiOpention** 来自 **Mi**（小米遥控器）、**Operation**（操作）与 **Attention**（关注）：用一个遥控器，把远处的操作带回手边。

---

## 交流与反馈

- 问题与建议：[GitHub Issues](https://github.com/HZDavy/MiOpention/issues)
- 官网：[hzdavy.github.io/MiOpention](https://hzdavy.github.io/MiOpention/)
- QQ 群：**89641716**

---

## 开源与许可

代码按 [GPL-3.0-only](LICENSE.md) 发布；第三方组件和素材按各自的许可与授权使用，见 [第三方说明](THIRD_PARTY_LICENSES/README.md) 与 [素材授权](ASSET_LICENSES.md)。

本项目为个人学习交流用途，非官方软件，与小米／米家官方无任何关联，也未获其授权或背书。所用接口来自公开资料与开源项目，可能随固件或系统更新变化。请在符合当地法律法规和软件许可的前提下使用。

---

<details>
<summary>开发与技术资料</summary>

- Windows 客户端的运行、构建与技术说明：[开发者文档](apps/windows/rc003/README.md)
- 元素导航的独立项目 OrthoFocus：[项目说明](apps/windows/orthofocus/README.md)
- 历史来源与上游致谢：[ATTRIBUTION.md](apps/windows/rc003/ATTRIBUTION.md)

</details>
