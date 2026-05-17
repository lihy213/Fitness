# FitTracker 团队 Git 规范与代码质量标准

> 适合前端/Web 团队转型 HarmonyOS 开发使用
> 零基础说明：Git 是一个"时光机器"——记录每次代码修改，随时可以回到过去的版本

---

## 一、Git 分支策略

### 分支模型（基于 Git Flow 简化版）

```
main          ← 【生产分支】只存放稳定发布版本，不直接提交代码
  │
  └── develop ← 【开发主干】所有功能最终合并到这里
        │
        ├── feature/checkin-system   ← 开发新功能
        ├── feature/weight-chart     ← 开发体重图表
        ├── feature/workout-record   ← 开发训练记录
        │
        ├── bugfix/fix-streak-calc   ← 修复普通 bug
        │
        └── hotfix/crash-on-login    ← 修复紧急 bug（从 main 分支出来）
```

### 分支命名规则

| 类型 | 格式 | 示例 |
|------|------|------|
| 功能开发 | `feature/功能名` | `feature/checkin-calendar` |
| Bug 修复 | `bugfix/问题描述` | `bugfix/weight-chart-crash` |
| 紧急修复 | `hotfix/问题描述` | `hotfix/login-null-pointer` |
| 发布版本 | `release/版本号` | `release/1.0.0` |

### 分支操作流程（口诀：从哪来，回哪去）

```bash
# 1. 开始新功能（从 develop 分支出去）
git checkout develop
git pull origin develop        # 先拉最新代码，避免冲突
git checkout -b feature/checkin-system

# 2. 开发过程中定期推送
git add .
git commit -m "feat: 完成打卡日历组件"
git push origin feature/checkin-system

# 3. 功能完成，提交 Pull Request（PR）到 develop
# 在 GitHub/Gitee 上发起 PR，等待 Code Review

# 4. 不要直接 merge，等代码审查通过后由负责人合并
```

---

## 二、Commit 提交规范

### 格式

```
类型(范围): 简短描述（中文，不超过50字）

[可选] 详细说明（换行后写，解释为什么这么改）

[可选] 关联的任务编号：Closes #123
```

### 类型说明

| 类型 | 用途 | 示例 |
|------|------|------|
| `feat` | 新功能 | `feat(打卡): 添加连续打卡天数计算` |
| `fix` | 修复 bug | `fix(体重): 修复 BMI 计算在身高为空时崩溃` |
| `style` | 样式调整（不影响逻辑） | `style(首页): 调整打卡按钮圆角和颜色` |
| `refactor` | 代码重构（不新增功能，不修 bug） | `refactor(数据库): 将 DAO 层抽取为独立文件` |
| `docs` | 更新文档 | `docs: 更新数据库设计文档` |
| `test` | 添加测试 | `test(打卡): 添加连续打卡逻辑单元测试` |
| `chore` | 构建配置、依赖更新 | `chore: 升级 AGC SDK 到 1.9.0` |
| `perf` | 性能优化 | `perf(图表): 减少体重图表重绘次数` |

### 好的 Commit vs 坏的 Commit

```
坏的（看了不知道改了什么）：
  git commit -m "修改了一些东西"
  git commit -m "update"
  git commit -m "bug fix"

好的（一眼明白做了什么）：
  git commit -m "feat(训练记录): 实现卧推历史最佳重量对比显示"
  git commit -m "fix(体重图表): 修复周视图在无数据时显示空白的问题"
  git commit -m "refactor(数据库): 将 WeightDao 从 service 层抽离，遵循单一职责原则"
```

---

## 三、Code Review（代码审查）流程

### 为什么要 Code Review？

> 就像写完文章要让人校对一样——自己看自己的代码容易忽略问题，另一个人看10分钟可能发现你看了10小时没发现的 bug。

### PR（Pull Request）提交要求

PR 标题格式：`[类型] 简短描述`
例如：`[feat] 实现打卡模块 - 包含日历视图和连续天数计算`

PR 描述模板（每次提交 PR 都要填写）：
```markdown
## 改了什么
- 实现了打卡日历组件（CheckinCalendarComponent）
- 添加了连续打卡天数计算逻辑（CheckinService）
- 集成了每日提醒通知功能

## 为什么这样改
连续打卡的 streak 计算需要查询前一天的记录，
采用递归查询会导致性能问题，改为一次性查询最近30天数据在内存里计算。

## 如何测试
1. 打开 APP，进入首页
2. 点击打卡按钮
3. 关闭 APP 重新打开，验证连续天数 +1
4. 跳过一天后验证 streak 重置为 1

## 相关截图（UI 改动必须附图）
[附上截图]
```

### Reviewer（代码审查者）检查清单

```
功能正确性：
  □ 代码逻辑是否实现了需求描述的功能？
  □ 边界情况是否处理（空数据、网络失败、用户未登录等）？

代码质量：
  □ 函数/变量命名是否清晰（看名字能猜到用途）？
  □ 单个函数是否超过50行？（超过说明要拆分）
  □ 是否有重复代码？（重复3次以上就要提取公共函数）

性能：
  □ 数据库查询是否在子线程（不能在主线程查数据库）？
  □ 列表渲染是否使用懒加载（LazyForEach）？

安全：
  □ 用户数据是否有权限保护？
  □ 是否有硬编码的密钥或密码（绝对不允许）？
```

---

## 四、ArkTS 代码规范

> 这部分对你（有 Python/C 基础）尤其重要，ArkTS 有很多新概念

### 4.1 命名规范

```typescript
// 文件名：PascalCase（大驼峰）
// HomePage.ets, WeightService.ets, CheckinDao.ets

// 类名：PascalCase
class WeightRecord { }
class CheckinService { }

// 函数名、变量名：camelCase（小驼峰）
// 对比 Python 的 snake_case（下划线），ArkTS 用驼峰
let weightKg: number = 72.5       // Python: weight_kg = 72.5
function calculateBmi() { }       // Python: def calculate_bmi():

// 常量：UPPER_SNAKE_CASE（全大写+下划线）
const MAX_STREAK_DAYS = 365
const DATABASE_NAME = 'fittracker.db'

// 布尔变量：用 is/has/can 前缀
let isCheckedIn: boolean = false
let hasWorkoutToday: boolean = true
```

### 4.2 类型声明（ArkTS 比 Python 更严格）

```typescript
// 错误写法（ArkTS 不允许隐式 any）
let data = fetchData()          // 不知道是什么类型

// 正确写法（明确声明类型）
let weight: number = 72.5
let userName: string = '张三'
let records: WeightRecord[] = []   // WeightRecord 数组

// 接口（相当于 Python 的 dataclass，定义数据结构）
interface WeightRecord {
  id: number
  date: string
  weightKg: number
  bmi?: number                  // ? 表示可选字段（Python: Optional[float]）
}
```

### 4.3 异步操作规范（重点！数据库和网络都是异步的）

```typescript
// ArkTS 的异步 = Python 的 asyncio

// 错误写法（同步执行会卡死界面）
// 想象成：在收银台结账时，让所有顾客等你查库存——不行！
queryDatabase()  // 直接调用，卡死

// 正确写法一：async/await（推荐，最像 Python 的写法）
async function loadWeightData(): Promise<WeightRecord[]> {
  try {
    const records = await WeightDao.queryAll()   // await = Python 的 await
    return records
  } catch (error) {
    console.error('加载体重数据失败:', error)
    return []
  }
}

// 正确写法二：Promise 链式调用
WeightDao.queryAll()
  .then(records => {
    this.weightList = records
  })
  .catch(error => {
    console.error('失败:', error)
  })
```

### 4.4 组件规范

```typescript
// 每个 ArkTS 组件文件的标准结构：
@Component                          // 声明这是一个组件（像 React 的函数组件）
struct WeightCard {
  // 1. 状态变量（会自动触发界面刷新）
  @State private weightKg: number = 0
  
  // 2. 属性（从外部传入，像 Python 函数的参数）
  @Prop targetWeight: number = 70
  
  // 3. 生命周期函数
  aboutToAppear() {
    // 组件显示前执行（相当于 Python 类的 __init__）
    this.loadData()
  }
  
  // 4. 私有方法
  private async loadData() {
    this.weightKg = await WeightService.getLatest()
  }
  
  // 5. build 函数（必须有，相当于 React 的 return JSX）
  build() {
    Column() {
      Text(`当前体重: ${this.weightKg} kg`)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
    }
  }
}
```

### 4.5 禁止事项

```typescript
// 禁止1：在主线程执行耗时操作
// 数据库查询、网络请求 必须用 async/await

// 禁止2：硬编码密钥
const API_KEY = 'abc123'   // 绝对禁止！密钥要存在配置文件里

// 禁止3：不处理异常
await WeightDao.save(record)    // 错误：没有 try/catch

try {                            // 正确：必须处理异常
  await WeightDao.save(record)
} catch (e) {
  promptAction.showToast({ message: '保存失败，请重试' })
}

// 禁止4：魔法数字（不知道含义的数字）
if (streakDays > 7) { }        // 错误：7 是什么意思？

const WEEKLY_GOAL = 7           // 正确：定义为常量
if (streakDays > WEEKLY_GOAL) { }
```

---

## 五、项目文件命名一览

```
页面文件：    [功能]Page.ets     → HomePage.ets, WeightPage.ets
组件文件：    [功能]Component.ets → CheckinCalendarComponent.ets
ViewModel：   [功能]ViewModel.ets → WeightViewModel.ets
Service：     [功能]Service.ets   → CheckinService.ets
DAO：         [实体]Dao.ets       → WeightDao.ets
实体/模型：   [名称]Model.ets     → WeightRecordModel.ets
工具类：      [功能]Utils.ets     → DateUtils.ets
常量：        AppConstants.ets（全局）
```

---

## 六、每日工作流程建议

```
早上开始工作：
  git checkout develop
  git pull origin develop    ← 第一件事：拉最新代码
  git checkout feature/你的功能分支
  git merge develop          ← 把最新代码合并到你的分支（避免冲突堆积）

下班前：
  git add .
  git commit -m "feat(xxx): 今天完成了什么"
  git push origin feature/你的功能分支   ← 推到远端，不怕电脑坏掉

功能完成后：
  在 Gitee/GitHub 发起 PR → 等 Code Review → 合并
```

---

*文档版本：v1.0 | 创建日期：2026-05-17*
