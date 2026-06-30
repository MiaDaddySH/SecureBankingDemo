# 01 - 登录与登出流程

这是 SecureBankingDemo 的第一个可见 App 流程。它使用一个 `MockAuthService` 模拟登录成功，不连接真实服务端，也不硬编码真实凭据。

## 登录时发生什么

用户在 `LoginView` 输入用户名和密码后，`LoginViewModel` 调用 `AppSessionController.login()`。

登录流程：

1. `MockAuthService` 返回一组模拟的 `AuthTokens`。
2. `SessionManager` 把 access token 保存在内存中。
3. `KeychainTokenStore` 通过 `TokenStoring` 把 refresh token 保存到 Keychain。
4. App 状态切换到 dashboard，界面显示 `DashboardView`。

## 为什么 access token 只放内存

Access token 是短生命周期凭证，会被频繁用于 API 请求。把它只保存在内存里，可以减少持久化泄露面。

App 重启后，内存中的 access token 会消失。真实应用会用 Keychain 中的 refresh token 向服务端换取新的 access token。

## 为什么 refresh token 通过 TokenStore 保存

Refresh token 生命周期更长，能用来换取新的 access token，所以不能放进 `UserDefaults`。

当前流程中，App 通过 `AuthKit.KeychainTokenStore` 保存 refresh token。App 不直接调用 `Security.framework`，而是通过 AuthKit 和 SecurityKit 的抽象完成安全存储。

## 登出时发生什么

用户在 `DashboardView` 点击退出登录后：

1. `SessionManager` 清空内存中的 access token。
2. `TokenStoring` 删除 Keychain 中的 refresh token。
3. App 状态切回 login，界面显示 `LoginView`。

这意味着登出后不能继续使用旧 access token，也不能再通过 refresh token 静默恢复会话。

## 当前限制

- `MockAuthService` 只用于演示，不做真实网络请求。
- 当前没有实现 app restart 自动恢复 dashboard。
- 当前没有实现 token refresh 请求。
- 当前 UI 只展示最小登录/登出路径，后续功能会逐步接入 NetworkKit。
