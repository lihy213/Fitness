/**
 * WorkoutSession - 训练会话实体类
 *
 * 一次训练（如"周一练胸"）对应一条记录
 * 包含多个训练组（WorkoutSet）
 *
 * Python 对比:
 * class WorkoutSession:
 *     def __init__(self, id: int, date: str, name: str, duration_minutes: int,
 *                  total_volume: float, created_at: int):
 *         self.id = id
 *         self.date = date
 *         self.name = name  # 如 "胸部训练"
 *         self.duration_minutes = duration_minutes
 *         self.total_volume = total_volume  # 总训练量 kg
 *         self.created_at = created_at
 *         self.sets: list[WorkoutSet] = []
 */
export class WorkoutSession {
  // 主键 ID
  id: number = 0;

  // 训练日期 "YYYY-MM-DD"
  date: string = "";

  // 训练名称/部位，如 "胸部训练"、"背部训练"
  name: string = "";

  // 训练时长（分钟）
  durationMinutes: number = 0;

  // 总训练量（kg），= sum(重量 * 组数)
  totalVolume: number = 0;

  // 创建时间戳（毫秒）
  createdAt: number = 0;

  // 关联的训练组
  sets: WorkoutSet[] = [];

  constructor(name?: string) {
    if (name) this.name = name;
    this.createdAt = Date.now();
  }
}

/**
 * WorkoutSet - 训练组实体类
 *
 * Python 对比:
 * class WorkoutSet:
 *     def __init__(self, session_id: int, exercise_id: int, set_number: int,
 *                  weight: float, reps: int):
 *         self.id = int
 *         self.session_id = session_id  # 外键关联 WorkoutSession
 *         self.exercise_id = exercise_id  # 动作ID
 *         self.exercise_name = str  # 动作名称（冗余存储，方便查询）
 *         self.set_number = set_number  # 第几组
 *         self.weight = weight  # 重量 kg
 *         self.reps = reps  # 次数
 */
export class WorkoutSet {
  // 主键 ID
  id: number = 0;

  // 关联的训练会话 ID
  sessionId: number = 0;

  // 动作 ID（关联 Exercise 表）
  exerciseId: number = 0;

  // 动作名称
  exerciseName: string = "";

  // 组序号（1, 2, 3...）
  setNumber: number = 1;

  // 重量（kg）
  weight: number = 0;

  // 次数/重复次数
  reps: number = 0;

  // 备注（如 "力竭"、"辅助"）
  note: string = "";

  // 创建时间
  createdAt: number = 0;

  constructor(sessionId?: number, exerciseId?: number) {
    if (sessionId) this.sessionId = sessionId;
    if (exerciseId) this.exerciseId = exerciseId;
    this.createdAt = Date.now();
  }
}

/**
 * Exercise - 训练动作库
 *
 * Python 对比:
 * class Exercise:
 *     def __init__(self, id: int, name: str, category: str, muscle_groups: str):
 *         self.id = id
 *         self.name = name  # "杠铃卧推"
 *         self.category = category  # "胸部"
 *         self.muscle_groups = muscle_groups  # "胸肌、三头肌"
 */
export class Exercise {
  id: number = 0;
  name: string = "";
  category: string = "";  // 部位分类
  muscleGroups: string = "";  // 锻炼肌群
  equipment: string = "";  // 所需器材
  description: string = "";  // 动作说明
}

/**
 * 常用动作模板（预设）
 */
export const EXERCISE_TEMPLATES: Exercise[] = [
  // 胸部
  { id: 1, name: "杠铃卧推", category: "胸部", muscleGroups: "胸肌、三头肌", equipment: "杠铃" },
  { id: 2, name: "哑铃卧推", category: "胸部", muscleGroups: "胸肌", equipment: "哑铃" },
  { id: 3, name: "蝴蝶机夹胸", category: "胸部", muscleGroups: "胸肌", equipment: "蝴蝶机" },
  { id: 4, name: "俯卧撑", category: "胸部", muscleGroups: "胸肌、三头肌", equipment: "自重" },

  // 背部
  { id: 5, name: "引体向上", category: "背部", muscleGroups: "背阔肌", equipment: "单杠" },
  { id: 6, name: "杠铃划船", category: "背部", muscleGroups: "背阔肌、菱形肌", equipment: "杠铃" },
  { id: 7, name: "坐姿划船", category: "背部", muscleGroups: "背阔肌", equipment: "龙门架" },
  { id: 8, name: "高位下拉", category: "背部", muscleGroups: "背阔肌", equipment: "器械" },

  // 腿部
  { id: 9, name: "深蹲", category: "腿部", muscleGroups: "股四头肌、臀大肌", equipment: "杠铃" },
  { id: 10, name: "硬拉", category: "腿部", muscleGroups: "臀大肌、腘绳肌", equipment: "杠铃" },
  { id: 11, name: "腿举", category: "腿部", muscleGroups: "股四头肌", equipment: "器械" },
  { id: 12, name: "腿弯举", category: "腿部", muscleGroups: "腘绳肌", equipment: "器械" },

  // 肩部
  { id: 13, name: "哑铃推肩", category: "肩部", muscleGroups: "三角肌", equipment: "哑铃" },
  { id: 14, name: "侧平举", category: "肩部", muscleGroups: "三角肌中束", equipment: "哑铃" },
  { id: 15, name: "面拉", category: "肩部", muscleGroups: "三角肌后束", equipment: "龙门架" },

  // 手臂
  { id: 16, name: "杠铃弯举", category: "手臂", muscleGroups: "肱二头肌", equipment: "杠铃" },
  { id: 17, name: "锤式弯举", category: "手臂", muscleGroups: "肱桡肌", equipment: "哑铃" },
  { id: 18, name: "绳索下压", category: "手臂", muscleGroups: "肱三头肌", equipment: "龙门架" },
  { id: 19, name: "仰卧臂屈伸", category: "手臂", muscleGroups: "肱三头肌", equipment: "杠铃" },

  // 核心
  { id: 20, name: "平板支撑", category: "核心", muscleGroups: "腹肌", equipment: "自重" },
  { id: 21, name: "卷腹", category: "核心", muscleGroups: "腹肌", equipment: "自重" },
  { id: 22, name: "俄罗斯转体", category: "核心", muscleGroups: "腹斜肌", equipment: "自重" },
];

/**
 * 训练部位选项
 */
export const WORKOUT_CATEGORIES = [
  { id: "chest", label: "胸部", icon: "💪" },
  { id: "back", label: "背部", icon: "🔙" },
  { id: "legs", label: "腿部", icon: "🦵" },
  { id: "shoulders", label: "肩部", icon: "🎯" },
  { id: "arms", label: "手臂", icon: "💪" },
  { id: "core", label: "核心", icon: "🎯" },
  { id: "cardio", label: "有氧", icon: "🏃" },
  { id: "other", label: "其他", icon: "📝" },
];
