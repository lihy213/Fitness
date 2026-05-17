/**
 * 训练计划 ViewModel
 * 管理训练计划页面的状态
 * 
 * Python对比：
 * class WorkoutPlanViewModel(ViewModel):
 *     plans = []
 *     active_plan = None
 *     templates = []
 *     today_workout = None
 *     
 *     def load_plans(self):
 *         self.plans = self.service.get_all_plans()
 *     
 *     def create_from_template(self, template_id):
 *         self.service.create_plan_from_template(template_id)
 */

import { WorkoutPlan, PlanExercise, DailyWorkout, PlanProgress, PlanTemplate, PlanStatus, PlanGoal, PlanLevel } from '../database/entities/WorkoutPlan'
import { WorkoutPlanService } from '../services/WorkoutPlanService'

export class WorkoutPlanViewModel {
  // 所有训练计划列表
  @Observed
  plans: WorkoutPlan[] = []
  
  // 当前进行中的计划
  @Observed
  activePlan: WorkoutPlan | null = null
  
  // 计划模板列表
  @Obsured
  templates: PlanTemplate[] = []
  
  // 今日训练内容
  @Observed
  todayWorkout: DailyWorkout | null = null
  
  // 计划进度
  @Observed
  progress: PlanProgress | null = null
  
  // 进度百分比
  @Observed
  progressPercentage: number = 0
  
  // 本周训练计划
  @Observed
  weekPlan: DailyWorkout[] = []
  
  // 是否正在加载
  @Observed
  isLoading: boolean = false
  
  // 错误信息
  @Observed
  errorMessage: string = ""
  
  // 选中的模板
  @Observed
  selectedTemplate: PlanTemplate | null = null
  
  // 新建计划表单
  @Observed
  newPlanForm: {
    name: string
    goal: PlanGoal
    level: PlanLevel
    durationWeeks: number
    startDate: number
  } = {
    name: "",
    goal: PlanGoal.STRENGTH,
    level: PlanLevel.BEGINNER,
    durationWeeks: 4,
    startDate: Date.now()
  }
  
  // 训练目标选项
  goalOptions: { value: PlanGoal, label: string }[] = [
    { value: PlanGoal.STRENGTH, label: "增肌" },
    { value: PlanGoal.ENDURANCE, label: "耐力" },
    { value: PlanGoal.FLEXIBILITY, label: "柔韧性" },
    { value: PlanGoal.WEIGHT_LOSS, label: "减脂" },
    { value: PlanGoal.GENERAL, label: "综合健身" }
  ]
  
  // 难度等级选项
  levelOptions: { value: PlanLevel, label: string }[] = [
    { value: PlanLevel.BEGINNER, label: "初学者" },
    { value: PlanLevel.INTERMEDIATE, label: "中级" },
    { value: PlanLevel.ADVANCED, label: "高级" }
  ]
  
  // 周期选项
  durationOptions: number[] = [4, 6, 8, 12]
  
  // 服务实例
  private service: WorkoutPlanService
  
  constructor() {
    this.service = new WorkoutPlanService()
  }
  
  /**
   * 初始化 ViewModel
   */
  async initialize(): Promise<void> {
    this.isLoading = true
    this.errorMessage = ""
    
    try {
      await this.service.initialize()
      await this.loadPlans()
      await this.loadTemplates()
      await this.loadTodayWorkout()
    } catch (error) {
      this.errorMessage = "初始化失败: " + String(error)
      console.error(this.errorMessage)
    } finally {
      this.isLoading = false
    }
  }
  
  /**
   * 加载所有计划
   */
  async loadPlans(): Promise<void> {
    try {
      this.plans = await this.service.getAllPlans()
      this.activePlan = await this.service.getActivePlan()
      
      if (this.activePlan) {
        await this.loadProgress()
        await this.loadWeekPlan()
      }
    } catch (error) {
      this.errorMessage = "加载计划失败: " + String(error)
    }
  }
  
  /**
   * 加载模板列表
   */
  async loadTemplates(): Promise<void> {
    try {
      this.templates = this.service.getTemplates()
    } catch (error) {
      this.errorMessage = "加载模板失败: " + String(error)
    }
  }
  
  /**
   * 加载今日训练
   */
  async loadTodayWorkout(): Promise<void> {
    try {
      this.todayWorkout = await this.service.getTodayWorkout()
    } catch (error) {
      this.errorMessage = "加载今日训练失败: " + String(error)
    }
  }
  
  /**
   * 加载计划进度
   */
  async loadProgress(): Promise<void> {
    if (!this.activePlan) return
    
    try {
      this.progress = await this.service.getProgress(this.activePlan.id)
      this.progressPercentage = await this.service.getProgressPercentage(this.activePlan.id)
    } catch (error) {
      console.error("加载进度失败:", error)
    }
  }
  
  /**
   * 加载本周训练计划
   */
  async loadWeekPlan(): Promise<void> {
    if (!this.activePlan) return
    
    try {
      this.weekPlan = await this.service.getWeekPlan(this.activePlan.id)
    } catch (error) {
      console.error("加载周计划失败:", error)
    }
  }
  
  /**
   * 从模板创建计划
   */
  async createFromTemplate(template: PlanTemplate, customizations?: {
    name?: string
    durationWeeks?: number
  }): Promise<number> {
    this.isLoading = true
    
    try {
      const planId = await this.service.createPlanFromTemplate(template, customizations)
      await this.loadPlans()
      return planId
    } catch (error) {
      this.errorMessage = "创建计划失败: " + String(error)
      return -1
    } finally {
      this.isLoading = false
    }
  }
  
  /**
   * 创建自定义计划
   */
  async createCustomPlan(): Promise<number> {
    if (!this.newPlanForm.name) {
      this.errorMessage = "请输入计划名称"
      return -1
    }
    
    this.isLoading = true
    
    try {
      const plan = new WorkoutPlan()
      plan.name = this.newPlanForm.name
      plan.goal = this.newPlanForm.goal
      plan.level = this.newPlanForm.level
      plan.durationWeeks = this.newPlanForm.durationWeeks
      plan.startDate = this.newPlanForm.startDate
      
      const planId = await this.service['dao'].createPlan(plan)
      await this.loadPlans()
      
      // 重置表单
      this.newPlanForm = {
        name: "",
        goal: PlanGoal.STRENGTH,
        level: PlanLevel.BEGINNER,
        durationWeeks: 4,
        startDate: Date.now()
      }
      
      return planId
    } catch (error) {
      this.errorMessage = "创建计划失败: " + String(error)
      return -1
    } finally {
      this.isLoading = false
    }
  }
  
  /**
   * 开始计划
   */
  async startPlan(planId: number): Promise<boolean> {
    this.isLoading = true
    
    try {
      const success = await this.service.startPlan(planId)
      if (success) {
        await this.loadPlans()
      }
      return success
    } catch (error) {
      this.errorMessage = "启动计划失败: " + String(error)
      return false
    } finally {
      this.isLoading = false
    }
  }
  
  /**
   * 暂停计划
   */
  async pausePlan(planId: number): Promise<boolean> {
    this.isLoading = true
    
    try {
      const success = await this.service.pausePlan(planId)
      if (success) {
        await this.loadPlans()
      }
      return success
    } catch (error) {
      this.errorMessage = "暂停计划失败: " + String(error)
      return false
    } finally {
      this.isLoading = false
    }
  }
  
  /**
   * 放弃计划
   */
  async abandonPlan(planId: number): Promise<boolean> {
    this.isLoading = true
    
    try {
      const success = await this.service.abandonPlan(planId)
      if (success) {
        await this.loadPlans()
      }
      return success
    } catch (error) {
      this.errorMessage = "放弃计划失败: " + String(error)
      return false
    } finally {
      this.isLoading = false
    }
  }
  
  /**
   * 完成今日训练
   */
  async completeTodayWorkout(workout: DailyWorkout): Promise<boolean> {
    this.isLoading = true
    
    try {
      workout.isCompleted = true
      workout.completedAt = Date.now()
      
      const success = await this.service.completeTodayWorkout(workout)
      if (success) {
        await this.loadTodayWorkout()
        await this.loadProgress()
      }
      return success
    } catch (error) {
      this.errorMessage = "记录训练失败: " + String(error)
      return false
    } finally {
      this.isLoading = false
    }
  }
  
  /**
   * 筛选模板（按目标）
   */
  filterTemplatesByGoal(goal: PlanGoal): PlanTemplate[] {
    return this.templates.filter(t => t.goal === goal)
  }
  
  /**
   * 筛选模板（按难度）
   */
  filterTemplatesByLevel(level: PlanLevel): PlanTemplate[] {
    return this.templates.filter(t => t.level === level)
  }
  
  /**
   * 获取进行中的计划列表
   */
  getActivePlans(): WorkoutPlan[] {
    return this.plans.filter(p => p.status === PlanStatus.ACTIVE)
  }
  
  /**
   * 获取已完成的计划列表
   */
  getCompletedPlans(): WorkoutPlan[] {
    return this.plans.filter(p => p.status === PlanStatus.COMPLETED)
  }
  
  /**
   * 获取草稿计划列表
   */
  getDraftPlans(): WorkoutPlan[] {
    return this.plans.filter(p => p.status === PlanStatus.DRAFT)
  }
  
  /**
   * 清除错误信息
   */
  clearError(): void {
    this.errorMessage = ""
  }
  
  /**
   * 获取状态文本
   */
  getStatusText(status: PlanStatus): string {
    switch (status) {
      case PlanStatus.DRAFT: return "草稿"
      case PlanStatus.ACTIVE: return "进行中"
      case PlanStatus.PAUSED: return "已暂停"
      case PlanStatus.COMPLETED: return "已完成"
      case PlanStatus.ABANDONED: return "已放弃"
      default: return "未知"
    }
  }
  
  /**
   * 获取目标文本
   */
  getGoalText(goal: PlanGoal): string {
    const option = this.goalOptions.find(o => o.value === goal)
    return option?.label || "未知"
  }
  
  /**
   * 获取难度文本
   */
  getLevelText(level: PlanLevel): string {
    const option = this.levelOptions.find(o => o.value === level)
    return option?.label || "未知"
  }
}

// ArkUI 装饰器（需要在实际使用环境中导入）
function Observed(target: any, propertyKey: string) {
  // 装饰器实现
}

function Obsured(target: any, propertyKey: string) {
  // 简化实现
}
