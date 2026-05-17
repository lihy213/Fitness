/**
 * 训练计划 DAO
 * 数据库访问层，处理训练计划的所有CRUD操作
 * 
 * Python对比：
 * class WorkoutPlanDao:
 *     def __init__(self, db):
 *         self.db = db
 *     
 *     def create_plan(self, plan: WorkoutPlan) -> int:
 *         # 插入新计划
 *     
 *     def get_plan(self, plan_id: int) -> WorkoutPlan:
 *         # 获取单个计划
 *     
 *     def get_active_plan(self) -> WorkoutPlan:
 *         # 获取当前进行中的计划
 *     
 *     def update_plan(self, plan: WorkoutPlan):
 *         # 更新计划
 *     
 *     def get_templates(self) -> list:
 *         # 获取计划模板列表
 */

import { WorkoutPlan, PlanExercise, DailyWorkout, PlanProgress, PlanStatus, PlanGoal, PlanLevel, PlanTemplate } from '../entities/WorkoutPlan'
import { DatabaseSchema } from '../DatabaseSchema'

export class WorkoutPlanDao {
  private store: relationalStore.RdbStore | null = null
  
  constructor() {}
  
  /**
   * 初始化 DAO（获取数据库连接）
   */
  async initialize(): Promise<void> {
    this.store = await DatabaseSchema.getRdbStore()
  }
  
  /**
   * 创建新训练计划
   */
  async createPlan(plan: WorkoutPlan): Promise<number> {
    if (!this.store) await this.initialize()
    
    const result = await this.store.insert("workout_plans", {
      name: plan.name,
      goal: plan.goal,
      level: plan.level,
      duration_weeks: plan.durationWeeks,
      frequency_per_week: plan.frequencyPerWeek,
      rest_days: JSON.stringify(plan.restDays),
      start_date: plan.startDate,
      status: plan.status,
      current_week: plan.currentWeek,
      description: plan.description,
      notes: plan.notes,
      created_at: Date.now(),
      updated_at: Date.now()
    })
    
    return result.rowId
  }
  
  /**
   * 更新训练计划
   */
  async updatePlan(plan: WorkoutPlan): Promise<number> {
    if (!this.store) await this.initialize()
    
    const predicates = new relationalStore.RdbPredicates("workout_plans")
    predicates.equalTo("id", plan.id)
    
    const result = await this.store.update("workout_plans", {
      name: plan.name,
      goal: plan.goal,
      level: plan.level,
      duration_weeks: plan.durationWeeks,
      frequency_per_week: plan.frequencyPerWeek,
      rest_days: JSON.stringify(plan.restDays),
      start_date: plan.startDate,
      status: plan.status,
      current_week: plan.currentWeek,
      description: plan.description,
      notes: plan.notes,
      updated_at: Date.now()
    }, predicates)
    
    return result.rowsAffected
  }
  
  /**
   * 删除训练计划
   */
  async deletePlan(planId: number): Promise<number> {
    if (!this.store) await this.initialize()
    
    const predicates = new relationalStore.RdbPredicates("workout_plans")
    predicates.equalTo("id", planId)
    
    return await this.store.delete("workout_plans", predicates)
  }
  
  /**
   * 根据ID获取计划
   */
  async getPlanById(planId: number): Promise<WorkoutPlan | null> {
    if (!this.store) await this.initialize()
    
    const predicates = new relationalStore.RdbPredicates("workout_plans")
    predicates.equalTo("id", planId)
    
    const result = await this.store.query("workout_plans", [predicates])
    
    if (result.rowSet.length > 0) {
      return this.rowToPlan(result.rowSet[0])
    }
    return null
  }
  
  /**
   * 获取所有训练计划
   */
  async getAllPlans(): Promise<WorkoutPlan[]> {
    if (!this.store) await this.initialize()
    
    const predicates = new relationalStore.RdbPredicates("workout_plans")
    predicates.orderByDesc("updated_at")
    
    const result = await this.store.query("workout_plans", [predicates])
    
    const plans: WorkoutPlan[] = []
    for (const row of result.rowSet) {
      plans.push(this.rowToPlan(row))
    }
    return plans
  }
  
  /**
   * 获取当前进行中的计划
   */
  async getActivePlan(): Promise<WorkoutPlan | null> {
    if (!this.store) await this.initialize()
    
    const predicates = new relationalStore.RdbPredicates("workout_plans")
    predicates.equalTo("status", PlanStatus.ACTIVE)
    predicates.orderByDesc("updated_at")
    predicates.limitAs(1)
    
    const result = await this.store.query("workout_plans", [predicates])
    
    if (result.rowSet.length > 0) {
      return this.rowToPlan(result.rowSet[0])
    }
    return null
  }
  
  /**
   * 获取用户的计划列表
   */
  async getPlansByStatus(status: PlanStatus): Promise<WorkoutPlan[]> {
    if (!this.store) await this.initialize()
    
    const predicates = new relationalStore.RdbPredicates("workout_plans")
    predicates.equalTo("status", status)
    predicates.orderByDesc("updated_at")
    
    const result = await this.store.query("workout_plans", [predicates])
    
    const plans: WorkoutPlan[] = []
    for (const row of result.rowSet) {
      plans.push(this.rowToPlan(row))
    }
    return plans
  }
  
  /**
   * 保存计划动作
   */
  async savePlanExercises(planId: number, exercises: PlanExercise[]): Promise<void> {
    if (!this.store) await this.initialize()
    
    // 先删除旧的动作
    const deletePred = new relationalStore.RdbPredicates("plan_exercises")
    deletePred.equalTo("plan_id", planId)
    await this.store.delete("plan_exercises", deletePred)
    
    // 插入新动作
    for (let i = 0; i < exercises.length; i++) {
      const ex = exercises[i]
      await this.store.insert("plan_exercises", {
        plan_id: planId,
        exercise_id: ex.exerciseId,
        exercise_name: ex.exerciseName,
        sets: ex.sets,
        reps: ex.reps,
        rest_seconds: ex.restSeconds,
        notes: ex.notes,
        day_of_week: ex.dayOfWeek,
        order_index: i,
        weight: ex.weight,
        weight_unit: ex.weightUnit
      })
    }
  }
  
  /**
   * 获取计划的动作列表
   */
  async getPlanExercises(planId: number): Promise<PlanExercise[]> {
    if (!this.store) await this.initialize()
    
    const predicates = new relationalStore.RdbPredicates("plan_exercises")
    predicates.equalTo("plan_id", planId)
    predicates.orderByAsc("order_index")
    
    const result = await this.store.query("plan_exercises", [predicates])
    
    const exercises: PlanExercise[] = []
    for (const row of result.rowSet) {
      exercises.push(this.rowToExercise(row))
    }
    return exercises
  }
  
  /**
   * 获取某一天的训练内容
   */
  async getDailyWorkout(planId: number, dayOfWeek: number): Promise<PlanExercise[]> {
    if (!this.store) await this.initialize()
    
    const predicates = new relationalStore.RdbPredicates("plan_exercises")
    predicates.equalTo("plan_id", planId)
    predicates.equalTo("day_of_week", dayOfWeek)
    predicates.orderByAsc("order_index")
    
    const result = await this.store.query("plan_exercises", [predicates])
    
    const exercises: PlanExercise[] = []
    for (const row of result.rowSet) {
      exercises.push(this.rowToExercise(row))
    }
    return exercises
  }
  
  /**
   * 记录每日训练完成
   */
  async recordDailyWorkout(workout: DailyWorkout): Promise<number> {
    if (!this.store) await this.initialize()
    
    const result = await this.store.insert("daily_workouts", {
      plan_id: workout.dateString.split('-')[0], // TODO: 应该是真实planId
      workout_date: workout.date,
      date_string: workout.dateString,
      day_of_week: workout.dayOfWeek,
      exercises: JSON.stringify(workout.exercises),
      is_rest_day: workout.isRestDay ? 1 : 0,
      is_completed: workout.isCompleted ? 1 : 0,
      completed_at: workout.completedAt,
      total_sets: workout.totalSets,
      total_duration: workout.totalDuration,
      feeling: workout.feeling,
      notes: workout.notes
    })
    
    return result.rowId
  }
  
  /**
   * 获取计划进度
   */
  async getPlanProgress(planId: number): Promise<PlanProgress | null> {
    if (!this.store) await this.initialize()
    
    const predicates = new relationalStore.RdbPredicates("plan_progress")
    predicates.equalTo("plan_id", planId)
    
    const result = await this.store.query("plan_progress", [predicates])
    
    if (result.rowSet.length > 0) {
      return this.rowToProgress(result.rowSet[0])
    }
    return null
  }
  
  /**
   * 更新计划进度
   */
  async updatePlanProgress(progress: PlanProgress): Promise<number> {
    if (!this.store) await this.initialize()
    
    const predicates = new relationalStore.RdbPredicates("plan_progress")
    predicates.equalTo("plan_id", progress.planId)
    
    const result = await this.store.update("plan_progress", {
      current_week: progress.currentWeek,
      current_day_index: progress.currentDayIndex,
      completed_days: progress.completedDays,
      completed_sets: progress.completedSets,
      total_minutes: progress.totalMinutes,
      streak_days: progress.streakDays,
      last_workout_date: progress.lastWorkoutDate,
      completion_rate: progress.completionRate,
      updated_at: Date.now()
    }, predicates)
    
    return result.rowsAffected
  }
  
  /**
   * 获取预设的计划模板
   */
  getTemplates(): PlanTemplate[] {
    return [
      {
        id: "beginner_fullbody",
        name: "新手全身训练",
        description: "适合健身初学者的全身训练计划，每周3次",
        goal: PlanGoal.GENERAL,
        level: PlanLevel.BEGINNER,
        suggestedWeeks: 4,
        trainingDays: 3,
        targetAudience: "健身初学者，没有训练基础",
        expectedResults: "建立运动习惯，提升基础体能"
      },
      {
        id: "strength_upper_lower",
        name: "上下身分化训练",
        description: "增肌专用的上下身交替训练",
        goal: PlanGoal.STRENGTH,
        level: PlanLevel.INTERMEDIATE,
        suggestedWeeks: 8,
        trainingDays: 4,
        targetAudience: "有一定训练基础，想要增肌",
        expectedResults: "提升肌肉力量和体积"
      },
      {
        id: "weight_loss_cardio",
        name: "减脂计划",
        description: "结合有氧和力量训练的减脂计划",
        goal: PlanGoal.WEIGHT_LOSS,
        level: PlanLevel.BEGINNER,
        suggestedWeeks: 12,
        trainingDays: 5,
        targetAudience: "体脂较高，想要减脂的人群",
        expectedResults: "降低体脂率，提升心肺功能"
      },
      {
        id: "flexibility_yoga",
        name: "柔韧性训练",
        description: "提升身体柔韧性和平衡感",
        goal: PlanGoal.FLEXIBILITY,
        level: PlanLevel.BEGINNER,
        suggestedWeeks: 6,
        trainingDays: 4,
        targetAudience: "久坐人群，想要改善柔韧性",
        expectedResults: "改善柔韧性，缓解肌肉紧张"
      }
    ]
  }
  
  /**
   * 将数据库行转换为 WorkoutPlan 对象
   */
  private rowToPlan(row: relationalStore.ResultSet): WorkoutPlan {
    const plan = new WorkoutPlan()
    plan.id = row.getValue("id")
    plan.name = row.getValue("name")
    plan.goal = row.getValue("goal")
    plan.level = row.getValue("level")
    plan.durationWeeks = row.getValue("duration_weeks")
    plan.frequencyPerWeek = row.getValue("frequency_per_week")
    
    try {
      plan.restDays = JSON.parse(row.getValue("rest_days") || "[]")
    } catch {
      plan.restDays = []
    }
    
    plan.startDate = row.getValue("start_date")
    plan.status = row.getValue("status")
    plan.currentWeek = row.getValue("current_week")
    plan.description = row.getValue("description")
    plan.notes = row.getValue("notes")
    plan.createdAt = row.getValue("created_at")
    plan.updatedAt = row.getValue("updated_at")
    
    return plan
  }
  
  /**
   * 将数据库行转换为 PlanExercise 对象
   */
  private rowToExercise(row: relationalStore.ResultSet): PlanExercise {
    const ex = new PlanExercise()
    ex.exerciseId = row.getValue("exercise_id")
    ex.exerciseName = row.getValue("exercise_name")
    ex.sets = row.getValue("sets")
    ex.reps = row.getValue("reps")
    ex.restSeconds = row.getValue("rest_seconds")
    ex.notes = row.getValue("notes")
    ex.dayOfWeek = row.getValue("day_of_week")
    ex.orderIndex = row.getValue("order_index")
    ex.weight = row.getValue("weight")
    ex.weightUnit = row.getValue("weight_unit")
    return ex
  }
  
  /**
   * 将数据库行转换为 PlanProgress 对象
   */
  private rowToProgress(row: relationalStore.ResultSet): PlanProgress {
    const progress = new PlanProgress()
    progress.id = row.getValue("id")
    progress.planId = row.getValue("plan_id")
    progress.currentWeek = row.getValue("current_week")
    progress.currentDayIndex = row.getValue("current_day_index")
    progress.completedDays = row.getValue("completed_days")
    progress.completedSets = row.getValue("completed_sets")
    progress.totalMinutes = row.getValue("total_minutes")
    progress.streakDays = row.getValue("streak_days")
    progress.lastWorkoutDate = row.getValue("last_workout_date")
    progress.completionRate = row.getValue("completion_rate")
    progress.updatedAt = row.getValue("updated_at")
    return progress
  }
}
