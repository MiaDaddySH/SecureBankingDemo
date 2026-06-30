# 01 - Token 生命周期

认证系统通常会同时使用 access token 和 refresh token。它们看起来都是 token，但安全语义完全不同。

## Access Token 和 Refresh Token 的区别

Access token 用来访问业务 API。客户端把它放在请求头里，服务端用它判断当前请求是否已认证、是否有权限访问某个资源。

Refresh token 用来换取新的 access token。它通常不应该被频繁发送到普通业务 API，只在刷新会话时使用。

可以把它们理解成：

- access token：短期通行证。
- refresh token：续期凭证。

## 为什么 Access Token 应该短生命周期

Access token 会出现在更多运行路径里，例如网络请求、日志边界、调试器、内存快照和错误上报附近。它的暴露面比 refresh token 更大。

让 access token 短生命周期有几个好处：

- 泄露后的可用时间更短。
- 服务端可以更快地收回权限。
- 客户端可以通过 refresh token 静默换取新 access token，减少用户频繁登录。

在 `AuthKit` 中，access token 只保存在 `SessionManager` 的内存状态里，不写入 `UserDefaults`，也不写入 Keychain。

## 为什么 Refresh Token 需要安全存储

Refresh token 的生命周期通常更长，而且可以换取新的 access token。如果 refresh token 泄露，攻击者可能在较长时间内持续恢复会话。

因此 refresh token 必须使用安全存储。在本项目中：

- `AuthKit` 定义 `TokenStoring` 协议。
- `KeychainTokenStore` 使用 `SecurityKit.KeychainStoring` 保存 refresh token。
- refresh token 以 `Data` 形式写入 Keychain。
- token 不存入 `UserDefaults`。

## Logout 时发生什么

用户登出时，客户端需要同时清理两类状态：

- 清空内存中的 access token。
- 删除 Keychain 中保存的 refresh token。

这能确保登出后 App 不能继续调用需要认证的 API，也不能静默刷新出新的 access token。

`SessionManager.logout()` 负责执行这两个动作。

## App 重启时发生什么

App 重启后，内存状态会丢失，所以 access token 不会恢复。

如果 Keychain 中仍然存在 refresh token，App 可以认为“存在可恢复会话”，然后通过服务端刷新接口换取新的 access token。这个过程应该由后续的 AuthService 或网络层协作完成。

在当前实现中，`SessionManager.restoreSessionAfterAppRestart()` 会：

- 清空内存中的 access token。
- 检查 Keychain 中是否存在 refresh token。
- 返回是否存在可恢复会话。

它不会直接生成新的 access token，因为 token 刷新需要服务端参与。
