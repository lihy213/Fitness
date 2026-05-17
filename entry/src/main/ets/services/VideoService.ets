import { ExerciseVideo, EXERCISE_VIDEOS, DIFICULTY_LABELS } from '../database/entities/ExerciseVideo';

/**
 * VideoService - 动作教学视频服务层
 *
 * 功能：
 * - 获取动作视频列表
 * - 按分类筛选
 * - 搜索动作
 * - 获取动作详情
 */
export class VideoService {
  private videos: ExerciseVideo[] = EXERCISE_VIDEOS;

  /**
   * 获取所有动作视频
   */
  getAllVideos(): ExerciseVideo[] {
    return this.videos;
  }

  /**
   * 按分类获取动作
   */
  getVideosByCategory(category: string): ExerciseVideo[] {
    if (category === '全部') return this.videos;
    return this.videos.filter(v => v.category === category);
  }

  /**
   * 获取所有分类
   */
  getCategories(): string[] {
    const cats = new Set(this.videos.map(v => v.category));
    return ['全部', ...Array.from(cats)];
  }

  /**
   * 根据 ID 获取动作详情
   */
  getVideoById(id: number): ExerciseVideo | undefined {
    return this.videos.find(v => v.id === id);
  }

  /**
   * 搜索动作
   */
  searchVideos(keyword: string): ExerciseVideo[] {
    if (!keyword.trim()) return this.videos;
    const lower = keyword.toLowerCase();
    return this.videos.filter(v =>
      v.exerciseName.toLowerCase().includes(lower) ||
      v.description.toLowerCase().includes(lower)
    );
  }

  /**
   * 根据难度筛选
   */
  filterByDifficulty(difficulty: number): ExerciseVideo[] {
    if (difficulty === 0) return this.videos;
    return this.videos.filter(v => v.difficulty === difficulty);
  }

  /**
   * 获取难度标签
   */
  getDifficultyLabel(difficulty: number): string {
    return DIFICULTY_LABELS[difficulty] || '未知';
  }

  /**
   * 获取推荐动作（根据难度 <= 3）
   */
  getRecommendedVideos(): ExerciseVideo[] {
    return this.videos.filter(v => v.difficulty <= 3);
  }
}
