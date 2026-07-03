import { C, FontSize, Spacing, BorderRadius } from '../common/Constants'
import { router } from '@kit.ArkUI'

/**
 * 星尘规则说明页
 */
@Entry
@Component
struct StarDustRulesPage {
  @Builder RuleCard(title: string, icon: string, desc: string) {
    Row() {
      Text(icon)
        .fontSize(28)
        .width(48)
      Column() {
        Text(title)
          .fontSize(FontSize.title)
          .fontWeight(FontWeight.Bold)
          .fontColor(C.textPrimary)
        Text(desc)
          .fontSize(FontSize.sm)
          .fontColor(C.textHint)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: Spacing.md })
    }
    .width('100%')
    .padding({ top: Spacing.md, bottom: Spacing.md })
  }

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(24)
          .fontColor(C.textPrimary)
          .onClick(() => { router.back() })
        Text('星尘规则')
          .fontSize(FontSize.lg)
          .fontColor(C.textPrimary)
          .fontWeight(FontWeight.Medium)
          .margin({ left: Spacing.md })
        Blank()
      }
      .width('100%')
      .height(48)
      .padding({ left: Spacing.lg, right: Spacing.lg })
      .backgroundColor(C.bgCard)

      Scroll() {
        Column() {
          // 获取星尘
          Column() {
            Text('💰 如何获取星尘')
              .fontSize(FontSize.title)
              .fontWeight(FontWeight.Bold)
              .fontColor(C.textPrimary)
              .width('100%')

            this.RuleCard('每日签到', '✅', '每天签到获得 5 星尘')
            this.RuleCard('发布帖子', '📝', '每发布一篇帖子获得 2 星尘')
            this.RuleCard('优质内容', '⭐', '帖子被点赞、评论可获得星尘奖励')
            this.RuleCard('上榜奖励', '🔥', '登上热榜额外获得 10 星尘')
            this.RuleCard('被赞赏', '✨', '收到其他用户的星尘赞赏')
          }
          .width('100%')
          .backgroundColor(C.bgCard)
          .borderRadius(BorderRadius.lg)
          .padding(Spacing.lg)

          // 使用星尘
          Column() {
            Text('🎁 如何使用星尘')
              .fontSize(FontSize.title)
              .fontWeight(FontWeight.Bold)
              .fontColor(C.textPrimary)
              .width('100%')

            this.RuleCard('赞赏帖子', '💝', '用星尘赞赏你喜欢的内容，支持创作者')
            this.RuleCard('提升等级', '📈', '收到的星尘越多，用户等级越高')
            this.RuleCard('解锁功能', '🔓', '达到一定等级解锁特殊标识和功能')
          }
          .width('100%')
          .backgroundColor(C.bgCard)
          .borderRadius(BorderRadius.lg)
          .padding(Spacing.lg)
          .margin({ top: Spacing.md })

          // 等级说明
          Column() {
            Text('🌟 等级体系')
              .fontSize(FontSize.title)
              .fontWeight(FontWeight.Bold)
              .fontColor(C.textPrimary)
              .width('100%')

            this.RuleCard('Lv.1 星尘新芽', '🌱', '初始等级，累计收到 0-99 星尘')
            this.RuleCard('Lv.2 星尘学徒', '🔰', '累计收到 100-499 星尘')
            this.RuleCard('Lv.3 星辰旅者', '💫', '累计收到 500-1999 星尘')
            this.RuleCard('Lv.4 星光使者', '🌟', '累计收到 2000-4999 星尘')
            this.RuleCard('Lv.5 星尘大师', '👑', '累计收到 5000-9999 星尘')
            this.RuleCard('Lv.6 星海领主', '🌌', '累计收到 10000+ 星尘')
          }
          .width('100%')
          .backgroundColor(C.bgCard)
          .borderRadius(BorderRadius.lg)
          .padding(Spacing.lg)
          .margin({ top: Spacing.md })

          Blank().height(Spacing.xxl)
        }
        .width('100%')
        .padding({ left: Spacing.md, right: Spacing.md, top: Spacing.md })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(C.bg)
  }
}
