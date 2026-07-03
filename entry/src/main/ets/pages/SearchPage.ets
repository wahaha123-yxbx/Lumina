import { PostModel } from '../model/PostModel'
import { PostApi } from '../common/PostApi'
import { Colors, C, FontSize, Spacing, BorderRadius } from '../common/Constants'
import { PostCard } from '../components/PostCard'
import { router } from '@kit.ArkUI'

/**
 * 搜索页面
 */
@Entry
@Component
struct SearchPage {
  @State searchText: string = ''
  @State searchResults: PostModel[] = []
  @State hasSearched: boolean = false
  @State hotSearchWords: string[] = [
    '人类简史', '量子计算', '康德', '算法', '职业规划', 'AI绘画', '内卷', '分布式系统'
  ]

  async doSearch(): Promise<void> {
    if (this.searchText.trim().length === 0) return
    const data = await PostApi.search(this.searchText.trim())
    this.searchResults = data
    this.hasSearched = true
  }

  @Builder HeaderBuilder() {
    Row() {
      Text('←')
        .width(24)
        .height(24)
        .fontColor(Colors.textPrimary)
        .onClick(() => { router.back() })

      // 搜索框
      Search({ placeholder: '搜索帖子、标签、内容...', value: this.searchText })
        .placeholderColor(Colors.textHint)
        .fontColor(Colors.textPrimary)
        .backgroundColor(Colors.bgInput)
        .borderRadius(BorderRadius.full)
        .height(38)
        .layoutWeight(1)
        .margin({ left: Spacing.md, right: Spacing.md })
        .onChange((value: string) => { this.searchText = value })
        .onSubmit(() => { this.doSearch() })

      Text('搜索')
        .fontSize(FontSize.body)
        .fontColor(Colors.primary)
        .fontWeight(FontWeight.Medium)
        .onClick(() => { this.doSearch() })
    }
    .width('100%')
    .height(48)
    .padding({ left: Spacing.lg, right: Spacing.lg })
    .backgroundColor(C.bg)
  }

  @Builder HotSearchBuilder() {
    Column() {
      Text('🔥 热门搜索')
        .fontSize(FontSize.title)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.textPrimary)
        .width('100%')
        .margin({ bottom: Spacing.md })

      Row() {
        ForEach(this.hotSearchWords, (word: string, index: number) => {
          Text(word)
            .fontSize(FontSize.body)
            .fontColor(index < 3 ? Colors.likeRed : Colors.textSecondary)
            .padding({ left: Spacing.md, right: Spacing.md, top: Spacing.sm, bottom: Spacing.sm })
            .borderRadius(BorderRadius.full)
            .backgroundColor(Colors.bgInput)
            .margin({ right: Spacing.sm, bottom: Spacing.sm })
            .onClick(() => {
              this.searchText = word
              this.doSearch()
            })
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.lg)
  }

  @Builder SearchResultBuilder() {
    Column() {
      Row() {
        Text(`找到 ${this.searchResults.length} 个结果`)
          .fontSize(FontSize.body)
          .fontColor(Colors.textSecondary)
        Blank()
      }
      .width('100%')
      .padding({ left: Spacing.lg, right: Spacing.lg, top: Spacing.md, bottom: Spacing.sm })

      if (this.searchResults.length === 0) {
        Column() {
          Text('🔍')
            .fontSize(48)
            .margin({ top: Spacing.xxl, bottom: Spacing.md })
          Text('没有找到相关内容')
            .fontSize(FontSize.body)
            .fontColor(Colors.textHint)
          Text('换个关键词试试吧~')
            .fontSize(FontSize.sm)
            .fontColor(Colors.textHint)
            .margin({ top: Spacing.xs })
        }
        .width('100%')
      } else {
        List() {
          ForEach(this.searchResults, (post: PostModel) => {
            ListItem() {
              PostCard({ post: post })
            }
            .margin({ bottom: Spacing.sm, left: Spacing.md, right: Spacing.md })
          })
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
  }

  build() {
    Column() {
      this.HeaderBuilder()

      if (this.hasSearched) {
        this.SearchResultBuilder()
      } else {
        this.HotSearchBuilder()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(C.bg)
  }
}
