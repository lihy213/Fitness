/**
 * ExerciseVideo - 动作教学视频实体
 *
 * 参考主流健身 APP（Keep、Fit 等）
 * 每个动作可以关联一个教学视频/GIF
 */
export class ExerciseVideo {
  id: number = 0;
  exerciseId: number = 0;       // 关联动作 ID
  exerciseName: string = '';    // 动作名称（冗余）
  category: string = '';         // 部位分类
  videoUrl: string = '';          // 视频 URL（本地或网络）
  thumbnailUrl: string = '';      // 缩略图
  description: string = '';       // 动作要领说明
  tips: string[] = [];           // 注意事项
  equipment: string = '';        // 所需器材
  difficulty: number = 1;        // 难度 1-5
  duration: number = 0;          // 建议时长（秒）

  constructor(exerciseId?: number, exerciseName?: string) {
    if (exerciseId) this.exerciseId = exerciseId;
    if (exerciseName) this.exerciseName = exerciseName;
  }
}

/**
 * 难度标签
 */
export const DIFICULTY_LABELS: Record<number, string> = {
  1: '入门',
  2: '简单',
  3: '中等',
  4: '较难',
  5: '挑战'
};

/**
 * 预设动作视频库（本地资源）
 *
 * 实际项目中：
 * 1. 视频文件放在 resources/base/media/exercises/ 目录
 * 2. 使用 $r('app.media.exercise_xxx') 引用
 * 3. 或使用网络 URL（需申请网络权限）
 */
export const EXERCISE_VIDEOS: ExerciseVideo[] = [
  // 胸部
  {
    id: 1,
    exerciseId: 1,
    exerciseName: '杠铃卧推',
    category: '胸部',
    videoUrl: 'exercises/bench_press.mp4',
    thumbnailUrl: 'exercises/bench_press_thumb.jpg',
    description: '主练胸大肌。仰卧，双脚踩地，双手握杠铃，下放至胸口，推起。',
    tips: ['手腕保持中立', '下放时吸气，推起时呼气', '杠铃下放至乳头连线位置'],
    equipment: '杠铃、卧推架',
    difficulty: 3,
    duration: 45
  },
  {
    id: 2,
    exerciseId: 2,
    exerciseName: '哑铃卧推',
    category: '胸部',
    videoUrl: 'exercises/dumbbell_press.mp4',
    thumbnailUrl: 'exercises/dumbbell_press_thumb.jpg',
    description: '单侧手臂独立发力，更均衡地锻炼胸肌。',
    tips: ['哑铃下放时要控制速度', '肘部与身体呈 45°', '不要锁死肘关节'],
    equipment: '哑铃',
    difficulty: 2,
    duration: 40
  },

  // 背部
  {
    id: 3,
    exerciseId: 5,
    exerciseName: '引体向上',
    category: '背部',
    videoUrl: 'exercises/pull_up.mp4',
    thumbnailUrl: 'exercises/pull_up_thumb.jpg',
    description: '背部训练之王。利用自重，拉起身体至下巴过杠。',
    tips: ['启动前先沉肩', '不要摆动身体借力', '下放时充分拉伸背阔肌'],
    equipment: '单杠',
    difficulty: 4,
    duration: 30
  },

  // 腿部
  {
    id: 4,
    exerciseId: 9,
    exerciseName: '深蹲',
    category: '腿部',
    videoUrl: 'exercises/squat.mp4',
    thumbnailUrl: 'exercises/squat_thumb.jpg',
    description: '腿部训练基础动作。杠铃置于斜方肌，蹲至大腿平行地面。',
    tips: ['膝盖不要内扣', '保持背部挺直', '下放时吸气，站起时呼气'],
    equipment: '杠铃',
    difficulty: 3,
    duration: 50
  },

  // 肩部
  {
    id: 5,
    exerciseId: 13,
    exerciseName: '哑铃推肩',
    category: '肩部',
    videoUrl: 'exercises/shoulder_press.mp4',
    thumbnailUrl: 'exercises/shoulder_press_thumb.jpg',
    description: '坐姿或站姿，哑铃从肩部推至头顶上方。',
    tips: ['不要过度后仰', '核心收紧', '哑铃不要完全伸直锁死'],
    equipment: '哑铃',
    difficulty: 2,
    duration: 35
  },

  // 手臂
  {
    id: 6,
    exerciseId: 16,
    exerciseName: '杠铃弯举',
    category: '手臂',
    videoUrl: 'exercises/barbell_curl.mp4',
    thumbnailUrl: 'exercises/barbell_curl_thumb.jpg',
    description: '经典二头肌训练。双手握杠铃，弯曲肘部将杠铃举至胸前。',
    tips: ['上臂保持固定不动', '不要摆动身体借力', '下放时控制速度'],
    equipment: '杠铃',
    difficulty: 2,
    duration: 30
  },

  // 核心
  {
    id: 7,
    exerciseId: 20,
    exerciseName: '平板支撑',
    category: '核心',
    videoUrl: 'exercises/plank.mp4',
    thumbnailUrl: 'exercises/plank_thumb.jpg',
    description: '核心训练基础动作。前臂支撑，身体保持一条直线。',
    tips: ['不要塌腰', '臀部不要抬高', '保持均匀呼吸'],
    equipment: '自重',
    difficulty: 1,
    duration: 60
  }
];
