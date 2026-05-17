import { CheckinRecord, MOOD_CONFIG } from '../database/entities/CheckinRecord';
import { CheckinService } from '../services/CheckinService';

/**
 * HomeViewModel - 首页/打卡页面的 ViewModel
 *
 * MVVM 模式中的 VM（ViewModel）层
 *
 * Python 对比 (Vue 组合式 API 风格):
 * import { ref, computed, onMounted } from 'vue'
 *
 * export class HomeViewModel {
 *     today_checkin = ref(null)
 *     streak = ref(0)
 *     month_checkins = ref([])
 *
 *     is_checked_in = computed(() => this.today_checkin.value !== null)
 *
 *     async on_mount():
 *         self.today_checkin.value = await checkin_service.get_today()
 *         self.streak.value = await checkin_service.get_streak()
 *         self.month_checkins.value = await checkin_service.get_month()
 *
 * ViewModel 负责:
 * - 持有页面状态（@State 装饰器）
 * - 调用 Service 处理业务
 * - 提供 UI 需要的数据（计算属性）
 * - 处理用户交互事件
 */
@Observed
export class HomeViewModel {
  // ========== 页面状态 ==========

  // 今日打卡记录
  @Trace todayCheckin: CheckinRecord | null = null;

  // 连续打卡天数
  @Trace streak: number = 0;

  // 本月打卡记录列表
  @Trace monthCheckins: CheckinRecord[] = [];

  // 当前选中的心情
  @Trace selectedMood: number = 3;

  // 打卡备注
  @Trace note: string = '';

  // 加载状态
  @Trace isLoading: boolean = false;

  // 错误信息
  @Trace errorMessage: string = '';

  // 服务实例
  private service: CheckinService | null = null;

  /**
   * 初始化 ViewModel
   * 在这里注入 Service 实例
   */
  init(service: CheckinService): void {
    this.service = service;
  }

  /**
   * 页面加载时调用
   * Python: async def on_page_load():
   */
  async loadData(): Promise<void> {
    if (!this.service) {
      this.errorMessage = '服务未初始化';
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    try {
      // 并行加载多个数据
      const [today, streak, month] = await Promise.all([
        this.service.getTodayCheckin(),
        this.service.getStreak(),
        this.service.getCurrentMonthCheckins()
      ]);

      this.todayCheckin = today;
      this.streak = streak;
      this.monthCheckins = month;

      // 如果今日已打卡，恢复数据
      if (today) {
        this.selectedMood = today.mood;
        this.note = today.note;
      }
    } catch (err) {
      this.errorMessage = `加载失败: ${err}`;
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 执行打卡
   */
  async doCheckin(): Promise<boolean> {
    if (!this.service) {
      this.errorMessage = '服务未初始化';
      return false;
    }

    this.isLoading = true;
    this.errorMessage = '';

    try {
      const record = await this.service.checkin(this.selectedMood, this.note);
      this.todayCheckin = record;
      this.streak = await this.service.getStreak();
      this.monthCheckins = await this.service.getCurrentMonthCheckins();
      return true;
    } catch (err) {
      this.errorMessage = `${err}`;
      return false;
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 更新打卡心情
   */
  setMood(mood: number): void {
    if (mood >= 1 && mood <= 5) {
      this.selectedMood = mood;
    }
  }

  /**
   * 更新打卡备注
   */
  setNote(note: string): void {
    this.note = note;
  }

  /**
   * 计算属性：是否已打卡
   */
  get isCheckedIn(): boolean {
    return this.todayCheckin !== null;
  }

  /**
   * 计算属性：当前选中的心情配置
   */
  get currentMoodConfig(): { emoji: string; label: string } {
    return MOOD_CONFIG[this.selectedMood] || MOOD_CONFIG[3];
  }

  /**
   * 计算属性：获取打卡热力图数据
   * 返回一个 Map，key 是日期（1-31），value 是心情评分
   */
  get heatmapData(): Map<number, number> {
    const map = new Map<number, number>();
    for (const record of this.monthCheckins) {
      const day = parseInt(record.date.split('-')[2], 10);
      map.set(day, record.mood);
    }
    return map;
  }
}
