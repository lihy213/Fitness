/**
 * DatabaseSchema - 数据库初始化脚本
 *
 * 定义所有表的创建语句
 * 在应用首次启动时调用
 */

/**
 * 打卡记录表建表语句
 *
 * Python (SQLAlchemy 风格):
 * from sqlalchemy import Column, Integer, String, Date, DateTime
 * class CheckinRecord(Base):
 *     __tablename__ = 'checkin_records'
 *
 *     id = Column(Integer, primary_key=True, autoincrement=True)
 *     date = Column(String(10), nullable=False, unique=True)  # "YYYY-MM-DD"
 *     mood = Column(Integer, nullable=False)  # 1-5
 *     note = Column(Text, default='')
 *     created_at = Column(Integer, nullable=False)  # timestamp in ms
 */
export const CREATE_CHECKIN_TABLE = `
CREATE TABLE IF NOT EXISTS checkin_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL UNIQUE,
    mood INTEGER NOT NULL DEFAULT 3,
    note TEXT DEFAULT '',
    created_at INTEGER NOT NULL
)
`;

/**
 * 索引：日期查询优化
 */
export const CREATE_CHECKIN_DATE_INDEX = `
CREATE INDEX IF NOT EXISTS idx_checkin_date ON checkin_records(date)
`;

/**
 * 所有建表语句列表
 */
export const ALL_SCHEMA_SQL = [
  CREATE_CHECKIN_TABLE,
  CREATE_CHECKIN_DATE_INDEX,
  // TODO: 其他表的建表语句
  // CREATE_WORKOUT_SESSION_TABLE,
  // CREATE_WEIGHT_TABLE,
  // ...
];
