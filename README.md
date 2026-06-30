# SecureBankingDemo

SecureBankingDemo 是一个模块化的 iOS 安全学习 Demo。项目目标不是提供可直接上线的银行应用，而是用一个接近真实业务边界的示例，帮助学习和演示 iOS 安全能力如何被拆分、封装和组合。

当前阶段只建立项目文档和模块结构，不实现具体安全特性。

## 学习目标

项目后续会逐步演示以下主题：

- 使用 Keychain 安全存储 token
- 使用 LocalAuthentication 完成生物识别解锁
- 使用 CryptoKit 和 AES-GCM 进行本地数据加密
- 使用 Secure Enclave 完成挑战签名
- 抽象 URLSession 信任评估逻辑
- 设计 token refresh 流程
- 使用 Swift Package 组织模块化 iOS 代码

## 架构概览

项目保留四个模块：

| 模块 | 职责 |
| --- | --- |
| SecureBankingDemoApp | SwiftUI Demo App，只负责界面和用户交互 |
| SecurityKit | 安全基础能力，例如 Keychain、Biometrics、CryptoKit、Secure Enclave、Trust Evaluation |
| AuthKit | 认证、token、会话和认证状态管理 |
| NetworkKit | API 请求、Endpoint、认证请求封装、Mock Server 和 token refresh 支持 |

## 模块边界

### SecureBankingDemoApp

- 负责 SwiftUI 界面、Demo 流程和状态展示。
- 不直接调用 Security framework。
- 通过 AuthKit 和 NetworkKit 使用认证与网络能力。

### SecurityKit

- 只提供通用安全能力。
- 不包含用户、账户、交易、会话等业务概念。
- 不依赖 AuthKit、NetworkKit 或 App 模块。

### AuthKit

- 负责认证状态、token 存取抽象和会话管理。
- 可以通过协议依赖 SecurityKit 提供的安全存储能力。
- 不直接处理底层网络请求实现。

### NetworkKit

- 负责网络请求抽象和认证请求封装。
- 可以通过协议与 AuthKit 协作完成 token refresh。
- 不直接保存 secret，不把敏感信息写入 UserDefaults。

## 当前结构

```text
SecureBankingDemo/
├── SecureBankingDemo/          # App 源码，入口类型为 SecureBankingDemoApp
├── Packages/
│   ├── SecurityKit/            # 安全基础能力模块
│   ├── AuthKit/                # 认证与会话模块
│   └── NetworkKit/             # 网络模块
├── SecureBankingDemoTests/
├── SecureBankingDemoUITests/
├── README.md
└── AGENTS.md
```

## 开发约定

- 使用 Swift。
- 优先使用 async/await。
- 优先使用 protocol-oriented design。
- 保持模块独立，避免循环依赖。
- 可复用逻辑需要单元测试。
- 每次新增功能后同步更新文档。
- 不硬编码真实凭据，不把 secret 存入 UserDefaults。

## 提交约定

使用 conventional commits，例如：

- `chore: document project architecture and agent rules`
- `feat(security): add keychain store`
- `test(auth): add token store tests`
- `docs(security): explain keychain accessibility`
