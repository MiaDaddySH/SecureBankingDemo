# 01 - Token 生命周期

## Topic Name

Access token 与 refresh token 生命周期管理。

认证系统通常会同时使用 access token 和 refresh token。它们都叫 token，但用途、生命周期和安全要求不同。

## What problem does it solve?

Token 生命周期管理解决的是“如何在用户体验和凭证安全之间取得平衡”的问题。

如果 access token 生命周期太长，一旦泄露，攻击者可以长时间调用 API。如果每次 access token 过期都要求用户重新登录，体验又会很差。Refresh token 的作用是让客户端在合适的时机换取新的 access token，同时把长期凭证放在更安全的位置。

## Real-world scenario

一个移动银行 App 登录成功后，服务端返回两类凭证：

- access token：短生命周期，用于普通 API 请求。
- refresh token：长生命周期，用于换取新的 access token。

用户打开 App 后，App 使用内存中的 access token 调用接口。access token 过期后，App 使用 Keychain 中的 refresh token 请求服务端刷新会话。用户登出时，App 必须同时清空内存中的 access token，并删除 Keychain 中的 refresh token。

## Key APIs

本 Demo 的 AuthKit 当前不直接调用系统安全 API，而是通过协议连接 SecurityKit：

- `AuthTokens`：保存登录后得到的 access token、refresh token 和 access token 过期时间。
- `TokenStoring`：定义 refresh token 的保存、读取和删除接口。
- `KeychainTokenStore`：使用 `SecurityKit.KeychainStoring` 把 refresh token 写入 Keychain。
- `SessionManager`：管理当前会话，保存内存态 access token，并协调 refresh token 的持久化。
- `SecurityKit.KeychainStoring`：SecurityKit 暴露给 AuthKit 的安全存储协议。

## How this demo uses it

当前实现的规则是：

- access token 只存在 `SessionManager` 的内存状态中。
- refresh token 通过 `TokenStoring` 保存。
- 默认实现 `KeychainTokenStore` 使用 Keychain 保存 refresh token。
- 不使用 `UserDefaults` 保存 token。
- logout 会清空 access token，并删除 refresh token。
- app restart 后 access token 不会恢复；如果 Keychain 中仍有 refresh token，后续可以通过服务端刷新接口恢复会话。

当前 Demo 还没有实现真实 token refresh 网络请求，这部分属于后续 NetworkKit/AuthService 的扩展内容。

## Common mistakes

- 把 access token 或 refresh token 存入 `UserDefaults`。
- 让 access token 生命周期过长。
- 把 refresh token 当成普通 API token，到处发送。
- 登出时只清空内存状态，却忘记删除 refresh token。
- App 重启后直接假设用户仍然已登录，而不检查 refresh token 和服务端会话状态。
- 在 AuthKit 中直接写死 Keychain 细节，导致测试困难、模块边界变模糊。

## Interview explanation

可以这样解释：

Access token 是短生命周期访问凭证，主要用于调用 API；refresh token 是长期续期凭证，用来换取新的 access token。因为 access token 暴露面更大，所以应该短生命周期并尽量只放内存。Refresh token 能恢复会话，风险更高，因此需要用 Keychain 这类安全存储保存。

在实现上，我会让 `SessionManager` 管理内存态 access token，让 `TokenStoring` 抽象 refresh token 存储，再用 `KeychainTokenStore` 作为生产实现。这样既能保证“不用 UserDefaults 存 token”，也能通过 mock store 做单元测试。

## Further reading

- OAuth 2.0: Refresh Token
- OAuth 2.0 Security Best Current Practice
- OWASP Mobile Application Security: Authentication and Session Management
- Apple Developer Documentation: Keychain Services
