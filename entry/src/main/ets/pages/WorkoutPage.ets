import router from '@ohos.router';
import { WorkoutViewModel } from '../viewmodels/WorkoutViewModel';
import { WorkoutService } from '../services/WorkoutService';
import { WorkoutDao } from '../database/dao/WorkoutDao';
import { WorkoutSession, WorkoutSet, EXERCISE_TEMPLATES, WORKOUT_CATEGORIES } from '../database/entities/WorkoutEntity';

/**
 * WorkoutPage - 训练记录页面
 *
 * 功能：
 * - 开始新训练
 * - 添加训练组（动作、重量、次数）
 * - 查看训练历史
 * - 查看训练统计
 */
@Entry
@Component
struct WorkoutPage {
  // ViewModel
  @State viewModel: WorkoutViewModel = new WorkoutViewModel();

  // 服务实例
  private workoutDao: WorkoutDao = new WorkoutDao();
  private workoutService: WorkoutService | null = null;

  // 当前训练会话（用于添加组）
  @State currentSession: WorkoutSession | null = null;

  aboutToAppear() {
    this.workoutService = new WorkoutService(this.workoutDao);
    this.viewModel.init(this.workoutService);
    this.viewModel.loadData();
  }

  build() {
    Column() {
      // 顶部导航
      this.NavigationBar()

      // 主内容
      if (this.currentSession) {
        this.ActiveWorkoutView()
      } else {
        this.WorkoutListView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  NavigationBar() {
    Row() {
      Text('💪 训练记录')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      Blank()

      Row({ space: 20 }) {
        Text('🏠').fontSize(24).onClick(() => router.back())
        Text('💪').fontSize(24)
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
  WorkoutListView() {
    Column() {
      // 统计卡片
      this.StatsCard()

      // 开始新训练按钮
      Button('🏋️ 开始新训练')
        .width('100%')
        .height(48)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .borderRadius(24)
        .backgroundColor('#4CAF50')
        .margin({ top: 16, bottom: 16 })
        .onClick(() => this.startNewWorkout())

      // 训练历史列表
      Text('📋 训练历史')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .alignSelf(HorizontalAlign.Start)
        .margin({ bottom: 12 })

      if (this.viewModel.todayWorkouts.length === 0) {
        Text('今日暂无训练记录\n点击上方按钮开始今天的训练')
          .fontSize(14)
          .fontColor('#999999')
          .textAlign(TextAlign.Center)
          .padding(40)
      } else {
        List() {
          ForEach(this.viewModel.todayWorkouts, (session: WorkoutSession) => {
            ListItem() {
              this.WorkoutSessionCard(session)
            }
          })
        }
      }
    }
    .padding(16)
    .layoutWeight(1)
  }

  @Builder
  StatsCard() {
    Row() {
      Column() {
        Text(this.viewModel.stats.totalWorkouts.toString())
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor('#4CAF50')
        Text('训练次数')
          .fontSize(12)
          .fontColor('#666666')
      }
      .layoutWeight(1)

      Divider()
        .vertical(true)
        .height(40)

      Column() {
        Text(this.viewModel.stats.totalVolume.toFixed(0))
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2196F3')
        Text('总训练量(kg)')
          .fontSize(12)
          .fontColor('#666666')
      }
      .layoutWeight(1)

      Divider()
        .vertical(true)
        .height(40)

      Column() {
        Text(this.viewModel.stats.totalDuration.toString())
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF9800')
        Text('总时长(分钟)')
          .fontSize(12)
          .fontColor('#666666')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }

  @Builder
  WorkoutSessionCard(session: WorkoutSession) {
    Column() {
      Row() {
        Text(session.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        Blank()
        Text(`${session.durationMinutes}分钟`)
          .fontSize(12)
          .fontColor('#999999')
      }

      Row() {
        Text(`${session.sets.length} 组  |  ${session.totalVolume.toFixed(0)} kg`)
          .fontSize(12)
          .fontColor('#666666')
      }
      .margin({ top: 4 })

      // 显示动作列表
      if (session.sets.length > 0) {
        Row() {
          Text(session.sets.map(s => s.exerciseName).join(' / '))
            .fontSize(12)
            .fontColor('#999999')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .margin({ top: 8 })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 8 })
  }

  @Builder
  ActiveWorkoutView() {
    Column() {
      // 训练头部
      Row() {
        Column() {
          Text(this.currentSession!.name)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
          Text(this.getTodayStr())
            .fontSize(12)
            .fontColor('#999999')
        }

        Blank()

        Button('结束训练')
          .fontSize(14)
          .backgroundColor('#FF5722')
          .borderRadius(20)
          .onClick(() => this.finishWorkout())
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#4CAF50')
      .borderRadius(16)
      .margin({ bottom: 16 })

      // 添加组表单
      this.AddSetForm()

      // 当前训练的组列表
      Text('📝 已添加的组')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .alignSelf(HorizontalAlign.Start)
        .margin({ top: 16, bottom: 12 })

      List() {
        ForEach(this.currentSession!.sets, (set: WorkoutSet, index: number) => {
          ListItem() {
            this.SetItem(set, index)
          }
        })
      }
    }
    .padding(16)
    .layoutWeight(1)
  }

  @Builder
  AddSetForm() {
    Column() {
      // 动作选择
      Text('选择动作')
        .fontSize(14)
        .fontColor('#666666')
        .alignSelf(HorizontalAlign.Start)

      // 简化版：显示预设动作列表
      Scroll() {
        Row({ space: 8 }) {
          ForEach(EXERCISE_TEMPLATES.slice(0, 8), (exercise) => {
            Text(exercise.name)
              .fontSize(12)
              .padding({ horizontal: 12, vertical: 6 })
              .backgroundColor(this.viewModel.selectedExerciseId === exercise.id ? '#4CAF50' : '#E0E0E0')
              .fontColor(this.viewModel.selectedExerciseId === exercise.id ? '#FFFFFF' : '#333333')
              .borderRadius(16)
              .onClick(() => this.viewModel.selectedExerciseId = exercise.id)
          })
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .margin({ bottom: 12 })

      // 重量和次数输入
      Row({ space: 16 }) {
        Column() {
          Text('重量 (kg)')
            .fontSize(12)
            .fontColor('#666666')
          TextInput({ placeholder: '0' })
            .width('100%')
            .textAlign(TextAlign.Center)
            .inputMode(InputMode.Number)
            .onChange((value) => this.viewModel.weight = Number(value))
        }
        .layoutWeight(1)

        Column() {
          Text('次数')
            .fontSize(12)
            .fontColor('#666666')
          TextInput({ placeholder: '0' })
            .width('100%')
            .textAlign(TextAlign.Center)
            .inputMode(InputMode.Number)
            .onChange((value) => this.viewModel.reps = Number(value))
        }
        .layoutWeight(1)
      }
      .margin({ bottom: 12 })

      // 添加按钮
      Button('➕ 添加这一组')
        .width('100%')
        .height(44)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .borderRadius(22)
        .backgroundColor('#2196F3')
        .onClick(() => this.addSet())
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }

  @Builder
  SetItem(set: WorkoutSet, index: number) {
    Row() {
      Text(`${index + 1}`)
        .fontSize(12)
        .fontColor('#999999')
        .width(24)

      Column() {
        Text(set.exerciseName)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
        Text(`${set.weight} kg × ${set.reps} 次`)
          .fontSize(12)
          .fontColor('#666666')
      }
      .layoutWeight(1)

      if (set.note) {
        Text(set.note)
          .fontSize(10)
          .fontColor('#999999')
          .backgroundColor('#F5F5F5')
          .padding({ horizontal: 8, vertical: 2 })
          .borderRadius(8)
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ bottom: 4 })
  }

  // ========== 操作方法 ==========

  startNewWorkout(): void {
    // TODO: 显示训练名称选择对话框
    // 暂时使用默认名称
    const session = new WorkoutSession('综合训练');
    session.date = this.getTodayStr();
    this.currentSession = session;
    this.viewModel.currentSession = session;
  }

  async addSet(): Promise<void> {
    if (!this.currentSession || !this.workoutService) return;
    if (!this.viewModel.selectedExerciseId || !this.viewModel.weight || !this.viewModel.reps) {
      return;
    }

    try {
      const set = await this.workoutService.addSet(
        this.currentSession.id,
        this.viewModel.selectedExerciseId,
        this.viewModel.weight,
        this.viewModel.reps
      );
      this.currentSession.sets.push(set);
    } catch (err) {
      // TODO: 显示错误
    }
  }

  finishWorkout(): void {
    this.currentSession = null;
    this.viewModel.currentSession = null;
    this.viewModel.loadData();
  }

  getTodayStr(): string {
    return new Date().toISOString().split('T')[0];
  }
}
