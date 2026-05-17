import router from '@ohos.router';
import { WeightViewModel } from '../viewmodels/WeightViewModel';
import { WeightService } from '../services/WeightService';
import { WeightDao } from '../database/dao/WeightDao';
import { BMICategory, getBMICategory, getBMIColor, ChartDataPoint } from '../database/entities/WeightRecord';

/**
 * WeightPage - 体重管理页面
 *
 * 功能：
 * - 记录体重
 * - 周/月/年体重趋势图
 * - BMI 计算
 * - 目标进度
 */
@Entry
@Component
struct WeightPage {
  @State viewModel: WeightViewModel = new WeightViewModel();
  private weightDao: WeightDao = new WeightDao();
  private weightService: WeightService | null = null;

  // 图表周期选择
  @State selectedPeriod: 'week' | 'month' | 'year' = 'month';

  aboutToAppear() {
    this.weightService = new WeightService(this.weightDao);
    this.viewModel.init(this.weightService);
    this.viewModel.loadData();
  }

  build() {
    Column() {
      // 顶部导航
      this.NavigationBar()

      Scroll() {
        Column() {
          // 当前体重卡片
          this.CurrentWeightCard()

          // 体重记录输入
          this.WeightInputCard()

          // 周期选择 + 趋势图
          this.TrendChartCard()

          // BMI 卡片
          this.BMICard()

          // 进度卡片
          this.ProgressCard()
        }
        .padding(16)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  NavigationBar() {
    Row() {
      Text('⚖️ 体重管理')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      Blank()

      Row({ space: 20 }) {
        Text('🏠').fontSize(24).onClick(() => router.back())
        Text('💪').fontSize(24).onClick(() => router.pushUrl({ url: 'pages/WorkoutPage' }))
        Text('⚖️').fontSize(24)
        Text('📝').fontSize(24).onClick(() => router.pushUrl({ url: 'pages/DiaryPage' }))
        Text('👤').fontSize(24).onClick(() => router.pushUrl({ url: 'pages/ProfilePage' }))
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
  }

  @Builder
  CurrentWeightCard() {
    Column() {
      if (this.viewModel.stats.currentWeight > 0) {
        Row({ space: 8 }) {
          Text(this.viewModel.stats.currentWeight.toFixed(1))
            .fontSize(56)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2196F3')
          Text('kg')
            .fontSize(20)
            .fontColor('#666666')
        }

        // 变化量
        Row({ space: 4 }) {
          Text(this.viewModel.stats.change >= 0 ? '↑' : '↓')
            .fontColor(this.viewModel.stats.change >= 0 ? '#F44336' : '#4CAF50')
          Text(`${Math.abs(this.viewModel.stats.change).toFixed(1)} kg`)
            .fontColor(this.viewModel.stats.change >= 0 ? '#F44336' : '#4CAF50')
          Text('较起始')
            .fontColor('#999999')
          Text(' | ')
            .fontColor('#CCCCCC')
          Text(`目标: ${this.viewModel.stats.targetWeight} kg`)
            .fontColor('#999999')
        }
        .fontSize(14)
        .margin({ top: 8 })
      } else {
        Text('暂无数据')
          .fontSize(20)
          .fontColor('#999999')
        Text('记录今日体重开始追踪')
          .fontSize(14)
          .fontColor('#CCCCCC')
      }
    }
    .width('100%')
    .padding(24)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ bottom: 16 })
  }

  @Builder
  WeightInputCard() {
    Column() {
      Text('📝 记录体重')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .alignSelf(HorizontalAlign.Start)
        .margin({ bottom: 12 })

      Row({ space: 12 }) {
        Column() {
          Text('体重 (kg)')
            .fontSize(12)
            .fontColor('#666666')
            .alignSelf(HorizontalAlign.Start)
          TextInput({ placeholder: '70.0' })
            .width('100%')
            .textAlign(TextAlign.Center)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .inputMode(InputMode.Number)
            .onChange((value) => this.viewModel.inputWeight = Number(value))
        }
        .layoutWeight(1)

        Column() {
          Text('体脂率 (可选)')
            .fontSize(12)
            .fontColor('#666666')
            .alignSelf(HorizontalAlign.Start)
          TextInput({ placeholder: '20%' })
            .width('100%')
            .textAlign(TextAlign.Center)
            .inputMode(InputMode.Number)
            .onChange((value) => this.viewModel.inputBodyFat = Number(value))
        }
        .layoutWeight(1)
      }
      .margin({ bottom: 12 })

      Button('💾 保存记录')
        .width('100%')
        .height(44)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .borderRadius(22)
        .backgroundColor('#2196F3')
        .onClick(() => this.saveWeight())
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ bottom: 16 })
  }

  @Builder
  TrendChartCard() {
    Column() {
      Row() {
        Text('📊 体重趋势')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)

        Blank()

        // 周期选择
        Row({ space: 8 }) {
          Text('周')
            .fontSize(12)
            .padding(8)
            .backgroundColor(this.selectedPeriod === 'week' ? '#2196F3' : '#E0E0E0')
            .fontColor(this.selectedPeriod === 'week' ? '#FFFFFF' : '#666666')
            .borderRadius(12)
            .onClick(() => {
              this.selectedPeriod = 'week';
              this.viewModel.loadTrend('week');
            })
          Text('月')
            .fontSize(12)
            .padding(8)
            .backgroundColor(this.selectedPeriod === 'month' ? '#2196F3' : '#E0E0E0')
            .fontColor(this.selectedPeriod === 'month' ? '#FFFFFF' : '#666666')
            .borderRadius(12)
            .onClick(() => {
              this.selectedPeriod = 'month';
              this.viewModel.loadTrend('month');
            })
          Text('年')
            .fontSize(12)
            .padding(8)
            .backgroundColor(this.selectedPeriod === 'year' ? '#2196F3' : '#E0E0E0')
            .fontColor(this.selectedPeriod === 'year' ? '#FFFFFF' : '#666666')
            .borderRadius(12)
            .onClick(() => {
              this.selectedPeriod = 'year';
              this.viewModel.loadTrend('year');
            })
        }
      }
      .margin({ bottom: 16 })

      // 简单图表（用文字模拟）
      if (this.viewModel.chartData.length > 0) {
        this.SimpleChart()
      } else {
        Text('暂无趋势数据')
          .fontSize(14)
          .fontColor('#CCCCCC')
          .padding(40)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ bottom: 16 })
  }

  /**
   * 简化版图表（文字堆叠）
   * 实际项目使用 @ohos.app.ability.DataAbilityHelper 或 Charts 组件
   */
  @Builder
  SimpleChart() {
    Column() {
      // 最大值和最小值
      Row() {
        Text(`最高: ${this.getMaxWeight().toFixed(1)} kg`)
          .fontSize(12)
          .fontColor('#F44336')
        Blank()
        Text(`最低: ${this.getMinWeight().toFixed(1)} kg`)
          .fontSize(12)
          .fontColor('#4CAF50')
      }
      .width('100%')
      .margin({ bottom: 8 })

      // 简易柱状图
      Row({ space: 4 }) {
        ForEach(this.viewModel.chartData.slice(-7), (point: ChartDataPoint) => {
          Column() {
            // 高度比例（简化版）
            Column()
              .width(20)
              .height(this.getBarHeight(point.value))
              .backgroundColor('#2196F3')
              .borderRadius(4)

            Text(point.label || '')
              .fontSize(8)
              .fontColor('#999999')
              .margin({ top: 4 })
          }
          .layoutWeight(1)
        })
      }
      .height(100)
    }
  }

  getBarHeight(weight: number): string {
    // 简化：假设体重范围 50-100kg
    const min = 50;
    const max = 100;
    const ratio = Math.min(Math.max((weight - min) / (max - min), 0.1), 1);
    return `${ratio * 80}vp`;
  }

  getMaxWeight(): number {
    if (this.viewModel.chartData.length === 0) return 0;
    return Math.max(...this.viewModel.chartData.map(p => p.value));
  }

  getMinWeight(): number {
    if (this.viewModel.chartData.length === 0) return 0;
    return Math.min(...this.viewModel.chartData.map(p => p.value));
  }

  @Builder
  BMICard() {
    Column() {
      Text('📏 BMI 指数')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .alignSelf(HorizontalAlign.Start)
        .margin({ bottom: 12 })

      if (this.viewModel.stats.bmi > 0) {
        Row() {
          Column() {
            Text(this.viewModel.stats.bmi.toFixed(1))
              .fontSize(36)
              .fontWeight(FontWeight.Bold)
              .fontColor(getBMIColor(getBMICategory(this.viewModel.stats.bmi)))
            Text(getBMICategory(this.viewModel.stats.bmi))
              .fontSize(14)
              .fontColor(getBMIColor(getBMICategory(this.viewModel.stats.bmi)))
          }
          .layoutWeight(1)

          Column() {
            Text('BMI 参考')
              .fontSize(12)
              .fontColor('#666666')
              .alignSelf(HorizontalAlign.Start)
            this.BMILegend()
          }
          .layoutWeight(2)
        }
      } else {
        Text('记录体重后自动计算 BMI')
          .fontSize(14)
          .fontColor('#CCCCCC')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ bottom: 16 })
  }

  @Builder
  BMILegend() {
    Column() {
      Row() {
        Text('●')
          .fontColor(getBMIColor(BMICategory.UNDERWEIGHT))
        Text(' < 18.5 偏瘦')
          .fontSize(10)
          .fontColor('#666666')
      }
      Row() {
        Text('●')
          .fontColor(getBMIColor(BMICategory.NORMAL))
        Text(' 18.5-24 正常')
          .fontSize(10)
          .fontColor('#666666')
      }
      Row() {
        Text('●')
          .fontColor(getBMIColor(BMICategory.OVERWEIGHT))
        Text(' 24-28 偏胖')
          .fontSize(10)
          .fontColor('#666666')
      }
      Row() {
        Text('●')
          .fontColor(getBMIColor(BMICategory.OBESE))
        Text(' > 28 肥胖')
          .fontSize(10)
          .fontColor('#666666')
      }
    }
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  ProgressCard() {
    Column() {
      Text('🎯 目标进度')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .alignSelf(HorizontalAlign.Start)
        .margin({ bottom: 12 })

      Row() {
        Column() {
          Text('剩余')
            .fontSize(12)
            .fontColor('#666666')
          Text(`${(this.viewModel.stats.currentWeight - this.viewModel.stats.targetWeight).toFixed(1)} kg`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF9800')
        }
        .layoutWeight(1)

        Column() {
          Text('本周变化')
            .fontSize(12)
            .fontColor('#666666')
          Text(`${this.viewModel.stats.weeklyChange >= 0 ? '+' : ''}${this.viewModel.stats.weeklyChange.toFixed(1)} kg`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.viewModel.stats.weeklyChange >= 0 ? '#F44336' : '#4CAF50')
        }
        .layoutWeight(1)

        Column() {
          Text('达标天数')
            .fontSize(12)
            .fontColor('#666666')
          Text(`${this.viewModel.stats.onTrackDays}`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2196F3')
          Text('本月')
            .fontSize(10)
            .fontColor('#999999')
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }

  // ========== 操作方法 ==========

  async saveWeight(): Promise<void> {
    if (this.viewModel.inputWeight <= 0) return;
    await this.viewModel.saveWeight(this.viewModel.inputWeight, this.viewModel.inputBodyFat);
    this.viewModel.inputWeight = 0;
    this.viewModel.inputBodyFat = 0;
  }
}
