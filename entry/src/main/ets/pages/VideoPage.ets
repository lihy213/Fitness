import router from '@ohos.router';
import { VideoService } from '../services/VideoService';
import { ExerciseVideo, DIFICULTY_LABELS } from '../database/entities/ExerciseVideo';

/**
 * VideoPage - 动作教学视频页面
 *
 * 功能：
 * - 分类浏览动作库
 * - 搜索动作
 * - 查看动作详情 + 教学视频/GIF
 * - 难度筛选
 */
@Entry
@Component
struct VideoPage {
  @State videos: ExerciseVideo[] = [];
  @State categories: string[] = [];
  @State selectedCategory: string = '全部';
  @State searchKeyword: string = '';
  @State selectedDifficulty: number = 0;  // 0=全部

  private videoService: VideoService = new VideoService();

  aboutToAppear() {
    this.categories = this.videoService.getCategories();
    this.loadVideos();
  }

  /**
   * 加载视频列表（按筛选条件）
   */
  loadVideos(): void {
    let result = this.videoService.getAllVideos();

    // 按分类筛选
    if (this.selectedCategory !== '全部') {
      result = this.videoService.getVideosByCategory(this.selectedCategory);
    }

    // 按难度筛选
    if (this.selectedDifficulty > 0) {
      result = result.filter(v => v.difficulty === this.selectedDifficulty);
    }

    // 按关键词搜索
    if (this.searchKeyword.trim()) {
      const lower = this.searchKeyword.toLowerCase();
      result = result.filter(v =>
        v.exerciseName.toLowerCase().includes(lower) ||
        v.description.toLowerCase().includes(lower)
      );
    }

    this.videos = result;
  }

  build() {
    Column() {
      // 顶部导航
      this.NavigationBar()

      // 搜索框
      this.SearchBar()

      // 分类选择
      this.CategoryTabs()

      // 难度筛选
      this.DifficultyFilter()

      // 视频列表
      this.VideoList()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  NavigationBar() {
    Row() {
      Text('🎬 动作教学')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      Blank()

      Row({ space: 20 }) {
        Text('🏠').fontSize(24).onClick(() => router.back())
        Text('💪').fontSize(24).onClick(() => router.pushUrl({ url: 'pages/WorkoutPage' }))
        Text('⚖️').fontSize(24).onClick(() => router.pushUrl({ url: 'pages/WeightPage' }))
        Text('📝').fontSize(24).onClick(() => router.pushUrl({ url: 'pages/DiaryPage' }))
        Text('👤').fontSize(24).onClick(() => router.pushUrl({ url: 'pages/ProfilePage' }))
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
  }

  @Builder
  SearchBar() {
    TextInput({ placeholder: '🔍 搜索动作...', text: this.searchKeyword })
      .width('100%')
      .height(40)
      .backgroundColor('#FFFFFF')
      .borderRadius(20)
      .padding({ left: 16, right: 16 })
      .margin({ bottom: 12 })
      .onChange((value: string) => {
        this.searchKeyword = value;
        this.loadVideos();
      })
  }

  @Builder
  CategoryTabs() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(this.categories, (cat: string) => {
          Text(cat)
            .fontSize(12)
            .padding({ horizontal: 16, vertical: 6 })
            .backgroundColor(this.selectedCategory === cat ? '#2196F3' : '#E0E0E0')
            .fontColor(this.selectedCategory === cat ? '#FFFFFF' : '#333333')
            .borderRadius(16)
            .onClick(() => {
              this.selectedCategory = cat;
              this.loadVideos();
            })
        })
      }
    }
    .scrollable(ScrollDirection.Horizontal)
    .width('100%')
    .margin({ bottom: 12 })
  }

  @Builder
  DifficultyFilter() {
    Row({ space: 8 }) {
      Text('难度:')
        .fontSize(12)
        .fontColor('#666666')

      Text('全部')
        .fontSize(11)
        .padding({ horizontal: 10, vertical: 4 })
        .backgroundColor(this.selectedDifficulty === 0 ? '#4CAF50' : '#E0E0E0')
        .fontColor(this.selectedDifficulty === 0 ? '#FFFFFF' : '#333333')
        .borderRadius(12)
        .onClick(() => { this.selectedDifficulty = 0; this.loadVideos(); })

      ForEach([1, 2, 3, 4, 5], (d: number) => {
        Text(DIFICULTY_LABELS[d])
          .fontSize(11)
          .padding({ horizontal: 10, vertical: 4 })
          .backgroundColor(this.selectedDifficulty === d ? '#4CAF50' : '#E0E0E0')
          .fontColor(this.selectedDifficulty === d ? '#FFFFFF' : '#333333')
          .borderRadius(12)
          .onClick(() => { this.selectedDifficulty = d; this.loadVideos(); })
      })
    }
    .margin({ bottom: 12 })
  }

  @Builder
  VideoList() {
    if (this.videos.length === 0) {
      Column() {
        Text('📭')
          .fontSize(48)
        Text('暂无匹配的动作')
          .fontSize(14)
          .fontColor('#999999')
      }
      .width('100%')
      .padding(40)
    } else {
      List() {
        ForEach(this.videos, (video: ExerciseVideo) => {
          ListItem() {
            this.VideoCard(video)
          }
        })
      }
      .layoutWeight(1)
    }
  }

  @Builder
  VideoCard(video: ExerciseVideo) {
    Row() {
      // 縮略图区域
      Stack() {
        // 实际项目中这里放 Image(video.thumbnailUrl)
        Column() {
          Text('🎬')
            .fontSize(32)
          Text('GIF')
            .fontSize(10)
            .fontColor('#FFFFFF')
            .backgroundColor('#FF5722')
            .padding({ horizontal: 6, vertical: 2 })
            .borderRadius(4)
        }
        .width(80)
        .height(80)
        .backgroundColor('#E0E0E0')
        .borderRadius(12)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        // 时长标签
        Text(`${Math.floor(video.duration / 60)}:${(video.duration % 60).toString().padStart(2, '0')}`)
          .fontSize(10)
          .fontColor('#FFFFFF')
          .backgroundColor('rgba(0,0,0,0.6)')
          .padding({ horizontal: 6, vertical: 2 })
          .borderRadius(4)
          .position({ x: 8, y: 56 })
      }
      .margin({ right: 12 })

      // 动作信息
      Column() {
        Text(video.exerciseName)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 4 })

        Row({ space: 8 }) {
          Text(video.category)
            .fontSize(10)
            .fontColor('#2196F3')
            .backgroundColor('#E3F2FD')
            .padding({ horizontal: 8, vertical: 2 })
            .borderRadius(8)

          Text(DIFICULTY_LABELS[video.difficulty])
            .fontSize(10)
            .fontColor('#FF9800')
            .backgroundColor('#FFF3E0')
            .padding({ horizontal: 8, vertical: 2 })
            .borderRadius(8)

          if (video.equipment !== '自重') {
            Text(video.equipment)
              .fontSize(10)
              .fontColor('#666666')
          }
        }
        .margin({ bottom: 8 })

        Text(video.description)
          .fontSize(11)
          .fontColor('#999999')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 8 })
    .onClick(() => this.showVideoDetail(video))
  }

  /**
   * 显示动作详情（底部弹窗）
   */
  showVideoDetail(video: ExerciseVideo): void {
    // TODO: 使用 @ohos.router 或自定义弹窗显示详情
    // 实际项目中：
    // 1. 使用 router.pushUrl 跳转到详情页
    // 2. 或使用 @ohos.arkui.@CustomDialog 显示底部弹窗
    console.log(`显示动作详情: ${video.exerciseName}`);
  }
}
