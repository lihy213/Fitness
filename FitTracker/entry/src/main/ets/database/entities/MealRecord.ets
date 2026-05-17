/**
 * 饮食记录实体
 * 记录用户的每日饮食摄入
 * 
 * Python对比：
 * class MealRecord:
 *     def __init__(self):
 *         self.id: int = 0              # 主键自增
 *         self.date: int = 0           # 日期时间戳
 *         self.meal_type: str = ""      # 餐次：breakfast/lunch/dinner/snack
 *         self.food_name: str = ""      # 食物名称
 *         self.amount: float = 0       # 份量（克或ml）
 *         self.calories: int = 0        # 热量（千卡）
 *         self.protein: float = 0       # 蛋白质（克）
 *         self.carbs: float = 0         # 碳水化合物（克）
 *         self.fat: float = 0            # 脂肪（克）
 *         self.fiber: float = 0         # 膳食纤维（克）
 *         self.sodium: float = 0        # 钠（毫克）
 *         self.water: float = 0        # 饮水（ml）
 *         self.notes: str = ""          # 备注
 *         self.created_at: int = 0      # 创建时间
 */
export class MealRecord {
  // 主键
  id: number = 0
  
  // 日期时间戳
  date: number = 0
  
  // 日期字符串 (YYYY-MM-DD)
  dateString: string = ""
  
  // 餐次类型
  mealType: MealType = MealType.BREAKFAST
  
  // 食物名称
  foodName: string = ""
  
  // 份量
  amount: number = 0
  
  // 份量单位
  amountUnit: string = "g"
  
  // 热量（千卡）
  calories: number = 0
  
  // 蛋白质（克）
  protein: number = 0
  
  // 碳水化合物（克）
  carbs: number = 0
  
  // 脂肪（克）
  fat: number = 0
  
  // 膳食纤维（克）
  fiber: number = 0
  
  // 钠（毫克）
  sodium: number = 0
  
  // 饮水（ml）
  water: number = 0
  
  // 备注
  notes: string = ""
  
  // 创建时间
  createdAt: number = 0
  
  // 更新时间
  updatedAt: number = 0
  
  constructor(foodName: string = "", mealType: MealType = MealType.BREAKFAST) {
    const now = Date.now()
    this.date = now
    this.dateString = this.formatDate(new Date(now))
    this.mealType = mealType
    this.foodName = foodName
    this.createdAt = now
    this.updatedAt = now
  }
  
  /**
   * 获取总热量（用于显示）
   */
  getTotalCalories(): number {
    return this.calories
  }
  
  /**
   * 计算三大营养素占比
   */
  getMacrosRatio(): { protein: number, carbs: number, fat: number } {
    const totalCal = (this.protein * 4) + (this.carbs * 4) + (this.fat * 9)
    if (totalCal === 0) return { protein: 0, carbs: 0, fat: 0 }
    
    return {
      protein: Math.round((this.protein * 4 / totalCal) * 100),
      carbs: Math.round((this.carbs * 4 / totalCal) * 100),
      fat: Math.round((this.fat * 9 / totalCal) * 100)
    }
  }
  
  private formatDate(date: Date): string {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }
}

/**
 * 餐次类型枚举
 */
export enum MealType {
  BREAKFAST = "breakfast",     // 早餐
  LUNCH = "lunch",             // 午餐
  DINNER = "dinner",           // 晚餐
  SNACK = "snack"              // 零食/加餐
}

/**
 * 每日营养汇总
 * 用于显示一天的总摄入
 */
export class DailyNutrition {
  // 日期
  date: number = 0
  
  // 日期字符串
  dateString: string = ""
  
  // 总热量（千卡）
  totalCalories: number = 0
  
  // 总蛋白质（克）
  totalProtein: number = 0
  
  // 总碳水化合物（克）
  totalCarbs: number = 0
  
  // 总脂肪（克）
  totalFat: number = 0
  
  // 总膳食纤维（克）
  totalFiber: number = 0
  
  // 总钠（毫克）
  totalSodium: number = 0
  
  // 总饮水（ml）
  totalWater: number = 0
  
  // 早餐热量
  breakfastCalories: number = 0
  
  // 午餐热量
  lunchCalories: number = 0
  
  // 晚餐热量
  dinnerCalories: number = 0
  
  // 零食热量
  snackCalories: number = 0
  
  // 记录数
  recordCount: number = 0
  
  // 目标热量
  targetCalories: number = 2000
  
  // 热量完成率
  get caloriesProgress(): number {
    return this.targetCalories > 0 
      ? Math.round((this.totalCalories / this.targetCalories) * 100) 
      : 0
  }
}

/**
 * 食物数据库条目
 * 预设常用食物的营养成分
 */
export class FoodItem {
  // 食物ID
  id: number = 0
  
  // 食物名称
  name: string = ""
  
  // 分类
  category: FoodCategory = FoodCategory.GRAIN
  
  // 每100g的热量
  caloriesPer100g: number = 0
  
  // 每100g的蛋白质
  proteinPer100g: number = 0
  
  // 每100g的碳水
  carbsPer100g: number = 0
  
  // 每100g的脂肪
  fatPer100g: number = 0
  
  // 每100g的纤维
  fiberPer100g: number = 0
  
  // GI值（血糖生成指数）
  gi: number = 0
  
  // 常用份量
  commonServings: { name: string, amount: number }[] = []
  
  // 备注
  notes: string = ""
  
  /**
   * 根据份量计算营养
   */
  calculateNutrition(amount: number): { calories: number, protein: number, carbs: number, fat: number } {
    const factor = amount / 100
    return {
      calories: Math.round(this.caloriesPer100g * factor),
      protein: Math.round(this.proteinPer100g * factor * 10) / 10,
      carbs: Math.round(this.carbsPer100g * factor * 10) / 10,
      fat: Math.round(this.fatPer100g * factor * 10) / 10
    }
  }
}

/**
 * 食物分类枚举
 */
export enum FoodCategory {
  GRAIN = "grain",             // 谷物主食
  VEGETABLE = "vegetable",      // 蔬菜
  FRUIT = "fruit",              // 水果
  MEAT = "meat",                // 肉类
  SEAFOOD = "seafood",          // 海鲜
  EGG = "egg",                  // 蛋类
  DAIRY = "dairy",              // 奶制品
  BEAN = "bean",                // 豆类
  OIL = "oil",                  // 油脂
  SNACK = "snack",              // 零食
  DRINK = "drink",              // 饮料
  OTHER = "other"               // 其他
}

/**
 * 营养目标设定
 */
export class NutritionTarget {
  // 每日目标热量（千卡）
  dailyCalories: number = 2000
  
  // 蛋白质目标（克）或百分比
  proteinTarget: number = 150  // 约30%
  
  // 碳水目标（克）或百分比
  carbsTarget: number = 250   // 约50%
  
  // 脂肪目标（克）或百分比
  fatTarget: number = 65        // 约20%
  
  // 纤维目标（克）
  fiberTarget: number = 30
  
  // 钠上限（毫克）
  sodiumLimit: number = 2000
  
  // 饮水目标（ml）
  waterTarget: number = 2000
  
  // 减脂模式
  isCutting: boolean = false
  
  // 增肌模式
  isBulking: boolean = false
  
  /**
   * 根据模式调整目标
   */
  adjustForGoal(isCutting: boolean, isBulking: boolean): void {
    this.isCutting = isCutting
    this.isBulking = isBulking
    
    if (isCutting) {
      // 减脂：减少20%热量
      this.dailyCalories = Math.round(this.dailyCalories * 0.8)
      this.proteinTarget = Math.round(this.proteinTarget * 1.2) // 增加蛋白质比例
    } else if (isBulking) {
      // 增肌：增加20%热量
      this.dailyCalories = Math.round(this.dailyCalories * 1.2)
      this.carbsTarget = Math.round(this.carbsTarget * 1.3) // 增加碳水比例
    }
  }
}

/**
 * 每周营养报告
 */
export class WeeklyNutritionReport {
  // 开始日期
  startDate: number = 0
  
  // 结束日期
  endDate: number = 0
  
  // 每日数据
  dailyData: DailyNutrition[] = []
  
  // 平均每日热量
  get avgDailyCalories(): number {
    if (this.dailyData.length === 0) return 0
    const total = this.dailyData.reduce((sum, d) => sum + d.totalCalories, 0)
    return Math.round(total / this.dailyData.length)
  }
  
  // 平均蛋白质
  get avgDailyProtein(): number {
    if (this.dailyData.length === 0) return 0
    const total = this.dailyData.reduce((sum, d) => sum + d.totalProtein, 0)
    return Math.round(total / this.dailyData.length * 10) / 10
  }
  
  // 达标天数
  get targetMetDays(): number {
    return this.dailyData.filter(d => d.totalCalories >= d.targetCalories * 0.9).length
  }
  
  // 达标率
  get targetMetRate(): number {
    if (this.dailyData.length === 0) return 0
    return Math.round((this.targetMetDays / this.dailyData.length) * 100)
  }
}
