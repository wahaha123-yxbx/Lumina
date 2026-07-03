import { PostModel } from '../model/PostModel'
import { PostApi } from '../common/PostApi'
import { PostCard } from '../components/PostCard'
import { Colors, C, FontSize, Spacing, BorderRadius } from '../common/Constants'

/**
 * 热点页 - 热榜帖子排行
 */
@Component
export struct HotPage {
  @State hotPosts: PostModel[] = []
  @State refreshing: boolean = false
  @State selectedTimeRange: string = '今日'
  @StorageLink('feedNeedsRefresh') @Watch('onFeedRefresh') needsRefresh: boolean = false

  private timeRanges: string[] = ['今日', '本周', '本月', '全部']

  aboutToAppear(): void {
    this.loadHotPosts()
  }

  onFeedRefresh(): void {
    if (this.needsRefresh) {
      this.loadHotPosts()
      AppStorage.setOrCreate('feedNeedsRefresh', false)
    }
  }

  async loadHotPosts(): Promise<void> {
    const data = await PostApi.getHotPosts()
    this.hotPosts = data
    this.refreshing = false
  }

  @Builder TimeFilterBuilder() {
    Row({ space: Spacing.md }) {
      ForEach(this.timeRanges, (range: string) => {
        Text(range)
          .fontSize(FontSize.sm)
          .fontColor(this.selectedTimeRange === range ? Colors.primary : Colors.textSecondary)
          .fontWeight(this.selectedTimeRange === range ? FontWeight.Bold : FontWeight.Normal)
          .padding({ left: Spacing.lg, right: Spacing.lg, top: Spacing.sm, bottom: Spacing.sm })
          .border({
            width: this.selectedTimeRange === range ? 1.5 : 0,
            color: Colors.primary,
            radius: BorderRadius.full,
          })
          .backgroundColor(this.selectedTimeRange === range ? Colors.primary + '20' : Colors.bgInput)
          .onClick(() => {
            this.selectedTimeRange = range
            this.loadHotPosts()
          })
      })
    }
    .width('100%')
    .padding({ left: Spacing.lg, right: Spacing.lg, top: Spacing.md, bottom: Spacing.sm })
  }

  @Builder HotRankBadge(rank: number) {
    Text(rank.toString())
      .fontSize(FontSize.xs)
      .fontWeight(FontWeight.Bold)
      .fontColor(Color.White)
      .width(22)
      .height(22)
      .borderRadius(6)
      .textAlign(TextAlign.Center)
      .backgroundColor(
        rank === 1 ? '#FF6B6B' :
        rank === 2 ? '#FFA94D' :
        rank === 3 ? '#FFD43B' : Colors.textHint
      )
  }

  build() {
    Column() {
      // 热榜标题区
      Row() {
        Text('🔥')
          .fontSize(FontSize.xl)
        Text('热榜')
          .fontSize(FontSize.xl)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.textPrimary)
          .margin({ left: Spacing.xs })

        Blank()

        Text('热门帖子 · 实时更新')
          .fontSize(FontSize.xs)
          .fontColor(Colors.textHint)
      }
      .width('100%')
      .padding({ left: Spacing.lg, right: Spacing.lg, top: Spacing.md, bottom: Spacing.xs })

      // 时间筛选
      this.TimeFilterBuilder()

      // 热榜列表
      Refresh({ refreshing: $$this.refreshing }) {
        List() {
          ForEach(this.hotPosts, (post: PostModel, index: number) => {
            ListItem() {
              Row() {
                // 排名徽章
                Column() {
                  this.HotRankBadge(index + 1)
                }
                .width(32)
                .alignItems(HorizontalAlign.Center)

                // 帖子卡片
                PostCard({ post: post })
                  .layoutWeight(1)
              }
              .width('100%')
              .alignItems(VerticalAlign.Top)
            }
            .margin({ bottom: Spacing.sm })
          }, (post: PostModel) => post.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: Spacing.md, right: Spacing.md, top: Spacing.sm })
        .edgeEffect(EdgeEffect.Spring)
      }
      .onRefreshing(() => {
        this.refreshing = true
        this.loadHotPosts()
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(C.bg)
  }
}
