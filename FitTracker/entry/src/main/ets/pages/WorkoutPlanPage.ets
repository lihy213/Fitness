/**
 * 训练计划向导页面
 * 提供计划浏览、创建、执行的全套功能
 */

@Entry
@Component
struct WorkoutPlanPage {
  @State viewModel: WorkoutPlanViewModel = new WorkoutPlanViewModel()
  @State currentTab: number = 0
  @State showTemplateSelector: boolean = false
  @State showCreateForm: boolean = false
  
  aboutToAppear() {
    this.viewModel.initialize()
  }
  
  build() {
    Column() {
      // 顶部导航
      this.buildHeader()
      
      // Tab 切换
      this.buildTabs()
      
      // 内容区域
      this.buildContent()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
  
  /**
   * 顶部导航栏
   */
  @Builder
  buildHeader() {
    Row() {
      Text('训练计划')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      
      Blank()
      
      // 添加按钮
      Button() {
        Text('+')
          .fontSize(24)
          .fontColor(Color.White)
      }
      .width(40)
      .height(40)
      .backgroundColor('#1890FF')
      .borderRadius(20)
      .onClick(() => {
        this.showTemplateSelector = true
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
  }
  
  /**
   * Tab 切换
   */
  @Builder
  buildTabs() {
    Row() {
      TabButton('当前', 0)
      TabButton('全部', 1)
      TabButton('模板', 2)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .backgroundColor(Color.White)
  }
  
  /**
   * 内容区域
   */
  @Builder
  buildContent() {
    if (this.viewModel.isLoading) {
      this.buildLoading()
    } else if (this.currentTab === 0) {
      this.buildCurrentPlan()
    } else if (this.currentTab === 1) {
      this.buildAllPlans()
    } else {
      this.buildTemplates()
    }
  }
  
  /**
   * 当前进行中的计划
   */
  @Builder
  buildCurrentPlan() {
    Scroll() {
      Column({ space: 16 }) {
        if (this.viewModel.activePlan) {
          // 进度卡片
          this.buildProgressCard()
          
          // 今日训练卡片
          this.buildTodayWorkoutCard()
          
          // 本周计划
          this.buildWeekPlanCard()
          
          // 操作按钮
          this.buildActionButtons()
        } else {
          // 无计划状态
          this.buildNoPlanCard()
        }
      }
      .padding(16)
    }
  }
  
  /**
   * 进度卡片
   */
  @Builder
  buildProgressCard() {
    Card() {
      Column({ space: 12 }) {
        // 计划名称和状态
        Row() {
          Text(this.viewModel.activePlan?.name || '')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
          
          Blank()
          
          Text(this.viewModel.getStatusText(this.viewModel.activePlan?.status || ''))
            .fontSize(12)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor('#E6F7FF')
            .borderRadius(4)
            .fontColor('#1890FF')
        }
        
        // 进度条
        Column({ space: 8 }) {
          Row() {
            Text('计划进度')
              .fontSize(14)
              .fontColor('#666666')
            
            Blank()
            
            Text(`${this.viewModel.progressPercentage}%`)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1890FF')
          }
          
          Progress({
            value: this.viewModel.progressPercentage,
            total: 100,
            type: ProgressType.Linear
          })
            .color('#1890FF')
            .width('100%')
            .height(8)
        }
        
        // 统计信息
        Row() {
          StatItem('本周', `${this.viewModel.activePlan?.currentWeek || 1} 周`)
          StatItem('训练日', `${this.viewModel.progress?.completedDays || 0} 天`)
          StatItem('连续', `${this.viewModel.progress?.streakDays || 0} 天`)
        }
      }
    }
  }
  
  /**
   * 今日训练卡片
   */
  @Builder
  buildTodayWorkoutCard() {
    Card() {
      Column({ space: 12 }) {
        // 标题
        Row() {
          Text(this.viewModel.todayWorkout?.dayName || '今日')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
          
          Blank()
          
          if (this.viewModel.todayWorkout?.isCompleted) {
            Text('已完成')
              .fontSize(12)
              .fontColor('#52C41A')
          } else if (this.viewModel.todayWorkout?.isRestDay) {
            Text('休息日')
              .fontSize(12)
              .fontColor('#999999')
          } else {
            Text('进行中')
              .fontSize(12)
              .fontColor('#FAAD14')
          }
        }
        
        if (this.viewModel.todayWorkout?.isRestDay) {
          // 休息日提示
          Row() {
            Text('今天好好休息，为明天的训练做准备！')
              .fontSize(14)
              .fontColor('#666666')
          }
          .padding(16)
          .width('100%')
          .backgroundColor('#FAFAFA')
          .borderRadius(8)
        } else if (this.viewModel.todayWorkout?.exercises?.length) {
          // 训练动作列表
          ForEach(this.viewModel.todayWorkout.exercises, (exercise: any, index: number) => {
            Row() {
              Text(`${index + 1}`)
                .fontSize(12)
                .fontColor('#999999')
                .width(24)
              
              Text(exercise.exerciseName)
                .fontSize(14)
              
              Blank()
              
              Text(`${exercise.sets}组 × ${exercise.reps}`)
                .fontSize(12)
                .fontColor('#666666')
            }
            .padding(12)
            .width('100%')
            
            if (index < this.viewModel.todayWorkout.exercises.length - 1) {
              Divider()
            }
          })
          
          // 完成按钮
          if (!this.viewModel.todayWorkout.isCompleted) {
            Button('完成今日训练')
              .width('100%')
              .height(44)
              .backgroundColor('#1890FF')
              .borderRadius(8)
              .onClick(() => {
                this.completeTodayWorkout()
              })
          }
        }
      }
    }
  }
  
  /**
   * 本周训练计划卡片
   */
  @Builder
  buildWeekPlanCard() {
    Card() {
      Column({ space: 12 }) {
        Text('本周计划')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .alignSelf(ItemAlign.Start)
        
        // 周视图
        Row() {
          ForEach(this.viewModel.weekPlan, (day: any) => {
            Column({ space: 4 }) {
              Text(day.dayName.slice(1))
                .fontSize(12)
                .fontColor(day.dayOfWeek === new Date().getDay() ? '#1890FF' : '#999999')
              
              if (day.isRestDay) {
                Text('休')
                  .fontSize(12)
                  .fontColor('#999999')
                  .padding(8)
              } else {
                Circle({ width: 32, height: 32 })
                  .fill(day.isCompleted ? '#52C41A' : '#E6F7FF')
                  .onClick(() => {
                    // 查看当天详情
                  })
                
                if (day.exercises?.length > 0) {
                  Text(`${day.exercises.length}`)
                    .fontSize(10)
                    .fontColor('#666666')
                }
              }
            }
            .width(40)
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)
      }
    }
  }
  
  /**
   * 操作按钮
   */
  @Builder
  buildActionButtons() {
    Row({ space: 12 }) {
      if (this.viewModel.activePlan?.status === 'active') {
        Button('暂停计划')
          .layoutWeight(1)
          .height(44)
          .backgroundColor('#FAAD14')
          .borderRadius(8)
          .onClick(() => {
            this.viewModel.pausePlan(this.viewModel.activePlan!.id)
          })
        
        Button('放弃计划')
          .layoutWeight(1)
          .height(44)
          .backgroundColor('#FF4D4F')
          .borderRadius(8)
          .onClick(() => {
            this.viewModel.abandonPlan(this.viewModel.activePlan!.id)
          })
      } else if (this.viewModel.activePlan?.status === 'paused') {
        Button('继续计划')
          .width('100%')
          .height(44)
          .backgroundColor('#1890FF')
          .borderRadius(8)
          .onClick(() => {
            this.viewModel.startPlan(this.viewModel.activePlan!.id)
          })
      }
    }
  }
  
  /**
   * 无计划状态
   */
  @Builder
  buildNoPlanCard() {
    Card() {
      Column({ space: 16 }) {
        Image($r('app.media.ic_plan'))
          .width(80)
          .height(80)
          .opacity(0.5)
        
        Text('暂无进行中的计划')
          .fontSize(16)
          .fontColor('#666666')
        
        Text('选择一个模板开始你的训练之旅')
          .fontSize(14)
          .fontColor('#999999')
        
        Button('选择训练模板')
          .width('80%')
          .height(44)
          .backgroundColor('#1890FF')
          .borderRadius(8)
          .onClick(() => {
            this.currentTab = 2
          })
      }
      .width('100%')
      .padding(32)
      .alignItems(HorizontalAlign.Center)
    }
  }
  
  /**
   * 全部计划列表
   */
  @Builder
  buildAllPlans() {
    Scroll() {
      Column({ space: 12 }) {
        if (this.viewModel.plans.length > 0) {
          ForEach(this.viewModel.plans, (plan: any) => {
            this.buildPlanItem(plan)
          })
        } else {
          this.buildEmptyList('暂无训练计划')
        }
      }
      .padding(16)
    }
  }
  
  /**
   * 计划列表项
   */
  @Builder
  buildPlanItem(plan: any) {
    Card() {
      Row() {
        Column({ space: 8 }) {
          Text(plan.name)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
          
          Text(`${plan.durationWeeks}周 · ${this.viewModel.getGoalText(plan.goal)} · ${this.viewModel.getLevelText(plan.level)}`)
            .fontSize(12)
            .fontColor('#999999')
        }
        .alignItems(HorizontalAlign.Start)
        
        Blank()
        
        Column({ space: 4 }) {
          Text(this.viewModel.getStatusText(plan.status))
            .fontSize(12)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(this.getStatusColor(plan.status))
            .borderRadius(4)
            .fontColor(Color.White)
          
          if (plan.status === 'draft') {
            Button('开始')
              .fontSize(12)
              .height(28)
              .backgroundColor('#1890FF')
              .borderRadius(4)
              .onClick(() => {
                this.viewModel.startPlan(plan.id)
              })
          }
        }
      }
    }
  }
  
  /**
   * 模板列表
   */
  @Builder
  buildTemplates() {
    Scroll() {
      Column({ space: 16 }) {
        // 目标筛选
        Row({ space: 8 }) {
          ForEach(this.viewModel.goalOptions, (option: any) => {
            Chip(option.label)
              .onClick(() => {
                // 筛选模板
              })
          })
        }
        .width('100%')
        .scrollable(ScrollDirection.Horizontal)
        
        // 模板列表
        ForEach(this.viewModel.templates, (template: any) => {
          this.buildTemplateCard(template)
        })
      }
      .padding(16)
    }
  }
  
  /**
   * 模板卡片
   */
  @Builder
  buildTemplateCard(template: any) {
    Card() {
      Column({ space: 12 }) {
        // 模板名称和标签
        Row() {
          Text(template.name)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
          
          Blank()
          
          Text(this.viewModel.getGoalText(template.goal))
            .fontSize(12)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor('#E6F7FF')
            .borderRadius(4)
            .fontColor('#1890FF')
        }
        
        Text(template.description)
          .fontSize(14)
          .fontColor('#666666')
          .width('100%')
        
        // 模板信息
        Row() {
          InfoItem('周期', `${template.suggestedWeeks}周`)
          InfoItem('频率', `${template.trainingDays}次/周`)
          InfoItem('难度', this.viewModel.getLevelText(template.level))
        }
        
        // 操作按钮
        Row({ space: 12 }) {
          Button('查看详情')
            .layoutWeight(1)
            .height(36)
            .backgroundColor('#FAFAFA')
            .fontColor('#666666')
            .borderRadius(8)
            .onClick(() => {
              // 显示详情
            })
          
          Button('开始计划')
            .layoutWeight(1)
            .height(36)
            .backgroundColor('#1890FF')
            .borderRadius(8)
            .onClick(() => {
              this.viewModel.createFromTemplate(template)
            })
        }
      }
    }
  }
  
  /**
   * 加载中状态
   */
  @Builder
  buildLoading() {
    Column() {
      LoadingProgress()
        .width(40)
        .height(40)
      
      Text('加载中...')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 16 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
  
  /**
   * 空列表状态
   */
  @Builder
  buildEmptyList(message: string) {
    Column({ space: 16 }) {
      Text(message)
        .fontSize(14)
        .fontColor('#999999')
    }
    .width('100%')
    .padding(32)
    .alignItems(HorizontalAlign.Center)
  }
  
  /**
   * 完成今日训练
   */
  async completeTodayWorkout() {
    if (this.viewModel.todayWorkout) {
      await this.viewModel.completeTodayWorkout(this.viewModel.todayWorkout)
    }
  }
  
  /**
   * 获取状态颜色
   */
  getStatusColor(status: string): ResourceStr {
    switch (status) {
      case 'active': return '#52C41A'
      case 'paused': return '#FAAD14'
      case 'completed': return '#1890FF'
      case 'abandoned': return '#999999'
      default: return '#E6E6E6'
    }
  }
}

/**
 * Tab 按钮组件
 */
@Component
struct TabButton {
  @Prop title: string = ''
  @Prop index: number = 0
  @ObjectLink parent: WorkoutPlanPage
  
  build() {
    Column() {
      Text(this.title)
        .fontSize(14)
        .fontColor(this.parent.currentTab === this.index ? '#1890FF' : '#666666')
        .fontWeight(this.parent.currentTab === this.index ? FontWeight.Bold : FontWeight.Normal)
      
      Divider()
        .width(40)
        .height(2)
        .backgroundColor(this.parent.currentTab === this.index ? '#1890FF' : 'transparent')
        .margin({ top: 8 })
    }
    .padding(8)
    .onClick(() => {
      this.parent.currentTab = this.index
    })
  }
}

/**
 * 统计项组件
 */
@Component
struct StatItem {
  @Prop label: string = ''
  @Prop value: string = ''
  
  build() {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      
      Text(label)
        .fontSize(12)
        .fontColor('#999999')
    }
    .layoutWeight(1)
  }
}

/**
 * 信息项组件
 */
@Component
struct InfoItem {
  @Prop label: string = ''
  @Prop value: string = ''
  
  build() {
    Row({ space: 4 }) {
      Text(label)
        .fontSize(12)
        .fontColor('#999999')
      
      Text(value)
        .fontSize(12)
        .fontColor('#333333')
    }
    .layoutWeight(1)
  }
}

/**
 * 卡片容器组件
 */
@Component
struct Card {
  build() {
    Column() {
      // 卡片内容由父组件提供
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: 'rgba(0, 0, 0, 0.05)',
      offsetX: 0,
      offsetY: 2
    })
  }
}

/**
 * 标签组件
 */
@Component
struct Chip {
  @Prop label: string = ''
  
  build() {
    Text(this.label)
      .fontSize(12)
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .backgroundColor('#F0F0F0')
      .borderRadius(16)
  }
}
