import { PostModel, getTagColor } from '../model/PostModel'
import { CommentModel } from '../model/CommentModel'
import { PostApi } from '../common/PostApi'
import { ApiClient } from '../common/ApiClient'
import { CurrentUser } from '../model/UserModel'
import { REWARD_AMOUNTS, REWARD_MESSAGES } from '../model/StarDustModel'
import { Colors, C, FontSize, Spacing, BorderRadius } from '../common/Constants'
import { router, promptAction } from '@kit.ArkUI'

class PostDetailParams {
  postId: string = ''
}

class FollowStatusResult {
  isFollowing: boolean = false
}

class FollowBody {
  userId: string = ''
}

/**
 * 帖子详情页
 */
@Entry
@Component
struct PostDetailPage {
  @State post: PostModel | undefined = undefined
  @State comments: CommentModel[] = []
  @State isLiked: boolean = false
  @State likeCount: number = 0
  @State isStarred: boolean = false
  @State starDustCount: number = 0
  @State isFollowing: boolean = false
  @State commentText: string = ''
  @State showRewardPanel: boolean = false
  @State selectedRewardAmount: number = 10
  @State rewardMessage: string = ''
  @State showRewardSuccess: boolean = false
  private postId: string = ''

  aboutToAppear(): void {
    // 从路由参数获取帖子ID
    const params = router.getParams() as PostDetailParams
    if (params && params.postId) {
      this.postId = params.postId
      this.loadPost()
      this.loadComments()
    }
  }

  async loadPost(): Promise<void> {
    const post = await PostApi.getPostById(this.postId)
    if (post) {
      this.post = post
      this.likeCount = post.likeCount
      this.starDustCount = post.starDustCount
      this.checkFollowStatus()
    }
  }

  async loadComments(): Promise<void> {
    const data = await PostApi.getComments(this.postId)
    this.comments = data
  }

  async checkFollowStatus(): Promise<void> {
    if (!CurrentUser.id || !this.post) return
    const res = await ApiClient.get<FollowStatusResult>(
      '/api/users/' + this.post.authorId + '/follow-status?userId=' + CurrentUser.id
    )
    if (res.code === 0 && res.data) {
      this.isFollowing = res.data.isFollowing
    }
  }

  async toggleFollow(): Promise<void> {
    if (!this.post) return
    const authorId = this.post.authorId
    const body = new FollowBody()
    body.userId = CurrentUser.id
    if (this.isFollowing) {
      const res = await ApiClient.post<FollowStatusResult>('/api/users/' + authorId + '/unfollow', body)
      if (res.code === 0) this.isFollowing = false
    } else {
      const res = await ApiClient.post<FollowStatusResult>('/api/users/' + authorId + '/follow', body)
      if (res.code === 0) this.isFollowing = true
    }
  }

  async sendComment(): Promise<void> {
    if (this.commentText.trim().length === 0) return
    if (!CurrentUser.id) {
      promptAction.showToast({ message: '请先登录' })
      return
    }
    const comment = await PostApi.addComment(this.postId, this.commentText.trim(), CurrentUser.id)
    if (comment) {
      this.comments = [comment, ...this.comments]
      if (this.post) {
        this.post.commentCount++
      }
    }
    this.commentText = ''
  }

  async toggleLike(): Promise<void> {
    if (!CurrentUser.id) {
      promptAction.showToast({ message: '请先登录' })
      return
    }
    const result = await PostApi.toggleLike(this.postId, CurrentUser.id)
    if (result) {
      this.isLiked = result.isLiked
      this.likeCount = result.likeCount
      // 标记列表需要刷新
      AppStorage.setOrCreate('feedNeedsRefresh', true)
    }
  }

  async doReward(): Promise<void> {
    if (!CurrentUser.id) {
      promptAction.showToast({ message: '请先登录' })
      return
    }
    if (CurrentUser.starDustBalance < this.selectedRewardAmount) {
      promptAction.showToast({ message: '星尘余额不足，快去签到赚取吧~' })
      return
    }
    const result = await PostApi.rewardPost(this.postId, CurrentUser.id, this.selectedRewardAmount, this.rewardMessage || '支持优质内容')
    if (result) {
      CurrentUser.starDustBalance -= this.selectedRewardAmount
      this.isStarred = true
      this.starDustCount += this.selectedRewardAmount
      this.showRewardPanel = false
      this.showRewardSuccess = true
      AppStorage.setOrCreate('feedNeedsRefresh', true)
      setTimeout(() => { this.showRewardSuccess = false }, 2000)
    } else {
      promptAction.showToast({ message: '打赏失败，请重试' })
    }
  }

  @Builder HeaderBuilder() {
    Row() {
      Text('←')
        .width(24)
        .height(24)
        .fontColor(Colors.textPrimary)
        .onClick(() => { router.back() })

      Text('帖子详情')
        .fontSize(FontSize.lg)
        .fontColor(Colors.textPrimary)
        .fontWeight(FontWeight.Medium)
        .margin({ left: Spacing.md })

      Blank()

      Text('⋯')
        .width(24)
        .height(24)
        .fontColor(Colors.textPrimary)
    }
    .width('100%')
    .height(48)
    .padding({ left: Spacing.lg, right: Spacing.lg })
    .backgroundColor(C.bg)
  }

  @Builder PostContentBuilder() {
    Column() {
      // 标题
      Text(this.post!.title)
        .fontSize(FontSize.xxl)
        .fontWeight(FontWeight.Bold)
        .fontColor(C.textPrimary)
        .lineHeight(28)
        .width('100%')

      // 作者信息
      Row() {
        Text('👤')
          .fontSize(FontSize.title)
        Column() {
          Text(this.post!.authorName)
            .fontSize(FontSize.body)
            .fontColor(Colors.textPrimary)
            .fontWeight(FontWeight.Medium)
          Text(this.post!.getFormattedTime() + ' · ' + this.post!.tag)
            .fontSize(FontSize.xs)
            .fontColor(Colors.textHint)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: Spacing.sm })

        Blank()

        // 关注按钮
        Button(this.isFollowing ? '已关注' : '+ 关注')
          .fontSize(FontSize.xs)
          .fontColor(this.isFollowing ? C.textHint : C.primary)
          .backgroundColor(this.isFollowing ? C.bgInput : C.primary + '12')
          .borderRadius(BorderRadius.sm)
          .height(28)
          .padding({ left: Spacing.md, right: Spacing.md })
          .onClick(() => {
            if (!CurrentUser.id) {
              promptAction.showToast({ message: '请先登录' })
              return
            }
            this.toggleFollow()
          })
      }
      .width('100%')
      .margin({ top: Spacing.md })

      // 正文
      Text(this.post!.content)
        .fontSize(FontSize.body)
        .fontColor(Colors.textSecondary)
        .lineHeight(22)
        .margin({ top: Spacing.lg })
        .width('100%')

      // 互动数据
      Row() {
        Text(`👁 ${PostModel.formatCount(this.post!.viewCount)} 浏览`)
          .fontSize(FontSize.xs)
          .fontColor(Colors.textHint)
        Text(` · ${this.post!.getFormattedTime()}`)
          .fontSize(FontSize.xs)
          .fontColor(Colors.textHint)
      }
      .margin({ top: Spacing.lg })
    }
    .width('100%')
    .padding(Spacing.lg)
    .backgroundColor(Colors.bgCard)
    .borderRadius(BorderRadius.lg)
  }

  @Builder InteractionBar() {
    Row() {
      // 点赞
      Row() {
        Text('♥')
          .width(20)
          .height(20)
          .fontColor(this.isLiked ? Colors.likeRed : Colors.textSecondary)
        Text(PostModel.formatCount(this.likeCount))
          .fontSize(FontSize.body)
          .fontColor(this.isLiked ? Colors.likeRed : Colors.textSecondary)
          .margin({ left: Spacing.xs })
      }
      .padding({ left: Spacing.lg, right: Spacing.lg, top: Spacing.sm, bottom: Spacing.sm })
      .borderRadius(BorderRadius.md)
      .backgroundColor(Colors.bgCard)
      .onClick(() => { this.toggleLike() })
      .layoutWeight(1)

      // 星尘打赏
      Row() {
        Text('✨')
          .fontSize(20)
        Text(this.isStarred ? '已打赏' : '打赏')
          .fontSize(FontSize.body)
          .fontColor(this.isStarred ? Colors.stardustGold : Colors.textSecondary)
          .margin({ left: Spacing.xs })
        Text(PostModel.formatCount(this.starDustCount))
          .fontSize(FontSize.xs)
          .fontColor(Colors.stardustGold)
          .margin({ left: Spacing.xs })
      }
      .padding({ left: Spacing.lg, right: Spacing.lg, top: Spacing.sm, bottom: Spacing.sm })
      .borderRadius(BorderRadius.md)
      .backgroundColor(this.isStarred ? Colors.stardustGold + '15' : Colors.bgCard)
      .border({ width: this.isStarred ? 1 : 0, color: Colors.stardustGold + '40' })
      .onClick(() => { this.showRewardPanel = true })
      .layoutWeight(1)

      // 评论
      Row() {
        Text('💬')
          .width(20)
          .height(20)
          .fontColor(Colors.textSecondary)
        Text(PostModel.formatCount(this.comments.length))
          .fontSize(FontSize.body)
          .fontColor(Colors.textSecondary)
          .margin({ left: Spacing.xs })
      }
      .padding({ left: Spacing.lg, right: Spacing.lg, top: Spacing.sm, bottom: Spacing.sm })
      .borderRadius(BorderRadius.md)
      .backgroundColor(Colors.bgCard)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: Spacing.lg, right: Spacing.lg })
    .margin({ top: Spacing.md })
  }

  @Builder CommentItemBuilder(comment: CommentModel) {
    Row() {
      // 头像
      Text('👤')
        .fontSize(18)
        .width(36)
        .height(36)
        .borderRadius(18)
        .backgroundColor(Colors.bgInput)
        .textAlign(TextAlign.Center)

      Column() {
        Row() {
          Text(comment.authorName)
            .fontSize(FontSize.sm)
            .fontColor(Colors.primaryLight)
            .fontWeight(FontWeight.Medium)
          Text(comment.getFormattedTime())
            .fontSize(FontSize.xs)
            .fontColor(Colors.textHint)
            .margin({ left: Spacing.sm })
        }

        Text(comment.content)
          .fontSize(FontSize.body)
          .fontColor(Colors.textPrimary)
          .margin({ top: Spacing.xs })
          .lineHeight(20)

        // 点赞和回复
        Row() {
          Row() {
            Text('♥')
              .width(14)
              .height(14)
              .fontColor(comment.isLiked ? Colors.likeRed : Colors.textHint)
            Text(comment.likeCount > 0 ? comment.likeCount.toString() : '赞')
              .fontSize(FontSize.xs)
              .fontColor(comment.isLiked ? Colors.likeRed : Colors.textHint)
              .margin({ left: 2 })
          }
          .onClick(() => {
            comment.isLiked = !comment.isLiked
            comment.likeCount += comment.isLiked ? 1 : -1
          })

          Text('回复')
            .fontSize(FontSize.xs)
            .fontColor(Colors.textHint)
            .margin({ left: Spacing.lg })
        }
        .margin({ top: Spacing.sm })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: Spacing.sm })
    }
    .width('100%')
    .padding({ top: Spacing.md, bottom: Spacing.md })
    .alignItems(VerticalAlign.Top)
  }

  @Builder CommentSection() {
    Column() {
      Text(`评论 (${this.comments.length})`)
        .fontSize(FontSize.title)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.textPrimary)
        .width('100%')
        .padding({ left: Spacing.lg })

      // 评论列表
      if (this.comments.length === 0) {
        Column() {
          Text('💬')
            .fontSize(36)
            .margin({ top: Spacing.xxl, bottom: Spacing.sm })
          Text('暂无评论，来抢沙发吧~')
            .fontSize(FontSize.body)
            .fontColor(Colors.textHint)
        }
        .width('100%')
        .padding({ top: Spacing.xxl, bottom: Spacing.xxl })
      } else {
        List() {
          ForEach(this.comments, (comment: CommentModel) => {
            ListItem() {
              this.CommentItemBuilder(comment)
            }
            .padding({ left: Spacing.lg, right: Spacing.lg })
          }, (comment: CommentModel) => comment.id)
        }
        .width('100%')
        .divider({
          strokeWidth: 0.5,
          color: Colors.divider,
          startMargin: Spacing.lg,
          endMargin: Spacing.lg,
        })
      }
    }
    .width('100%')
    .backgroundColor(Colors.bgCard)
    .borderRadius(BorderRadius.lg)
    .margin({ top: Spacing.md })
    .padding({ top: Spacing.lg, bottom: Spacing.lg })
  }

  @Builder CommentInputBar() {
    Row() {
      TextInput({ placeholder: '说点什么...', text: this.commentText })
        .placeholderColor(Colors.textHint)
        .placeholderFont({ size: FontSize.body })
        .fontSize(FontSize.body)
        .fontColor(Colors.textPrimary)
        .backgroundColor(Colors.bgInput)
        .borderRadius(BorderRadius.full)
        .height(40)
        .layoutWeight(1)
        .padding({ left: Spacing.lg, right: Spacing.lg })
        .onChange((value: string) => { this.commentText = value })

      Button('发送')
        .fontSize(FontSize.body)
        .fontColor(Color.White)
        .backgroundColor(Colors.primary)
        .borderRadius(BorderRadius.full)
        .height(40)
        .padding({ left: Spacing.lg, right: Spacing.lg })
        .margin({ left: Spacing.md })
        .onClick(() => { this.sendComment() })
    }
    .width('100%')
    .padding({ left: Spacing.lg, right: Spacing.lg, top: Spacing.sm, bottom: Spacing.sm })
    .backgroundColor(C.bg)
  }

  @Builder RewardPanel() {
    Column() {
      // 遮罩层可点击关闭
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.overlay)
    .onClick(() => { this.showRewardPanel = false })

    Column() {
      // 面板标题
      Row() {
        Text('✨ 星尘打赏')
          .fontSize(FontSize.xl)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.textPrimary)

        Blank()

        Text('✕')
          .width(22)
          .height(22)
          .fontColor(Colors.textSecondary)
          .onClick(() => { this.showRewardPanel = false })
      }
      .width('100%')

      Text(`当前星尘余额：${CurrentUser.starDustBalance}`)
        .fontSize(FontSize.body)
        .fontColor(Colors.stardustGold)
        .margin({ top: Spacing.md })

      // 打赏金额选择
      Text('选择打赏金额')
        .fontSize(FontSize.body)
        .fontColor(Colors.textSecondary)
        .margin({ top: Spacing.xl })

      Grid() {
        ForEach(REWARD_AMOUNTS, (amount: number) => {
          GridItem() {
            Column() {
              Text(`✨${amount}`)
                .fontSize(FontSize.title)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.selectedRewardAmount === amount ? Colors.stardustGold : Colors.textPrimary)
            }
            .width('100%')
            .height(48)
            .justifyContent(FlexAlign.Center)
            .borderRadius(BorderRadius.sm)
            .backgroundColor(this.selectedRewardAmount === amount ?
              Colors.stardustGold + '25' : Colors.bgInput)
            .border({ width: this.selectedRewardAmount === amount ? 2 : 0, color: Colors.stardustGold })
            .onClick(() => { this.selectedRewardAmount = amount })
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsGap(Spacing.sm)
      .columnsGap(Spacing.sm)
      .width('100%')
      .margin({ top: Spacing.md })

      // 打赏留言
      Text('打赏留言（选填）')
        .fontSize(FontSize.body)
        .fontColor(Colors.textSecondary)
        .margin({ top: Spacing.xl })

      Grid() {
        ForEach(REWARD_MESSAGES.slice(0, 4), (msg: string) => {
          GridItem() {
            Text(msg)
              .fontSize(FontSize.xs)
              .fontColor(this.rewardMessage === msg ? Colors.primary : Colors.textSecondary)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
              .padding({ left: Spacing.sm, right: Spacing.sm, top: Spacing.sm, bottom: Spacing.sm })
              .borderRadius(BorderRadius.sm)
              .backgroundColor(this.rewardMessage === msg ? Colors.primary + '20' : Colors.bgInput)
              .textAlign(TextAlign.Center)
              .onClick(() => { this.rewardMessage = msg })
          }
        })
      }
      .columnsTemplate('1fr 1fr')
      .rowsGap(Spacing.sm)
      .columnsGap(Spacing.sm)
      .width('100%')
      .margin({ top: Spacing.sm })

      // 确认打赏按钮
      Button(`确认打赏 ✨${this.selectedRewardAmount}`)
        .fontSize(FontSize.title)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .backgroundColor(
          CurrentUser.starDustBalance >= this.selectedRewardAmount ?
          Colors.stardustGold : Colors.textHint
        )
        .borderRadius(BorderRadius.md)
        .width('100%')
        .height(48)
        .margin({ top: Spacing.xl })
        .onClick(() => { this.doReward() })

      if (CurrentUser.starDustBalance < this.selectedRewardAmount) {
        Text('星尘余额不足，快去赚取星尘吧~')
          .fontSize(FontSize.xs)
          .fontColor(Colors.likeRed)
          .margin({ top: Spacing.xs })
      }
    }
    .width('100%')
    .padding({ left: Spacing.xl, right: Spacing.xl, top: Spacing.xl, bottom: Spacing.xxl })
    .backgroundColor(C.bg)
    .borderRadius({ topLeft: 20, topRight: 20 })
    .position({ x: 0, y: '100%' })
    .translate({ x: 0, y: this.showRewardPanel ? '-100%' : 0 })
    .animation({ duration: 300, curve: Curve.EaseOut })
  }

  build() {
    Stack() {
      Column() {
        // 顶部导航
        this.HeaderBuilder()

        if (this.post === undefined) {
          Column() {
            LoadingProgress()
              .width(40)
              .height(40)
              .color(Colors.primary)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          // 内容区
          Scroll() {
            Column() {
              // 帖子内容
              this.PostContentBuilder()

              // 互动栏
              this.InteractionBar()

              // 评论区
              this.CommentSection()

              // 底部安全区
              Blank().height(60)
            }
            .padding({ top: Spacing.sm })
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)

          // 底部评论输入框
          this.CommentInputBar()
        }
      }
      .width('100%')
      .height('100%')

      // 星尘打赏面板
      if (this.showRewardPanel) {
        Column() {
          Scroll() {
            Column() {
              Row() {
                Text('星尘打赏').fontSize(18).fontWeight(FontWeight.Bold).fontColor(C.textPrimary)
                Blank()
                Text('✕').fontSize(20).fontColor(C.textSecondary)
                  .onClick(() => { this.showRewardPanel = false })
              }.width('100%')

              Text(`余额：${CurrentUser.starDustBalance} 星尘`).fontSize(13).fontColor(C.stardustGold).margin({ top: 8 })

              Text('选择金额').fontSize(13).fontColor(C.textSecondary).margin({ top: 12 })
              Row() {
                ForEach(REWARD_AMOUNTS, (a: number) => {
                  Text(`✨${a}`).fontSize(14).fontWeight(FontWeight.Bold)
                    .fontColor(this.selectedRewardAmount === a ? C.stardustGold : C.textPrimary)
                    .height(40).layoutWeight(1).textAlign(TextAlign.Center).borderRadius(8)
                    .backgroundColor(this.selectedRewardAmount === a ? C.stardustGold + '20' : C.bgInput)
                    .border({ width: this.selectedRewardAmount === a ? 2 : 0, color: C.stardustGold })
                    .margin({ left: a === 1 ? 0 : 6 })
                    .onClick(() => { this.selectedRewardAmount = a })
                })
              }.width('100%').margin({ top: 6 })

              Text('留言').fontSize(13).fontColor(C.textSecondary).margin({ top: 12 })
              TextInput({ placeholder: '写句鼓励的话...', text: this.rewardMessage })
                .placeholderColor(C.textHint).fontSize(14).fontColor(C.textPrimary)
                .backgroundColor(C.bgInput).borderRadius(8).height(40).width('100%').margin({ top: 6 })
                .onChange((v: string) => { this.rewardMessage = v })

              Button(`确认打赏 ✨${this.selectedRewardAmount}`)
                .fontSize(16).fontColor(Color.White).fontWeight(FontWeight.Bold)
                .backgroundColor(C.stardustGold).borderRadius(20).width('100%').height(48).margin({ top: 16 })
                .onClick(() => { this.doReward() })
            }.width('100%')
          }.width('100%').constraintSize({ maxHeight: 400 }).scrollBar(BarState.Off)

          Button('取消').fontSize(14).fontColor(C.textHint).margin({ top: 10 })
            .onClick(() => { this.showRewardPanel = false })
        }
        .width('88%').padding(20).backgroundColor(C.bgCard).borderRadius(16)
        .position({ x: '6%', y: '15%' })
      }

      // 打赏成功动画
      if (this.showRewardSuccess) {
        Column() {
          Text('✨').fontSize(56).scale({ x: 1.2, y: 1.2 })
          Text('打赏成功！').fontSize(20).fontColor(C.stardustGold).fontWeight(FontWeight.Bold).margin({ top: 8 })
          Text(`-${this.selectedRewardAmount} 星尘`).fontSize(14).fontColor(C.textHint).margin({ top: 4 })
          Text('🌟').fontSize(20).margin({ top: 8 }).opacity(0.6)
        }
        .width(200).padding(32).backgroundColor(C.bgCard).borderRadius(20)
        .border({ width: 1, color: C.stardustGold + '40' })
        .shadow({ radius: 30, color: C.stardustGold + '30', offsetX: 0, offsetY: 0 })
        .position({ x: '25%', y: '35%' })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(C.bg)
  }
}
