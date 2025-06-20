# API设计文档

## 1. API概述

### 1.1 API设计原则
- RESTful架构风格
- 统一的响应格式
- 版本化管理
- 安全性优先
- 向后兼容

### 1.2 基础信息
- **基础URL**: `https://api.example.com`
- **当前版本**: v1
- **协议**: HTTPS
- **数据格式**: JSON

## 2. 认证与授权

### 2.1 认证方式
```http
Authorization: Bearer {access_token}
```

### 2.2 获取Token
```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "username": "user@example.com",
  "password": "password123"
}

Response:
{
  "code": 200,
  "message": "success",
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "token_type": "Bearer",
    "expires_in": 3600,
    "refresh_token": "dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4..."
  }
}
```

## 3. 通用规范

### 3.1 HTTP方法
| 方法 | 用途 | 幂等性 |
|------|------|--------|
| GET | 获取资源 | 是 |
| POST | 创建资源 | 否 |
| PUT | 完整更新资源 | 是 |
| PATCH | 部分更新资源 | 否 |
| DELETE | 删除资源 | 是 |

### 3.2 状态码
| 状态码 | 含义 | 使用场景 |
|--------|------|----------|
| 200 | OK | 请求成功 |
| 201 | Created | 资源创建成功 |
| 204 | No Content | 删除成功 |
| 400 | Bad Request | 请求参数错误 |
| 401 | Unauthorized | 未认证 |
| 403 | Forbidden | 无权限 |
| 404 | Not Found | 资源不存在 |
| 422 | Unprocessable Entity | 验证失败 |
| 500 | Internal Server Error | 服务器错误 |

### 3.3 响应格式

#### 成功响应
```json
{
  "code": 200,
  "message": "success",
  "data": {
    // 响应数据
  },
  "timestamp": "2024-01-01T12:00:00Z"
}
```

#### 错误响应
```json
{
  "code": 400,
  "message": "Validation failed",
  "errors": [
    {
      "field": "email",
      "code": "invalid_format",
      "message": "邮箱格式不正确"
    }
  ],
  "timestamp": "2024-01-01T12:00:00Z"
}
```

### 3.4 分页规范
```http
GET /api/v1/users?page=1&per_page=20&sort=created_at&order=desc

Response:
{
  "code": 200,
  "message": "success",
  "data": {
    "items": [...],
    "pagination": {
      "page": 1,
      "per_page": 20,
      "total": 100,
      "total_pages": 5
    }
  }
}
```

## 4. API端点详细设计

### 4.1 用户管理

#### 4.1.1 获取用户列表
```http
GET /api/v1/users
```

**请求参数**:
| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| page | integer | 否 | 页码，默认1 |
| per_page | integer | 否 | 每页数量，默认20 |
| keyword | string | 否 | 搜索关键词 |
| status | string | 否 | 用户状态 |

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "items": [
      {
        "id": 1,
        "username": "john_doe",
        "email": "john@example.com",
        "status": "active",
        "created_at": "2024-01-01T12:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "per_page": 20,
      "total": 100,
      "total_pages": 5
    }
  }
}
```

#### 4.1.2 创建用户
```http
POST /api/v1/users
```

**请求体**:
```json
{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "securePassword123",
  "profile": {
    "full_name": "John Doe",
    "phone": "+1234567890"
  }
}
```

**请求验证规则**:
- username: 必填，3-50字符，唯一
- email: 必填，有效邮箱格式，唯一
- password: 必填，至少8字符，包含大小写字母和数字

#### 4.1.3 获取用户详情
```http
GET /api/v1/users/{id}
```

#### 4.1.4 更新用户
```http
PUT /api/v1/users/{id}
```

#### 4.1.5 删除用户
```http
DELETE /api/v1/users/{id}
```

### 4.2 文件上传

#### 4.2.1 上传文件
```http
POST /api/v1/files/upload
Content-Type: multipart/form-data

file: [binary data]
type: avatar
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "file_id": "550e8400-e29b-41d4-a716-446655440000",
    "url": "https://cdn.example.com/files/550e8400-e29b-41d4-a716-446655440000.jpg",
    "size": 1024000,
    "mime_type": "image/jpeg"
  }
}
```

## 5. 批量操作

### 5.1 批量创建
```http
POST /api/v1/users/batch

{
  "users": [
    {"username": "user1", "email": "user1@example.com"},
    {"username": "user2", "email": "user2@example.com"}
  ]
}
```

### 5.2 批量删除
```http
DELETE /api/v1/users/batch

{
  "ids": [1, 2, 3, 4, 5]
}
```

## 6. 搜索与过滤

### 6.1 高级搜索
```http
POST /api/v1/search/users

{
  "filters": {
    "status": ["active", "pending"],
    "created_at": {
      "from": "2024-01-01",
      "to": "2024-12-31"
    }
  },
  "sort": {
    "field": "created_at",
    "order": "desc"
  },
  "page": 1,
  "per_page": 20
}
```

## 7. WebSocket API

### 7.1 连接建立
```javascript
const ws = new WebSocket('wss://api.example.com/ws');

// 认证
ws.send(JSON.stringify({
  type: 'auth',
  token: 'Bearer eyJhbGciOiJIUzI1NiIs...'
}));
```

### 7.2 消息格式
```json
{
  "type": "message",
  "event": "user.updated",
  "data": {
    "user_id": 1,
    "changes": ["profile", "status"]
  },
  "timestamp": "2024-01-01T12:00:00Z"
}
```

## 8. 限流策略

### 8.1 速率限制
- 默认限制: 1000次/小时
- 认证用户: 5000次/小时
- 响应头信息:
```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1640995200
```

## 9. API版本管理

### 9.1 版本策略
- URL路径版本: `/api/v1/`, `/api/v2/`
- 向后兼容期: 至少6个月
- 废弃通知: 提前3个月

### 9.2 版本迁移
```http
Warning: API v1 is deprecated and will be removed on 2025-01-01. Please migrate to v2.
Link: <https://api.example.com/docs/migration/v1-to-v2>; rel="migration-guide"
```

## 10. 错误码参考

| 错误码 | 说明 | 处理建议 |
|--------|------|----------|
| 1001 | 参数缺失 | 检查必填参数 |
| 1002 | 参数格式错误 | 检查参数格式 |
| 2001 | 认证失败 | 重新登录 |
| 2002 | Token过期 | 刷新Token |
| 3001 | 权限不足 | 检查用户权限 |
| 4001 | 资源不存在 | 检查资源ID |
| 5001 | 服务器内部错误 | 稍后重试 |

## 11. SDK示例

### 11.1 JavaScript/TypeScript
```typescript
import { ApiClient } from '@example/api-sdk';

const client = new ApiClient({
  baseURL: 'https://api.example.com',
  token: 'your-access-token'
});

// 获取用户列表
const users = await client.users.list({
  page: 1,
  perPage: 20
});

// 创建用户
const newUser = await client.users.create({
  username: 'john_doe',
  email: 'john@example.com'
});
```

### 11.2 Python
```python
from example_api import Client

client = Client(
    base_url="https://api.example.com",
    token="your-access-token"
)

# 获取用户列表
users = client.users.list(page=1, per_page=20)

# 创建用户
new_user = client.users.create(
    username="john_doe",
    email="john@example.com"
)
```

## 12. 测试环境

### 12.1 Sandbox环境
- URL: `https://sandbox-api.example.com`
- 特性: 数据每天重置，无限制调用

### 12.2 测试账号
- 用户名: `test@example.com`
- 密码: `test123456`
- API Key: `sk_test_xxxxxxxxxxxx`

---
*文档版本*：1.0  
*最后更新*：YYYY-MM-DD  
*API负责人*：[姓名]