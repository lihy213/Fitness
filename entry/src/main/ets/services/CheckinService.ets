import { CheckinRecord, MoodLevel } from '../database/entities/CheckinRecord';
import { CheckinDao } from '../database/dao/CheckinDao';

/**
 * CheckinService - 打卡业务服务层
 *
 * Python 对比:
 * class CheckinService:
 *     def __init__(self, dao: CheckinDao):
 *         self.dao = dao
 *
 *     def checkin(self, mood: int, note: str) -> CheckinRecord:
 *         # 业务逻辑：检查是否已打卡
 *         today = datetime.now().strftime('%Y-%m-%d')
 *         existing = self.dao.query_by_date(today)
 *         if existing:
 *             raise ValueError('今日已打卡')
 *         record = CheckinRecord(date=today, mood=mood, note=note)
 *         self.dao.insert(record)
 *         return record
 *
 * Service 层: 处理业务逻辑、参数校验、事务管理
 * 不直接操作数据库，通过 DAO 间接操作
 */
export class CheckinService {
  private dao: CheckinDao;

  constructor(dao: CheckinDao) {
    this.dao = dao;
  }

  /**
   * 获取今日日期字符串
   * Python: datetime.now().strftime('%Y-%m-%d')
   */
  private getTodayStr(): string {
    const now = new Date();
    return now.toISOString().split('T')[0];
  }

  /**
   * 今日打卡
   *
   * @param mood 心情评分 (1-5)
   * @param note 打卡备注
   * @returns 打卡记录
   * @throws 如果今日已打卡则抛出异常
   */
  async checkin(mood: number, note: string): Promise<CheckinRecord> {
    // 业务校验
    if (mood < 1 || mood > 5) {
      throw new Error('心情评分必须在 1-5 之间');
    }

    const today = this.getTodayStr();

    // 检查是否已打卡
    const existing = await this.dao.queryByDate(today);
    if (existing) {
      throw new Error('今日已打卡，不能重复打卡');
    }

    // 创建记录
    const record = new CheckinRecord(today, mood, note);

    // 插入数据库
    const id = await this.dao.insert(record);
    record.id = id;

    return record;
  }

  /**
   * 获取今日打卡状态
   */
  async getTodayCheckin(): Promise<CheckinRecord | null> {
    return await this.dao.queryByDate(this.getTodayStr());
  }

  /**
   * 获取本月打卡热力图数据
   * @param yearMonth "YYYY-MM" 格式，如 "2026-05"
   */
  async getMonthCheckins(yearMonth: string): Promise<CheckinRecord[]> {
    return await this.dao.queryByMonth(yearMonth);
  }

  /**
   * 获取连续打卡天数
   */
  async getStreak(): Promise<number> {
    return await this.dao.getStreak();
  }

  /**
   * 更新打卡信息（心情/备注）
   */
  async updateCheckin(id: number, mood: number, note: string): Promise<void> {
    if (mood < 1 || mood > 5) {
      throw new Error('心情评分必须在 1-5 之间');
    }

    const record = new CheckinRecord();
    record.id = id;
    record.mood = mood;
    record.note = note;

    await this.dao.update(record);
  }

  /**
   * 删除打卡记录
   */
  async deleteCheckin(id: number): Promise<void> {
    await this.dao.delete(id);
  }

  /**
   * 获取打卡统计数据
   */
  async getStats(): Promise<{
    totalDays: number;
    currentStreak: number;
    longestStreak: number;
  }> {
    const currentStreak = await this.dao.getStreak();
    // TODO: 统计 totalDays 和 longestStreak 需要更复杂的查询
    return {
      totalDays: 0,  // 待实现
      currentStreak: currentStreak,
      longestStreak: 0  // 待实现
    };
  }
}
