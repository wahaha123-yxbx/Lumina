import { StarDustRecord, StarDustRuleItem, getStarDustRules, REWARD_AMOUNTS, REWARD_MESSAGES } from '../model/StarDustModel'
import { CurrentUser } from '../model/UserModel'
import { PostApi } from '../common/PostApi'
import { Colors, C, FontSize, Spacing, BorderRadius } from '../common/Constants'
import { router } from '@kit.ArkUI'

class RewardParams {
  postId: string = ''
  postTitle: string = ''
  authorName: string = ''
}

/**
 * 星尘打赏页面 - 完整的打赏流程
 */
@Entry
@Component
struct StarDustRewardPage {
  @State selectedAmount: number = 10
  @State rewardMessage: string = ''
  @State customMessage: string = ''
  @State showSuccess: boolean = false
  @State currentStep: number = 0 // 0=选择金额 1=确认打赏

  // 从路由获取目标帖子信息
  private targetPostTitle: string = '帖子标题'
  private targetAuthor: string = '作者'
  private targetPostId: string = ''

  aboutToAppear(): void {
    const params = router.getParams() as RewardParams
    if (params) {
      if (params.postTitle) { this.targetPostTitle = params.postTitle }
      if (params.authorName) { this.targetAuthor = params.authorName }
      if (params.postId) { this.targetPostId = params.postId }
    }
  }

  async doReward(): Promise<void> {
    if (CurrentUser.starDustBalance < this.selectedAmount) return

    const msg = this.customMessage || this.rewardMessage || '支持优质内容'
    const result = await PostApi.rewardPost(this.targetPostId, CurrentUser.id, this.selectedAmount, msg)
    if (result) {
      CurrentUser.starDustBalance -= this.selectedAmount
      this.showSuccess = true
      setTimeout(() => {
        router.back()
      }, 2000)
    }
  }

  @Builder HeaderBuilder() {
    Row() {
      Text('←')
        .width(24)
        .height(24)
        .fontColor(Colors.textPrimary)
        .onClick(() => { router.back() })

      Text('星尘打赏')
        .fontSize(FontSize.lg)
        .fontColor(Colors.textPrimary)
        .fontWeight(FontWeight.Medium)
        .margin({ left: Spacing.md })
      Blank()
    }
    .width('100%')
    .height(48)
    .padding({ left: Spacing.lg, right: Spacing.lg })
    .backgroundColor(C.bg)
  }

  build() {
    Column() {
      this.HeaderBuilder()

      if (this.showSuccess) {
        // 打赏成功动画
        Column() {
          Text('✨')
            .fontSize(80)
            .transition({ type: TransitionType.Insert, opacity: 0, scale: { x: 0.5, y: 0.5 } })

          Text('打赏成功！')
            .fontSize(FontSize.xxl)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.stardustGold)
            .margin({ top: Spacing.md })

          Text(`你向 ${this.targetAuthor} 打赏了 ${this.selectedAmount} 星尘`)
            .fontSize(FontSize.body)
            .fontColor(Colors.textSecondary)
            .margin({ top: Spacing.sm })

          Text('感谢你对优质内容的支持 💫')
            .fontSize(FontSize.sm)
            .fontColor(Colors.textHint)
            .margin({ top: Spacing.xs })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            // 打赏目标
            Column() {
              Text('打赏帖子')
                .fontSize(FontSize.xs)
                .fontColor(Colors.textHint)
              Text(this.targetPostTitle)
                .fontSize(FontSize.title)
                .fontColor(Colors.textPrimary)
                .fontWeight(FontWeight.Bold)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({ top: Spacing.xs })
              Text(`作者：${this.targetAuthor}`)
                .fontSize(FontSize.xs)
                .fontColor(Colors.textHint)
                .margin({ top: 2 })
            }
            .width('100%')
            .padding(Spacing.lg)
            .backgroundColor(Colors.bgCard)
            .borderRadius(BorderRadius.lg)
            .margin({ left: Spacing.lg, right: Spacing.lg, top: Spacing.lg })

            // 余额
            Row() {
              Text('✨')
                .fontSize(FontSize.xl)
              Text(`当前余额：${CurrentUser.starDustBalance} 星尘`)
                .fontSize(FontSize.body)
                .fontColor(Colors.stardustGold)
                .margin({ left: Spacing.sm })
            }
            .width('100%')
            .padding({ left: Spacing.lg, top: Spacing.lg })

            // 金额选择
            Text('选择打赏金额')
              .fontSize(FontSize.title)
              .fontColor(Colors.textPrimary)
              .fontWeight(FontWeight.Bold)
              .width('100%')
              .padding({ left: Spacing.lg, top: Spacing.xl })

            Grid() {
              ForEach(REWARD_AMOUNTS, (amount: number) => {
                GridItem() {
                  Column() {
                    Text(`✨${amount}`)
                      .fontSize(FontSize.lg)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(this.selectedAmount === amount ? Colors.stardustGold : Colors.textPrimary)
                    Text('星尘')
                      .fontSize(10)
                      .fontColor(this.selectedAmount === amount ? Colors.stardustGold : Colors.textHint)
                  }
                  .width('100%')
                  .height(64)
                  .justifyContent(FlexAlign.Center)
                  .borderRadius(BorderRadius.md)
                  .backgroundColor(this.selectedAmount === amount ?
                    Colors.stardustGold + '20' : Colors.bgInput)
                  .border({ width: this.selectedAmount === amount ? 2 : 0, color: Colors.stardustGold })
                  .onClick(() => { this.selectedAmount = amount })
                }
              })
            }
            .columnsTemplate('1fr 1fr 1fr')
            .rowsGap(Spacing.sm)
            .columnsGap(Spacing.sm)
            .width('100%')
            .padding({ left: Spacing.lg, right: Spacing.lg, top: Spacing.md })

            // 留言
            Text('打赏留言')
              .fontSize(FontSize.title)
              .fontColor(Colors.textPrimary)
              .fontWeight(FontWeight.Bold)
              .width('100%')
              .padding({ left: Spacing.lg, top: Spacing.xl })

            Grid() {
              ForEach(REWARD_MESSAGES, (msg: string) => {
                GridItem() {
                  Text(msg)
                    .fontSize(FontSize.sm)
                    .fontColor(this.rewardMessage === msg ? Colors.primary : Colors.textSecondary)
                    .width('100%')
                    .padding({ left: Spacing.md, right: Spacing.md, top: Spacing.sm, bottom: Spacing.sm })
                    .borderRadius(BorderRadius.sm)
                    .backgroundColor(this.rewardMessage === msg ? Colors.primary + '18' : Colors.bgInput)
                    .textAlign(TextAlign.Center)
                    .onClick(() => { this.rewardMessage = msg })
                }
              })
            }
            .columnsTemplate('1fr 1fr')
            .rowsGap(Spacing.sm)
            .columnsGap(Spacing.sm)
            .width('100%')
            .padding({ left: Spacing.lg, right: Spacing.lg, top: Spacing.md })

            // 自定义留言
            TextInput({ placeholder: '或输入自定义留言...', text: this.customMessage })
              .placeholderColor(Colors.textHint)
              .fontSize(FontSize.body)
              .fontColor(Colors.textPrimary)
              .backgroundColor(Colors.bgInput)
              .borderRadius(BorderRadius.md)
              .height(44)
              .width('100%')
              .padding({ left: Spacing.md, right: Spacing.md })
              .margin({ left: Spacing.lg, right: Spacing.lg, top: Spacing.md })
              .onChange((value: string) => { this.customMessage = value })

            // 打赏按钮
            Button(`确认打赏 ✨${this.selectedAmount}`)
              .fontSize(FontSize.lg)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .backgroundColor(
                CurrentUser.starDustBalance >= this.selectedAmount ?
                Colors.stardustGold : Colors.textHint
              )
              .borderRadius(BorderRadius.md)
              .width('100%')
              .height(50)
              .margin({ left: Spacing.lg, right: Spacing.lg, top: Spacing.xxl })
              .onClick(() => { this.doReward() })

            if (CurrentUser.starDustBalance < this.selectedAmount) {
              Text('⚠️ 星尘余额不足，可通过每日登录、发布帖子获取星尘')
                .fontSize(FontSize.xs)
                .fontColor(Colors.likeRed)
                .padding({ left: Spacing.lg, right: Spacing.lg, top: Spacing.sm })
                .width('100%')
            }

            // 星尘规则
            Column() {
              Text('💡 星尘获取方式')
                .fontSize(FontSize.title)
                .fontColor(Colors.textPrimary)
                .fontWeight(FontWeight.Bold)
                .width('100%')
                .margin({ bottom: Spacing.md })

              ForEach(getStarDustRules(), (item: StarDustRuleItem) => {
                Row() {
                  Text('✦')
                    .fontSize(FontSize.sm)
                    .fontColor(Colors.stardustGold)
                  Text(item.desc)
                    .fontSize(FontSize.body)
                    .fontColor(Colors.textSecondary)
                    .margin({ left: Spacing.sm })
                  Blank()
                  Text('+' + item.amount.toString())
                    .fontSize(FontSize.body)
                    .fontColor(Colors.stardustGold)
                    .fontWeight(FontWeight.Bold)
                }
                .width('100%')
                .padding({ top: Spacing.xs, bottom: Spacing.xs })
              })
            }
            .width('100%')
            .padding(Spacing.lg)
            .backgroundColor(Colors.bgCard)
            .borderRadius(BorderRadius.lg)
            .margin({ left: Spacing.lg, right: Spacing.lg, top: Spacing.xl })

            Blank().height(Spacing.xxl)
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(C.bg)
  }
}
