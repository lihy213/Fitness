/**
 * 饮食记录 DAO
 * 数据库访问层
 * 
 * Python对比：
 * class MealDao:
 *     def __init__(self, db):
 *         self.db = db
 *     
 *     def add_meal(self, record: MealRecord) -> int:
 *         # 添加饮食记录
 *     
 *     def get_meals_by_date(self, date: str) -> list:
 *         # 获取某日饮食记录
 *     
 *     def get_nutrition_summary(self, start_date: str, end_date: str) -> dict:
 *         # 获取日期范围内的营养汇总
 */

import { MealRecord, DailyNutrition, FoodItem, FoodCategory, MealType } from '../entities/MealRecord'
import { DatabaseSchema } from '../DatabaseSchema'

export class MealDao {
  private store: relationalStore.RdbStore | null = null
  
  constructor() {}
  
  /**
   * 初始化 DAO
   */
  async initialize(): Promise<void> {
    this.store = await DatabaseSchema.getRdbStore()
  }
  
  /**
   * 添加饮食记录
   */
  async addMeal(record: MealRecord): Promise<number> {
    if (!this.store) await this.initialize()
    
    const result = await this.store.insert("meal_records", {
      date: record.date,
      date_string: record.dateString,
      meal_type: record.mealType,
      food_name: record.foodName,
      amount: record.amount,
      amount_unit: record.amountUnit,
      calories: record.calories,
      protein: record.protein,
      carbs: record.carbs,
      fat: record.fat,
      fiber: record.fiber,
      sodium: record.sodium,
      water: record.water,
      notes: record.notes,
      created_at: Date.now(),
      updated_at: Date.now()
    })
    
    return result.rowId
  }
  
  /**
   * 更新饮食记录
   */
  async updateMeal(record: MealRecord): Promise<number> {
    if (!this.store) await this.initialize()
    
    const predicates = new relationalStore.RdbPredicates("meal_records")
    predicates.equalTo("id", record.id)
    
    const result = await this.store.update("meal_records", {
      meal_type: record.mealType,
      food_name: record.foodName,
      amount: record.amount,
      amount_unit: record.amountUnit,
      calories: record.calories,
      protein: record.protein,
      carbs: record.carbs,
      fat: record.fat,
      fiber: record.fiber,
      sodium: record.sodium,
      water: record.water,
      notes: record.notes,
      updated_at: Date.now()
    }, predicates)
    
    return result.rowsAffected
  }
  
  /**
   * 删除饮食记录
   */
  async deleteMeal(id: number): Promise<number> {
    if (!this.store) await this.initialize()
    
    const predicates = new relationalStore.RdbPredicates("meal_records")
    predicates.equalTo("id", id)
    
    return await this.store.delete("meal_records", predicates)
  }
  
  /**
   * 根据ID获取记录
   */
  async getMealById(id: number): Promise<MealRecord | null> {
    if (!this.store) await this.initialize()
    
    const predicates = new relationalStore.RdbPredicates("meal_records")
    predicates.equalTo("id", id)
    
    const result = await this.store.query("meal_records", [predicates])
    
    if (result.rowSet.length > 0) {
      return this.rowToMeal(result.rowSet[0])
    }
    return null
  }
  
  /**
   * 获取某天的所有饮食记录
   */
  async getMealsByDate(dateString: string): Promise<MealRecord[]> {
    if (!this.store) await this.initialize()
    
    const predicates = new relationalStore.RdbPredicates("meal_records")
    predicates.equalTo("date_string", dateString)
    predicates.orderByAsc("created_at")
    
    const result = await this.store.query("meal_records", [predicates])
    
    const records: MealRecord[] = []
    for (const row of result.rowSet) {
      records.push(this.rowToMeal(row))
    }
    return records
  }
  
  /**
   * 获取某天某餐的所有记录
   */
  async getMealsByDateAndType(dateString: string, mealType: MealType): Promise<MealRecord[]> {
    if (!this.store) await this.initialize()
    
    const predicates = new relationalStore.RdbPredicates("meal_records")
    predicates.equalTo("date_string", dateString)
    predicates.equalTo("meal_type", mealType)
    predicates.orderByAsc("created_at")
    
    const result = await this.store.query("meal_records", [predicates])
    
    const records: MealRecord[] = []
    for (const row of result.rowSet) {
      records.push(this.rowToMeal(row))
    }
    return records
  }
  
  /**
   * 获取日期范围的记录
   */
  async getMealsByDateRange(startDate: string, endDate: string): Promise<MealRecord[]> {
    if (!this.store) await this.initialize()
    
    const predicates = new relationalStore.RdbPredicates("meal_records")
    predicates.greaterThanOrEqualTo("date_string", startDate)
    predicates.lessThanOrEqualTo("date_string", endDate)
    predicates.orderByDesc("date")
    
    const result = await this.store.query("meal_records", [predicates])
    
    const records: MealRecord[] = []
    for (const row of result.rowSet) {
      records.push(this.rowToMeal(row))
    }
    return records
  }
  
  /**
   * 获取每日营养汇总
   */
  async getDailyNutrition(dateString: string): Promise<DailyNutrition> {
    if (!this.store) await this.initialize()
    
    const meals = await this.getMealsByDate(dateString)
    const summary = new DailyNutrition()
    
    summary.dateString = dateString
    summary.date = new Date(dateString).getTime()
    summary.recordCount = meals.length
    
    // 累加营养成分
    for (const meal of meals) {
      summary.totalCalories += meal.calories
      summary.totalProtein += meal.protein
      summary.totalCarbs += meal.carbs
      summary.totalFat += meal.fat
      summary.totalFiber += meal.fiber
      summary.totalSodium += meal.sodium
      summary.totalWater += meal.water
      
      // 按餐次统计
      switch (meal.mealType) {
        case MealType.BREAKFAST:
          summary.breakfastCalories += meal.calories
          break
        case MealType.LUNCH:
          summary.lunchCalories += meal.calories
          break
        case MealType.DINNER:
          summary.dinnerCalories += meal.calories
          break
        case MealType.SNACK:
          summary.snackCalories += meal.calories
          break
      }
    }
    
    // 保留一位小数
    summary.totalProtein = Math.round(summary.totalProtein * 10) / 10
    summary.totalCarbs = Math.round(summary.totalCarbs * 10) / 10
    summary.totalFat = Math.round(summary.totalFat * 10) / 10
    summary.totalFiber = Math.round(summary.totalFiber * 10) / 10
    
    return summary
  }
  
  /**
   * 获取本周每日营养汇总
   */
  async getWeekNutrition(): Promise<DailyNutrition[]> {
    const today = new Date()
    const weekData: DailyNutrition[] = []
    
    // 获取本周从周一开始的数据
    const startOfWeek = new Date(today)
    startOfWeek.setDate(today.getDate() - ((today.getDay() + 6) % 7))
    
    for (let i = 0; i < 7; i++) {
      const date = new Date(startOfWeek)
      date.setDate(startOfWeek.getDate() + i)
      const dateString = this.formatDate(date)
      
      const dailyNutrition = await this.getDailyNutrition(dateString)
      weekData.push(dailyNutrition)
    }
    
    return weekData
  }
  
  /**
   * 搜索食物
   */
  searchFoods(keyword: string): FoodItem[] {
    const allFoods = this.getFoodDatabase()
    const lowerKeyword = keyword.toLowerCase()
    
    return allFoods.filter(food => 
      food.name.toLowerCase().includes(lowerKeyword)
    ).slice(0, 20) // 限制返回数量
  }
  
  /**
   * 获取食物数据库
   */
  getFoodDatabase(): FoodItem[] {
    return [
      // 谷物主食
      { id: 1, name: "米饭", category: FoodCategory.GRAIN, caloriesPer100g: 116, proteinPer100g: 2.6, carbsPer100g: 25.9, fatPer100g: 0.3, fiberPer100g: 0.3, gi: 73 },
      { id: 2, name: "面条", category: FoodCategory.GRAIN, caloriesPer100g: 284, proteinPer100g: 8.3, carbsPer100g: 59.5, fatPer100g: 0.8, fiberPer100g: 1.8, gi: 55 },
      { id: 3, name: "全麦面包", category: FoodCategory.GRAIN, caloriesPer100g: 247, proteinPer100g: 13, carbsPer100g: 41, fatPer100g: 3.4, fiberPer100g: 7, gi: 51 },
      { id: 4, name: "燕麦", category: FoodCategory.GRAIN, caloriesPer100g: 389, proteinPer100g: 16.9, carbsPer100g: 66, fatPer100g: 6.9, fiberPer100g: 10.6, gi: 55 },
      { id: 5, name: "红薯", category: FoodCategory.GRAIN, caloriesPer100g: 99, proteinPer100g: 1.1, carbsPer100g: 24, fatPer100g: 0.1, fiberPer100g: 2.3, gi: 54 },
      { id: 6, name: "玉米", category: FoodCategory.GRAIN, caloriesPer100g: 112, proteinPer100g: 4, carbsPer100g: 23, fatPer100g: 1.2, fiberPer100g: 2.9, gi: 52 },
      
      // 蔬菜
      { id: 10, name: "西兰花", category: FoodCategory.VEGETABLE, caloriesPer100g: 34, proteinPer100g: 2.8, carbsPer100g: 7, fatPer100g: 0.4, fiberPer100g: 2.6 },
      { id: 11, name: "菠菜", category: FoodCategory.VEGETABLE, caloriesPer100g: 23, proteinPer100g: 2.9, carbsPer100g: 3.6, fatPer100g: 0.4, fiberPer100g: 2.2 },
      { id: 12, name: "胡萝卜", category: FoodCategory.VEGETABLE, caloriesPer100g: 41, proteinPer100g: 0.9, carbsPer100g: 10, fatPer100g: 0.2, fiberPer100g: 2.8 },
      { id: 13, name: "番茄", category: FoodCategory.VEGETABLE, caloriesPer100g: 18, proteinPer100g: 0.9, carbsPer100g: 3.9, fatPer100g: 0.2, fiberPer100g: 1.2 },
      { id: 14, name: "黄瓜", category: FoodCategory.VEGETABLE, caloriesPer100g: 15, proteinPer100g: 0.7, carbsPer100g: 3.6, fatPer100g: 0.1, fiberPer100g: 0.5 },
      { id: 15, name: "生菜", category: FoodCategory.VEGETABLE, caloriesPer100g: 15, proteinPer100g: 1.4, carbsPer100g: 2.9, fatPer100g: 0.2, fiberPer100g: 1.3 },
      { id: 16, name: "青椒", category: FoodCategory.VEGETABLE, caloriesPer100g: 26, proteinPer100g: 1, carbsPer100g: 6, fatPer100g: 0.3, fiberPer100g: 2.1 },
      
      // 水果
      { id: 20, name: "苹果", category: FoodCategory.FRUIT, caloriesPer100g: 52, proteinPer100g: 0.3, carbsPer100g: 14, fatPer100g: 0.2, fiberPer100g: 2.4 },
      { id: 21, name: "香蕉", category: FoodCategory.FRUIT, caloriesPer100g: 93, proteinPer100g: 1.4, carbsPer100g: 23, fatPer100g: 0.2, fiberPer100g: 1.7, gi: 51 },
      { id: 22, name: "橙子", category: FoodCategory.FRUIT, caloriesPer100g: 47, proteinPer100g: 0.9, carbsPer100g: 12, fatPer100g: 0.1, fiberPer100g: 2.4 },
      { id: 23, name: "葡萄", category: FoodCategory.FRUIT, caloriesPer100g: 67, proteinPer100g: 0.6, carbsPer100g: 17, fatPer100g: 0.2, fiberPer100g: 0.9, gi: 59 },
      { id: 24, name: "西瓜", category: FoodCategory.FRUIT, caloriesPer100g: 30, proteinPer100g: 0.6, carbsPer100g: 8, fatPer100g: 0.1, fiberPer100g: 0.4, gi: 76 },
      { id: 25, name: "蓝莓", category: FoodCategory.FRUIT, caloriesPer100g: 57, proteinPer100g: 0.7, carbsPer100g: 14, fatPer100g: 0.3, fiberPer100g: 2.4 },
      
      // 肉类
      { id: 30, name: "鸡胸肉", category: FoodCategory.MEAT, caloriesPer100g: 133, proteinPer100g: 31, carbsPer100g: 0, fatPer100g: 1.2, fiberPer100g: 0 },
      { id: 31, name: "牛肉", category: FoodCategory.MEAT, caloriesPer100g: 250, proteinPer100g: 26, carbsPer100g: 0, fatPer100g: 15, fiberPer100g: 0 },
      { id: 32, name: "猪肉", category: FoodCategory.MEAT, caloriesPer100g: 242, proteinPer100g: 27, carbsPer100g: 0, fatPer100g: 14, fiberPer100g: 0 },
      { id: 33, name: "羊肉", category: FoodCategory.MEAT, caloriesPer100g: 294, proteinPer100g: 25, carbsPer100g: 0, fatPer100g: 21, fiberPer100g: 0 },
      { id: 34, name: "火鸡肉", category: FoodCategory.MEAT, caloriesPer100g: 114, proteinPer100g: 28, carbsPer100g: 0, fatPer100g: 0.7, fiberPer100g: 0 },
      
      // 海鲜
      { id: 40, name: "三文鱼", category: FoodCategory.SEAFOOD, caloriesPer100g: 208, proteinPer100g: 20, carbsPer100g: 0, fatPer100g: 13, fiberPer100g: 0 },
      { id: 41, name: "虾", category: FoodCategory.SEAFOOD, caloriesPer100g: 99, proteinPer100g: 24, carbsPer100g: 0.2, fatPer100g: 0.3, fiberPer100g: 0 },
      { id: 42, name: "鳕鱼", category: FoodCategory.SEAFOOD, caloriesPer100g: 82, proteinPer100g: 18, carbsPer100g: 0, fatPer100g: 0.7, fiberPer100g: 0 },
      { id: 43, name: "金枪鱼", category: FoodCategory.SEAFOOD, caloriesPer100g: 132, proteinPer100g: 28, carbsPer100g: 0, fatPer100g: 1.3, fiberPer100g: 0 },
      
      // 蛋类
      { id: 50, name: "鸡蛋", category: FoodCategory.EGG, caloriesPer100g: 144, proteinPer100g: 13, carbsPer100g: 1.1, fatPer100g: 10, fiberPer100g: 0 },
      { id: 51, name: "蛋白", category: FoodCategory.EGG, caloriesPer100g: 52, proteinPer100g: 11, carbsPer100g: 0.7, fatPer100g: 0.2, fiberPer100g: 0 },
      { id: 52, name: "蛋黄", category: FoodCategory.EGG, caloriesPer100g: 322, proteinPer100g: 16, carbsPer100g: 3.6, fatPer100g: 27, fiberPer100g: 0 },
      
      // 奶制品
      { id: 60, name: "牛奶", category: FoodCategory.DAIRY, caloriesPer100g: 54, proteinPer100g: 3, carbsPer100g: 5, fatPer100g: 3.2, fiberPer100g: 0 },
      { id: 61, name: "希腊酸奶", category: FoodCategory.DAIRY, caloriesPer100g: 97, proteinPer100g: 9, carbsPer100g: 4, fatPer100g: 5, fiberPer100g: 0 },
      { id: 62, name: "奶酪", category: FoodCategory.DAIRY, caloriesPer100g: 402, proteinPer100g: 25, carbsPer100g: 1.3, fatPer100g: 33, fiberPer100g: 0 },
      { id: 63, name: "豆浆", category: FoodCategory.DAIRY, caloriesPer100g: 33, proteinPer100g: 3, carbsPer100g: 1.8, fatPer100g: 1.6, fiberPer100g: 0.6 },
      
      // 豆类
      { id: 70, name: "鸡胸肉", category: FoodCategory.BEAN, caloriesPer100g: 218, proteinPer100g: 20, carbsPer100g: 39, fatPer100g: 1, fiberPer100g: 11 },
      { id: 71, name: "黑豆", category: FoodCategory.BEAN, caloriesPer100g: 132, proteinPer100g: 8.9, carbsPer100g: 24, fatPer100g: 0.5, fiberPer100g: 8.7 },
      { id: 72, name: "豆腐", category: FoodCategory.BEAN, caloriesPer100g: 76, proteinPer100g: 8, carbsPer100g: 1.9, fatPer100g: 4.8, fiberPer100g: 0.3 },
      
      // 零食
      { id: 80, name: "坚果", category: FoodCategory.SNACK, caloriesPer100g: 607, proteinPer100g: 20, carbsPer100g: 15, fatPer100g: 54, fiberPer100g: 8 },
      { id: 81, name: "花生酱", category: FoodCategory.SNACK, caloriesPer100g: 588, proteinPer100g: 25, carbsPer100g: 20, fatPer100g: 50, fiberPer100g: 6 },
      { id: 82, name: "巧克力", category: FoodCategory.SNACK, caloriesPer100g: 546, proteinPer100g: 5, carbsPer100g: 60, fatPer100g: 31, fiberPer100g: 7 },
      
      // 饮料
      { id: 90, name: "白开水", category: FoodCategory.DRINK, caloriesPer100g: 0, proteinPer100g: 0, carbsPer100g: 0, fatPer100g: 0, fiberPer100g: 0 },
      { id: 91, name: "绿茶", category: FoodCategory.DRINK, caloriesPer100g: 1, proteinPer100g: 0, carbsPer100g: 0, fatPer100g: 0, fiberPer100g: 0 },
      { id: 92, name: "咖啡", category: FoodCategory.DRINK, caloriesPer100g: 2, proteinPer100g: 0.1, carbsPer100g: 0, fatPer100g: 0, fiberPer100g: 0 },
      { id: 93, name: "橙汁", category: FoodCategory.DRINK, caloriesPer100g: 45, proteinPer100g: 0.7, carbsPer100g: 10, fatPer100g: 0.2, fiberPer100g: 0.2 }
    ]
  }
  
  /**
   * 获取常见份量
   */
  getCommonServings(foodName: string): { name: string, amount: number }[] {
    const defaults: Record<string, { name: string, amount: number }[]> = {
      "米饭": [
        { name: "小碗", amount: 150 },
        { name: "中碗", amount: 250 },
        { name: "大碗", amount: 400 }
      ],
      "鸡胸肉": [
        { name: "一块", amount: 120 },
        { name: "两块", amount: 240 }
      ],
      "鸡蛋": [
        { name: "一个", amount: 50 },
        { name: "两个", amount: 100 }
      ],
      "苹果": [
        { name: "小", amount: 150 },
        { name: "中", amount: 200 },
        { name: "大", amount: 280 }
      ],
      "牛奶": [
        { name: "一杯", amount: 250 },
        { name: "一盒", amount: 500 }
      ]
    }
    
    return defaults[foodName] || [{ name: "100g", amount: 100 }]
  }
  
  /**
   * 将数据库行转换为 MealRecord 对象
   */
  private rowToMeal(row: relationalStore.ResultSet): MealRecord {
    const record = new MealRecord()
    record.id = row.getValue("id")
    record.date = row.getValue("date")
    record.dateString = row.getValue("date_string")
    record.mealType = row.getValue("meal_type")
    record.foodName = row.getValue("food_name")
    record.amount = row.getValue("amount")
    record.amountUnit = row.getValue("amount_unit")
    record.calories = row.getValue("calories")
    record.protein = row.getValue("protein")
    record.carbs = row.getValue("carbs")
    record.fat = row.getValue("fat")
    record.fiber = row.getValue("fiber")
    record.sodium = row.getValue("sodium")
    record.water = row.getValue("water")
    record.notes = row.getValue("notes")
    record.createdAt = row.getValue("created_at")
    record.updatedAt = row.getValue("updated_at")
    return record
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
