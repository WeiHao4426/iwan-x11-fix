# 修复 Ubuntu 22.04 下 iWAN 黑屏、无响应

适用于 `iwan_2.4.3_amd64.deb` 在 **Ubuntu 22.04 + X11**（常见于 NVIDIA 显卡）上的以下问题：

- 从菜单打开后黑屏，随后提示“应用无响应”；
- 终端出现 `XInitThreads has not been called`、`xcb_io.c` 断言失败；
- iWAN 后端服务正常，但前端反复崩溃或提示“VPN 服务不可用”。

原因是 iWAN 的 Flutter 前端在多线程访问 X11 前没有初始化 Xlib 线程支持。本项目通过一个极小的 `LD_PRELOAD` 兼容库，在 iWAN 启动前调用 `XInitThreads()`。

## 一行修复

先正常安装 iWAN，然后执行：

```bash
curl -fsSL https://raw.githubusercontent.com/WeiHao4426/iwan-x11-fix/main/fix-iwan-x11.sh | bash
```

完成后关闭旧的 iWAN 窗口，再从应用菜单重新打开。修复只写入当前用户的 `~/.local`，不会修改系统显卡驱动或 iWAN 安装包。


## 验证

```bash
systemctl status iwan.service --no-pager
```

服务应显示 `active (running)`，iWAN 界面应能正常显示。

## 卸载修复

```bash
rm -f ~/.local/share/applications/iwan.desktop ~/.local/lib/iwan/libiwan-xinitthreads.so
```

