# 数据库设计文档

## 1. 数据库概述

### 1.1 设计目标
- 数据完整性
- 查询性能优化
- 可扩展性
- 数据安全性

### 1.2 数据库选型
| 数据类型 | 数据库选择 | 选择理由 |
|---------|-----------|----------|
| 关系型数据 | PostgreSQL/MySQL | ACID特性，事务支持 |
| 缓存数据 | Redis | 高性能，支持多种数据结构 |
| 文档数据 | MongoDB | 灵活的文档结构 |
| 时序数据 | InfluxDB | 时间序列数据优化 |

## 2. 数据模型设计

### 2.1 概念模型 (ER图)
```
┌──────────┐      1:N      ┌──────────┐
│   User   │───────────────│  Order   │
└──────────┘               └──────────┘
     │                           │
     │ 1:N                       │ 1:N
     │                           │
┌──────────┐               ┌──────────┐
│ Profile  │               │OrderItem │
└──────────┘               └──────────┘
```

### 2.2 逻辑模型

#### 2.2.1 用户相关表

```sql
-- 用户基础信息表
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    status SMALLINT DEFAULT 1, -- 1:活跃 0:禁用
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_created_at (created_at)
);

-- 用户详情表
CREATE TABLE user_profiles (
    user_id BIGINT PRIMARY KEY,
    full_name VARCHAR(100),
    avatar_url VARCHAR(500),
    phone VARCHAR(20),
    bio TEXT,
    metadata JSONB,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 用户角色表
CREATE TABLE user_roles (
    id SERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    role_id INT NOT NULL,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE KEY uk_user_role (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id)
);
```

#### 2.2.2 权限相关表

```sql
-- 角色表
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    is_system BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 权限表
CREATE TABLE permissions (
    id SERIAL PRIMARY KEY,
    resource VARCHAR(100) NOT NULL,
    action VARCHAR(50) NOT NULL,
    description TEXT,
    
    UNIQUE KEY uk_resource_action (resource, action)
);

-- 角色权限关联表
CREATE TABLE role_permissions (
    role_id INT NOT NULL,
    permission_id INT NOT NULL,
    
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
);
```

### 2.3 物理模型优化

#### 2.3.1 索引设计
```sql
-- 复合索引
CREATE INDEX idx_users_status_created ON users(status, created_at DESC);

-- 部分索引
CREATE INDEX idx_active_users ON users(username) WHERE status = 1;

-- 函数索引
CREATE INDEX idx_users_email_lower ON users(LOWER(email));
```

#### 2.3.2 分区策略
```sql
-- 按时间范围分区
CREATE TABLE orders (
    id BIGSERIAL,
    user_id BIGINT NOT NULL,
    order_date DATE NOT NULL,
    total_amount DECIMAL(10,2),
    PRIMARY KEY (id, order_date)
) PARTITION BY RANGE (order_date);

-- 创建分区
CREATE TABLE orders_2024_01 PARTITION OF orders
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
```

## 3. 数据完整性

### 3.1 约束设计
- **主键约束**: 确保唯一标识
- **外键约束**: 维护引用完整性
- **唯一约束**: 防止重复数据
- **检查约束**: 业务规则验证
- **非空约束**: 必填字段控制

### 3.2 触发器
```sql
-- 自动更新时间戳
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();
```

## 4. 性能优化

### 4.1 查询优化
- 使用 EXPLAIN ANALYZE 分析查询计划
- 避免 SELECT *
- 合理使用 JOIN
- 使用预编译语句

### 4.2 存储优化
- 选择合适的数据类型
- 规范化 vs 反规范化权衡
- 使用压缩技术
- 定期清理无用数据

### 4.3 缓存策略
```
查询流程:
Client -> Cache -> Database
  ↑                    ↓
  └────────────────────┘
```

## 5. 备份与恢复

### 5.1 备份策略
- **全量备份**: 每周一次
- **增量备份**: 每天一次
- **事务日志备份**: 每小时一次

### 5.2 恢复策略
- **RPO** (Recovery Point Objective): 1小时
- **RTO** (Recovery Time Objective): 2小时

## 6. 安全设计

### 6.1 访问控制
- 最小权限原则
- 角色基础访问控制 (RBAC)
- 行级安全 (RLS)

### 6.2 数据加密
- 传输加密: SSL/TLS
- 存储加密: 透明数据加密 (TDE)
- 敏感字段加密

### 6.3 审计日志
```sql
CREATE TABLE audit_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT,
    action VARCHAR(50),
    resource_type VARCHAR(50),
    resource_id VARCHAR(100),
    old_value JSONB,
    new_value JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

## 7. 数据迁移

### 7.1 迁移工具
- Flyway
- Liquibase
- 自定义迁移脚本

### 7.2 迁移版本管理
```sql
CREATE TABLE schema_migrations (
    version VARCHAR(50) PRIMARY KEY,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description TEXT
);
```

## 8. 监控指标

### 8.1 性能指标
- 查询响应时间
- 连接池使用率
- 锁等待时间
- 缓存命中率

### 8.2 容量指标
- 表大小增长趋势
- 索引使用情况
- 磁盘空间使用率

## 9. 最佳实践

### 9.1 命名规范
- 表名: 小写，复数形式，下划线分隔
- 列名: 小写，下划线分隔
- 索引: idx_表名_列名
- 外键: fk_子表_父表

### 9.2 数据类型选择
| 数据类型 | 使用场景 |
|---------|----------|
| BIGINT | 主键、外键 |
| VARCHAR | 可变长度字符串 |
| TEXT | 长文本 |
| JSONB | 半结构化数据 |
| TIMESTAMP WITH TIME ZONE | 时间戳 |

---
*文档版本*：1.0  
*最后更新*：YYYY-MM-DD  
*数据库架构师*：[姓名]