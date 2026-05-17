import { WorkoutSession, WorkoutSet } from '../database/entities/WorkoutEntity';
import { WorkoutService } from '../services/WorkoutService';

/**
 * WorkoutViewModel - 训练记录页面 ViewModel
 */
@Observed
export class WorkoutViewModel {
  // 今日训练列表
  @Trace todayWorkouts: WorkoutSession[] = [];

  // 当前进行中的训练
  @Trace currentSession: WorkoutSession | null = null;

  // 统计数据
  @Trace stats = {
    totalWorkouts: 0,
    totalVolume: 0,
    totalDuration: 0
  };

  // 添加组表单数据
  @Trace selectedExerciseId: number = 0;
  @Trace weight: number = 0;
  @Trace reps: number = 0;

  // 加载状态
  @Trace isLoading: boolean = false;

  // 错误信息
  @Trace errorMessage: string = '';

  private service: WorkoutService | null = null;

  init(service: WorkoutService): void {
    this.service = service;
  }

  async loadData(): Promise<void> {
    if (!this.service) return;

    this.isLoading = true;
    try {
      const [workouts, stats] = await Promise.all([
        this.service.getTodayWorkouts(),
        this.service.getStats()
      ]);
      this.todayWorkouts = workouts;
      this.stats = stats;
    } catch (err) {
      this.errorMessage = `${err}`;
    } finally {
      this.isLoading = false;
    }
  }

  // 计算属性：今日总训练量
  get todayTotalVolume(): number {
    return this.todayWorkouts.reduce((sum, s) => sum + s.totalVolume, 0);
  }
}
