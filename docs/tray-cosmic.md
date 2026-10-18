# COSMIC panel 里两个 magpie 图标

## 现象

COSMIC 的 panel 顶栏托盘区里 magpie 的图标出现两份（本机 2026-10-18 还多出第三份，
是早先某个连接死掉留下的僵尸条目，见文末）。

## 谁注册了两次

`org.kde.StatusNotifierWatcher.RegisteredStatusNotifierItems` 里同一个进程（pid 24248）
有两条：

```
:1.1004/StatusNotifierItem      ← Wails 托盘启动时的注册（按 well-known 名字）
:1.1004                         ← 上游 dropTrayName 释放名字后再注册的那次
```

两条都指向 `/StatusNotifierItem`，Id 都是 `magpie`。

## 上游为什么那么写

`internal/gui/bus_linux.go` 的 `dropTrayName()`：

1. Wails 的托盘启动时占住 `org.kde.StatusNotifierItem-<pid>-1` 这个名字并向 watcher
   注册。**有些** watcher（Quickshell / noctalia，上游注释里提到的 #2421）按"注册时
   给的名字"记条目，释放名字就把条目一起丢了，于是同一个图标变成两条。
2. 所以上游主动 `ReleaseName` 掉它，再用连接自己的名字 `conn.Names()[0]`（`:1.x`）
   重新注册一次：对这种 watcher 来说，重新注册的正是它已经有的那条，数量不变。

## 在 COSMIC 上为什么反而多一个

COSMIC 的 watcher（`com.system76.CosmicStatusNotifierWatcher`，由
`cosmic-applet-status-area --status-notifier-watcher` 提供）不按注册时给的名字记，
而是记成**发送者的唯一名 + 路径**：第一条落成 `:1.1004/StatusNotifierItem`。
释放 `org.kde.StatusNotifierItem-<pid>-1` 不会动这条，再用 `:1.1004` 注册
就是**另一个字符串**，于是列表里多一条，panel 画两个图标。

## 补丁

`no-double-tray-item-cosmic.patch`：`dropTrayName()` 开头先问一句
`org.freedesktop.DBus.NameHasOwner("com.system76.CosmicStatusNotifierWatcher")`，
是 COSMIC 就直接返回。它已经有的那条就是对的，不需要也不该再注册一次。

其它 watcher 的行为不变。

## 僵尸条目不是同一个问题

`RegisteredStatusNotifierItems` 里还留着 `:1.173`，`GetConnectionUnixProcessID` 报
`NameHasNoOwner`——连接早就没了，COSMIC 的 watcher 从不清死条目，panel 继续按缓存的
图标画出来，看起来是同款第三个图标。补丁管不了这个：要清得重启
`com.system76.CosmicStatusNotifierWatcher.service`（重启 panel 不够，列表在 watcher
进程里）。
