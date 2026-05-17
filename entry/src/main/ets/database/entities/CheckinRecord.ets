/**
 * CheckinRecord - 打卡记录实体类
 *
 * Python 对比:
 * class CheckinRecord:
 *     def __init__(self, id: int, date: str, mood: int, note: str, created_at: datetime):
 *         self.id = id
 *         self.date = date
 *         self.mood = mood  # 1-5 心情评分
 *         self.note = note
 *         self.created_at = created_at
 *
 * ArkTS 的 class 更像 TypeScript/Python dataclass，
 * 需要用 @Observed 装饰器才能被观察变化
 */
export class CheckinRecord {
  // 主键 ID（自增）
  id: number = 0;

  // 打卡日期，格式: "YYYY-MM-DD"
  date: string = "";

  // 心情评分: 1=很差, 2=较差, 3=一般, 4=较好, 5=很好
  mood: number = 3;

  // 打卡备注/感受
  note: string = "";

  // 创建时间戳（毫秒）
  createdAt: number = 0;

  // 构造函数
  constructor(date?: string, mood?: number, note?: string) {
    if (date) this.date = date;
    if (mood !== undefined) this.mood = mood;
    if (note) this.note = note;
    this.createdAt = Date.now();
  }
}

/**
 * 心情选项枚举（用于 UI 显示）
 * Python: from enum import Enum, IntEnum
 */
export enum MoodLevel {
  VERY_BAD = 1,    // 😫 很差
  BAD = 2,         // 😕 较差
  NORMAL = 3,      // 😐 一般
  GOOD = 4,        // 🙂 较好
  VERY_GOOD = 5    // 😄 很好
}

/**
 * 心情配置信息
 * 提供 UI 显示用的 emoji 和中文标签
 */
export const MOOD_CONFIG: Record<number, { emoji: string; label: string }> = {
  1: { emoji: '😫', label: '很累' },
  2: { emoji: '😕', label: '有点累' },
  3: { emoji: '😐', label: '一般般' },
  4: { emoji: '🙂', label: '状态不错' },
  5: { emoji: '😄', label: '超有劲' }
};
