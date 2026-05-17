/**
 * 饮食记录页面
 */

@Entry
@Component
struct MealPage {
  @State viewModel: MealViewModel = new MealViewModel()
  @State showWaterDialog: boolean = false
  @State waterAmount: string = "250"
  
  aboutToAppear() {
    this.viewModel.initialize()
  }
  
  build() {
    Column() {
      // 顶部导航
      this.buildHeader()
      
      // 日期选择器
      this.buildDateSelector()
      
      // 营养概览
      this.buildNutritionOverview()
      
      // 餐次选择
      this.buildMealTypeSelector()
      
      // 食物列表
      this.buildFoodList()
      
      // 底部操作栏
      this.buildBottomActions()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
  
  /**
   * 顶部导航
   */
  @Builder
  buildHeader() {
    Row() {
      Text('饮食记录')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      
      Blank()
      
      // 饮水按钮
      Button('💧 饮水')
        .fontSize(14)
        .height(32)
        .backgroundColor('#E6F7FF')
        .fontColor('#1890FF')
        .borderRadius(16)
        .onClick(() => {
          this.showWaterDialog = true
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
  }
  
  /**
   * 日期选择器
   */
  @Builder
  buildDateSelector() {
    Row() {
      // 左箭头
      Button('<')
        .fontSize(16)
        .width(32)
        .height(32)
        .backgroundColor('#F0F0F0')
        .fontColor('#333333')
        .borderRadius(16)
        .onClick(() => {
          this.navigateDate(-1)
        })
      
      Text(this.viewModel.formatDateDisplay(this.viewModel.selectedDate))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      
      // 右箭头
      Button('>')
        .fontSize(16)
        .width(32)
        .height(32)
        .backgroundColor('#F0F0F0')
        .fontColor('#333333')
        .borderRadius(16)
        .onClick(() => {
          this.navigateDate(1)
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .backgroundColor(Color.White)
  }
  
  /**
   * 营养概览卡片
   */
  @Builder
  buildNutritionOverview() {
    Card() {
      Column({ space: 16 }) {
        // 热量概览
        Row() {
          Column({ space: 4 }) {
            Text(this.viewModel.selectedDateNutrition.totalCalories.toString())
              .fontSize(32)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.viewModel.getCaloriesColor())
            
            Text('千卡')
              .fontSize(12)
              .fontColor('#999999')
          }
          
          Blank()
          
          Column({ space: 4 }) {
            Text(`/ ${this.viewModel.nutritionTarget.dailyCalories}`)
              .fontSize(16)
              .fontColor('#999999')
            
            Text('目标')
              .fontSize(12)
              .fontColor('#999999')
          }
        }
        .width('100%')
        
        // 热量进度条
        Progress({
          value: this.viewModel.calculateProgress(
            this.viewModel.selectedDateNutrition.totalCalories,
            this.viewModel.nutritionTarget.dailyCalories
          ),
          total: 100,
          type: ProgressType.Capsule
        })
          .width('100%')
          .height(8)
          .color(this.viewModel.getCaloriesColor())
        
        // 三大营养素
        Row() {
          MacroItem('蛋白质', this.viewModel.selectedDateNutrition.totalProtein, 'g', '#FF6B6B')
          MacroItem('碳水', this.viewModel.selectedDateNutrition.totalCarbs, 'g', '#4ECDC4')
          MacroItem('脂肪', this.viewModel.selectedDateNutrition.totalFat, 'g', '#FFE66D')
        }
        
        // 营养建议
        if (this.viewModel.nutritionAdvice) {
          Text(this.viewModel.nutritionAdvice)
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
            .padding(12)
            .backgroundColor('#FFF9E6')
            .borderRadius(8)
        }
      }
    }
    .margin({ left: 16, right: 16, top: 8 })
  }
  
  /**
   * 餐次选择器
   */
  @Builder
  buildMealTypeSelector() {
    Row() {
      ForEach(this.viewModel.mealTypeOptions, (option: any) => {
        MealTypeTab({
          label: option.label,
          icon: option.icon,
          isSelected: this.viewModel.selectedMealType === option.value,
          calories: this.getMealCalories(option.value),
          onClick: () => {
            this.viewModel.selectMealType(option.value)
          }
        })
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
  }
  
  /**
   * 食物列表
   */
  @Builder
  buildFoodList() {
    Scroll() {
      Column({ space: 8 }) {
        const meals = this.viewModel.getMealsBySelectedType()
        
        if (meals.length > 0) {
          ForEach(meals, (meal: any) => {
            FoodItemCard({
              meal: meal,
              onDelete: () => {
                this.viewModel.deleteMeal(meal.id)
              }
            })
          })
        } else {
          // 空状态
          Column({ space: 8 }) {
            Text('暂无记录')
              .fontSize(14)
              .fontColor('#999999')
            
            Text('点击下方按钮添加食物')
              .fontSize(12)
              .fontColor('#CCCCCC')
          }
          .width('100%')
          .padding(32)
          .alignItems(HorizontalAlign.Center)
        }
        
        // 间隔
        Divider().height(80)
      }
      .padding({ left: 16, right: 16, top: 8 })
    }
  }
  
  /**
   * 底部操作栏
   */
  @Builder
  buildBottomActions() {
    Row() {
      Button('添加食物')
        .width('100%')
        .height(48)
        .backgroundColor('#1890FF')
        .borderRadius(24)
        .onClick(() => {
          this.viewModel.openAddFoodDialog()
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .shadow({
      radius: 8,
      color: 'rgba(0, 0, 0, 0.1)',
      offsetY: -2
    })
  }
  
  /**
   * 获取指定餐次的热量
   */
  getMealCalories(mealType: MealType): number {
    return this.viewModel.selectedDateMeals
      .filter(m => m.mealType === mealType)
      .reduce((sum, m) => sum + m.calories, 0)
  }
  
  /**
   * 日期导航
   */
  navigateDate(days: number) {
    const current = new Date(this.viewModel.selectedDate)
    current.setDate(current.getDate() + days)
    const dateString = this.formatDate(current)
    this.viewModel.selectDate(dateString)
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
}

/**
 * 餐次 Tab 组件
 */
@Component
struct MealTypeTab {
  @Prop label: string = ''
  @Prop icon: string = ''
  @Prop isSelected: boolean = false
  @Prop calories: number = 0
  onClick: () => void = () => {}
  
  build() {
    Column({ space: 4 }) {
      Text(this.icon)
        .fontSize(20)
      
      Text(this.label)
        .fontSize(12)
        .fontColor(this.isSelected ? '#1890FF' : '#666666')
      
      Text(`${this.calories}kcal`)
        .fontSize(10)
        .fontColor(this.isSelected ? '#1890FF' : '#999999')
    }
    .layoutWeight(1)
    .padding(8)
    .backgroundColor(this.isSelected ? '#E6F7FF' : 'transparent')
    .borderRadius(8)
    .onClick(this.onClick)
  }
}

/**
 * 营养素项组件
 */
@Component
struct MacroItem {
  @Prop label: string = ''
  @Prop value: number = 0
  @Prop unit: string = ''
  @Prop color: string = ''
  
  build() {
    Column({ space: 4 }) {
      Text(`${Math.round(value)}${unit}`)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.color)
      
      Text(label)
        .fontSize(10)
        .fontColor('#999999')
    }
    .layoutWeight(1)
  }
}

/**
 * 食物项卡片
 */
@Component
struct FoodItemCard {
  @Object meal: MealRecord
  onDelete: () => void = () => {}
  
  build() {
    Row() {
      Column({ space: 4 }) {
        Text(this.meal.foodName)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
        
        Text(`${this.meal.amount}${this.meal.amountUnit}`)
          .fontSize(12)
          .fontColor('#999999')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      Column({ space: 4 }) {
        Text(`${this.meal.calories}kcal`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FF6B6B')
        
        Text(`P:${this.meal.protein}g C:${this.meal.carbs}g F:${this.meal.fat}g`)
          .fontSize(10)
          .fontColor('#999999')
      }
      .alignItems(HorizontalAlign.End)
      
      // 删除按钮
      Button('×')
        .fontSize(16)
        .width(24)
        .height(24)
        .backgroundColor('#FFE6E6')
        .fontColor('#FF4D4F')
        .borderRadius(12)
        .margin({ left: 12 })
        .onClick(() => {
          this.onDelete()
        })
    }
    .width('100%')
    .padding(12)
    .backgroundColor(Color.White)
    .borderRadius(8)
  }
}

/**
 * 卡片容器
 */
@Component
struct Card {
  build() {
    Column() {
      // 内容由父组件提供
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
  }
}
