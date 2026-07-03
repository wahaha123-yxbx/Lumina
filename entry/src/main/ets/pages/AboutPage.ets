import { C, FontSize, Spacing, BorderRadius } from '../common/Constants'
import { router } from '@kit.ArkUI'

/**
 * 关于 Lumina
 */
@Entry
@Component
struct AboutPage {
  @Builder InfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(FontSize.body)
        .fontColor(C.textSecondary)
      Blank()
      Text(value)
        .fontSize(FontSize.body)
        .fontColor(C.textPrimary)
    }
    .width('100%')
    .padding({ top: Spacing.sm, bottom: Spacing.sm })
  }

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(24)
          .fontColor(C.textPrimary)
          .onClick(() => { router.back() })
        Text('关于 Lumina')
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

      Column() {
        // Logo
        Column() {
          Image($r('app.media.app_icon'))
            .width(80)
            .height(80)
            .borderRadius(20)

          Text('Lumina')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(C.textPrimary)
            .margin({ top: Spacing.md })

          Text('以星尘之力，连接每一个有趣的灵魂')
            .fontSize(FontSize.sm)
            .fontColor(C.textHint)
            .margin({ top: Spacing.xs })

          Text('v1.0.0')
            .fontSize(FontSize.xs)
            .fontColor(C.textHint)
            .margin({ top: Spacing.sm })
        }
        .width('100%')
        .padding({ top: Spacing.xxl, bottom: Spacing.xl })
        .alignItems(HorizontalAlign.Center)

        // 信息
        this.InfoRow('开发团队', 'LuminaTeam')
        Divider().color(C.divider).strokeWidth(0.5)
        this.InfoRow('技术框架', 'HarmonyOS ArkTS')
        Divider().color(C.divider).strokeWidth(0.5)
        this.InfoRow('后端', 'Node.js + Express')
        Divider().color(C.divider).strokeWidth(0.5)
        this.InfoRow('定位', '校园论坛 · 星尘社区')

        Text('Made with ✨ for every student')
          .fontSize(FontSize.xs)
          .fontColor(C.textHint)
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: Spacing.xxl })
      }
      .width('100%')
      .backgroundColor(C.bgCard)
      .borderRadius(BorderRadius.lg)
      .padding(Spacing.lg)
      .margin({ top: Spacing.md, left: Spacing.md, right: Spacing.md })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(C.bg)
  }
}
