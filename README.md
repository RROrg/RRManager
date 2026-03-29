# RR Manager

RR Manager 是一个为 RR 引导的 DSM 系统重新实现的 DSM WebApp，用来在 DSM 内直接管理 bootloader 配置、addons、modules，并执行 RR 在线或本地升级。


## 注意事项

- RR Manager 会直接修改 bootloader 分区内容。
- 错误配置或错误升级可能导致 DSM 无法正常启动。
- 更新完成后通常需要重启 DSM，新的 bootloader 才会真正生效。
