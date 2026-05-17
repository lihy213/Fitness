import { DiaryRecord, DIARY_MOOD } from '../database/entities/DiaryRecord';
import { DiaryService } from '../services/DiaryService';

/**
 * DiaryViewModel - 感受日记页面 ViewModel
 */
@Observed
export class DiaryViewModel {
  @Trace todayDiary: DiaryRecord | null = null;
  @Trace monthDiaries: DiaryRecord[] = [];
  @Trace selectedMood: number = 3;
  @Trace content: string = '';
  @Trace photos: string[] = [];
  @Trace moodStats: Record<number, number> = {};
  @Trace isLoading: boolean = false;
  @Trace errorMessage: string = '';
  @Trace showTemplates: boolean = false;

  private service: DiaryService | null = null;

  init(service: DiaryService): void {
    this.service = service;
  }

  async loadData(): Promise<void> {
    if (!this.service) return;
    this.isLoading = true;
    try {
      const [diary, monthDiaries, stats] = await Promise.all([
        this.service.getTodayDiary(),
        this.service.getMonthDiaries(new Date().toISOString().slice(0, 7)),
        this.service.getMoodStats(new Date().toISOString().slice(0, 7))
      ]);
      this.todayDiary = diary;
      this.monthDiaries = monthDiaries;
      this.moodStats = stats;
      if (diary) {
        this.selectedMood = diary.mood;
        this.content = diary.content;
        this.photos = diary.photos;
      }
    } catch (err) {
      this.errorMessage = `${err}`;
    } finally {
      this.isLoading = false;
    }
  }

  async saveDiary(): Promise<boolean> {
    if (!this.service) return false;
    this.isLoading = true;
    try {
      await this.service.writeDiary(this.selectedMood, this.content, this.photos);
      await this.loadData();
      return true;
    } catch (err) {
      this.errorMessage = `${err}`;
      return false;
    } finally {
      this.isLoading = false;
    }
  }

  setMood(mood: number): void {
    if (mood >= 1 && mood <= 5) this.selectedMood = mood;
  }

  setContent(content: string): void {
    this.content = content;
  }

  get isWritten(): boolean {
    return this.todayDiary !== null;
  }

  get moodConfig() {
    return DIARY_MOOD[this.selectedMood] || DIARY_MOOD[3];
  }

  toggleTemplates(): void {
    this.showTemplates = !this.showTemplates;
  }

  useTemplate(template: string): void {
    this.content = template;
    this.showTemplates = false;
  }
}
