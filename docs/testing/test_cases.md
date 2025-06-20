# 测试用例文档

## 1. 测试用例概述

### 1.1 文档说明
本文档包含系统各模块的详细测试用例，用于指导测试执行和自动化脚本编写。

### 1.2 用例编写规范
- 用例ID格式：TC_模块_功能_序号
- 优先级定义：P0(冒烟)、P1(核心)、P2(重要)、P3(一般)
- 执行方式：手工/自动化
- 测试类型：功能/性能/安全/兼容性

## 2. 用户管理模块

### 2.1 用户注册

#### TC_USER_REG_001
- **测试标题**：正常注册流程测试
- **优先级**：P0
- **前置条件**：无
- **测试数据**：
  ```json
  {
    "username": "testuser001",
    "email": "test001@example.com",
    "password": "Test@123456"
  }
  ```
- **测试步骤**：
  1. 访问注册页面
  2. 输入用户名、邮箱、密码
  3. 点击注册按钮
- **预期结果**：
  - 注册成功，自动登录
  - 跳转到欢迎页面
  - 数据库创建用户记录

#### TC_USER_REG_002
- **测试标题**：重复用户名注册测试
- **优先级**：P1
- **前置条件**：已存在用户名"existuser"
- **测试步骤**：
  1. 使用已存在的用户名注册
  2. 填写其他有效信息
  3. 提交注册
- **预期结果**：
  - 注册失败
  - 提示"用户名已存在"
  - 保持在注册页面

### 2.2 用户登录

#### TC_USER_LOGIN_001
- **测试标题**：正常登录测试
- **优先级**：P0
- **测试类型**：功能测试
- **自动化脚本**：
  ```python
  def test_normal_login():
      driver.get(f"{BASE_URL}/login")
      driver.find_element(By.ID, "username").send_keys("testuser")
      driver.find_element(By.ID, "password").send_keys("Test@123")
      driver.find_element(By.ID, "login-btn").click()
      
      assert "dashboard" in driver.current_url
      assert driver.find_element(By.CLASS_NAME, "user-info").is_displayed()
  ```

#### TC_USER_LOGIN_002
- **测试标题**：密码错误登录测试
- **优先级**：P1
- **测试步骤**：
  1. 输入正确用户名
  2. 输入错误密码
  3. 点击登录
- **预期结果**：
  - 登录失败
  - 显示错误提示"用户名或密码错误"
  - 清空密码输入框

### 2.3 密码重置

#### TC_USER_PWD_001
- **测试标题**：忘记密码流程测试
- **优先级**：P1
- **测试流程**：
  ```mermaid
  graph TD
      A[点击忘记密码] --> B[输入邮箱]
      B --> C[发送重置邮件]
      C --> D[检查邮箱]
      D --> E[点击重置链接]
      E --> F[设置新密码]
      F --> G[使用新密码登录]
  ```

## 3. 业务功能模块

### 3.1 数据查询

#### TC_BIZ_QUERY_001
- **测试标题**：条件查询测试
- **优先级**：P0
- **测试数据集**：
  | 查询条件 | 预期结果数 | 响应时间要求 |
  |---------|-----------|-------------|
  | status=active | >0 | <200ms |
  | date=today | >=0 | <200ms |
  | keyword=test | >=0 | <500ms |

### 3.2 数据导出

#### TC_BIZ_EXPORT_001
- **测试标题**：Excel导出功能测试
- **优先级**：P1
- **测试步骤**：
  1. 执行查询获取数据
  2. 点击"导出Excel"按钮
  3. 等待文件下载
- **验证点**：
  - [ ] 文件格式正确(.xlsx)
  - [ ] 数据完整性
  - [ ] 列标题正确
  - [ ] 数据格式正确(日期、数字等)

## 4. API接口测试

### 4.1 RESTful API测试

#### TC_API_USER_001
- **测试标题**：获取用户列表API
- **接口地址**：GET /api/v1/users
- **请求参数**：
  ```json
  {
    "page": 1,
    "per_page": 10,
    "sort": "created_at",
    "order": "desc"
  }
  ```
- **测试脚本**：
  ```python
  def test_get_users_api():
      response = requests.get(
          f"{API_BASE_URL}/users",
          headers={"Authorization": f"Bearer {token}"},
          params={"page": 1, "per_page": 10}
      )
      
      assert response.status_code == 200
      data = response.json()
      assert "items" in data["data"]
      assert len(data["data"]["items"]) <= 10
      assert data["data"]["pagination"]["page"] == 1
  ```

### 4.2 GraphQL API测试

#### TC_API_GQL_001
- **测试标题**：GraphQL查询测试
- **查询语句**：
  ```graphql
  query GetUser($id: ID!) {
    user(id: $id) {
      id
      username
      email
      profile {
        fullName
        avatar
      }
    }
  }
  ```
- **变量**：
  ```json
  {
    "id": "123"
  }
  ```

## 5. 性能测试用例

### 5.1 负载测试

#### TC_PERF_LOAD_001
- **测试标题**：登录接口负载测试
- **测试目标**：
  - 并发用户数：100
  - 持续时间：10分钟
  - 成功率要求：>99%
- **JMeter配置**：
  ```xml
  <ThreadGroup>
    <stringProp name="ThreadGroup.num_threads">100</stringProp>
    <stringProp name="ThreadGroup.ramp_time">60</stringProp>
    <stringProp name="ThreadGroup.duration">600</stringProp>
  </ThreadGroup>
  ```

### 5.2 压力测试

#### TC_PERF_STRESS_001
- **测试标题**：系统压力测试
- **测试策略**：
  1. 初始并发：50用户
  2. 每5分钟增加50用户
  3. 直到系统响应时间>5秒或错误率>5%
  4. 记录系统极限值

## 6. 安全测试用例

### 6.1 认证安全

#### TC_SEC_AUTH_001
- **测试标题**：SQL注入测试
- **测试点**：登录接口
- **测试数据**：
  ```
  username: admin' OR '1'='1
  password: anything
  ```
- **预期结果**：登录失败，系统正常响应

### 6.2 权限控制

#### TC_SEC_PERM_001
- **测试标题**：越权访问测试
- **测试场景**：普通用户访问管理员接口
- **测试步骤**：
  1. 使用普通用户Token
  2. 调用管理员专用API
  3. 验证返回403错误

## 7. 兼容性测试

### 7.1 浏览器兼容性

#### TC_COMP_BROWSER_001
- **测试标题**：Chrome浏览器兼容性
- **测试范围**：
  - 版本：最新版、最新版-1、最新版-2
  - 分辨率：1920x1080、1366x768、1024x768
- **测试点清单**：
  - [ ] 页面布局正常
  - [ ] JavaScript功能正常
  - [ ] CSS样式正确
  - [ ] 响应式布局正常

### 7.2 移动端兼容性

#### TC_COMP_MOBILE_001
- **测试标题**：移动端适配测试
- **测试设备**：
  | 设备 | 系统版本 | 分辨率 |
  |------|---------|--------|
  | iPhone 12 | iOS 14+ | 1170x2532 |
  | Samsung S21 | Android 11+ | 1080x2400 |
  | iPad Pro | iPadOS 14+ | 2048x2732 |

## 8. 自动化测试集

### 8.1 冒烟测试集
```yaml
smoke_test_suite:
  - TC_USER_LOGIN_001
  - TC_USER_REG_001
  - TC_BIZ_QUERY_001
  - TC_API_USER_001
  
execution_time: 5 minutes
pass_criteria: 100%
```

### 8.2 回归测试集
```yaml
regression_test_suite:
  includes:
    - all P0 test cases
    - all P1 test cases
    - critical P2 test cases
  
execution_time: 2 hours
pass_criteria: >95%
parallel_execution: true
```

## 9. 测试数据管理

### 9.1 测试数据分类
| 数据类型 | 存储位置 | 更新频率 | 负责人 |
|---------|---------|---------|--------|
| 基础数据 | test_data.json | 每个版本 | QA |
| 用户数据 | database | 每日重置 | DevOps |
| 性能数据 | data_generator | 按需生成 | QA |

### 9.2 数据生成脚本
```python
# 批量生成测试用户数据
def generate_test_users(count=100):
    users = []
    for i in range(count):
        users.append({
            "username": f"test_user_{i:04d}",
            "email": f"test{i:04d}@example.com",
            "password": "Test@123456",
            "role": random.choice(["user", "admin", "guest"])
        })
    return users
```

## 10. 用例维护

### 10.1 用例评审标准
- 用例描述清晰明确
- 测试步骤详细可执行
- 预期结果具体可验证
- 测试数据完整准确

### 10.2 用例更新规则
- 需求变更后24小时内更新相关用例
- 发现缺陷后补充相应测试用例
- 定期（每月）评审和优化用例
- 自动化脚本与用例文档保持同步

---
*文档版本*：1.0  
*最后更新*：YYYY-MM-DD  
*测试负责人*：[姓名]