import { PostModel, getTagColor } from '../model/PostModel'
import { C, FontSize, Spacing, BorderRadius } from '../common/Constants'
import { CurrentUser } from '../model/UserModel'
import { PostApi } from '../common/PostApi'
import { router } from '@kit.ArkUI'

/**
 * 帖子卡片 — 简洁现代风格
 */
@Component
export struct PostCard {
  @Prop post: PostModel
  @State isLiked: boolean = false
  @State likeCount: number = 0
  @State starDustCount: number = 0

  aboutToAppear(): void {
    this.isLiked = this.post.isLiked
    this.likeCount = this.post.likeCount
    this.starDustCount = this.post.starDustCount
  }

  toggleLike(): void {
    if (!CurrentUser.id) return
    if (this.isLiked) {
      this.isLiked = false
      this.likeCount--
    } else {
      this.isLiked = true
      this.likeCount++
    }
    PostApi.toggleLike(this.post.id, CurrentUser.id)
    AppStorage.setOrCreate('feedNeedsRefresh', true)
  }

  quickReward(): void {
    if (!CurrentUser.id) return
    if (CurrentUser.starDustBalance < 1) return
    PostApi.rewardPost(this.post.id, CurrentUser.id, 1, '支持好内容')
    this.starDustCount++
    CurrentUser.starDustBalance -= 1
    AppStorage.setOrCreate('feedNeedsRefresh', true)
  }

  build() {
    Column() {
      // 标题行
      Text(this.post.title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(C.textPrimary)
        .lineHeight(22)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      // 内容摘要
      if (this.post.content) {
        Text(this.post.content)
          .fontSize(14)
          .fontColor(C.textSecondary)
          .lineHeight(20)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 8 })
          .width('100%')
      }

      // 底部信息行
      Row() {
        // 作者 + 标签
        Row() {
          Text(this.post.authorName)
            .fontSize(12)
            .fontColor(C.textHint)
            .maxLines(1)

          // 标签
          Text(this.post.tag)
            .fontSize(10)
            .fontColor(getTagColor(this.post.tag))
            .backgroundColor(getTagColor(this.post.tag) + '14')
            .borderRadius(4)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .margin({ left: 8 })
        }

        Blank()

        // 互动数据
        Row() {
          Row() {
            Text('♥')
              .fontSize(14)
              .fontColor(this.isLiked ? C.likeRed : C.textHint)
            Text(this.likeCount > 0 ? this.likeCount.toString() : '')
              .fontSize(12)
              .fontColor(C.textHint)
              .margin({ left: 3 })
          }
          .margin({ right: 14 })
          .onClick(() => { this.toggleLike() })

          Row() {
            Text('💬')
              .fontSize(13)
              .fontColor(C.textHint)
            Text(this.post.commentCount > 0 ? this.post.commentCount.toString() : '')
              .fontSize(12)
              .fontColor(C.textHint)
              .margin({ left: 3 })
          }
        }
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor(C.bgCard)
    .borderRadius(10)
    .onClick(() => {
      router.pushUrl({ url: 'pages/PostDetailPage', params: { postId: this.post.id } })
    })
  }
}
