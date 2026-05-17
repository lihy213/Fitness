/**
 * 训练计划服务
 * 业务逻辑层，处理训练计划的核心业务
 * 
 * Python对比：
 * class WorkoutPlanService:
 *     def __init__(self):
 *         self.dao = WorkoutPlanDao()
 *     
 *     def create_plan_from_template(self, template_id: str, customizations: dict) -> WorkoutPlan:
 *         # 根据模板创建计划
 *     
 *     def start_plan(self, plan_id: int):
 *         # 开始一个计划
 *     
 *     def complete_workout(self, plan_id: int, day: int):
 *         # 完成当日训练
 */

import { WorkoutPlan, PlanExercise, DailyWorkout, PlanProgress, PlanStatus, PlanGoal, PlanLevel, PlanTemplate } from '../database/entities/WorkoutPlan'
import { WorkoutPlanDao } from '../database/dao/WorkoutPlanDao'

// 星期几的中文名称
const DAY_NAMES = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]

export class WorkoutPlanService {
  private dao: WorkoutPlanDao
  
  constructor() {
    this.dao = new WorkoutPlanDao()
  }
  
  /**
   * 初始化服务
   */
  async initialize(): Promise<void> {
    await this.dao.initialize()
  }
  
  /**
   * 获取所有训练计划
   */
  async getAllPlans(): Promise<WorkoutPlan[]> {
    return await this.dao.getAllPlans()
  }
  
  /**
   * 获取当前进行中的计划
   */
  async getActivePlan(): Promise<WorkoutPlan | null> {
    return await this.dao.getActivePlan()
  }
  
  /**
   * 创建新计划
   */
  async createPlan(plan: WorkoutPlan): Promise<number> {
    plan.status = PlanStatus.DRAFT
    plan.createdAt = Date.now()
    plan.updatedAt = Date.now()
    
    const planId = await this.dao.createPlan(plan)
    
    // 保存计划动作
    if (planId > 0 && plan.description) {
      // 如果有预设动作描述，创建默认动作
      const defaultExercises = this.generateDefaultExercises(plan)
      await this.dao.savePlanExercises(planId, defaultExercises)
    }
    
    return planId
  }
  
  /**
   * 根据模板创建计划
   */
  async createPlanFromTemplate(template: PlanTemplate, customizations?: {
    name?: string
    durationWeeks?: number
    startDate?: number
  }): Promise<number> {
    const plan = new WorkoutPlan()
    
    plan.name = customizations?.name || template.name
    plan.goal = template.goal
    plan.level = template.level
    plan.durationWeeks = customizations?.durationWeeks || template.suggestedWeeks
    plan.frequencyPerWeek = template.trainingDays
    plan.startDate = customizations?.startDate || Date.now()
    plan.description = template.description
    plan.status = PlanStatus.DRAFT
    
    // 设置休息日（根据训练频率计算）
    plan.restDays = this.calculateRestDays(template.trainingDays)
    
    // 创建计划
    const planId = await this.dao.createPlan(plan)
    
    // 根据模板生成动作
    const exercises = this.generateExercisesFromTemplate(template)
    await this.dao.savePlanExercises(planId, exercises)
    
    // 初始化进度
    await this.initializeProgress(planId)
    
    return planId
  }
  
  /**
   * 开始一个计划
   */
  async startPlan(planId: number): Promise<boolean> {
    const plan = await this.dao.getPlanById(planId)
    if (!plan) return false
    
    // 如果有其他进行中的计划，先暂停
    const activePlan = await this.dao.getActivePlan()
    if (activePlan && activePlan.id !== planId) {
      activePlan.status = PlanStatus.PAUSED
      await this.dao.updatePlan(activePlan)
    }
    
    // 启动新计划
    plan.status = PlanStatus.ACTIVE
    plan.startDate = Date.now()
    plan.updatedAt = Date.now()
    
    await this.dao.updatePlan(plan)
    return true
  }
  
  /**
   * 暂停计划
   */
  async pausePlan(planId: number): Promise<boolean> {
    const plan = await this.dao.getPlanById(planId)
    if (!plan) return false
    
    plan.status = PlanStatus.PAUSED
    plan.updatedAt = Date.now()
    
    await this.dao.updatePlan(plan)
    return true
  }
  
  /**
   * 放弃计划
   */
  async abandonPlan(planId: number): Promise<boolean> {
    const plan = await this.dao.getPlanById(planId)
    if (!plan) return false
    
    plan.status = PlanStatus.ABANDONED
    plan.updatedAt = Date.now()
    
    await this.dao.updatePlan(plan)
    return true
  }
  
  /**
   * 完成今日训练
   */
  async completeTodayWorkout(workout: DailyWorkout): Promise<boolean> {
    // 记录完成
    await this.dao.recordDailyWorkout(workout)
    
    // 更新进度
    const progress = await this.dao.getPlanProgress(workout.dateString.split('-')[0])
    if (progress) {
      progress.completedDays++
      progress.totalMinutes += workout.totalDuration
      progress.totalSets += workout.totalSets
      progress.lastWorkoutDate = Date.now()
      progress.completionRate = this.calculateCompletionRate(progress)
      
      // 计算连续天数
      progress.streakDays = await this.calculateStreakDays(progress)
      
      await this.dao.updatePlanProgress(progress)
    }
    
    return true
  }
  
  /**
   * 获取今日训练内容
   */
  async getTodayWorkout(): Promise<DailyWorkout | null> {
    const activePlan = await this.dao.getActivePlan()
    if (!activePlan) return null
    
    const today = new Date()
    const dayOfWeek = today.getDay() // 0=周日, 1=周一...
    const dateString = this.formatDate(today)
    
    // 检查是否是休息日
    if (activePlan.restDays.includes(dayOfWeek)) {
      return {
        date: today.getTime(),
        dateString: dateString,
        dayOfWeek: dayOfWeek,
        dayName: DAY_NAMES[dayOfWeek],
        exercises: [],
        isRestDay: true,
        isCompleted: false,
        totalSets: 0,
        totalDuration: 0
      }
    }
    
    // 获取当天的训练动作
    const exercises = await this.dao.getDailyWorkout(activePlan.id, dayOfWeek)
    
    // 检查是否已完成
    const progress = await this.dao.getPlanProgress(activePlan.id)
    const isCompleted = progress?.lastWorkoutDate > today.getTime() - 86400000
    
    return {
      date: today.getTime(),
      dateString: dateString,
      dayOfWeek: dayOfWeek,
      dayName: DAY_NAMES[dayOfWeek],
      exercises: exercises,
      isRestDay: false,
      isCompleted: isCompleted,
      totalSets: exercises.reduce((sum, ex) => sum + ex.sets, 0),
      totalDuration: exercises.length * 10 // 估算
    }
  }
  
  /**
   * 获取本周训练计划（用于日历展示）
   */
  async getWeekPlan(planId: number): Promise<DailyWorkout[]> {
    const plan = await this.dao.getPlanById(planId)
    if (!plan) return []
    
    const weekPlan: DailyWorkout[] = []
    const today = new Date()
    
    // 获取本周从周一开始的日期
    const startOfWeek = new Date(today)
    startOfWeek.setDate(today.getDate() - ((today.getDay() + 6) % 7))
    
    for (let i = 0; i < 7; i++) {
      const date = new Date(startOfWeek)
      date.setDate(startOfWeek.getDate() + i)
      
      const dayOfWeek = date.getDay()
      const isRestDay = plan.restDays.includes(dayOfWeek === 0 ? 7 : dayOfWeek)
      
      let exercises: PlanExercise[] = []
      if (!isRestDay) {
        // 转换周日为7
        const adjustedDay = dayOfWeek === 0 ? 7 : dayOfWeek
        exercises = await this.dao.getDailyWorkout(planId, adjustedDay)
      }
      
      weekPlan.push({
        date: date.getTime(),
        dateString: this.formatDate(date),
        dayOfWeek: dayOfWeek,
        dayName: DAY_NAMES[dayOfWeek],
        exercises: exercises,
        isRestDay: isRestDay,
        isCompleted: false,
        totalSets: exercises.reduce((sum, ex) => sum + ex.sets, 0),
        totalDuration: exercises.length * 10
      })
    }
    
    return weekPlan
  }
  
  /**
   * 获取计划进度
   */
  async getProgress(planId: number): Promise<PlanProgress | null> {
    return await this.dao.getPlanProgress(planId)
  }
  
  /**
   * 获取进度百分比
   */
  async getProgressPercentage(planId: number): Promise<number> {
    const progress = await this.dao.getPlanProgress(planId)
    const plan = await this.dao.getPlanById(planId)
    
    if (!progress || !plan) return 0
    
    const totalDays = plan.durationWeeks * 7
    const elapsedDays = Math.floor((Date.now() - plan.startDate) / 86400000)
    
    return Math.min(100, Math.round((progress.completedDays / Math.min(elapsedDays, totalDays)) * 100))
  }
  
  /**
   * 获取计划模板列表
   */
  getTemplates(): PlanTemplate[] {
    return this.dao.getTemplates()
  }
  
  /**
   * 根据目标筛选模板
   */
  getTemplatesByGoal(goal: PlanGoal): PlanTemplate[] {
    return this.getTemplates().filter(t => t.goal === goal)
  }
  
  /**
   * 根据难度筛选模板
   */
  getTemplatesByLevel(level: PlanLevel): PlanTemplate[] {
    return this.getTemplates().filter(t => t.level === level)
  }
  
  // ==================== 私有辅助方法 ====================
  
  /**
   * 根据训练频率计算休息日
   */
  private calculateRestDays(trainingDays: number): number[] {
    // 默认休息日是周日(7)和周三(3)
    const allDays = [1, 2, 3, 4, 5, 6, 7]
    const restDaysCount = 7 - trainingDays
    
    if (restDaysCount <= 0) return []
    if (restDaysCount === 1) return [7] // 周日
    if (restDaysCount === 2) return [3, 7] // 周三、周日
    
    return [7] // 默认只休息周日
  }
  
  /**
   * 从模板生成动作列表
   */
  private generateExercisesFromTemplate(template: PlanTemplate): PlanExercise[] {
    const exercises: PlanExercise[] = []
    
    // 根据模板类型生成不同的动作组合
    switch (template.id) {
      case "beginner_fullbody":
        // 新手全身训练 - 周一、周三、周五
        exercises.push(...this.generateFullBodyExercises(1))
        exercises.push(...this.generateFullBodyExercises(3))
        exercises.push(...this.generateFullBodyExercises(5))
        break
        
      case "strength_upper_lower":
        // 上下身分化 - 周一/周三上半身，周二/周四下半身
        exercises.push(...this.generateUpperBodyExercises(1))
        exercises.push(...this.generateLowerBodyExercises(2))
        exercises.push(...this.generateUpperBodyExercises(3))
        exercises.push(...this.generateLowerBodyExercises(4))
        break
        
      case "weight_loss_cardio":
        // 减脂计划 - 每天都有训练
        for (let day = 1; day <= 6; day++) {
          exercises.push(...this.generateCardioExercises(day))
        }
        break
        
      case "flexibility_yoga":
        // 柔韧性训练 - 周一、周三、周五、周日
        exercises.push(...this.generateFlexibilityExercises(1))
        exercises.push(...this.generateFlexibilityExercises(3))
        exercises.push(...this.generateFlexibilityExercises(5))
        exercises.push(...this.generateFlexibilityExercises(7))
        break
    }
    
    return exercises
  }
  
  /**
   * 生成默认动作（当没有具体模板时）
   */
  private generateDefaultExercises(plan: WorkoutPlan): PlanExercise[] {
    const exercises: PlanExercise[] = []
    let orderIndex = 0
    
    // 根据目标和难度生成不同的动作
    for (let day = 1; day <= plan.frequencyPerWeek; day++) {
      if (!plan.restDays.includes(day)) {
        // 添加3-4个动作
        const exercisesForDay = this.getDefaultExercisesByGoal(plan.goal, day)
        for (const ex of exercisesForDay) {
          ex.dayOfWeek = day
          ex.orderIndex = orderIndex++
          exercises.push(ex)
        }
      }
    }
    
    return exercises
  }
  
  /**
   * 根据目标获取默认动作
   */
  private getDefaultExercisesByGoal(goal: PlanGoal, dayOfWeek: number): PlanExercise[] {
    switch (goal) {
      case PlanGoal.STRENGTH:
        return [
          { exerciseId: 1, exerciseName: "深蹲", sets: 3, reps: "10-12", restSeconds: 90, dayOfWeek, orderIndex: 0, weight: 0, weightUnit: "kg" },
          { exerciseId: 2, exerciseName: "卧推", sets: 3, reps: "10-12", restSeconds: 90, dayOfWeek, orderIndex: 1, weight: 0, weightUnit: "kg" },
          { exerciseId: 3, exerciseName: "硬拉", sets: 3, reps: "8-10", restSeconds: 120, dayOfWeek, orderIndex: 2, weight: 0, weightUnit: "kg" }
        ]
      case PlanGoal.WEIGHT_LOSS:
        return [
          { exerciseId: 10, exerciseName: "快走/慢跑", sets: 1, reps: "20分钟", restSeconds: 0, dayOfWeek, orderIndex: 0, weight: 0, weightUnit: "kg" },
          { exerciseId: 11, exerciseName: "HIIT训练", sets: 3, reps: "30秒", restSeconds: 30, dayOfWeek, orderIndex: 1, weight: 0, weightUnit: "kg" }
        ]
      default:
        return [
          { exerciseId: 1, exerciseName: "深蹲", sets: 3, reps: "15", restSeconds: 60, dayOfWeek, orderIndex: 0, weight: 0, weightUnit: "kg" },
          { exerciseId: 2, exerciseName: "俯卧撑", sets: 3, reps: "10", restSeconds: 60, dayOfWeek, orderIndex: 1, weight: 0, weightUnit: "kg" }
        ]
    }
  }
  
  /**
   * 生成全身训练动作
   */
  private generateFullBodyExercises(dayOfWeek: number): PlanExercise[] {
    return [
      { exerciseId: 1, exerciseName: "深蹲", sets: 3, reps: "12", restSeconds: 60, dayOfWeek, orderIndex: 0, weight: 0, weightUnit: "kg" },
      { exerciseId: 2, exerciseName: "卧推", sets: 3, reps: "10", restSeconds: 60, dayOfWeek, orderIndex: 1, weight: 0, weightUnit: "kg" },
      { exerciseId: 3, exerciseName: "哑铃划船", sets: 3, reps: "10", restSeconds: 60, dayOfWeek, orderIndex: 2, weight: 0, weightUnit: "kg" },
      { exerciseId: 4, exerciseName: "平板支撑", sets: 3, reps: "30秒", restSeconds: 30, dayOfWeek, orderIndex: 3, weight: 0, weightUnit: "kg" }
    ]
  }
  
  /**
   * 生成上半身训练动作
   */
  private generateUpperBodyExercises(dayOfWeek: number): PlanExercise[] {
    return [
      { exerciseId: 2, exerciseName: "卧推", sets: 4, reps: "8-10", restSeconds: 90, dayOfWeek, orderIndex: 0, weight: 0, weightUnit: "kg" },
      { exerciseId: 5, exerciseName: "引体向上", sets: 3, reps: "6-8", restSeconds: 90, dayOfWeek, orderIndex: 1, weight: 0, weightUnit: "kg" },
      { exerciseId: 6, exerciseName: "肩推", sets: 3, reps: "10", restSeconds: 60, dayOfWeek, orderIndex: 2, weight: 0, weightUnit: "kg" },
      { exerciseId: 7, exerciseName: "二头弯举", sets: 3, reps: "12", restSeconds: 45, dayOfWeek, orderIndex: 3, weight: 0, weightUnit: "kg" }
    ]
  }
  
  /**
   * 生成下半身训练动作
   */
  private generateLowerBodyExercises(dayOfWeek: number): PlanExercise[] {
    return [
      { exerciseId: 1, exerciseName: "深蹲", sets: 4, reps: "8-10", restSeconds: 120, dayOfWeek, orderIndex: 0, weight: 0, weightUnit: "kg" },
      { exerciseId: 3, exerciseName: "硬拉", sets: 4, reps: "6-8", restSeconds: 120, dayOfWeek, orderIndex: 1, weight: 0, weightUnit: "kg" },
      { exerciseId: 8, exerciseName: "腿举", sets: 3, reps: "12", restSeconds: 60, dayOfWeek, orderIndex: 2, weight: 0, weightUnit: "kg" },
      { exerciseId: 9, exerciseName: "小腿提踵", sets: 3, reps: "15", restSeconds: 45, dayOfWeek, orderIndex: 3, weight: 0, weightUnit: "kg" }
    ]
  }
  
  /**
   * 生成有氧训练动作
   */
  private generateCardioExercises(dayOfWeek: number): PlanExercise[] {
    return [
      { exerciseId: 10, exerciseName: "热身拉伸", sets: 1, reps: "5分钟", restSeconds: 0, dayOfWeek, orderIndex: 0, weight: 0, weightUnit: "kg" },
      { exerciseId: 11, exerciseName: "有氧运动", sets: 1, reps: "30分钟", restSeconds: 0, dayOfWeek, orderIndex: 1, weight: 0, weightUnit: "kg" },
      { exerciseId: 12, exerciseName: "核心训练", sets: 3, reps: "15", restSeconds: 30, dayOfWeek, orderIndex: 2, weight: 0, weightUnit: "kg" }
    ]
  }
  
  /**
   * 生成柔韧性训练动作
   */
  private generateFlexibilityExercises(dayOfWeek: number): PlanExercise[] {
    return [
      { exerciseId: 13, exerciseName: "全身拉伸", sets: 1, reps: "15分钟", restSeconds: 0, dayOfWeek, orderIndex: 0, weight: 0, weightUnit: "kg" },
      { exerciseId: 14, exerciseName: "瑜伽体式", sets: 5, reps: "1分钟", restSeconds: 30, dayOfWeek, orderIndex: 1, weight: 0, weightUnit: "kg" }
    ]
  }
  
  /**
   * 初始化计划进度
   */
  private async initializeProgress(planId: number): Promise<void> {
    const progress = new PlanProgress()
    progress.planId = planId
    progress.currentWeek = 1
    progress.completedDays = 0
    progress.updatedAt = Date.now()
    
    // TODO: 保存到数据库
    // await this.dao.saveProgress(progress)
  }
  
  /**
   * 计算完成率
   */
  private calculateCompletionRate(progress: PlanProgress): number {
    // 简化计算：完成天数 / 预期天数
    return Math.round((progress.completedDays / 28) * 100) // 假设4周=28天
  }
  
  /**
   * 计算连续训练天数
   */
  private async calculateStreakDays(progress: PlanProgress): Promise<number> {
    const lastWorkout = new Date(progress.lastWorkoutDate)
    const today = new Date()
    
    // 如果上次训练是今天或昨天，连续天数继续
    const daysDiff = Math.floor((today.getTime() - lastWorkout.getTime()) / 86400000)
    
    if (daysDiff > 1) {
      return 0 // 中断了
    }
    
    return progress.streakDays + 1
  }
  
  /**
   * 格式化日期为 YYYY-MM-DD
   */
  private formatDate(date: Date): string {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }
}
