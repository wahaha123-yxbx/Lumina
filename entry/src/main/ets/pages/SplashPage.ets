import { C, ThemeManager, Spacing, FontSize } from '../common/Constants'
import { router } from '@kit.ArkUI'

/**
 * Lumina 启动页
 * 首次打开时展示，2 秒后自动进入主页
 */
@Entry
@Component
struct SplashPage {
  @State opacityValue: number = 0
  @State scaleValue: number = 0.8
  @State tagOpacity: number = 0

  aboutToAppear(): void {
    // 初始化主题
    ThemeManager.init()

    // 入场动画：Logo 淡入 + 放大
    animateTo({ duration: 600, curve: Curve.EaseOut }, () => {
      this.opacityValue = 1
      this.scaleValue = 1
    })

    // 副标题延迟出现
    setTimeout(() => {
      animateTo({ duration: 400, curve: Curve.EaseOut }, () => {
        this.tagOpacity = 1
      })
    }, 400)

    // 2 秒后跳转主页
    setTimeout(() => {
      animateTo({ duration: 300, curve: Curve.EaseIn }, () => {
        this.opacityValue = 0
      })
      setTimeout(() => {
        router.replaceUrl({ url: 'pages/Index' })
      }, 300)
    }, 2000)
  }

  build() {
    Column() {
      Column() {
        // App 图标
        Image($r('app.media.app_icon'))
          .width(96)
          .height(96)
          .borderRadius(24)
          .scale({ x: this.scaleValue, y: this.scaleValue })
          .opacity(this.opacityValue)

        // App 名称
        Text('Lumina')
          .fontSize(42)
          .fontWeight(FontWeight.Bold)
          .fontColor(C.textPrimary)
          .fontFamily('sans-serif-medium')
          .margin({ top: Spacing.lg })
          .opacity(this.opacityValue)

        // 副标题
        Text('以知识为星尘，照亮彼此的视野')
          .fontSize(FontSize.title)
          .fontColor(C.textHint)
          .margin({ top: Spacing.md })
          .opacity(this.tagOpacity)

        // 底部标语
        Text('知识社区 · 让深度思考被看见')
          .fontSize(FontSize.sm)
          .fontColor(C.primaryLight)
          .margin({ top: Spacing.xxl })
          .opacity(this.tagOpacity)
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(C.bg)
  }
}
