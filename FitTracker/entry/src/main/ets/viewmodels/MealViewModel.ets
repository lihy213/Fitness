/**
 * 饮食记录 ViewModel
 */

import { MealRecord, DailyNutrition, FoodItem, MealType, NutritionTarget } from '../database/entities/MealRecord'
import { MealService } from '../services/MealService'

export class MealViewModel {
  // 当日饮食记录
  @Observed
  todayMeals: MealRecord[] = []
  
  // 今日营养汇总
  @Observed
  todayNutrition: DailyNutrition = new DailyNutrition()
  
  // 选中日期的记录
  @Observed
  selectedDateMeals: MealRecord[] = []
  
  // 选中日期的营养汇总
  @Observed
  selectedDateNutrition: DailyNutrition = new DailyNutrition()
  
  // 当前选中的日期
  @Observed
  selectedDate: string = ""
  
  // 当前选中的餐次
  @Observed
  selectedMealType: MealType = MealType.BREAKFAST
  
  // 搜索结果
  @Observed
  searchResults: FoodItem[] = []
  
  // 搜索关键词
  @Observed
  searchKeyword: string = ""
  
  // 营养目标
  @Observed
  nutritionTarget: NutritionTarget = new NutritionTarget()
  
  // 营养建议
  @Observed
  nutritionAdvice: string = ""
  
  // 剩余可摄入热量
  @Observed
  remainingCalories: number = 0
  
  // 餐次营养分布
  @Observed
  mealDistribution: {
    breakfast: { calories: number, percentage: number }
    lunch: { calories: number, percentage: number }
    dinner: { calories: number, percentage: number }
    snack: { calories: number, percentage: number }
  } | null = null
  
  // 是否正在加载
  @Observed
  isLoading: boolean = false
  
  // 错误信息
  @Observed
  errorMessage: string = ""
  
  // 添加食物表单
  @Observed
  addFoodForm: {
    foodName: string
    amount: string
    amountUnit: string
    calories: string
    protein: string
    carbs: string
    fat: string
  } = {
    foodName: "",
    amount: "100",
    amountUnit: "g",
    calories: "",
    protein: "",
    carbs: "",
    fat: ""
  }
  
  // 是否显示添加食物弹窗
  @Observed
  showAddFoodDialog: boolean = false
  
  // 餐次选项
  mealTypeOptions: { value: MealType, label: string, icon: string }[] = [
    { value: MealType.BREAKFAST, label: "早餐", icon: "☀️" },
    { value: MealType.LUNCH, label: "午餐", icon: "🌤️" },
    { value: MealType.DINNER, label: "晚餐", icon: "🌙" },
    { value: MealType.SNACK, label: "加餐", icon: "🍎" }
  ]
  
  // 服务实例
  private service: MealService
  
  constructor() {
    this.service = new MealService()
    this.selectedDate = this.formatDate(new Date())
  }
  
  /**
   * 初始化 ViewModel
   */
  async initialize(): Promise<void> {
    this.isLoading = true
    this.errorMessage = ""
    
    try {
      await this.service.initialize()
      await this.loadTodayData()
      await this.loadNutritionTarget()
      await this.loadAdvice()
    } catch (error) {
      this.errorMessage = "初始化失败: " + String(error)
      console.error(this.errorMessage)
    } finally {
      this.isLoading = false
    }
  }
  
  /**
   * 加载今日数据
   */
  async loadTodayData(): Promise<void> {
    try {
      this.todayMeals = await this.service.getTodayMeals()
      this.todayNutrition = await this.service.getTodayNutrition()
      this.selectedDateMeals = this.todayMeals
      this.selectedDateNutrition = this.todayNutrition
      this.remainingCalories = await this.service.getRemainingCalories()
      this.mealDistribution = await this.service.getMealDistribution(this.selectedDate)
    } catch (error) {
      this.errorMessage = "加载数据失败: " + String(error)
    }
  }
  
  /**
   * 选择日期
   */
  async selectDate(dateString: string): Promise<void> {
    this.selectedDate = dateString
    
    try {
      this.selectedDateMeals = await this.service.getMealsByDate(dateString)
      this.selectedDateNutrition = await this.service.getDailyNutrition(dateString)
      this.mealDistribution = await this.service.getMealDistribution(dateString)
    } catch (error) {
      this.errorMessage = "加载数据失败: " + String(error)
    }
  }
  
  /**
   * 选择餐次
   */
  selectMealType(mealType: MealType): void {
    this.selectedMealType = mealType
  }
  
  /**
   * 获取选中餐次的记录
   */
  getMealsBySelectedType(): MealRecord[] {
    return this.selectedDateMeals.filter(m => m.mealType === this.selectedMealType)
  }
  
  /**
   * 获取选中餐次的热量
   */
  getCaloriesBySelectedType(): number {
    return this.getMealsBySelectedType().reduce((sum, m) => sum + m.calories, 0)
  }
  
  /**
   * 搜索食物
   */
  searchFood(keyword: string): void {
    this.searchKeyword = keyword
    if (keyword.length >= 1) {
      this.searchResults = this.service.searchFoods(keyword)
    } else {
      this.searchResults = []
    }
  }
  
  /**
   * 选择搜索结果
   */
  selectFood(food: FoodItem): void {
    this.addFoodForm.foodName = food.name
    this.addFoodForm.calories = String(food.caloriesPer100g)
    this.addFoodForm.protein = String(food.proteinPer100g)
    this.addFoodForm.carbs = String(food.carbsPer100g)
    this.addFoodForm.fat = String(food.fatPer100g)
    this.searchResults = []
    this.searchKeyword = ""
  }
  
  /**
   * 更新份量后重新计算营养
   */
  updateAmount(amount: string): void {
    this.addFoodForm.amount = amount
    const amountNum = parseFloat(amount) || 0
    const calNum = parseFloat(this.addFoodForm.calories) || 0
    const protNum = parseFloat(this.addFoodForm.protein) || 0
    const carbNum = parseFloat(this.addFoodForm.carbs) || 0
    const fatNum = parseFloat(this.addFoodForm.fat) || 0
    
    if (amountNum > 0) {
      const factor = amountNum / 100
      // 营养值已在选择食物时设置，这里用于显示提示
    }
  }
  
  /**
   * 添加食物记录
   */
  async addMeal(): Promise<boolean> {
    if (!this.addFoodForm.foodName) {
      this.errorMessage = "请输入食物名称"
      return false
    }
    
    const amount = parseFloat(this.addFoodForm.amount) || 100
    
    this.isLoading = true
    
    try {
      await this.service.addCustomMeal(
        this.addFoodForm.foodName,
        parseFloat(this.addFoodForm.calories) || 0,
        parseFloat(this.addFoodForm.protein) || 0,
        parseFloat(this.addFoodForm.carbs) || 0,
        parseFloat(this.addFoodForm.fat) || 0,
        amount,
        this.addFoodForm.amountUnit,
        this.selectedMealType,
        this.selectedDate
      )
      
      // 重新加载数据
      await this.selectDate(this.selectedDate)
      
      // 重置表单
      this.resetForm()
      this.showAddFoodDialog = false
      
      return true
    } catch (error) {
      this.errorMessage = "添加失败: " + String(error)
      return false
    } finally {
      this.isLoading = false
    }
  }
  
  /**
   * 删除饮食记录
   */
  async deleteMeal(id: number): Promise<boolean> {
    this.isLoading = true
    
    try {
      await this.service.deleteMeal(id)
      await this.selectDate(this.selectedDate)
      return true
    } catch (error) {
      this.errorMessage = "删除失败: " + String(error)
      return false
    } finally {
      this.isLoading = false
    }
  }
  
  /**
   * 添加饮水记录
   */
  async addWater(amount: number): Promise<boolean> {
    this.isLoading = true
    
    try {
      await this.service.addWaterRecord(amount, this.selectedDate)
      await this.selectDate(this.selectedDate)
      return true
    } catch (error) {
      this.errorMessage = "添加失败: " + String(error)
      return false
    } finally {
      this.isLoading = false
    }
  }
  
  /**
   * 加载营养目标
   */
  async loadNutritionTarget(): Promise<void> {
    try {
      this.nutritionTarget = this.service.getNutritionTarget()
    } catch (error) {
      console.error("加载营养目标失败:", error)
    }
  }
  
  /**
   * 加载营养建议
   */
  async loadAdvice(): Promise<void> {
    try {
      this.nutritionAdvice = await this.service.getNutritionAdvice()
    } catch (error) {
      console.error("加载营养建议失败:", error)
    }
  }
  
  /**
   * 获取营养建议
   */
  getAdvice(): string {
    return this.nutritionAdvice
  }
  
  /**
   * 计算进度百分比
   */
  calculateProgress(current: number, target: number): number {
    if (target <= 0) return 0
    return Math.min(100, Math.round((current / target) * 100))
  }
  
  /**
   * 获取热量颜色
   */
  getCaloriesColor(): string {
    const progress = this.calculateProgress(
      this.selectedDateNutrition.totalCalories,
      this.nutritionTarget.dailyCalories
    )
    
    if (progress < 80) return '#FAAD14' // 不足
    if (progress <= 100) return '#52C41A' // 达标
    return '#FF4D4F' // 超标
  }
  
  /**
   * 获取餐次图标
   */
  getMealTypeIcon(mealType: MealType): string {
    const option = this.mealTypeOptions.find(o => o.value === mealType)
    return option?.icon || "🍽️"
  }
  
  /**
   * 获取餐次名称
   */
  getMealTypeName(mealType: MealType): string {
    const option = this.mealTypeOptions.find(o => o.value === mealType)
    return option?.label || "未知"
  }
  
  /**
   * 重置表单
   */
  resetForm(): void {
    this.addFoodForm = {
      foodName: "",
      amount: "100",
      amountUnit: "g",
      calories: "",
      protein: "",
      carbs: "",
      fat: ""
    }
    this.searchKeyword = ""
    this.searchResults = []
  }
  
  /**
   * 显示添加食物弹窗
   */
  openAddFoodDialog(): void {
    this.showAddFoodDialog = true
    this.resetForm()
  }
  
  /**
   * 关闭添加食物弹窗
   */
  closeAddFoodDialog(): void {
    this.showAddFoodDialog = false
    this.resetForm()
  }
  
  /**
   * 清除错误
   */
  clearError(): void {
    this.errorMessage = ""
  }
  
  /**
   * 格式化日期显示
   */
  formatDateDisplay(dateString: string): string {
    const today = this.formatDate(new Date())
    const yesterday = this.getYesterday()
    
    if (dateString === today) return "今天"
    if (dateString === yesterday) return "昨天"
    
    const date = new Date(dateString)
    return `${date.getMonth() + 1}月${date.getDate()}日`
  }
  
  /**
   * 获取昨天的日期字符串
   */
  private getYesterday(): string {
    const yesterday = new Date()
    yesterday.setDate(yesterday.getDate() - 1)
    return this.formatDate(yesterday)
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

// ArkUI 装饰器
function Observed(target: any, propertyKey: string) {
  // 装饰器实现
}
