# 01 - Keychain

## Topic Name

Keychain 安全存储。

Keychain 是 Apple 平台提供的系统级安全存储能力，适合保存 token、密码、私钥引用、随机密钥材料等敏感数据。SecureBankingDemo 使用 `SecurityKit` 封装 Keychain，让 App 和业务模块不直接接触 `Security.framework`。

## What problem does it solve?

Keychain 解决的是“敏感数据应该如何持久化保存”的问题。

`UserDefaults` 适合保存偏好设置，例如主题、排序方式、开关状态。它不是安全存储，不应该保存 access token、refresh token、密码或私钥。Keychain 让系统参与保护数据，并允许开发者声明数据在什么设备状态下可以被读取。

在本项目中，Keychain 用来保存 refresh token 这类生命周期较长、泄露风险较高的凭证。

## Real-world scenario

一个真实 App 登录成功后，服务端通常会返回 access token 和 refresh token。

Access token 生命周期短，常用于 API 请求；refresh token 生命周期长，用来换取新的 access token。如果把 refresh token 放进 `UserDefaults`，攻击者在调试、备份分析或越狱环境中更容易拿到它。

更合理的做法是：access token 保留在内存中，refresh token 存入 Keychain。用户登出时，Keychain 中的 refresh token 必须被删除。

## Key APIs

`Security.framework` 中和本 Demo 相关的核心 API 包括：

- `SecItemAdd`：新增 Keychain item。
- `SecItemCopyMatching`：查询 Keychain item。
- `SecItemUpdate`：更新 Keychain item。
- `SecItemDelete`：删除 Keychain item。
- `kSecClassGenericPassword`：表示保存的是 generic password 类型条目。
- `kSecAttrService`：表示条目的服务域，常用于区分 App、模块或功能。
- `kSecAttrAccount`：表示服务域下的具体条目名。
- `kSecAttrAccessible`：声明条目在什么设备状态下可访问。
- `OSStatus`：Keychain API 返回的状态码，例如 `errSecSuccess` 和 `errSecItemNotFound`。

`kSecClassGenericPassword` 虽然名字里有 password，但不只用于密码；token、随机密钥材料等 `Data` 也可以放在这个类型里。

## How this demo uses it

`SecurityKit` 当前提供四个核心类型：

- `KeychainStoring`：协议，定义 `save`、`read`、`delete`。
- `KeychainStore`：基于 `Security.framework` 的实现。
- `KeychainAccessibility`：封装常见 `kSecAttrAccessible` 选项。
- `KeychainError`：封装 Keychain 错误，并保留底层 `OSStatus`。

当前实现只保存 `Data`。这是有意设计：安全存储层不隐藏业务编码格式，调用方需要明确把字符串、模型或 token 转成 `Data`。

`AuthKit.KeychainTokenStore` 通过 `KeychainStoring` 保存 refresh token。App 不直接调用 `Security.framework`。

## Common mistakes

- 把 token、密码或私钥存入 `UserDefaults`。
- 在 `service` 或 `account` 中放入真实 token、密码片段或敏感用户信息。
- 忘记处理 `errSecItemNotFound`。
- 保存时不考虑 `kSecAttrAccessible`，导致锁屏、重启、后台刷新场景下行为不符合预期。
- 在 SecurityKit 中加入业务概念，例如“银行卡”“转账”“用户等级”。
- 认为使用 Keychain 就等于绝对安全。Keychain 能降低风险，但仍需要配合短 token 生命周期、服务端撤销、设备安全和风控策略。

## Interview explanation

可以这样解释：

Keychain 是 Apple 平台用于保存敏感数据的系统级安全存储。相比 `UserDefaults`，它提供更明确的安全语义和访问控制。保存 token 时，我会把短生命周期 access token 放在内存里，把生命周期更长的 refresh token 放在 Keychain，并通过 `kSecAttrAccessible` 决定数据在设备锁定、重启和备份迁移时的行为。

在架构上，我不会让 UI 或业务层直接调用 `Security.framework`。我会在安全模块里定义协议和实现，例如 `KeychainStoring` 和 `KeychainStore`，再让认证模块通过协议依赖它。这样可以保持模块边界清晰，也方便单元测试。

## Further reading

- Apple Developer Documentation: Keychain Services
- Apple Developer Documentation: `SecItemAdd`
- Apple Developer Documentation: `SecItemCopyMatching`
- Apple Developer Documentation: `kSecAttrAccessible`
- OWASP Mobile Application Security: Data Storage
