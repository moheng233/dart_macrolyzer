# Dart Macrolyzer Lsp

## 概念说明

### 上行服务器 （ `upstream` ）
指作为实际提供代码补全等操作的 `analyzer_server` 服务器

### 下行服务器 （ `downstream` ）
指作为中间层的用来劫持对 `upstream` 操作的服务器
