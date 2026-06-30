# 02 - Biometrics

## Topic Name

Face ID / Touch ID 本地生物识别解锁。

Biometrics 指使用设备上的 Face ID 或 Touch ID 验证当前操作者是否是设备 owner。SecureBankingDemo 使用 `SecurityKit` 封装 `LocalAuthentication.LAContext`，让 App 可以在存在 refresh token 时显示 “Unlock with Face ID”。

## What problem does it solve?

生物识别解决的是“本地重新进入 App 时，如何确认当前拿着设备的人可以解锁本地会话入口”的问题。

它不能证明用户已经通过服务端认证，也不能替代账号密码、OAuth、token refresh 或服务端风控。它只是一个本地门禁：在访问本地保存的 refresh token 或恢复会话之前，先让系统确认当前用户通过了 Face ID / Touch ID。

## Real-world scenario

一个银行 App 登录后保存 refresh token。用户关闭 App 后再次打开，如果 refresh token 仍存在，App 可以显示 “Unlock with Face ID”。

用户通过 Face ID 后，App 才继续使用 refresh token 向服务端换取新的 access token。这样用户不必每次都输入密码，但 refresh token 也不会在没有本地解锁的情况下直接用于恢复会话。

如果 Face ID 不可用、用户取消、设备未录入面容，App 应该回退到账号密码登录。

## Key APIs

本 Demo 涉及的关键 API 和类型：

- `LAContext`：LocalAuthentication 的上下文对象，用来检查和执行本地认证。
- `canEvaluatePolicy(_:error:)`：检查当前设备是否能执行指定认证策略。
- `evaluatePolicy(_:localizedReason:)`：触发系统生物识别认证。
- `LAPolicy.deviceOwnerAuthenticationWithBiometrics`：只允许生物识别，不自动回退到设备密码。
- `LAError`：LocalAuthentication 返回的错误类型，例如用户取消、未录入、锁定、不可用。
- `NSFaceIDUsageDescription`：Info.plist 中必须提供的 Face ID 使用说明。
- `BiometricAuthenticating`：SecurityKit 暴露的协议。
- `BiometricAuthenticator`：基于 `LAContext` 的默认实现。

## How this demo uses it

当前流程：

1. App 启动时，`AppSessionController.prepareLaunch()` 检查 Keychain 中是否存在 refresh token。
2. 如果 refresh token 存在，并且 `BiometricAuthenticator.canAuthenticate()` 返回 true，登录页显示 “Unlock with Face ID”。
3. 用户点击后，App 调用 `BiometricAuthenticator.authenticate(reason:)`。
4. 本地生物识别通过后，App 读取 refresh token。
5. Demo 使用 `MockAuthService.restoreSession(refreshToken:)` 模拟服务端刷新，生成新的 access token。
6. `SessionManager` 把新的 access token 放入内存，并继续保留 refresh token。

这个流程仍然保持模块边界：App 不直接调用 `LocalAuthentication`，而是通过 `SecurityKit.BiometricAuthenticating` 使用生物识别能力。

## Common mistakes

- 把 Face ID 当成服务端登录。Face ID 只证明本地设备验证通过，不证明服务端会话有效。
- 生物识别通过后直接进入业务页，却不刷新或校验服务端会话。
- 忘记配置 `NSFaceIDUsageDescription`，导致 Face ID 调用失败或 App 行为异常。
- 不处理 fallback，例如用户取消、未录入面容、Face ID 被锁定。
- 在 UI 层直接使用 `LAContext`，导致测试困难、模块边界混乱。
- 使用 `.deviceOwnerAuthentication` 时没有意识到它可能回退到设备密码；本 Demo 使用 `.deviceOwnerAuthenticationWithBiometrics`，语义更明确。

## Interview explanation

可以这样解释：

`LAContext` 是 Apple LocalAuthentication 框架中执行本地认证的对象。它可以检查当前设备是否支持 Face ID / Touch ID，也可以触发系统认证弹窗。生物识别适合用作本地解锁，例如 App 重启后允许用户快速解锁本地保存的会话入口。

但 Face ID 不能替代服务端认证。正确做法是：Face ID 通过后，客户端才使用安全存储中的 refresh token 去服务端换取新的 access token。也就是说，Face ID 是本地门禁，后端 token refresh 才是服务端会话恢复。

在架构上，我会把 `LAContext` 封装在 SecurityKit 中，暴露 `BiometricAuthenticating` 协议。App 只依赖协议，测试时可以用 mock，真实运行时使用 `BiometricAuthenticator`。

## Further reading

- Apple Developer Documentation: LocalAuthentication
- Apple Developer Documentation: LAContext
- Apple Developer Documentation: LAError
- Apple Developer Documentation: NSFaceIDUsageDescription
- OWASP Mobile Application Security: Authentication and Session Management
