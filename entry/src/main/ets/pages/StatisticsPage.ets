import router from '@ohos.router';
import { CheckinService } from '../services/CheckinService';
import { WorkoutService } from '../services/WorkoutService';
import { WeightService, calculateBMI } from '../services/WeightService';
import { CheckinDao } from '../database/dao/CheckinDao';
import { WorkoutDao } from '../database/dao/WorkoutDao';
import { WeightDao } from '../database/dao/WeightDao';

/**
 * StatisticsPage - 统计优化页面
 *
 * Phase 2 功能增强：
 * - 打卡连续天数可视化
 * - 训练统计（次数、总重量、时长）
 * - 体重趋势统计
 * - 热力图日历视图
 * - 周/月/年统计切换
 */
@Entry
@Component
struct StatisticsPage {
  // 统计周期选择
  @State selectedPeriod: 'week' | 'month' | 'year' = 'month';

  // 服务实例
  private checkinService: CheckinService = new CheckinService(new CheckinDao());
  private workoutService: WorkoutService = new WorkoutService(new WorkoutDao());
  private weightService: WeightService = new WeightService(new WeightDao());

  // 统计数据
  @State totalCheckins: number = 0;
  @State currentStreak: number = 0;
  @State longestStreak: number = 0;
  @State totalWorkouts: number = 0;
  @State totalVolume: number = 0;
  @State totalDuration: number = 0;
  @State currentWeight: number = 0;
  @State bmi: number = 0;

  aboutToAppear() {
    this.loadAllStats();
  }

  /**
   * 加载所有统计数据
   */
  async loadAllStats(): Promise<void> {
    try {
      // 并行加载
      const [checkinStats, workoutStats, weightStats] = await Promise.all([
        this.getCheckinStats(),
        this.workoutService.getStats(),
        this.weightService.getStats()
      ]);

      this.totalCheckins = checkinStats.total;
      this.currentStreak = checkinStats.streak;
      this.longestStreak = checkinStats.longest;

      this.totalWorkouts = workoutStats.totalWorkouts;
      this.totalVolume = workoutStats.totalVolume;
      this.totalDuration = workoutStats.totalDuration;

      this.currentWeight = weightStats.currentWeight;
      this.bmi = weightStats.bmi;
    } catch (err) {
      console.error(`加载统计失败: ${err}`);
    }
  }

  /**
   * 获取打卡统计（需扩展 CheckinDao）
   */
  async getCheckinStats(): Promise<{ total: number; streak: number; longest: number }> {
    // TODO: 实际项目中需要完善 CheckinDao
    return {
      total: 0,
      streak: 0,
      longest: 0
    };
  }

  build() {
    Column() {
      // 顶部导航
      this.NavigationBar()

      Scroll() {
        Column() {
          // 打卡统计卡片
          this.CheckinStatsCard()

          // 训练统计卡片
          this.WorkoutStatsCard()

          // 体重统计卡片
          this.WeightStatsCard()

          // 热力图（简化版）
          this.HeatmapCard()

          // 打卡趋势图（简化版）
          this.CheckinTrendCard()
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
      Text('📊 数据统计')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      Blank()

      Row({ space: 20 }) {
        Text('🏠').fontSize(24).onClick(() => router.back())
        Text('💪').fontSize(24).onClick(() => router.pushUrl({ url: 'pages/WorkoutPage' }))
        Text('⚖️').fontSize(24).onClick(() => router.pushUrl({ url: 'pages/WeightPage' }))
        Text('📝').fontSize(24).onClick(() => router.pushUrl({ url: 'pages/DiaryPage' }))
        Text('👤').fontSize(24).onClick(() => router.pushUrl({ url: 'pages/ProfilePage' }))
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
  }

  @Builder
  CheckinStatsCard() {
    Column() {
      Text('📅 打卡统计')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .alignSelf(HorizontalAlign.Start)
        .margin({ bottom: 12 })

      Row() {
        // 连续天数
        Column() {
          Text(this.currentStreak.toString())
            .fontSize(36)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF6B6B')
          Text('连续天数')
            .fontSize(12)
            .fontColor('#666666')
        }
        .layoutWeight(1)

        Divider()
          .vertical(true)
          .height(40)

        // 总打卡
        Column() {
          Text(this.totalCheckins.toString())
            .fontSize(36)
            .fontWeight(FontWeight.Bold)
            .fontColor('#4CAF50')
          Text('总打卡')
            .fontSize(12)
            .fontColor('#666666')
        }
        .layoutWeight(1)

        Divider()
          .vertical(true)
          .height(40)

        // 最长连续
        Column() {
          Text(this.longestStreak.toString())
            .fontSize(36)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF9800')
          Text('最长连续')
            .fontSize(12)
            .fontColor('#666666')
        }
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ bottom: 16 })
  }

  @Builder
  WorkoutStatsCard() {
    Column() {
      Text('💪 训练统计')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .alignSelf(HorizontalAlign.Start)
        .margin({ bottom: 12 })

      Row() {
        Column() {
          Text(this.totalWorkouts.toString())
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2196F3')
          Text('训练次数')
            .fontSize(12)
            .fontColor('#666666')
        }
        .layoutWeight(1)

        Column() {
          Text(`${this.totalVolume.toFixed(0)}`)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#9C27B0')
          Text('总重量(kg)')
            .fontSize(12)
            .fontColor('#666666')
        }
        .layoutWeight(1)

        Column() {
          Text(`${this.totalDuration}`)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF9800')
          Text('总时长(分)')
            .fontSize(12)
            .fontColor('#666666')
        }
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ bottom: 16 })
  }

  @Builder
  WeightStatsCard() {
    Column() {
      Text('⚖️ 体重统计')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .alignSelf(HorizontalAlign.Start)
        .margin({ bottom: 12 })

      Row({ space: 16 }) {
        // BMI 圆环（简化）
        Column() {
          Text(this.bmi > 0 ? this.bmi.toFixed(1) : '--')
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getBMIColor())
          Text('BMI')
            .fontSize(10)
            .fontColor('#999999')
        }
        .width(80)
        .height(80)
        .borderRadius(40)
        .backgroundColor('#F5F5F5')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Column() {
          Text(`${this.currentWeight.toFixed(1)} kg`)
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
          Text('当前体重')
            .fontSize(12)
            .fontColor('#666666')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ bottom: 16 })
  }

  @Builder
  HeatmapCard() {
    Column() {
      Text('📅 打卡热力图')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .alignSelf(HorizontalAlign.Start)
        .margin({ bottom: 12 })

      // 简化热力图 - 实际项目使用 Canvas 或第三方图表库
      Grid() {
        ForEach(Array.from({ length: 35 }, (_, i) => i), (index: number) => {
          GridItem() {
            Column() {
              // 随机颜色模拟热力
              Text((index + 1).toString())
                .fontSize(8)
                .fontColor('#999999')
            }
            .width(20)
            .height(20)
            .backgroundColor(this.getHeatColor(index))
            .borderRadius(4)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr 1fr 1fr 1fr')
      .width('100%')
      .height(120)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ bottom: 16 })
  }

  @Builder
  CheckinTrendCard() {
    Column() {
      // 周期选择
      Row() {
        Text('📈 打卡趋势')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)

        Row({ space: 8 }) {
          this.PeriodButton('周', 'week')
          this.PeriodButton('月', 'month')
          this.PeriodButton('年', 'year')
        }
      }
      .margin({ bottom: 12 })

      // 简化趋势图（实际项目用图表库）
      Row({ space: 4 }) {
        ForEach([3, 5, 2, 4, 6, 3, 5], (value: number, index: number) => {
          Column() {
            Column()
              .width(16)
              .height(`${value * 10}vp`)
              .backgroundColor('#4CAF50')
              .borderRadius(4)
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.End)
        })
      }
      .height(80)
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }

  @Builder
  PeriodButton(label: string, period: 'week' | 'month' | 'year') {
    Text(label)
      .fontSize(12)
      .padding({ horizontal: 12, vertical: 4 })
      .backgroundColor(this.selectedPeriod === period ? '#2196F3' : '#E0E0E0')
      .fontColor(this.selectedPeriod === period ? '#FFFFFF' : '#666666')
      .borderRadius(12)
      .onClick(() => {
        this.selectedPeriod = period;
        // TODO: 重新加载对应周期的数据
      })
  }

  getHeatColor(index: number): string {
    // 简化：根据 index 返回不同深浅
    const colors = ['#EBEDF0', '#9BE9A8', '#40C463', '#30A14E', '#216E39'];
    return colors[index % 5];
  }

  getBMIColor(): string {
    if (this.bmi === 0) return '#999999';
    if (this.bmi < 18.5) return '#FFC107';
    if (this.bmi < 24) return '#4CAF50';
    if (this.bmi < 28) return '#FF9800';
    return '#F44336';
  }
}
