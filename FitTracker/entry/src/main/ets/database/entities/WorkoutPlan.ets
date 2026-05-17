/**
 * 训练计划实体
 * 定义用户创建的个性化训练计划
 * 
 * Python对比：
 * class WorkoutPlan:
 *     def __init__(self):
 *         self.id: int = 0              # 主键自增
 *         self.name: str = ""           # 计划名称，如"增肌计划"
 *         self.goal: str = ""           # 目标：strength/endurance/flexibility/weight_loss
 *         self.level: str = ""          # 难度：beginner/intermediate/advanced
 *         self.duration_weeks: int = 0  # 计划周期（周）
 *         self.frequency_per_week: int = 0  # 每周训练次数
 *         self.exercises: list = []     # 包含的动作列表
 *         self.rest_days: list = []     # 休息日
 *         self.start_date: int = 0      # 开始日期时间戳
 *         self.status: str = ""         # 状态：active/paused/completed
 *         self.current_week: int = 1    # 当前第几周
 *         self.notes: str = ""          # 备注
 *         self.created_at: int = 0      # 创建时间
 *         self.updated_at: int = 0      # 更新时间
 */
export class WorkoutPlan {
  // 主键
  id: number = 0
  
  // 计划名称
  name: string = ""
  
  // 训练目标
  goal: PlanGoal = PlanGoal.STRENGTH
  
  // 难度等级
  level: PlanLevel = PlanLevel.BEGINNER
  
  // 计划周期（周）
  durationWeeks: number = 4
  
  // 每周训练次数
  frequencyPerWeek: number = 3
  
  // 休息日（周一到周日，用数字表示，1-7）
  restDays: number[] = [0, 7] // 默认周日休息
  
  // 计划开始日期
  startDate: number = 0
  
  // 计划状态
  status: PlanStatus = PlanStatus.DRAFT
  
  // 当前进行到的周数
  currentWeek: number = 1
  
  // 计划描述
  description: string = ""
  
  // 备注
  notes: string = ""
  
  // 创建时间
  createdAt: number = 0
  
  // 更新时间
  updatedAt: number = 0
  
  constructor(name: string = "") {
    this.name = name
    this.startDate = Date.now()
    this.createdAt = Date.now()
    this.updatedAt = Date.now()
  }
}

/**
 * 训练目标枚举
 */
export enum PlanGoal {
  STRENGTH = "strength",           // 增肌
  ENDURANCE = "endurance",         // 耐力
  FLEXIBILITY = "flexibility",     // 柔韧性
  WEIGHT_LOSS = "weight_loss",      // 减脂
  GENERAL = "general"               // 综合健身
}

/**
 * 难度等级枚举
 */
export enum PlanLevel {
  BEGINNER = "beginner",           // 初学者
  INTERMEDIATE = "intermediate",   // 中级
  ADVANCED = "advanced"            // 高级
}

/**
 * 计划状态枚举
 */
export enum PlanStatus {
  DRAFT = "draft",                 // 草稿（未开始）
  ACTIVE = "active",               // 进行中
  PAUSED = "paused",               // 已暂停
  COMPLETED = "completed",         // 已完成
  ABANDONED = "abandoned"          // 已放弃
}

/**
 * 训练计划中的单个动作配置
 * 
 * Python对比：
 * class PlanExercise:
 *     def __init__(self):
 *         self.exercise_id: int = 0      # 动作ID（关联动作库）
 *         self.sets: int = 3             # 组数
 *         self.reps: str = "10-12"       # 次数（可以是范围如"8-12"）
 *         self.rest_seconds: int = 60    # 组间休息秒数
 *         self.notes: str = ""           # 动作备注
 *         self.day_of_week: int = 1      # 周几训练（1-7）
 */
export class PlanExercise {
  // 动作ID
  exerciseId: number = 0
  
  // 动作名称
  exerciseName: string = ""
  
  // 目标组数
  sets: number = 3
  
  // 目标次数（支持范围如 "8-12"）
  reps: string = "10"
  
  // 组间休息秒数
  restSeconds: number = 60
  
  // 动作备注
  notes: string = ""
  
  // 训练日（周几，1=周一，7=周日）
  dayOfWeek: number = 1
  
  // 顺序
  orderIndex: number = 0
  
  // 重量（可选）
  weight: number = 0
  weightUnit: string = "kg"
}

/**
 * 每日训练安排
 * 包含当天要做的所有动作
 */
export class DailyWorkout {
  // 日期
  date: number = 0
  
  // 当天的日期字符串 (YYYY-MM-DD)
  dateString: string = ""
  
  // 星期几 (1-7)
  dayOfWeek: number = 1
  
  // 星期名称
  dayName: string = "周一"
  
  // 训练动作列表
  exercises: PlanExercise[] = []
  
  // 是否休息日
  isRestDay: boolean = false
  
  // 是否已完成
  isCompleted: boolean = false
  
  // 完成时间
  completedAt: number = 0
  
  // 当日总训练组数
  totalSets: number = 0
  
  // 当日总训练时长（分钟）
  totalDuration: number = 0
  
  // 训练感受（1-5分）
  feeling: number = 3
  
  // 训练备注
  notes: string = ""
}

/**
 * 计划模板（预设的训练计划）
 */
export class PlanTemplate {
  // 模板ID
  id: string = ""
  
  // 模板名称
  name: string = ""
  
  // 模板描述
  description: string = ""
  
  // 目标
  goal: PlanGoal = PlanGoal.STRENGTH
  
  // 难度
  level: PlanLevel = PlanLevel.BEGINNER
  
  // 建议周期（周）
  suggestedWeeks: number = 4
  
  // 每周训练天数
  trainingDays: number = 3
  
  // 模板动作（按训练日分组）
  workoutsByDay: Map<number, PlanExercise[]> = new Map()
  
  // 适用人群描述
  targetAudience: string = ""
  
  // 预期效果
  expectedResults: string = ""
}

/**
 * 用户训练进度记录
 */
export class PlanProgress {
  // 主键
  id: number = 0
  
  // 关联的计划ID
  planId: number = 0
  
  // 当前的周数
  currentWeek: number = 1
  
  // 当前训练日
  currentDayIndex: number = 0
  
  // 累计完成天数
  completedDays: number = 0
  
  // 累计完成组数
  completedSets: number = 0
  
  // 累计训练时长（分钟）
  totalMinutes: number = 0
  
  // 坚持连续天数
  streakDays: number = 0
  
  // 上次训练日期
  lastWorkoutDate: number = 0
  
  // 完成率百分比
  completionRate: number = 0
  
  // 更新日期
  updatedAt: number = 0
}
