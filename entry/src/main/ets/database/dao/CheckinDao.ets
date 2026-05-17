import relationalStore from '@ohos.data.relationalStore';
import { CheckinRecord } from '../entities/CheckinRecord';

/**
 * CheckinDao - 打卡记录数据访问对象
 *
 * Python 对比:
 * class CheckinDao:
 *     def __init__(self, db):
 *         self.db = db
 *
 *     def insert(self, record: CheckinRecord) -> int:
 *         # 插入记录
 *         pass
 *
 *     def query_by_date(self, date: str) -> Optional[CheckinRecord]:
 *         # 按日期查询
 *         pass
 *
 * Dao 负责: SQL 操作、数据库 CRUD，不做业务逻辑
 */
export class CheckinDao {
  private store: relationalStore.RdbStore | null = null;
  private tableName: string = 'checkin_records';

  /**
   * 初始化 DAO，注入数据库实例
   */
  init(store: relationalStore.RdbStore): void {
    this.store = store;
  }

  /**
   * 插入打卡记录
   *
   * Python (伪代码):
   * def insert(self, record):
   *     sql = "INSERT INTO checkin_records (date, mood, note, created_at)
   *            VALUES (?, ?, ?, ?)"
   *     cursor.execute(sql, (record.date, record.mood, record.note, record.created_at))
   *     return cursor.lastrowid
   *
   * @returns 新记录 ID
   */
  async insert(record: CheckinRecord): Promise<number> {
    if (!this.store) {
      throw new Error('CheckinDao not initialized');
    }

    const valueBuckets: relationalStore.ValuesBucket = {
      'date': record.date,
      'mood': record.mood,
      'note': record.note,
      'created_at': record.createdAt
    };

    const id = await this.store.insert(this.tableName, valueBuckets);
    return id;
  }

  /**
   * 按日期查询打卡记录
   *
   * @param date 日期字符串 "YYYY-MM-DD"
   */
  async queryByDate(date: string): Promise<CheckinRecord | null> {
    if (!this.store) {
      throw new Error('CheckinDao not initialized');
    }

    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.equalTo('date', date);

    const resultSet = await this.store.query(predicates, ['id', 'date', 'mood', 'note', 'created_at']);

    if (resultSet.goToFirstRow()) {
      const record = new CheckinRecord();
      record.id = resultSet.getLong(resultSet.getColumnIndex('id'));
      record.date = resultSet.getString(resultSet.getColumnIndex('date'));
      record.mood = resultSet.getLong(resultSet.getColumnIndex('mood'));
      record.note = resultSet.getString(resultSet.getColumnIndex('note'));
      record.createdAt = resultSet.getLong(resultSet.getColumnIndex('created_at'));
      resultSet.close();
      return record;
    }

    resultSet.close();
    return null;
  }

  /**
   * 查询某月所有打卡记录（用于打卡热力图）
   *
   * @param yearMonth "YYYY-MM" 格式
   */
  async queryByMonth(yearMonth: string): Promise<CheckinRecord[]> {
    if (!this.store) {
      throw new Error('CheckinDao not initialized');
    }

    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.like('date', `${yearMonth}%`);  // 模糊匹配 "2026-05-%"

    const resultSet = await this.store.query(predicates, ['id', 'date', 'mood', 'note', 'created_at']);

    const records: CheckinRecord[] = [];
    while (resultSet.goToNextRow()) {
      const record = new CheckinRecord();
      record.id = resultSet.getLong(resultSet.getColumnIndex('id'));
      record.date = resultSet.getString(resultSet.getColumnIndex('date'));
      record.mood = resultSet.getLong(resultSet.getColumnIndex('mood'));
      record.note = resultSet.getString(resultSet.getColumnIndex('note'));
      record.createdAt = resultSet.getLong(resultSet.getColumnIndex('created_at'));
      records.push(record);
    }

    resultSet.close();
    return records;
  }

  /**
   * 查询连续打卡天数
   */
  async getStreak(): Promise<number> {
    if (!this.store) {
      throw new Error('CheckinDao not initialized');
    }

    // 获取所有打卡日期，按日期倒序
    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.orderByDesc('date');

    const resultSet = await this.store.query(predicates, ['date']);

    const dates: string[] = [];
    while (resultSet.goToNextRow()) {
      dates.push(resultSet.getString(resultSet.getColumnIndex('date')));
    }
    resultSet.close();

    if (dates.length === 0) {
      return 0;
    }

    // 计算连续天数（从今天/昨天开始往前数）
    let streak = 0;
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    const todayStr = today.toISOString().split('T')[0];
    const yesterdayStr = yesterday.toISOString().split('T')[0];

    // 必须从今天或昨天开始才计算连续
    if (dates[0] !== todayStr && dates[0] !== yesterdayStr) {
      return 0;
    }

    let expectedDate = new Date(dates[0]);
    for (const dateStr of dates) {
      const checkDate = new Date(dateStr);
      if (checkDate.getTime() === expectedDate.getTime()) {
        streak++;
        expectedDate.setDate(expectedDate.getDate() - 1);
      } else {
        break;  // 连续中断
      }
    }

    return streak;
  }

  /**
   * 更新打卡记录
   */
  async update(record: CheckinRecord): Promise<number> {
    if (!this.store) {
      throw new Error('CheckinDao not initialized');
    }

    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.equalTo('id', record.id);

    const valueBuckets: relationalStore.ValuesBucket = {
      'mood': record.mood,
      'note': record.note
    };

    return await this.store.update(this.tableName, valueBuckets, predicates);
  }

  /**
   * 删除打卡记录
   */
  async delete(id: number): Promise<number> {
    if (!this.store) {
      throw new Error('CheckinDao not initialized');
    }

    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.equalTo('id', id);

    return await this.store.delete(this.tableName, predicates);
  }
}
