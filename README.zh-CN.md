# 鲸跃深潮 / Whale Drift

**一款使用 Godot 4.7 制作的 2D 深海无尽跑酷。**

> 本仓库只包含**游戏代码**。贴图、音频等美术素材不包含在仓库中；要构建可玩版本，请按 [`godot/assets/ASSETS.md`](godot/assets/ASSETS.md) 补齐素材。

## 简介

《鲸跃深潮》是一款 2D 深海无尽跑酷。操控鲸鱼穿过微光珊瑚海、暮色峡谷与幽蓝深渊，在尖刺、海胆和洋流之间寻找缝隙，收集珍珠、气泡护盾与加速。六档难度、手柄支持、分辨率设置，速度缓慢提升；没有跳跃键，只有流动、节奏和一次深呼吸。使用 Godot 4.7.2 制作。

## 特性

- 无限横向地图与自由上下游动
- 尖刺、门缝、礁石、水母、海胆等收窄碰撞
- 珍珠、护盾、洋流加速、冲刺与检查点
- 六档难度：浮光悠游 到 海沟寂灭
- 缓慢提速，支持 60–240 FPS、分辨率与显示模式
- 键盘、鼠标和标准手柄
- 默认英文，可在 **设置 → 语言** 或按 **L** 切换中文
- 本地 JSON 存档与自动检查点

## 操作

| 功能 | 键盘 / 鼠标 |
|---|---|
| 上下游动 | W / S 或 ↑ / ↓ |
| 冲刺 | SHIFT / SPACE |
| 暂停 | ESC / P |
| 静音 | M |
| 全屏 | F11 |
| 菜单 | 鼠标 |

| 功能 | 手柄 |
|---|---|
| 移动 / 菜单 | 左摇杆 / 十字键 |
| 调整设置 | 左摇杆 / 十字键 ← → |
| 冲刺 | A / X / RB / RT |
| 确认 | A |
| 返回 | B |
| 暂停 / 继续 | START |

## 构建

需要 **Godot 4.7.2**、Windows x86_64 导出模板，以及 [`godot/assets/ASSETS.md`](godot/assets/ASSETS.md) 中列出的素材。

1. 将所需贴图和音频放入 `godot/assets/`
2. 用 Godot 打开 `godot/project.godot`
3. **项目 → 导出 → Windows Desktop**
4. 启用 **Embed PCK** 后导出

## 存档

```text
%APPDATA%\Godot\app_userdata\Whale Drift
```

删除该文件夹即可清空记录、设置和检查点。

## 项目结构

```text
godot/          Godot 4.7 工程
godot/assets/   仅素材清单，不包含贴图/音频
README.md       英文说明
README.zh-CN.md 中文说明
SHORT_DESCRIPTION.md  简介文案
```

## 许可

源代码使用 **MIT License**，见 [LICENSE](LICENSE)。

MIT 许可**不覆盖**原游戏的贴图、音频、图标等美术素材；这些素材没有包含在本仓库中。
