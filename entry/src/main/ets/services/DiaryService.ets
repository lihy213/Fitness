import { DiaryRecord, DIARY_TEMPLATES } from '../database/entities/DiaryRecord';
import { DiaryDao } from '../database/dao/DiaryDao';

/**
 * DiaryService - 感受日记业务服务层
 */
export class DiaryService {
  private dao: DiaryDao;

  constructor(dao: DiaryDao) {
    this.dao = dao;
  }

  /**
   * 写日记
   */
  async writeDiary(mood: number, content: string, photos?: string[]): Promise<DiaryRecord> {
    if (mood < 1 || mood > 5) {
      throw new Error('心情评分必须在 1-5 之间');
    }

    const today = new Date().toISOString().split('T')[0];

    // 检查今日是否已有日记
    const existing = await this.dao.queryByDate(today);
    if (existing) {
      // 更新现有日记
      existing.mood = mood;
      existing.content = content;
      if (photos) existing.photos = photos;
      await this.dao.update(existing);
      return existing;
    }

    // 创建新日记
    const record = new DiaryRecord(mood, content);
    record.date = today;
    if (photos) record.photos = photos;

    record.id = await this.dao.insert(record);
    return record;
  }

  /**
   * 获取今日日记
   */
  async getTodayDiary(): Promise<DiaryRecord | null> {
    const today = new Date().toISOString().split('T')[0];
    return await this.dao.queryByDate(today);
  }

  /**
   * 获取某月日记
   */
  async getMonthDiaries(yearMonth: string): Promise<DiaryRecord[]> {
    return await this.dao.queryByMonth(yearMonth);
  }

  /**
   * 删除日记
   */
  async deleteDiary(id: number): Promise<void> {
    await this.dao.delete(id);
  }

  /**
   * 获取心情统计
   */
  async getMoodStats(yearMonth: string): Promise<Record<number, number>> {
    return await this.dao.getMoodStats(yearMonth);
  }

  /**
   * 获取随机日记模板
   */
  getRandomTemplate(): string {
    const index = Math.floor(Math.random() * DIARY_TEMPLATES.length);
    return DIARY_TEMPLATES[index];
  }

  /**
   * 获取所有模板
   */
  getAllTemplates(): string[] {
    return DIARY_TEMPLATES;
  }
}
