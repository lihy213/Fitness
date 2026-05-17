import router from '@ohos.router';
import { DiaryViewModel } from '../viewmodels/DiaryViewModel';
import { DiaryService } from '../services/DiaryService';
import { DiaryDao } from '../database/dao/DiaryDao';
import { DIARY_MOOD, DIARY_TEMPLATES } from '../database/entities/DiaryRecord';

/**
 * DiaryPage - 感受日记页面
 *
 * 功能：
 * - 写今日日记（心情 + 文字 + 照片）
 * - 查看今日日记
 * - 查看本月日记列表
 * - 心情统计
 */
@Entry
@Component
struct DiaryPage {
  @State viewModel: DiaryViewModel = new DiaryViewModel();
  private diaryDao: DiaryDao = new DiaryDao();
  private diaryService: DiaryService | null = null;

  aboutToAppear() {
    this.diaryService = new DiaryService(this.diaryDao);
    this.viewModel.init(this.diaryService);
    this.viewModel.loadData();
  }

  build() {
    Column() {
      // 顶部导航
      this.NavigationBar()

      Scroll() {
        Column() {
          // 今日心情卡片
          this.TodayMoodCard()

          // 写日记 / 查看日记
          if (this.viewModel.isWritten) {
            this.ViewDiaryCard()
          } else {
            this.WriteDiaryCard()
          }

          // 本月日记列表
          this.MonthDiaryList()

          // 心情统计
          this.MoodStatsCard()
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
      Text('📝 感受日记')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      Blank()

      Row({ space: 20 }) {
        Text('🏠').fontSize(24).onClick(() => router.back())
        Text('💪').fontSize(24).onClick(() => router.pushUrl({ url: 'pages/WorkoutPage' }))
        Text('⚖️').fontSize(24).onClick(() => router.pushUrl({ url: 'pages/WeightPage' }))
        Text('📝').fontSize(24)
        Text('👤').fontSize(24).onClick(() => router.pushUrl({ url: 'pages/ProfilePage' }))
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
  }

  @Builder
  TodayMoodCard() {
    Row() {
      Column() {
        Text('今日心情')
          .fontSize(14)
          .fontColor('#666666')
        Row({ space: 4 }) {
          Text(this.viewModel.moodConfig.emoji)
            .fontSize(32)
          Text(this.viewModel.moodConfig.label)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.viewModel.moodConfig.color)
        }
      }
      .alignItems(HorizontalAlign.Start)

      Blank()

      // 快速心情选择
      Row({ space: 4 }) {
        ForEach([1, 2, 3, 4, 5], (mood: number) => {
          Text(DIARY_MOOD[mood].emoji)
            .fontSize(20)
            .padding(4)
            .backgroundColor(this.viewModel.selectedMood === mood ? '#F0F0F0' : 'transparent')
            .borderRadius(8)
            .onClick(() => this.viewModel.setMood(mood))
        })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ bottom: 16 })
  }

  @Builder
  WriteDiaryCard() {
    Column() {
      Text('✍️ 写今日日记')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .alignSelf(HorizontalAlign.Start)
        .margin({ bottom: 12 })

      // 模板按钮
      Row() {
        Text('📋 快捷模板')
          .fontSize(12)
          .fontColor('#2196F3')
          .padding({ horizontal: 12, vertical: 6 })
          .backgroundColor('#E3F2FD')
          .borderRadius(12)
          .onClick(() => this.viewModel.toggleTemplates())
      }
      .margin({ bottom: 8 })

      // 模板列表
      if (this.viewModel.showTemplates) {
        Column() {
          ForEach(DIARY_TEMPLATES, (t: string) => {
            Text(t)
              .fontSize(12)
              .fontColor('#666666')
              .width('100%')
              .padding(8)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .margin({ bottom: 4 })
              .onClick(() => this.viewModel.useTemplate(t))
          })
        }
        .margin({ bottom: 8 })
      }

      // 正文输入
      TextArea({ placeholder: '记录今天的运动感受...', text: this.viewModel.content })
        .width('100%')
        .height(120)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .onChange((value: string) => this.viewModel.setContent(value))

      // 保存按钮
      Button('💾 保存日记')
        .width('100%')
        .height(44)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .borderRadius(22)
        .backgroundColor('#4CAF50')
        .margin({ top: 12 })
        .onClick(() => this.saveDiary())
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ bottom: 16 })
  }

  @Builder
  ViewDiaryCard() {
    Column() {
      Row() {
        Text('📖 今日日记')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        Blank()
        Text(new Date().toISOString().split('T')[0])
          .fontSize(12)
          .fontColor('#999999')
      }
      .margin({ bottom: 8 })

      // 心情
      Row({ space: 8 }) {
        Text(this.viewModel.todayDiary ? DIARY_MOOD[this.viewModel.todayDiary.mood].emoji : '')
          .fontSize(24)
        Text(this.viewModel.todayDiary ? DIARY_MOOD[this.viewModel.todayDiary.mood].label : '')
          .fontSize(14)
          .fontColor('#666666')
      }
      .margin({ bottom: 8 })

      // 内容
      if (this.viewModel.todayDiary && this.viewModel.todayDiary.content) {
        Text(this.viewModel.todayDiary.content)
          .fontSize(14)
          .fontColor('#333333')
          .textAlign(TextAlign.Start)
          .width('100%')
          .margin({ bottom: 8 })
      }

      // 照片缩略图（如果有）
      if (this.viewModel.photos.length > 0) {
        Row({ space: 8 }) {
          ForEach(this.viewModel.photos.slice(0, 3), (photo: string) => {
            Image(photo)
              .width(60)
              .height(60)
              .borderRadius(8)
              .objectFit(ImageFit.Cover)
          })
        }
        .margin({ top: 8 })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#E8F5E9')
    .borderRadius(16)
    .margin({ bottom: 16 })
  }

  @Builder
  MonthDiaryList() {
    Column() {
      Text('📅 本月日记')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .alignSelf(HorizontalAlign.Start)
        .margin({ bottom: 12 })

      if (this.viewModel.monthDiaries.length === 0) {
        Text('本月暂无日记')
          .fontSize(14)
          .fontColor('#999999')
          .padding(20)
      } else {
        List() {
          ForEach(this.viewModel.monthDiaries.slice(0, 5), (record: DiaryRecord) => {
            ListItem() {
              this.DiaryListItem(record)
            }
          })
        }
        .height(300)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ bottom: 16 })
  }

  @Builder
  DiaryListItem(record: DiaryRecord) {
    Row() {
      Text(DIARY_MOOD[record.mood]?.emoji || '😐')
        .fontSize(20)
        .margin({ right: 12 })

      Column() {
        Text(record.content || '无内容')
          .fontSize(14)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(record.date)
          .fontSize(10)
          .fontColor('#999999')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#F5F5F5')
    .borderRadius(8)
    .margin({ bottom: 4 })
  }

  @Builder
  MoodStatsCard() {
    Column() {
      Text('📊 本月心情统计')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .alignSelf(HorizontalAlign.Start)
        .margin({ bottom: 12 })

      Row({ space: 8 }) {
        ForEach([5, 4, 3, 2, 1], (mood: number) => {
          Column() {
            Text(DIARY_MOOD[mood].emoji)
              .fontSize(16)
            Text(`${this.viewModel.moodStats[mood] || 0}天`)
              .fontSize(10)
              .fontColor('#666666')
            // 简单柱状图
            Column()
              .width(20)
              .height(this.getStatBarHeight(mood))
              .backgroundColor(DIARY_MOOD[mood].color)
              .borderRadius(4)
              .margin({ top: 4 })
          }
        })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }

  getStatBarHeight(mood: number): string {
    const count = this.viewModel.moodStats[mood] || 0;
    return `${Math.max(count * 8, 4)}vp`;
  }

  async saveDiary(): Promise<void> {
    const success = await this.viewModel.saveDiary();
    if (success) {
      // TODO: 显示 Toast
    }
  }
}
