# AGENTS.md

## 项目目标

SecureBankingDemo 是一个模块化的 iOS 安全学习 Demo，用来演示常见移动端安全能力如何在清晰的模块边界内组合使用。

项目后续会逐步覆盖：

- Keychain token 存储
- LocalAuthentication 生物识别解锁
- CryptoKit AES-GCM 加密
- Secure Enclave 挑战签名
- URLSession 信任评估抽象
- Token refresh 流程
- Swift Package 模块化架构

当前阶段只建立项目文档和模块骨架，不实现具体安全特性。

## 模块架构

项目保留四个模块：

1. SecureBankingDemoApp
   - SwiftUI Demo App
   - 只负责界面、状态展示和用户交互
   - 不直接调用 Security framework
   - 通过 AuthKit 和 NetworkKit 使用业务能力

2. SecurityKit
   - 负责安全基础能力
   - 可封装 Keychain、Biometrics、CryptoKit、Secure Enclave、Trust Evaluation
   - 不依赖业务概念，例如用户、账户、会话、银行交易
   - 不依赖 AuthKit、NetworkKit 或 App 模块

3. AuthKit
   - 负责认证和会话相关逻辑
   - 可包含 TokenStore、SessionManager、AuthService、AuthState
   - 可以通过协议依赖安全存储能力
   - 不直接承担网络传输细节

4. NetworkKit
   - 负责网络请求抽象
   - 可包含 APIClient、Endpoint、AuthenticatedAPIClient、Mock Server、Token Refresh 支持
   - 通过协议获取认证状态或 token
   - 不直接保存 secret

## 编码规则

- 使用 Swift。
- 优先使用 async/await。
- 优先使用 protocol-oriented design。
- 保持模块独立，避免循环依赖。
- SecurityKit 必须保持通用，不能包含业务概念。
- 不要把 secret 存入 UserDefaults。
- 不要硬编码真实账号、密码、token、证书私钥或服务端凭据。
- 可复用逻辑需要补充单元测试。
- 每次新增功能后更新相关文档。
- 保持提交小而清晰，使用 conventional commits。

## 文档规则

- 新增功能时，同步更新 README 或模块内文档，说明学习目的、边界和使用方式。
- 涉及安全知识点时，优先使用中文解释，并保留必要英文术语。
- 文档应明确 Demo 目的，避免暗示示例代码可直接用于生产环境。
- 如果暂未实现某个能力，应标注为规划内容，不要写成已完成。

## 提交风格

使用 conventional commits：

- chore:
- feat:
- fix:
- refactor:
- test:
- docs:

示例：

- feat(security): add keychain store
- test(auth): add token store tests
- docs(security): explain keychain accessibility
