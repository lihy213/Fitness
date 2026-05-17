/**
 * 云同步记录实体
 * 用于记录每次同步的状态和时间
 * 
 * Python对比：
 * class SyncRecord:
 *     def __init__(self):
 *         self.id: int = 0          # 主键自增
 *         self.table_name: str = ""  # 同步的表名
 *         self.last_sync_time: int = 0  # 最后同步时间戳(毫秒)
 *         self.sync_status: str = ""     # 同步状态: pending/success/failed
 *         self.error_message: str = ""   # 错误信息(如果有)
 */
export class SyncRecord {
  // 主键
  id: number = 0
  
  // 同步的表名 (checkin/workout/weight/diary)
  tableName: string = ""
  
  // 最后同步时间戳（毫秒）
  lastSyncTime: number = 0
  
  // 同步状态枚举
  syncStatus: SyncStatus = SyncStatus.PENDING
  
  // 错误信息
  errorMessage: string = ""
  
  // 同步方向: upload(上传)/download(下载)
  syncDirection: SyncDirection = SyncDirection.UPLOAD
  
  constructor(tableName: string = "") {
    this.tableName = tableName
    this.lastSyncTime = Date.now()
  }
}

/**
 * 同步状态枚举
 */
export enum SyncStatus {
  PENDING = "pending",      // 待同步
  SYNCING = "syncing",      // 同步中
  SUCCESS = "success",      // 成功
  FAILED = "failed",        // 失败
  CONFLICT = "conflict"     // 冲突
}

/**
 * 同步方向枚举
 */
export enum SyncDirection {
  UPLOAD = "upload",        // 上传到云端
  DOWNLOAD = "download"     // 从云端下载
}

/**
 * 云端数据格式（统一格式）
 * 用于与华为 AGC 云数据库交互
 */
export class CloudData {
  // 数据唯一标识
  id: string = ""
  
  // 本地数据库ID
  localId: number = 0
  
  // 数据类型
  dataType: string = ""
  
  // JSON数据内容
  content: string = ""
  
  // 创建时间
  createdAt: number = 0
  
  // 更新时间
  updatedAt: number = 0
  
  // 版本号（用于冲突解决）
  version: number = 1
  
  // 删除标记（软删除）
  deleted: boolean = false
}

/**
 * 同步结果
 */
export class SyncResult {
  // 是否成功
  success: boolean = false
  
  // 同步数量
  syncedCount: number = 0
  
  // 冲突数量
  conflictCount: number = 0
  
  // 失败数量
  failedCount: number = 0
  
  // 错误信息
  errorMessage: string = ""
  
  // 同步时间
  syncTime: number = Date.now()
}
