import { PostModel, PostTags, getTagColor } from '../model/PostModel'
import { PostApi } from '../common/PostApi'
import { PostCard } from '../components/PostCard'
import { Colors, C, FontSize, Spacing, BorderRadius } from '../common/Constants'
import { CurrentUser } from '../model/UserModel'
import { UserApi } from '../common/UserApi'
import { ProjectApi } from '../common/ProjectApi'
import { MockProjectService } from '../common/MockData'
import { ProjectModel, getCategoryColor } from '../model/ProjectModel'
import { promptAction, router } from '@kit.ArkUI'

/**
 * 首页 - 帖子信息流
 */
@Component
export struct HomePage {
  @State posts: PostModel[] = []
  @State selectedTag: string = '全部'
  @State refreshing: boolean = false
  @State isLoading: boolean = false
  @StorageLink('feedNeedsRefresh') @Watch('onFeedRefresh') needsRefresh: boolean = false
  @State checkedInToday: boolean = false
  @State hotProjects: ProjectModel[] = []
  @State newProjects: ProjectModel[] = []
  private scroller: Scroller = new Scroller()

  aboutToAppear(): void {
    this.loadPosts()
    this.loadProjects()
  }

  onFeedRefresh(): void {
    if (this.needsRefresh) {
      this.loadPosts()
      AppStorage.setOrCreate('feedNeedsRefresh', false)
    }
  }

  async loadPosts(): Promise<void> {
    this.isLoading = true
    const data = await PostApi.getPosts(this.selectedTag === '全部' ? undefined : this.selectedTag)
    this.posts = data
    this.isLoading = false
    this.refreshing = false
  }

  @Builder TagFilterBuilder() {
    Row() {
      Scroll() {
        Row({ space: 8 }) {
          ForEach(PostTags, (tag: string) => {
            Text(tag)
              .fontSize(13)
              .fontColor(this.selectedTag === tag ? Color.White : C.textSecondary)
              .fontWeight(this.selectedTag === tag ? FontWeight.Medium : FontWeight.Normal)
              .padding({ left: 14, right: 14, top: 6, bottom: 6 })
              .borderRadius(16)
              .backgroundColor(this.selectedTag === tag ?
                C.primary : C.bgCard)
              .onClick(() => {
                this.selectedTag = tag
                this.loadPosts()
              })
          })
        }
        .padding({ left: 16, right: 16 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .backgroundColor(C.bg)
  }

  async doCheckIn(): Promise<void> {
    if (!CurrentUser.id) {
      promptAction.showToast({ message: '请先登录' })
      return
    }
    const balance = await UserApi.checkIn(CurrentUser.id)
    if (balance >= 0) {
      CurrentUser.starDustBalance = balance
      this.checkedInToday = true
      promptAction.showToast({ message: `签到成功！+5 星尘` })
      AppStorage.setOrCreate('loginVersion', Date.now())
    }
  }

  async loadProjects(): Promise<void> {
    // 先本地 Mock 数据
    this.hotProjects = MockProjectService.getHotProjects(3)
    this.newProjects = MockProjectService.getNewProjects(3)
    // 后台尝试刷新
    const discover = await ProjectApi.getDiscover()
    if (discover && discover.hotProjects.length > 0) {
      this.hotProjects = discover.hotProjects
      this.newProjects = discover.newProjects
    }
  }

  @Builder ProjectCard(item: ProjectModel) {
    Column() {
      Text(item.title)
        .fontSize(13).fontWeight(FontWeight.Bold).fontColor(C.textPrimary)
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(item.leaderName + ' · ' + item.getStatusLabel())
        .fontSize(11).fontColor(C.textHint).margin({ top: 2 })
      Text(item.members.length + '/' + item.maxMembers + '人 · ' + item.completedTaskCount + '/' + item.taskCount + '任务')
        .fontSize(10).fontColor(C.textHint).margin({ top: 2 })
    }
    .width(140).padding(Spacing.md).backgroundColor(C.bgCard)
    .borderRadius(BorderRadius.md).margin({ right: Spacing.sm })
    .onClick(() => {
      router.pushUrl({ url: 'pages/ProjectDetailPage', params: { projectId: item.id } })
    })
  }

  @Builder ProjectRecommendSection() {
    if (this.hotProjects.length > 0) {
      Column() {
        Row() {
          Text('🔥 推荐项目').fontSize(FontSize.title).fontWeight(FontWeight.Bold).fontColor(C.textPrimary)
          Blank()
          Text('查看更多 →').fontSize(FontSize.sm).fontColor(C.primary)
            .onClick(() => { router.pushUrl({ url: 'pages/ProjectSquarePage' }) })
        }
        .width('100%').padding({ left: Spacing.lg, right: Spacing.lg, bottom: Spacing.sm })

        Scroll() {
          Row({ space: 0 }) {
            ForEach(this.hotProjects, (item: ProjectModel) => {
              this.ProjectCard(item)
            }, (item: ProjectModel) => item.id)
          }
          .padding({ left: Spacing.lg, right: Spacing.lg })
        }
        .scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
        .width('100%')
      }
      .width('100%').padding({ top: Spacing.sm, bottom: Spacing.sm })
      .backgroundColor(C.bg)
    }
  }

  @Builder StarDustBanner() {
    Row() {
      Text('✦')
        .fontSize(22)
        .fontColor(C.stardustGold)

      Column() {
        Text(CurrentUser.id ? `${CurrentUser.starDustBalance} 星尘` : '星尘系统')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(C.textPrimary)
        Text(this.checkedInToday ? '今日已签到 ✓' : '签到获星尘 · 赞赏好内容')
          .fontSize(11)
          .fontColor(this.checkedInToday ? C.successGreen : C.textHint)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 10 })
      .layoutWeight(1)

      Button(this.checkedInToday ? '已签到' : '签到 +5')
        .fontSize(13)
        .fontColor(this.checkedInToday ? C.textHint : Color.White)
        .fontWeight(FontWeight.Medium)
        .backgroundColor(this.checkedInToday ? C.bgInput : C.stardustGold)
        .borderRadius(16)
        .height(32)
        .padding({ left: 14, right: 14 })
        .onClick(() => { if (!this.checkedInToday) this.doCheckIn() })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(C.bgCard)
    .borderRadius(10)
    .margin({ left: 16, right: 16, bottom: 8 })
  }

  build() {
    Column() {
      // 搜索栏
      Row() {
        Row() {
          Text('🔍').fontSize(16).margin({ right: 6 })
          Text('搜索帖子、标签...').fontSize(14).fontColor(C.textHint)
        }
        .width('100%').height(38).borderRadius(19).backgroundColor(C.bgCard)
        .padding({ left: 14, right: 14 }).alignItems(VerticalAlign.Center)
        .onClick(() => { router.pushUrl({ url: 'pages/SearchPage' }) })
      }
      .width('100%').padding({ left: 16, right: 16, bottom: 8 }).backgroundColor(C.bg)

      // 星尘签到横幅
      this.StarDustBanner()

      // 推荐项目（新增）
      this.ProjectRecommendSection()

      // 标签筛选栏
      this.TagFilterBuilder()

      // 帖子列表
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color(Colors.primary)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.posts.length === 0) {
        Column() {
          Text('📭')
            .fontSize(48)
            .margin({ bottom: Spacing.md })
          Text('还没有帖子哦~')
            .fontSize(FontSize.body)
            .fontColor(Colors.textHint)
          Text('点击右下角按钮发布第一条帖子吧！')
            .fontSize(FontSize.sm)
            .fontColor(Colors.textHint)
            .margin({ top: Spacing.xs })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Refresh({ refreshing: $$this.refreshing }) {
          List({ scroller: this.scroller }) {
            ForEach(this.posts, (post: PostModel) => {
              ListItem() {
                PostCard({ post: post })
              }
              .margin({ bottom: Spacing.sm })
            }, (post: PostModel) => post.id)
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: Spacing.md, right: Spacing.md, top: Spacing.sm })
          .divider({
            strokeWidth: 0.5,
            color: Colors.divider,
            startMargin: Spacing.md,
            endMargin: Spacing.md,
          })
          .edgeEffect(EdgeEffect.Spring)
          .onScrollIndex((first: number) => {
            // 滚动事件处理
          })
        }
        .onRefreshing(() => {
          this.refreshing = true
          this.loadPosts()
        })
        .refreshOffset(64)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(C.bg)
  }
}
