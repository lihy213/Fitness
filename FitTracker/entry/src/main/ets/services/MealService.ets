/**
 * 饮食记录服务
 * 业务逻辑层
 */

import { MealRecord, DailyNutrition, FoodItem, MealType, NutritionTarget, WeeklyNutritionReport } from '../database/entities/MealRecord'
import { MealDao } from '../database/dao/MealDao'

export class MealService {
  private dao: MealDao
  
  constructor() {
    this.dao = new MealDao()
  }
  
  /**
   * 初始化服务
   */
  async initialize(): Promise<void> {
    await this.dao.initialize()
  }
  
  /**
   * 添加饮食记录
   */
  async addMeal(record: MealRecord): Promise<number> {
    return await this.dao.addMeal(record)
  }
  
  /**
   * 添加食物记录（通过搜索食物）
   */
  async addFoodRecord(foodName: string, amount: number, mealType: MealType, dateString?: string): Promise<number> {
    // 搜索食物
    const foods = this.dao.searchFoods(foodName)
    if (foods.length === 0) {
      throw new Error("未找到该食物")
    }
    
    const food = foods[0]
    
    // 计算营养
    const nutrition = food.calculateNutrition(amount)
    
    // 创建记录
    const record = new MealRecord(food.name, mealType)
    record.amount = amount
    record.calories = nutrition.calories
    record.protein = nutrition.protein
    record.carbs = nutrition.carbs
    record.fat = nutrition.fat
    record.dateString = dateString || this.formatDate(new Date())
    
    return await this.dao.addMeal(record)
  }
  
  /**
   * 添加自定义食物记录
   */
  async addCustomMeal(
    foodName: string,
    calories: number,
    protein: number,
    carbs: number,
    fat: number,
    amount: number,
    amountUnit: string,
    mealType: MealType,
    dateString?: string
  ): Promise<number> {
    const record = new MealRecord(foodName, mealType)
    record.amount = amount
    record.amountUnit = amountUnit
    record.calories = calories
    record.protein = protein
    record.carbs = carbs
    record.fat = fat
    record.dateString = dateString || this.formatDate(new Date())
    
    return await this.dao.addMeal(record)
  }
  
  /**
   * 添加饮水记录
   */
  async addWaterRecord(amount: number, dateString?: string): Promise<number> {
    const record = new MealRecord("饮水", MealType.SNACK)
    record.water = amount
    record.amount = amount
    record.amountUnit = "ml"
    record.dateString = dateString || this.formatDate(new Date())
    
    return await this.dao.addMeal(record)
  }
  
  /**
   * 更新饮食记录
   */
  async updateMeal(record: MealRecord): Promise<number> {
    return await this.dao.updateMeal(record)
  }
  
  /**
   * 删除饮食记录
   */
  async deleteMeal(id: number): Promise<number> {
    return await this.dao.deleteMeal(id)
  }
  
  /**
   * 获取某日饮食记录
   */
  async getMealsByDate(dateString: string): Promise<MealRecord[]> {
    return await this.dao.getMealsByDate(dateString)
  }
  
  /**
   * 获取某天某餐的记录
   */
  async getMealsByMealType(dateString: string, mealType: MealType): Promise<MealRecord[]> {
    return await this.dao.getMealsByDateAndType(dateString, mealType)
  }
  
  /**
   * 获取今日饮食记录
   */
  async getTodayMeals(): Promise<MealRecord[]> {
    const today = this.formatDate(new Date())
    return await this.getMealsByDate(today)
  }
  
  /**
   * 获取今日营养汇总
   */
  async getTodayNutrition(): Promise<DailyNutrition> {
    const today = this.formatDate(new Date())
    const nutrition = await this.dao.getDailyNutrition(today)
    return nutrition
  }
  
  /**
   * 获取指定日期的营养汇总
   */
  async getDailyNutrition(dateString: string): Promise<DailyNutrition> {
    return await this.dao.getDailyNutrition(dateString)
  }
  
  /**
   * 获取本周营养数据
   */
  async getWeekNutrition(): Promise<DailyNutrition[]> {
    return await this.dao.getWeekNutrition()
  }
  
  /**
   * 获取日期范围的营养报告
   */
  async getWeeklyReport(startDate: string, endDate: string): Promise<WeeklyNutritionReport> {
    const meals = await this.dao.getMealsByDateRange(startDate, endDate)
    
    // 按日期分组
    const mealsByDate = new Map<string, MealRecord[]>()
    for (const meal of meals) {
      const existing = mealsByDate.get(meal.dateString) || []
      existing.push(meal)
      mealsByDate.set(meal.dateString, existing)
    }
    
    // 生成每日汇总
    const dailyData: DailyNutrition[] = []
    const start = new Date(startDate)
    const end = new Date(endDate)
    
    for (let d = new Date(start); d <= end; d.setDate(d.getDate() + 1)) {
      const dateString = this.formatDate(d)
      const dayMeals = mealsByDate.get(dateString) || []
      
      const nutrition = new DailyNutrition()
      nutrition.dateString = dateString
      nutrition.date = d.getTime()
      nutrition.recordCount = dayMeals.length
      
      for (const meal of dayMeals) {
        nutrition.totalCalories += meal.calories
        nutrition.totalProtein += meal.protein
        nutrition.totalCarbs += meal.carbs
        nutrition.totalFat += meal.fat
        nutrition.totalWater += meal.water
      }
      
      dailyData.push(nutrition)
    }
    
    const report = new WeeklyNutritionReport()
    report.startDate = start.getTime()
    report.endDate = end.getTime()
    report.dailyData = dailyData
    
    return report
  }
  
  /**
   * 搜索食物
   */
  searchFoods(keyword: string): FoodItem[] {
    return this.dao.searchFoods(keyword)
  }
  
  /**
   * 获取常见份量
   */
  getCommonServings(foodName: string): { name: string, amount: number }[] {
    return this.dao.getCommonServings(foodName)
  }
  
  /**
   * 获取营养目标（根据用户设置）
   */
  getNutritionTarget(): NutritionTarget {
    // TODO: 从用户设置中读取
    const target = new NutritionTarget()
    return target
  }
  
  /**
   * 设置营养目标
   */
  async setNutritionTarget(target: NutritionTarget): Promise<void> {
    // TODO: 保存到用户设置
  }
  
  /**
   * 获取今日剩余可摄入热量
   */
  async getRemainingCalories(): Promise<number> {
    const nutrition = await this.getTodayNutrition()
    const target = this.getNutritionTarget()
    return target.dailyCalories - nutrition.totalCalories
  }
  
  /**
   * 获取营养建议
   */
  async getNutritionAdvice(): Promise<string> {
    const nutrition = await this.getTodayNutrition()
    const target = this.getNutritionTarget()
    const advice: string[] = []
    
    // 热量建议
    if (nutrition.totalCalories < target.dailyCalories * 0.8) {
      advice.push("今日摄入较少，注意补充能量")
    } else if (nutrition.totalCalories > target.dailyCalories) {
      advice.push("今日热量已超标，建议减少晚餐份量")
    }
    
    // 蛋白质建议
    if (nutrition.totalProtein < target.proteinTarget * 0.8) {
      advice.push("蛋白质摄入不足，建议增加肉类、蛋类")
    }
    
    // 碳水建议
    if (nutrition.totalCarbs > target.carbsTarget) {
      advice.push("碳水化合物偏高，减少主食摄入")
    }
    
    // 饮水建议
    if (nutrition.totalWater < target.waterTarget * 0.5) {
      advice.push("记得多喝水！")
    }
    
    return advice.length > 0 ? advice.join("；") + "。" : "今日营养摄入良好，继续保持！"
  }
  
  /**
   * 获取餐次营养分布
   */
  async getMealDistribution(dateString: string): Promise<{
    breakfast: { calories: number, percentage: number }
    lunch: { calories: number, percentage: number }
    dinner: { calories: number, percentage: number }
    snack: { calories: number, percentage: number }
  }> {
    const nutrition = await this.getDailyNutrition(dateString)
    const total = nutrition.totalCalories || 1
    
    return {
      breakfast: {
        calories: nutrition.breakfastCalories,
        percentage: Math.round((nutrition.breakfastCalories / total) * 100)
      },
      lunch: {
        calories: nutrition.lunchCalories,
        percentage: Math.round((nutrition.lunchCalories / total) * 100)
      },
      dinner: {
        calories: nutrition.dinnerCalories,
        percentage: Math.round((nutrition.dinnerCalories / total) * 100)
      },
      snack: {
        calories: nutrition.snackCalories,
        percentage: Math.round((nutrition.snackCalories / total) * 100)
      }
    }
  }
  
  /**
   * 获取星期几的中文名称
   */
  getDayName(dateString: string): string {
    const date = new Date(dateString)
    const days = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
    return days[date.getDay()]
  }
  
  /**
   * 获取指定日期是周几
   */
  getDayOfWeek(dateString: string): number {
    return new Date(dateString).getDay()
  }
  
  /**
   * 格式化日期
   */
  private formatDate(date: Date): string {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }
  
  /**
   * 获取昨天的日期字符串
   */
  getYesterdayDateString(): string {
    const yesterday = new Date()
    yesterday.setDate(yesterday.getDate() - 1)
    return this.formatDate(yesterday)
  }
  
  /**
   * 获取上周的日期范围
   */
  getLastWeekDateRange(): { start: string, end: string } {
    const today = new Date()
    const end = new Date(today)
    end.setDate(today.getDate() - 1) // 昨天
    
    const start = new Date(end)
    start.setDate(end.getDate() - 6) // 7天前
    
    return {
      start: this.formatDate(start),
      end: this.formatDate(end)
    }
  }
}
