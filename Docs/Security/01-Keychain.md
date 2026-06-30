# 01 - Keychain

Keychain 是 iOS、iPadOS、macOS 等 Apple 平台提供的安全存储系统，适合保存 token、密码、私钥引用等敏感数据。SecureBankingDemo 使用 `SecurityKit` 封装 Keychain，让 App 和业务模块不需要直接调用 `Security.framework`。

## 为什么不用 UserDefaults

`UserDefaults` 适合保存偏好设置，例如开关状态、排序方式、上次打开的页面等。它不适合保存 secret。

常见原因：

- `UserDefaults` 不是为敏感数据设计的。
- 数据通常以 plist 形式保存，容易被调试、备份或导出时看到。
- 它没有 Keychain 的访问控制、设备锁定状态保护和系统级安全语义。
- 把 token 放进 `UserDefaults` 容易让后续代码误以为 token 只是普通配置。

Keychain 的价值在于：它把“敏感数据”作为一等概念处理，并允许开发者声明数据在什么设备状态下可以被读取。

## kSecClassGenericPassword 是什么

`kSecClassGenericPassword` 表示 Keychain item 的类型是“通用密码”。

虽然名字里有 password，但它不只能保存密码。常见的 token、refresh token、随机密钥材料等 `Data` 值，也可以用 generic password item 保存。

在 `KeychainStore` 中，保存、读取、删除都使用：

```swift
kSecClass as String: kSecClassGenericPassword
```

这告诉 Keychain：本次操作面向通用密码类型的条目。

## kSecAttrService 和 kSecAttrAccount 是什么

`kSecAttrService` 和 `kSecAttrAccount` 一起用于定位一个 Keychain item。

- `kSecAttrService`：通常表示应用、模块或功能域，例如 `com.example.bank.auth`。
- `kSecAttrAccount`：通常表示这个 service 下的具体账号或条目名，例如 `accessToken`、`refreshToken`。

可以把它们理解成一个组合键：

```text
service + account -> keychain item
```

在 Demo 中，建议 service 使用稳定、可读、带命名空间的字符串；account 使用能表达用途的名字，避免使用真实用户密码或 token 片段作为 account。

## kSecAttrAccessible 是什么

`kSecAttrAccessible` 用来声明 Keychain item 什么时候可以被系统解密和读取。

常见选项包括：

- `kSecAttrAccessibleWhenUnlocked`：设备解锁时可访问。
- `kSecAttrAccessibleAfterFirstUnlock`：设备重启后，用户第一次解锁之后可访问。
- `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly`：仅当设备设置了密码时可用，并且不会迁移到其他设备。
- `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`：设备解锁时可访问，并且不会迁移到其他设备。
- `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`：首次解锁后可访问，并且不会迁移到其他设备。

`ThisDeviceOnly` 选项通常更适合高敏感数据，因为这些数据不会通过备份迁移到新设备。代价是用户换设备或恢复备份后，需要重新登录或重新生成对应数据。

## 当前实现

`SecurityKit` 提供：

- `KeychainStoring`：协议，定义 `save`、`read`、`delete`。
- `KeychainStore`：基于 `Security.framework` 的实现。
- `KeychainAccessibility`：封装常见 `kSecAttrAccessible` 选项。
- `KeychainError`：封装常见错误，并保留底层 `OSStatus`。

当前只支持保存 `Data`，这是刻意选择：调用方需要明确处理编码和解码，避免在安全存储层隐藏业务格式。

## 常见错误

- 把 token 存入 `UserDefaults`。
- 使用真实账号、密码、token 片段作为 `service` 或 `account`。
- 忘记处理 `errSecItemNotFound`。
- 保存前不考虑 `kSecAttrAccessible`，导致锁屏、重启或后台刷新场景行为不符合预期。
- 在 SecurityKit 中加入业务概念，例如“银行卡”“转账”“用户等级”。
- 认为 Keychain 等于绝对安全。Keychain 能降低风险，但仍需要配合最小权限、合理过期时间、token refresh、设备完整性和服务端风控。
