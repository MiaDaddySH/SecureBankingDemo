# 01 - Authenticated Requests

## Topic Name

Authenticated API requests with access token refresh.

NetworkKit 负责把认证状态应用到网络请求上：普通 API 请求携带 access token；当服务端返回 401 时，客户端尝试刷新 access token，并且只重试原始请求一次。

## What problem does it solve?

它解决的是“access token 过期后，如何让用户无感恢复请求”的问题。

Access token 生命周期应该较短，所以它过期是正常情况。客户端需要在收到 401 后，通过 refresh token 换取新的 access token，再重新发送失败的请求。这样既能保持较好的用户体验，也能避免把长期凭证暴露给每一个业务 API。

## Real-world scenario

用户打开银行 App，Dashboard 调用 `/accounts` 接口。请求头里带着当前 access token：

```text
Authorization: Bearer access-token
```

如果服务端判断 token 已过期，会返回 401。客户端随后使用本地安全存储中的 refresh token 调用刷新接口，拿到新的 access token，然后重试 `/accounts`。

如果刷新失败，客户端应该停止重试，并让上层进入重新登录流程。

## Key APIs

当前 NetworkKit 提供：

- `Endpoint`：描述 path、method、query、headers、body。
- `HTTPMethod`：封装常见 HTTP method。
- `APIClient`：使用 async/await `URLSession.data(for:)` 发送请求。
- `APIClientError`：封装无效 URL、无效响应、HTTP 状态码、缺少 token、刷新失败等错误。
- `AccessTokenProviding`：提供当前内存中的 access token。
- `AccessTokenRefreshing`：执行 access token refresh。
- `AuthenticatedAPIClient`：为请求添加 `Authorization` header，并处理 401 refresh retry。
- 测试中使用 `MockURLProtocol` 模拟服务端响应。

## How this demo uses it

当前实现中，`AuthenticatedAPIClient` 的流程是：

1. 从 `AccessTokenProviding` 读取当前 access token。
2. 把 access token 写入请求头：`Authorization: Bearer <token>`。
3. 使用 `APIClient` 发送请求。
4. 如果响应是 2xx，直接返回数据。
5. 如果响应是 401，调用 `AccessTokenRefreshing.refreshAccessToken()`。
6. 使用新的 access token 重试原始请求一次。
7. 如果刷新失败，抛出 `APIClientError.refreshFailed`。

NetworkKit 不直接保存 refresh token。refresh token 应由 AuthKit 和 SecurityKit 管理，NetworkKit 只依赖协议完成刷新动作。

## Common mistakes

- 把 refresh token 附加到每个业务 API 请求中。
- 401 后无限重试，造成请求风暴或死循环。
- refresh 失败后仍继续发送原始请求。
- 在 NetworkKit 中直接读写 Keychain，破坏模块边界。
- 把 access token 硬编码在 API client 里。
- 不区分 401 和其他 HTTP 错误，导致所有失败都触发 token refresh。

## Interview explanation

可以这样解释：

Access token 是访问 API 的短期凭证，所以每个需要认证的业务请求会把它放在 `Authorization` header 中。Refresh token 是长期续期凭证，风险更高，不应该发送给每个业务 API，而应该只用于专门的刷新流程。

当请求返回 401 时，客户端可以认为 access token 可能过期，于是调用 refresh 流程获取新 access token，然后重试原请求一次。只重试一次很重要，因为如果新 token 仍然失败，可能是 refresh token 失效、账号状态变化或服务端拒绝继续会话；继续无限重试只会掩盖问题并浪费资源。

## Further reading

- Apple Developer Documentation: URLSession
- Apple Developer Documentation: URLProtocol
- RFC 6750: Bearer Token Usage
- OAuth 2.0 Security Best Current Practice
- OWASP Mobile Application Security: Authentication and Session Management
