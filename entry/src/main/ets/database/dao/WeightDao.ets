import relationalStore from '@ohos.data.relationalStore';
import { WeightRecord } from '../entities/WeightRecord';

/**
 * WeightDao - 体重记录数据访问对象
 */
export class WeightDao {
  private store: relationalStore.RdbStore | null = null;
  private tableName = 'weight_records';

  init(store: relationalStore.RdbStore): void {
    this.store = store;
  }

  /**
   * 插入体重记录
   */
  async insert(record: WeightRecord): Promise<number> {
    if (!this.store) {
      throw new Error('WeightDao not initialized');
    }

    const bucket: relationalStore.ValuesBucket = {
      'date': record.date,
      'weight': record.weight,
      'body_fat': record.bodyFat,
      'note': record.note,
      'created_at': record.createdAt
    };

    return await this.store.insert(this.tableName, bucket);
  }

  /**
   * 按日期查询
   */
  async queryByDate(date: string): Promise<WeightRecord | null> {
    if (!this.store) {
      throw new Error('WeightDao not initialized');
    }

    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.equalTo('date', date);

    const resultSet = await this.store.query(predicates,
      ['id', 'date', 'weight', 'body_fat', 'note', 'created_at']);

    if (resultSet.goToFirstRow()) {
      const record = new WeightRecord();
      record.id = resultSet.getLong(resultSet.getColumnIndex('id'));
      record.date = resultSet.getString(resultSet.getColumnIndex('date'));
      record.weight = resultSet.getDouble(resultSet.getColumnIndex('weight'));
      record.bodyFat = resultSet.getDouble(resultSet.getColumnIndex('body_fat'));
      record.note = resultSet.getString(resultSet.getColumnIndex('note'));
      record.createdAt = resultSet.getLong(resultSet.getColumnIndex('created_at'));
      resultSet.close();
      return record;
    }

    resultSet.close();
    return null;
  }

  /**
   * 查询某范围的所有记录（用于图表）
   *
   * @param startDate 开始日期 "YYYY-MM-DD"
   * @param endDate 结束日期 "YYYY-MM-DD"
   */
  async queryByDateRange(startDate: string, endDate: string): Promise<WeightRecord[]> {
    if (!this.store) {
      throw new Error('WeightDao not initialized');
    }

    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.greaterThanOrEqualTo('date', startDate);
    predicates.lessThanOrEqualTo('date', endDate);
    predicates.orderByAsc('date');

    const resultSet = await this.store.query(predicates,
      ['id', 'date', 'weight', 'body_fat', 'note', 'created_at']);

    const records: WeightRecord[] = [];
    while (resultSet.goToNextRow()) {
      const record = new WeightRecord();
      record.id = resultSet.getLong(resultSet.getColumnIndex('id'));
      record.date = resultSet.getString(resultSet.getColumnIndex('date'));
      record.weight = resultSet.getDouble(resultSet.getColumnIndex('weight'));
      record.bodyFat = resultSet.getDouble(resultSet.getColumnIndex('body_fat'));
      record.note = resultSet.getString(resultSet.getColumnIndex('note'));
      record.createdAt = resultSet.getLong(resultSet.getColumnIndex('created_at'));
      records.push(record);
    }
    resultSet.close();

    return records;
  }

  /**
   * 查询最近 N 天的记录
   */
  async queryRecentDays(days: number): Promise<WeightRecord[]> {
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const startStr = startDate.toISOString().split('T')[0];
    const endStr = endDate.toISOString().split('T')[0];

    return await this.queryByDateRange(startStr, endStr);
  }

  /**
   * 查询最近 N 周的记录（按周聚合）
   */
  async queryRecentWeeks(weeks: number): Promise<WeightRecord[]> {
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - weeks * 7);

    return await this.queryByDateRange(
      startDate.toISOString().split('T')[0],
      endDate.toISOString().split('T')[0]
    );
  }

  /**
   * 获取最新一条记录
   */
  async queryLatest(): Promise<WeightRecord | null> {
    if (!this.store) {
      throw new Error('WeightDao not initialized');
    }

    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.orderByDesc('date');
    predicates.limitAs(1);

    const resultSet = await this.store.query(predicates,
      ['id', 'date', 'weight', 'body_fat', 'note', 'created_at']);

    if (resultSet.goToFirstRow()) {
      const record = new WeightRecord();
      record.id = resultSet.getLong(resultSet.getColumnIndex('id'));
      record.date = resultSet.getString(resultSet.getColumnIndex('date'));
      record.weight = resultSet.getDouble(resultSet.getColumnIndex('weight'));
      record.bodyFat = resultSet.getDouble(resultSet.getColumnIndex('body_fat'));
      record.note = resultSet.getString(resultSet.getColumnIndex('note'));
      record.createdAt = resultSet.getLong(resultSet.getColumnIndex('created_at'));
      resultSet.close();
      return record;
    }

    resultSet.close();
    return null;
  }

  /**
   * 更新记录
   */
  async update(record: WeightRecord): Promise<number> {
    if (!this.store) {
      throw new Error('WeightDao not initialized');
    }

    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.equalTo('id', record.id);

    const bucket: relationalStore.ValuesBucket = {
      'weight': record.weight,
      'body_fat': record.bodyFat,
      'note': record.note
    };

    return await this.store.update(this.tableName, bucket, predicates);
  }

  /**
   * 删除记录
   */
  async delete(id: number): Promise<number> {
    if (!this.store) {
      throw new Error('WeightDao not initialized');
    }

    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.equalTo('id', id);

    return await this.store.delete(this.tableName, predicates);
  }

  /**
   * 获取体重变化趋势（用于图表）
   *
   * @param period 'week' | 'month' | 'year'
   */
  async getTrend(period: 'week' | 'month' | 'year'): Promise<{ date: string; weight: number }[]> {
    let days: number;
    switch (period) {
      case 'week': days = 7; break;
      case 'month': days = 30; break;
      case 'year': days = 365; break;
      default: days = 7;
    }
    const records = await this.queryRecentDays(days);
    return records.map(r => ({ date: r.date, weight: r.weight }));
  }
}
