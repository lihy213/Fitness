import relationalStore from '@ohos.data.relationalStore';
import { DiaryRecord } from '../entities/DiaryRecord';

/**
 * DiaryDao - 感受日记数据访问对象
 */
export class DiaryDao {
  private store: relationalStore.RdbStore | null = null;
  private tableName = 'diary_entries';

  init(store: relationalStore.RdbStore): void {
    this.store = store;
  }

  /**
   * 插入日记
   */
  async insert(record: DiaryRecord): Promise<number> {
    if (!this.store) throw new Error('DiaryDao not initialized');

    const bucket: relationalStore.ValuesBucket = {
      'date': record.date,
      'mood': record.mood,
      'content': record.content,
      'photos': JSON.stringify(record.photos),  // 存为 JSON 字符串
      'created_at': record.createdAt
    };

    return await this.store.insert(this.tableName, bucket);
  }

  /**
   * 按日期查询
   */
  async queryByDate(date: string): Promise<DiaryRecord | null> {
    if (!this.store) throw new Error('DiaryDao not initialized');

    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.equalTo('date', date);

    const resultSet = await this.store.query(predicates,
      ['id', 'date', 'mood', 'content', 'photos', 'created_at']);

    if (resultSet.goToFirstRow()) {
      const record = new DiaryRecord();
      record.id = resultSet.getLong(resultSet.getColumnIndex('id'));
      record.date = resultSet.getString(resultSet.getColumnIndex('date'));
      record.mood = resultSet.getLong(resultSet.getColumnIndex('mood'));
      record.content = resultSet.getString(resultSet.getColumnIndex('content'));
      try {
        record.photos = JSON.parse(resultSet.getString(resultSet.getColumnIndex('photos')) || '[]');
      } catch {
        record.photos = [];
      }
      record.createdAt = resultSet.getLong(resultSet.getColumnIndex('created_at'));
      resultSet.close();
      return record;
    }
    resultSet.close();
    return null;
  }

  /**
   * 查询某月所有日记
   */
  async queryByMonth(yearMonth: string): Promise<DiaryRecord[]> {
    if (!this.store) throw new Error('DiaryDao not initialized');

    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.like('date', `${yearMonth}%`);
    predicates.orderByDesc('date');

    const resultSet = await this.store.query(predicates,
      ['id', 'date', 'mood', 'content', 'photos', 'created_at']);

    const records: DiaryRecord[] = [];
    while (resultSet.goToNextRow()) {
      const record = new DiaryRecord();
      record.id = resultSet.getLong(resultSet.getColumnIndex('id'));
      record.date = resultSet.getString(resultSet.getColumnIndex('date'));
      record.mood = resultSet.getLong(resultSet.getColumnIndex('mood'));
      record.content = resultSet.getString(resultSet.getColumnIndex('content'));
      try {
        record.photos = JSON.parse(resultSet.getString(resultSet.getColumnIndex('photos')) || '[]');
      } catch {
        record.photos = [];
      }
      record.createdAt = resultSet.getLong(resultSet.getColumnIndex('created_at'));
      records.push(record);
    }
    resultSet.close();
    return records;
  }

  /**
   * 更新日记
   */
  async update(record: DiaryRecord): Promise<number> {
    if (!this.store) throw new Error('DiaryDao not initialized');

    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.equalTo('id', record.id);

    const bucket: relationalStore.ValuesBucket = {
      'mood': record.mood,
      'content': record.content,
      'photos': JSON.stringify(record.photos)
    };

    return await this.store.update(this.tableName, bucket, predicates);
  }

  /**
   * 删除日记
   */
  async delete(id: number): Promise<number> {
    if (!this.store) throw new Error('DiaryDao not initialized');

    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.equalTo('id', id);

    return await this.store.delete(this.tableName, predicates);
  }

  /**
   * 获取心情统计（某月）
   * 返回各心情次数
   */
  async getMoodStats(yearMonth: string): Promise<Record<number, number>> {
    const records = await this.queryByMonth(yearMonth);
    const stats: Record<number, number> = { 1:0, 2:0, 3:0, 4:0, 5:0 };
    for (const r of records) {
      stats[r.mood] = (stats[r.mood] || 0) + 1;
    }
    return stats;
  }
}
