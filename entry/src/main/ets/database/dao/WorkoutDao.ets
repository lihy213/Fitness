import relationalStore from '@ohos.data.relationalStore';
import { WorkoutSession, WorkoutSet } from '../entities/WorkoutEntity';

/**
 * WorkoutDao - 训练记录数据访问对象
 *
 * Python 对比:
 * class WorkoutDao:
 *     def __init__(self, db):
 *         self.db = db
 *
 *     def insert_session(self, session: WorkoutSession) -> int:
 *         pass
 *
 *     def insert_set(self, set: WorkoutSet) -> int:
 *         pass
 *
 *     def get_session_with_sets(self, session_id: int) -> WorkoutSession:
 *         pass
 */
export class WorkoutDao {
  private store: relationalStore.RdbStore | null = null;
  private sessionTable = 'workout_sessions';
  private setTable = 'workout_sets';

  init(store: relationalStore.RdbStore): void {
    this.store = store;
  }

  /**
   * 插入训练会话
   */
  async insertSession(session: WorkoutSession): Promise<number> {
    if (!this.store) {
      throw new Error('WorkoutDao not initialized');
    }

    const bucket: relationalStore.ValuesBucket = {
      'date': session.date,
      'name': session.name,
      'duration_minutes': session.durationMinutes,
      'total_volume': session.totalVolume,
      'created_at': session.createdAt
    };

    return await this.store.insert(this.sessionTable, bucket);
  }

  /**
   * 插入训练组
   */
  async insertSet(set: WorkoutSet): Promise<number> {
    if (!this.store) {
      throw new Error('WorkoutDao not initialized');
    }

    const bucket: relationalStore.ValuesBucket = {
      'session_id': set.sessionId,
      'exercise_id': set.exerciseId,
      'exercise_name': set.exerciseName,
      'set_number': set.setNumber,
      'weight': set.weight,
      'reps': set.reps,
      'note': set.note,
      'created_at': set.createdAt
    };

    return await this.store.insert(this.setTable, bucket);
  }

  /**
   * 批量插入训练组
   */
  async insertSets(sets: WorkoutSet[]): Promise<void> {
    for (const set of sets) {
      await this.insertSet(set);
    }
  }

  /**
   * 按日期查询训练会话（包含所有组）
   */
  async querySessionsByDate(date: string): Promise<WorkoutSession[]> {
    if (!this.store) {
      throw new Error('WorkoutDao not initialized');
    }

    const predicates = new relationalStore.RdbPredicates(this.sessionTable);
    predicates.equalTo('date', date);
    predicates.orderByDesc('created_at');

    const resultSet = await this.store.query(predicates,
      ['id', 'date', 'name', 'duration_minutes', 'total_volume', 'created_at']);

    const sessions: WorkoutSession[] = [];
    while (resultSet.goToNextRow()) {
      const session = new WorkoutSession();
      session.id = resultSet.getLong(resultSet.getColumnIndex('id'));
      session.date = resultSet.getString(resultSet.getColumnIndex('date'));
      session.name = resultSet.getString(resultSet.getColumnIndex('name'));
      session.durationMinutes = resultSet.getLong(resultSet.getColumnIndex('duration_minutes'));
      session.totalVolume = resultSet.getDouble(resultSet.getColumnIndex('total_volume'));
      session.createdAt = resultSet.getLong(resultSet.getColumnIndex('created_at'));
      sessions.push(session);
    }
    resultSet.close();

    // 查询每个会话的组
    for (const session of sessions) {
      session.sets = await this.querySetsBySessionId(session.id);
    }

    return sessions;
  }

  /**
   * 查询某会话的所有组
   */
  async querySetsBySessionId(sessionId: number): Promise<WorkoutSet[]> {
    if (!this.store) {
      throw new Error('WorkoutDao not initialized');
    }

    const predicates = new relationalStore.RdbPredicates(this.setTable);
    predicates.equalTo('session_id', sessionId);
    predicates.orderByAsc('set_number');

    const resultSet = await this.store.query(predicates,
      ['id', 'session_id', 'exercise_id', 'exercise_name', 'set_number', 'weight', 'reps', 'note', 'created_at']);

    const sets: WorkoutSet[] = [];
    while (resultSet.goToNextRow()) {
      const set = new WorkoutSet();
      set.id = resultSet.getLong(resultSet.getColumnIndex('id'));
      set.sessionId = resultSet.getLong(resultSet.getColumnIndex('session_id'));
      set.exerciseId = resultSet.getLong(resultSet.getColumnIndex('exercise_id'));
      set.exerciseName = resultSet.getString(resultSet.getColumnIndex('exercise_name'));
      set.setNumber = resultSet.getLong(resultSet.getColumnIndex('set_number'));
      set.weight = resultSet.getDouble(resultSet.getColumnIndex('weight'));
      set.reps = resultSet.getLong(resultSet.getColumnIndex('reps'));
      set.note = resultSet.getString(resultSet.getColumnIndex('note'));
      set.createdAt = resultSet.getLong(resultSet.getColumnIndex('created_at'));
      sets.push(set);
    }
    resultSet.close();

    return sets;
  }

  /**
   * 查询某月所有训练会话
   */
  async querySessionsByMonth(yearMonth: string): Promise<WorkoutSession[]> {
    if (!this.store) {
      throw new Error('WorkoutDao not initialized');
    }

    const predicates = new relationalStore.RdbPredicates(this.sessionTable);
    predicates.like('date', `${yearMonth}%`);
    predicates.orderByDesc('date');

    const resultSet = await this.store.query(predicates,
      ['id', 'date', 'name', 'duration_minutes', 'total_volume', 'created_at']);

    const sessions: WorkoutSession[] = [];
    while (resultSet.goToNextRow()) {
      const session = new WorkoutSession();
      session.id = resultSet.getLong(resultSet.getColumnIndex('id'));
      session.date = resultSet.getString(resultSet.getColumnIndex('date'));
      session.name = resultSet.getString(resultSet.getColumnIndex('name'));
      session.durationMinutes = resultSet.getLong(resultSet.getColumnIndex('duration_minutes'));
      session.totalVolume = resultSet.getDouble(resultSet.getColumnIndex('total_volume'));
      session.createdAt = resultSet.getLong(resultSet.getColumnIndex('created_at'));
      sessions.push(session);
    }
    resultSet.close();

    // 查询每个会话的组
    for (const session of sessions) {
      session.sets = await this.querySetsBySessionId(session.id);
    }

    return sessions;
  }

  /**
   * 删除训练会话（级联删除组）
   */
  async deleteSession(sessionId: number): Promise<void> {
    if (!this.store) {
      throw new Error('WorkoutDao not initialized');
    }

    // 先删除组
    const setPredicates = new relationalStore.RdbPredicates(this.setTable);
    setPredicates.equalTo('session_id', sessionId);
    await this.store.delete(this.setTable, setPredicates);

    // 再删除会话
    const sessionPredicates = new relationalStore.RdbPredicates(this.sessionTable);
    sessionPredicates.equalTo('id', sessionId);
    await this.store.delete(this.sessionTable, sessionPredicates);
  }

  /**
   * 获取训练统计数据
   */
  async getStats(): Promise<{
    totalWorkouts: number;
    totalVolume: number;
    totalDuration: number;
  }> {
    if (!this.store) {
      throw new Error('WorkoutDao not initialized');
    }

    // 获取总训练次数
    const countPredicates = new relationalStore.RdbPredicates(this.sessionTable);
    const countResult = await this.store.query(countPredicates, ['COUNT(*) as total']);
    countResult.goToFirstRow();
    const totalWorkouts = countResult.getLong(0);
    countResult.close();

    // 获取总训练量和时长
    const sumPredicates = new relationalStore.RdbPredicates(this.sessionTable);
    const sumResult = await this.store.query(sumPredicates,
      ['SUM(total_volume) as volume', 'SUM(duration_minutes) as duration']);
    sumResult.goToFirstRow();
    const totalVolume = sumResult.getDouble(0);
    const totalDuration = sumResult.getLong(1);
    sumResult.close();

    return { totalWorkouts, totalVolume, totalDuration };
  }
}
