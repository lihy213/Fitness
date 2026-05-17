import { WorkoutSession, WorkoutSet, EXERCISE_TEMPLATES, Exercise } from '../database/entities/WorkoutEntity';
import { WorkoutDao } from '../database/dao/WorkoutDao';

/**
 * WorkoutService - 训练记录业务服务层
 *
 * Python 对比:
 * class WorkoutService:
 *     def __init__(self, dao: WorkoutDao):
 *         self.dao = dao
 *         self.exercises = EXERCISE_TEMPLATES  # 内置动作库
 *
 *     def start_workout(self, name: str) -> WorkoutSession:
 *         # 开始一次新训练
 *         session = WorkoutSession(name=name, date=today)
 *         self.dao.insert_session(session)
 *         return session
 *
 *     def add_set(self, session_id: int, exercise_id: int,
 *                 weight: float, reps: int) -> WorkoutSet:
 *         # 添加一组
 *         pass
 *
 *     def finish_workout(self, session_id: int) -> WorkoutSession:
 *         # 完成训练，计算总训练量
 *         pass
 */
export class WorkoutService {
  private dao: WorkoutDao;
  exercises: Exercise[] = EXERCISE_TEMPLATES;

  constructor(dao: WorkoutDao) {
    this.dao = dao;
  }

  /**
   * 获取今日日期字符串
   */
  private getTodayStr(): string {
    return new Date().toISOString().split('T')[0];
  }

  /**
   * 开始一次新训练
   */
  async startWorkout(name: string): Promise<WorkoutSession> {
    const session = new WorkoutSession(name);
    session.date = this.getTodayStr();
    session.id = await this.dao.insertSession(session);
    return session;
  }

  /**
   * 添加一组训练
   */
  async addSet(
    sessionId: number,
    exerciseId: number,
    weight: number,
    reps: number,
    note?: string
  ): Promise<WorkoutSet> {
    // 校验参数
    if (weight < 0) {
      throw new Error('重量不能为负数');
    }
    if (reps <= 0) {
      throw new Error('次数必须大于 0');
    }

    // 获取动作名称
    const exercise = this.exercises.find(e => e.id === exerciseId);
    if (!exercise) {
      throw new Error('未找到该动作');
    }

    // 获取当前组数
    const sets = await this.dao.querySetsBySessionId(sessionId);
    const exerciseSets = sets.filter(s => s.exerciseId === exerciseId);
    const setNumber = exerciseSets.length + 1;

    const set = new WorkoutSet(sessionId, exerciseId);
    set.exerciseName = exercise.name;
    set.setNumber = setNumber;
    set.weight = weight;
    set.reps = reps;
    if (note) set.note = note;

    set.id = await this.dao.insertSet(set);
    return set;
  }

  /**
   * 完成训练
   */
  async finishWorkout(sessionId: number, durationMinutes: number): Promise<WorkoutSession> {
    const sessions = await this.dao.querySessionsByDate(this.getTodayStr());
    const session = sessions.find(s => s.id === sessionId);

    if (!session) {
      throw new Error('未找到该训练记录');
    }

    // 计算总训练量
    let totalVolume = 0;
    for (const set of session.sets) {
      totalVolume += set.weight * set.reps;
    }

    session.durationMinutes = durationMinutes;
    session.totalVolume = totalVolume;

    // TODO: 更新会话记录（需要添加 update 方法）

    return session;
  }

  /**
   * 获取今日训练
   */
  async getTodayWorkouts(): Promise<WorkoutSession[]> {
    return await this.dao.querySessionsByDate(this.getTodayStr());
  }

  /**
   * 获取本月所有训练
   */
  async getMonthWorkouts(yearMonth: string): Promise<WorkoutSession[]> {
    return await this.dao.querySessionsByMonth(yearMonth);
  }

  /**
   * 删除训练会话
   */
  async deleteWorkout(sessionId: number): Promise<void> {
    await this.dao.deleteSession(sessionId);
  }

  /**
   * 获取训练统计
   */
  async getStats(): Promise<{
    totalWorkouts: number;
    totalVolume: number;
    totalDuration: number;
  }> {
    return await this.dao.getStats();
  }

  /**
   * 搜索动作
   */
  searchExercises(keyword: string): Exercise[] {
    if (!keyword.trim()) {
      return this.exercises;
    }
    const lower = keyword.toLowerCase();
    return this.exercises.filter(e =>
      e.name.toLowerCase().includes(lower) ||
      e.category.toLowerCase().includes(lower)
    );
  }

  /**
   * 按部位筛选动作
   */
  getExercisesByCategory(category: string): Exercise[] {
    return this.exercises.filter(e => e.category === category);
  }
}
