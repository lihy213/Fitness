/**
 * WeightRecord - 体重记录实体类
 *
 * Python 对比:
 * class WeightRecord:
 *     def __init__(self, id: int, date: str, weight: float,
 *                  body_fat: float, note: str, created_at: int):
 *         self.id = id
 *         self.date = date
 *         self.weight = weight  # 体重 kg
 *         self.body_fat = body_fat  # 体脂率 %
 *         self.note = note  # 备注
 *         self.created_at = created_at
 */
export class WeightRecord {
  id: number = 0;
  date: string = "";  // "YYYY-MM-DD"
  weight: number = 0;  // kg
  bodyFat: number = 0;  // % (可选)
  note: string = "";
  createdAt: number = 0;

  constructor(weight?: number) {
    if (weight) this.weight = weight;
    this.createdAt = Date.now();
  }
}

/**
 * 体重统计信息
 */
export class WeightStats {
  // 目标体重
  targetWeight: number = 70;

  // 当前体重
  currentWeight: number = 0;

  // 起始体重
  startWeight: number = 0;

  // 变化量
  change: number = 0;

  // BMI
  bmi: number = 0;

  // 达标天数
  onTrackDays: number = 0;

  // 平均每周变化
  weeklyChange: number = 0;
}

/**
 * 图表数据点
 */
export class ChartDataPoint {
  date: string = "";
  value: number = 0;
  label?: string;
}

/**
 * BMI 分类
 */
export enum BMICategory {
  UNDERWEIGHT = "偏瘦",
  NORMAL = "正常",
  OVERWEIGHT = "偏胖",
  OBESE = "肥胖"
}

/**
 * BMI 工具函数
 *
 * Python:
 * def calculate_bmi(weight: float, height: float) -> float:
 *     return weight / (height / 100) ** 2
 *
 * def get_bmi_category(bmi: float) -> str:
 *     if bmi < 18.5:
 *         return "偏瘦"
 *     elif bmi < 24:
 *         return "正常"
 *     elif bmi < 28:
 *         return "偏胖"
 *     else:
 *         return "肥胖"
 */
export function calculateBMI(weight: number, heightMeters: number): number {
  if (heightMeters <= 0) return 0;
  return weight / (heightMeters * heightMeters);
}

export function getBMICategory(bmi: number): BMICategory {
  if (bmi < 18.5) return BMICategory.UNDERWEIGHT;
  if (bmi < 24) return BMICategory.NORMAL;
  if (bmi < 28) return BMICategory.OVERWEIGHT;
  return BMICategory.OBESE;
}

export function getBMIColor(category: BMICategory): string {
  const colors: Record<BMICategory, string> = {
    [BMICategory.UNDERWEIGHT]: '#FFC107',  // 黄色
    [BMICategory.NORMAL]: '#4CAF50',        // 绿色
    [BMICategory.OVERWEIGHT]: '#FF9800',    // 橙色
    [BMICategory.OBESE]: '#F44336'          // 红色
  };
  return colors[category];
}
