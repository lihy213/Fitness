import { WeightRecord, WeightStats, ChartDataPoint } from '../database/entities/WeightRecord';
import { WeightDao } from '../database/dao/WeightDao';

/**
 * WeightService - 体重管理业务服务层
 */
export class WeightService {
  private dao: WeightDao;

  // 用户身高（用于计算 BMI）
  private userHeight: number = 170;  // cm

  // 目标体重
  private targetWeight: number = 70;  // kg

  constructor(dao: WeightDao) {
    this.dao = dao;
  }

  /**
   * 设置用户身高
   */
  setUserHeight(height: number): void {
    if (height > 0) {
      this.userHeight = height;
    }
  }

  /**
   * 设置目标体重
   */
  setTargetWeight(weight: number): void {
    this.targetWeight = weight;
  }

  /**
   * 记录体重
   */
  async recordWeight(weight: number, bodyFat?: number, note?: string): Promise<WeightRecord> {
    if (weight <= 0 || weight > 500) {
      throw new Error('请输入有效的体重值（1-500 kg）');
    }

    const today = new Date().toISOString().split('T')[0];

    // 检查今日是否已有记录
    const existing = await this.dao.queryByDate(today);
    if (existing) {
      // 更新现有记录
      existing.weight = weight;
      if (bodyFat !== undefined) existing.bodyFat = bodyFat;
      if (note) existing.note = note;
      await this.dao.update(existing);
      return existing;
    }

    // 创建新记录
    const record = new WeightRecord(weight);
    record.date = today;
    if (bodyFat !== undefined) record.bodyFat = bodyFat;
    if (note) record.note = note;

    record.id = await this.dao.insert(record);
    return record;
  }

  /**
   * 获取今日体重
   */
  async getTodayWeight(): Promise<WeightRecord | null> {
    const today = new Date().toISOString().split('T')[0];
    return await this.dao.queryByDate(today);
  }

  /**
   * 获取最新体重
   */
  async getLatestWeight(): Promise<WeightRecord | null> {
    return await this.dao.queryLatest();
  }

  /**
   * 获取体重趋势数据（图表用）
   *
   * @param period 'week' | 'month' | 'year'
   */
  async getTrendData(period: 'week' | 'month' | 'year'): Promise<ChartDataPoint[]> {
    const rawData = await this.dao.getTrend(period);

    return rawData.map(item => ({
      date: item.date,
      value: item.weight,
      // 简化标签：只显示日期数字
      label: item.date.split('-')[2]  // "2026-05-17" -> "17"
    }));
  }

  /**
   * 获取体重统计
   */
  async getStats(): Promise<WeightStats> {
    const latest = await this.dao.queryLatest();
    const weekData = await this.dao.queryRecentDays(7);
    const monthData = await this.dao.queryRecentDays(30);

    const stats = new WeightStats();
    stats.targetWeight = this.targetWeight;

    if (latest) {
      stats.currentWeight = latest.weight;
      stats.bmi = latest.weight / Math.pow(this.userHeight / 100, 2);
    }

    // 计算起始体重（取 30 天前的记录）
    if (monthData.length > 0) {
      stats.startWeight = monthData[0].weight;
      stats.change = stats.currentWeight - stats.startWeight;
    }

    // 计算每周平均变化
    if (weekData.length >= 2) {
      const firstWeek = weekData[0];
      const lastWeek = weekData[weekData.length - 1];
      const daysDiff = (firstWeek.createdAt - lastWeek.createdAt) / (1000 * 60 * 60 * 24);
      if (daysDiff > 0) {
        stats.weeklyChange = ((lastWeek.weight - firstWeek.weight) / daysDiff) * 7;
      }
    }

    // 计算达标天数（接近目标体重 1kg 以内）
    stats.onTrackDays = monthData.filter(r =>
      Math.abs(r.weight - this.targetWeight) <= 1
    ).length;

    return stats;
  }

  /**
   * 删除体重记录
   */
  async deleteRecord(id: number): Promise<void> {
    await this.dao.delete(id);
  }
}
