import router from '@ohos.router';
import { HomeViewModel } from '../viewmodels/HomeViewModel';
import { CheckinService } from '../services/CheckinService';
import { CheckinDao } from '../database/dao/CheckinDao';
import { MOOD_CONFIG } from '../database/entities/CheckinRecord';

/**
 * HomePage - 首页/打卡页面
 *
 * ArkUI 声明式 UI
 *
 * Python 对比 (Vue 模板):
 * <template>
 *   <div class="container">
 *     <div v-if="!isCheckedIn" class="checkin-form">
 *       <h2>今日打卡</h2>
 *       <div class="mood-selector">
 *         <button
 *           v-for="(config, mood) in moodConfig"
 *           :key="mood"
 *           :class="{ active: selectedMood == mood }"
 *           @click="selectMood(mood)"
 *         >
 *           {{ config.emoji }}
 *         </button>
 *       </div>
 *       <textarea v-model="note" placeholder="今天的感受..."></textarea>
 *       <button @click="doCheckin" :disabled="loading">
 *         {{ loading ? '打卡中...' : '打卡' }}
 *       </button>
 *     </div>
 *     <div v-else class="checked-in">
 *       <h2>今日已打卡 🎉</h2>
 *       <p>心情: {{ currentMoodConfig.emoji }} {{ currentMoodConfig.label }}</p>
 *     </div>
 *   </div>
 * </template>
 */

/**
 * 工具函数：获取当月 YYYY-MM 格式
 */
function getCurrentYearMonth(): string {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  return `${year}-${month}`;
}

@Entry
@Component
struct HomePage {
  // ViewModel 实例
  @State viewModel: HomeViewModel = new HomeViewModel();

  // 私有变量，不触发 UI 更新
  private dao: CheckinDao = new CheckinDao();
  private service: CheckinService | null = null;

  /**
   * 页面即将显示时调用
   * Python: onMounted(() => { ... })
   */
  aboutToAppear() {
    // TODO: 实际项目中从 DatabaseManager 获取 store
    // this.dao.init(store);
    this.service = new CheckinService(this.dao);
    this.viewModel.init(this.service);
    this.viewModel.loadData();
  }

  build() {
    Column() {
      // ========== 顶部导航栏 ==========
      this.NavigationBar()

      // ========== 主内容区 ==========
      Scroll() {
        Column() {
          // 连续打卡天数卡片
          this.StreakCard()

          // 打卡热力图
          this.HeatmapCard()

          // 打卡表单/结果
          if (this.viewModel.isCheckedIn) {
            this.CheckedInView()
          } else {
            this.CheckinForm()
          }

          // 错误提示
          if (this.viewModel.errorMessage) {
            Text(this.viewModel.errorMessage)
              .fontSize(14)
              .fontColor('#FF6B6B')
              .padding(10)
          }
        }
        .padding(16)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  /**
   * 顶部导航栏
   */
  @Builder
  NavigationBar() {
    Row() {
      Text('🏋️ FitTracker')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      Blank()

      // 底部导航占位（实际项目用 Navigation 组件）
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

  /**
   * 连续打卡天数卡片
   */
  @Builder
  StreakCard() {
    Row() {
      Column() {
        Text(this.viewModel.streak.toString())
          .fontSize(48)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF6B6B')
        Text('连续打卡天数')
          .fontSize(14)
          .fontColor('#666666')
      }
      .alignItems(HorizontalAlign.Center)

      Blank()

      Column() {
        Text('🔥')
          .fontSize(40)
      }
    }
    .width('100%')
    .padding(24)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ bottom: 16 })
  }

  /**
   * 打卡热力图卡片
   */
  @Builder
  HeatmapCard() {
    Column() {
      Text('📅 本月打卡')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 12 })

      // 热力图网格（简单版 7x5）
      Grid() {
        ForEach(Array.from({ length: 35 }, (_, i) => i), (index: number) => {
          GridItem() {
            this.HeatmapCell(index)
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

  /**
   * 热力图单元格
   */
  @Builder
  HeatmapCell(index: number) {
    // 计算日期（假设本月1号是周一，可根据实际情况调整）
    const day = index + 1;
    const mood = this.viewModel.heatmapData.get(day);

    Column() {
      if (mood !== undefined) {
        Text(MOOD_CONFIG[mood].emoji)
          .fontSize(16)
      } else {
        Text(day.toString())
          .fontSize(10)
          .fontColor('#CCCCCC')
      }
    }
    .width(36)
    .height(20)
    .backgroundColor(mood ? this.getMoodColor(mood) : '#F0F0F0')
    .borderRadius(4)
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 获取心情对应的颜色
   */
  getMoodColor(mood: number): string {
    const colors: Record<number, string> = {
      1: '#FFE0E0',  // 红色系 - 累
      2: '#FFE8D0',
      3: '#FFF3D0',  // 黄色系 - 一般
      4: '#E0F0D0',
      5: '#D0F0D0'   // 绿色系 - 很有劲
    };
    return colors[mood] || '#F0F0F0';
  }

  /**
   * 打卡表单
   */
  @Builder
  CheckinForm() {
    Column() {
      Text('📝 今日打卡')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })

      // 心情选择
      Text('今天感觉怎么样？')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ bottom: 8 })

      Row() {
        ForEach([1, 2, 3, 4, 5], (mood: number) => {
          Column() {
            Text(MOOD_CONFIG[mood].emoji)
              .fontSize(28)
            Text(MOOD_CONFIG[mood].label)
              .fontSize(10)
              .fontColor(this.viewModel.selectedMood === mood ? '#FF6B6B' : '#999999')
          }
          .padding(8)
          .backgroundColor(this.viewModel.selectedMood === mood ? '#FFF0F0' : 'transparent')
          .borderRadius(12)
          .onClick(() => this.viewModel.setMood(mood))
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .margin({ bottom: 16 })

      // 备注输入
      TextArea({ placeholder: '写点今天的感受...', text: this.viewModel.note })
        .width('100%')
        .height(80)
        .borderRadius(12)
        .backgroundColor('#F5F5F5')
        .onChange((value: string) => this.viewModel.setNote(value))

      // 打卡按钮
      Button('✅ 打卡')
        .width('100%')
        .height(48)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .borderRadius(24)
        .backgroundColor('#FF6B6B')
        .margin({ top: 16 })
        .enabled(!this.viewModel.isLoading)
        .onClick(() => this.handleCheckin())
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }

  /**
   * 已打卡视图
   */
  @Builder
  CheckedInView() {
    Column() {
      Text('🎉 今日已完成打卡')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 12 })

      Row() {
        Text('心情：')
          .fontColor('#666666')
        Text(this.viewModel.currentMoodConfig.emoji + ' ' + this.viewModel.currentMoodConfig.label)
          .fontColor('#FF6B6B')
          .fontWeight(FontWeight.Medium)
      }
      .margin({ bottom: 8 })

      if (this.viewModel.note) {
        Text(this.viewModel.note)
          .fontSize(14)
          .fontColor('#666666')
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }

      Text('明天继续加油 💪')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 12 })
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#E8F5E9')
    .borderRadius(16)
  }

  /**
   * 处理打卡
   */
  async handleCheckin(): Promise<void> {
    const success = await this.viewModel.doCheckin();
    if (success) {
      // TODO: 显示 Toast 或其他反馈
    }
  }
}
