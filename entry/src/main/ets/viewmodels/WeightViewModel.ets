import { WeightStats, ChartDataPoint } from '../database/entities/WeightRecord';
import { WeightService } from '../services/WeightService';

/**
 * WeightViewModel - 体重管理页面 ViewModel
 */
@Observed
export class WeightViewModel {
  // 统计数据
  @Trace stats: WeightStats = new WeightStats();

  // 图表数据
  @Trace chartData: ChartDataPoint[] = [];

  // 输入
  @Trace inputWeight: number = 0;
  @Trace inputBodyFat: number = 0;

  // 加载状态
  @Trace isLoading: boolean = false;

  // 错误信息
  @Trace errorMessage: string = '';

  private service: WeightService | null = null;

  init(service: WeightService): void {
    this.service = service;
  }

  async loadData(): Promise<void> {
    if (!this.service) return;

    this.isLoading = true;
    try {
      const stats = await this.service.getStats();
      this.stats = stats;
      await this.loadTrend('month');
    } catch (err) {
      this.errorMessage = `${err}`;
    } finally {
      this.isLoading = false;
    }
  }

  async loadTrend(period: 'week' | 'month' | 'year'): Promise<void> {
    if (!this.service) return;

    try {
      this.chartData = await this.service.getTrendData(period);
    } catch (err) {
      this.errorMessage = `${err}`;
    }
  }

  async saveWeight(weight: number, bodyFat?: number): Promise<void> {
    if (!this.service) return;

    this.isLoading = true;
    try {
      await this.service.recordWeight(weight, bodyFat);
      await this.loadData();
    } catch (err) {
      this.errorMessage = `${err}`;
    } finally {
      this.isLoading = false;
    }
  }
}
