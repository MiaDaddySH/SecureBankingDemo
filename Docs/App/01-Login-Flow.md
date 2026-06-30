# 01 - 登录与登出流程

## Topic Name

SwiftUI 登录与登出可见流程。

这是 SecureBankingDemo 的第一个可见 App 流程。它使用 `MockAuthService` 模拟登录，不连接真实服务端，也不硬编码真实凭据。

## What problem does it solve?

这个流程解决的是“如何把安全模块和认证模块连接到一个可见 UI 流程里”的问题。

前面的 SecurityKit 和 AuthKit 已经有 Keychain 存储、token store 和 session manager，但用户还看不到这些能力如何协作。登录与登出流程把它们串起来：登录成功后进入 dashboard，登出后清空会话并回到 login。

## Real-world scenario

真实移动 App 通常有类似流程：

1. 用户输入用户名和密码。
2. App 调用登录接口。
3. 服务端返回 access token 和 refresh token。
4. App 把 access token 放在内存中，把 refresh token 存入安全存储。
5. 用户进入业务首页。
6. 用户登出时，App 清理所有本地认证状态。

当前 Demo 用 `MockAuthService` 替代真实登录接口，用来演示流程和模块边界。

## Key APIs

当前 App 流程涉及的主要类型：

- `LoginView`：登录界面。
- `LoginViewModel`：处理登录按钮状态和登录动作。
- `DashboardView`：登录后的简单 dashboard。
- `DashboardViewModel`：处理 dashboard 展示和 logout 动作。
- `AppSessionController`：连接 SwiftUI 导航状态和 AuthKit 会话状态。
- `MockAuthService`：模拟登录成功并返回 `AuthTokens`。
- `AuthKit.SessionManager`：保存内存态 access token，并协调 refresh token 存储。
- `AuthKit.KeychainTokenStore`：通过 Keychain 保存 refresh token。

## How this demo uses it

登录时：

1. `LoginView` 调用 `LoginViewModel.login()`。
2. `LoginViewModel` 调用 `AppSessionController.login()`。
3. `MockAuthService` 返回模拟的 `AuthTokens`。
4. `SessionManager` 把 access token 保存在内存中。
5. `KeychainTokenStore` 把 refresh token 写入 Keychain。
6. `AppSessionController` 把路由切换到 dashboard。

登出时：

1. `DashboardView` 调用 `DashboardViewModel.logout()`。
2. `DashboardViewModel` 调用 `AppSessionController.logout()`。
3. `SessionManager` 清空内存中的 access token。
4. `TokenStoring` 删除 Keychain 中的 refresh token。
5. `AppSessionController` 把路由切回 login。

当前 UI 保持简单，只展示最小登录/登出路径。

## Common mistakes

- 在 SwiftUI View 中直接调用 Keychain 或 `Security.framework`。
- 登录成功后把 access token 写入 `UserDefaults`。
- 登出时只切换 UI，不清理 token。
- 把 mock 登录写得像真实认证，导致学习者误以为 Demo 里有真实安全校验。
- 在 App 模块里加入过多认证细节，绕过 AuthKit 的边界。
- 在 dashboard 中展示完整 token。当前 Demo 只用于学习，真实 App 不应该把 token 显示给用户。

## Interview explanation

可以这样解释：

这个登录流程把 UI、认证状态和安全存储分开。SwiftUI View 只负责展示和触发动作，ViewModel 负责把用户动作转成调用，`AppSessionController` 负责路由和会话协调。真正的 token 生命周期由 AuthKit 的 `SessionManager` 管理：access token 只存在内存里，refresh token 通过 `KeychainTokenStore` 进入 Keychain。

这样做的好处是 UI 不直接依赖 Security framework，安全存储可以被测试替换，登出逻辑也集中在一个地方，避免只切 UI 不清 token 的问题。

## Further reading

- Apple Developer Documentation: SwiftUI
- Apple Developer Documentation: ObservableObject
- Apple Developer Documentation: Keychain Services
- OWASP Mobile Application Security: Authentication and Session Management
