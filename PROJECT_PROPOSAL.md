# MoonBit 九月黑客松项目申报说明

## 项目名称

uritemplate.mbt — MoonBit 的 RFC 6570 URI Template 实现

## 项目目标

实现一个无第三方依赖、可复用、可测试的 URI Template 展开库，为 MoonBit
网络请求、API 客户端、代码生成器和 Web 工具补充标准化 URL 构造能力。

## 需求背景

直接拼接 URL 容易遗漏百分号编码、查询参数分隔符和保留字符规则。RFC 6570
定义了统一的 URI 模板语法，已用于 OpenAPI、HAL 等接口描述和超媒体格式。
当前检索未发现 MoonBit 生态中面向 RFC 6570 的独立实现。

## 本期交付范围

1. 支持 RFC 6570 Level 1–4 表达式；
2. 支持字符串、列表和键值映射三种变量类型；
3. 支持 `+ # . / ; ? &` 运算符、前缀截断和 `*` 展开；
4. 正确处理 UTF-8 百分号编码与保留字符；
5. 提供错误信息、API 文档、使用示例和 RFC 测试向量；
6. 在公开仓库保留连续 commits、Issues 和版本记录。

## 验收方式

- `moon check` 完成类型检查；
- `moon test` 运行单元测试及 RFC 示例测试；
- README 中提供复制即可运行的使用示例；
- 对外 API 生成 `.mbti` 接口文件；
- 发布 `v0.1.0` 并记录支持范围及限制。

## 原创与参考说明

代码为 MoonBit 原创实现，行为规范与测试示例参考 RFC 6570。RFC 文档：
https://www.rfc-editor.org/rfc/rfc6570 。项目采用 Apache-2.0 许可证。
