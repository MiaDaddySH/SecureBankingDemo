# 03 - CryptoKit AES-GCM

## Topic Name

使用 CryptoKit 和 AES-GCM 加密本地 Secure Notes。

SecureBankingDemo 使用 `SecurityKit.AESGCMCryptoService` 加密笔记内容，并把对称加密密钥保存到 Keychain。App 只把密文保存到本地文件。

## What problem does it solve?

它解决的是“本地敏感内容如何加密保存”的问题。

如果 App 需要保存用户的私密笔记、草稿或离线数据，直接把明文写入文件会增加泄露风险。加密后，即使攻击者拿到本地文件，也只能看到 ciphertext。真正需要保护的是 encryption key。

## Real-world scenario

一个银行 App 允许用户保存一条本地备注。备注内容可能包含敏感信息，例如转账说明、账号别名或私人提醒。

合理做法是：

1. App 生成一个随机对称密钥。
2. 密钥保存到 Keychain。
3. 笔记内容用 AES-GCM 加密。
4. 本地文件只保存密文。
5. 读取时先从 Keychain 取出密钥，再解密密文。

## Key APIs

当前实现涉及：

- `CryptoKit.SymmetricKey`：对称密钥。
- `CryptoKit.AES.GCM.seal`：使用 AES-GCM 加密并生成认证标签。
- `CryptoKit.AES.GCM.open`：验证认证标签并解密。
- `AES.GCM.SealedBox.combined`：把 nonce、ciphertext、tag 打包成一个 `Data`。
- `KeychainStoring`：保存和读取对称密钥。
- `CryptoServicing`：SecurityKit 暴露的加密服务协议。
- `AESGCMCryptoService`：CryptoKit AES-GCM 的默认实现。

## How this demo uses it

Secure Notes 流程：

1. 用户在 Dashboard 的 Secure Notes 区域输入笔记。
2. `SecureNoteRepository` 调用 `CryptoServicing.encrypt(_:)`。
3. `AESGCMCryptoService` 从 Keychain 读取对称密钥；如果不存在，就生成 256-bit 随机密钥并保存。
4. 笔记明文通过 AES-GCM 加密。
5. App 把加密后的 `Data` 写入本地文件。
6. 读取时，Repository 读取密文文件并调用 `decrypt(_:)`。
7. 解密成功后，UI 显示明文。

这个 Demo 中，密文可以保存在本地文件里；密钥必须放在 Keychain 中。

## Common mistakes

- 把 encryption key 硬编码在源码里。
- 把 key 和 ciphertext 放在同一个普通文件里。
- 把 hashing 当成 encryption。Hash 不能还原明文，加密可以用 key 解密回明文。
- 使用没有认证能力的加密模式，导致密文被篡改时不容易发现。
- 复用固定 nonce。AES-GCM 每次加密都应使用新的 nonce，CryptoKit 默认会生成安全 nonce。
- 捕获解密失败后直接返回空字符串，掩盖 key 错误或密文被篡改的问题。

## Interview explanation

可以这样解释：

Hashing 和 encryption 的目的不同。Hashing 是单向摘要，适合校验完整性或保存密码摘要；encryption 是可逆保护，适合保存之后还需要读回明文的数据。Secure Notes 需要读回原文，所以应该使用 encryption。

AES-GCM 很适合这种场景，因为它同时提供机密性和完整性校验。解密时如果 key 不对、ciphertext 被改过或 tag 校验失败，CryptoKit 会抛错。密文可以存本地文件，但 key 不能硬编码，也不应该和密文放在一起；本 Demo 把 key 存入 Keychain。

## Further reading

- Apple Developer Documentation: CryptoKit
- Apple Developer Documentation: AES.GCM
- Apple Developer Documentation: SymmetricKey
- Apple Developer Documentation: Keychain Services
- OWASP Mobile Application Security: Cryptography
