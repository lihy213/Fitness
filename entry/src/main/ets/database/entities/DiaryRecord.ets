/**
 * DiaryRecord - 感受日记实体类
 *
 * Python 对比:
 * class DiaryRecord:
 *     def __init__(self, id: int, date: str,
 *                  mood: int, content: str,
 *                  photos: list[str], created_at: int):
 *         self.id = id
 *         self.date = date
 *         self.mood = mood  # 1-5 心情评分
 *         self.content = content  # 日记内容
 *         self.photos = photos  # 照片路径列表
 *         self.created_at = created_at
 */
export class DiaryRecord {
  id: number = 0;
  date: string = "";         // "YYYY-MM-DD"
  mood: number = 3;          // 1-5 心情评分
  content: string = "";       // 日记内容
  photos: string[] = [];     // 照片路径列表
  createdAt: number = 0;

  constructor(mood?: number, content?: string) {
    if (mood !== undefined) this.mood = mood;
    if (content) this.content = content;
    this.createdAt = Date.now();
  }
}

/**
 * 心情配置（日记专用）
 */
export const DIARY_MOOD: Record<number, { emoji: string; label: string; color: string }> = {
  1: { emoji: '😫', label: '很糟糕', color: '#FF6B6B' },
  2: { emoji: '😕', label: '不太好', color: '#FFA07A' },
  3: { emoji: '😐', label: '一般般', color: '#FFD700' },
  4: { emoji: '🙂', label: '还不错', color: '#98FB98' },
  5: { emoji: '😄', label: '超开心', color: '#32CD32' },
};

/**
 * 日记模板（快捷输入）
 */
export const DIARY_TEMPLATES = [
  "今天状态不错，按计划完成了训练💪",
  "练后感觉肌肉充血明显，效果很好！",
  "今天有点累，稍微降低了重量",
  "完成了新的训练计划，突破了自己🎯",
  "休息日，让身体充分恢复",
  "饮食控制得不错，继续努力！",
  "和朋友一起练，氛围很好👫",
  "今天特别有劲，所有组都完成了✅",
];
