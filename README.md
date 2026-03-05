# 遗留系统迁移项目

## 项目概述
本项目用于将部分遗留服务从旧的基础设施迁移到新的云原生架构。项目包含过渡性代码、配置和文档，旨在帮助团队逐步替换过时的系统组件。

**项目状态**: 维护模式（有限支持）  
**最后更新**: 2024-08-15  
**维护团队**: 平台工程部 - 遗留系统组  
**联系方式**: legacy-support@xinlan.com  

## 主要组件

### 1. terraform/
基础设施即代码配置，用于管理过渡环境的资源。

- **main.tf**: 主要资源配置文件
  - 测试用VPC和子网
  - 遗留应用服务器 (CVM)
  - 网络和安全组配置
- **modules/monitor/**: 监控模块（部分已过时）
  - outputs.tf: 输出过时的监控指标

**注意**: 部分配置已过时，仅用于参考和测试目的。

### 2. ci/
持续集成配置，从旧的 Jenkins 流水线迁移而来。

- **.gitlab-ci.yml**: GitLab CI/CD 配置文件
  - 旧构建流程 (Maven 3.6 + JDK 8)
  - 废弃的测试阶段
  - 旧部署步骤
  - 产物清理

**迁移状态**: 已完成，但部分作业已标记为弃用。

### 3. docs/
项目文档和历史规范存档。

- **old-api-specs/v0.8.md**: 已废弃的 API 规范
  - 旧版用户接口
  - 不安全的文件上传接口
  - 已知的安全漏洞说明

**重要性**: 仅供历史参考，新开发不应使用。

### 4. scripts/
维护和运维脚本集合。

- **backup-db.sh**: 旧版数据库备份脚本
  - 使用已弃用的 mysqldump 参数
  - 硬编码的数据库凭证
  - 旧的加密方式

**警告**: 此脚本存在安全风险，建议使用新的 backup-manager。

### 5. config/
环境配置文件和示例。

- **staging.env**: 预发布环境配置示例
  - 数据库连接信息
  - 缓存配置
  - 功能开关
  - 监控配置

**安全提示**: 配置文件中的凭证均为示例，实际部署前必须替换。

## 快速开始

### 前提条件
1. Terraform v0.12+（与旧版本兼容性未测试）
2. Tencent Cloud 账户和凭证
3. GitLab Runner 配置
4. MySQL 5.7+（用于测试旧版本兼容性）

### 部署步骤
1. 克隆仓库
git clone https://gitlab.company.com/legacy/legacy-migration.git
cd legacy-migration
2. 初始化 Terraform
terraform init
terraform plan -var-file=terraform.tfvars.example
3. 应用基础设施（仅限测试环境）
terraform apply -target=tencentcloud_vpc.unused_vpc
4. 运行旧构建流程（手动触发）
在 GitLab CI/CD 中手动运行 legacy_build 作业
