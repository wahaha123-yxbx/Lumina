import { CurrentUser } from '../model/UserModel'
import { Colors, FontSize, Spacing, BorderRadius, ThemeMode, ThemeManager, C } from '../common/Constants'
import { ApiClient } from '../common/ApiClient'
import { router, promptAction } from '@kit.ArkUI'

/**
 * 设置页面
 */
@Entry
@Component
struct SettingsPage {
  @State darkMode: boolean = ThemeManager.isDark()
  @State notificationEnabled: boolean = true
  @State soundEnabled: boolean = true
  @State showClearCache: boolean = false

  @Builder HeaderBuilder() {
    Row() {
      Text('←')
        .width(24)
        .height(24)
        .fontColor(Colors.textPrimary)
        .onClick(() => { router.back() })

      Text('设置')
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

  @Builder SectionTitle(title: string) {
    Text(title)
      .fontSize(FontSize.xs)
      .fontColor(Colors.textHint)
      .fontWeight(FontWeight.Bold)
      .width('100%')
      .padding({ left: Spacing.lg, top: Spacing.xl, bottom: Spacing.xs })
  }

  @Builder SettingItem(icon: string, title: string, subtitle: string, onClick?: () => void) {
    Row() {
      Text(icon)
        .fontSize(FontSize.xl)

      Column() {
        Text(title)
          .fontSize(FontSize.title)
          .fontColor(Colors.textPrimary)
        Text(subtitle)
          .fontSize(FontSize.xs)
          .fontColor(Colors.textHint)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: Spacing.md })

      Blank()

      Text('→')
        .width(18)
        .height(18)
        .fontColor(Colors.textHint)
    }
    .width('100%')
    .padding({ left: Spacing.lg, right: Spacing.lg, top: Spacing.md, bottom: Spacing.md })
    .backgroundColor(Colors.bgCard)
    .onClick(() => {
      if (onClick) onClick()
    })
  }

  @Builder ToggleItem(icon: string, title: string, subtitle: string, isOn: boolean, callback: () => void) {
    Row() {
      Text(icon)
        .fontSize(FontSize.xl)

      Column() {
        Text(title)
          .fontSize(FontSize.title)
          .fontColor(Colors.textPrimary)
        Text(subtitle)
          .fontSize(FontSize.xs)
          .fontColor(Colors.textHint)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: Spacing.md })

      Blank()

      Toggle({ type: ToggleType.Switch, isOn: isOn })
        .selectedColor(Colors.primary)
        .onChange((value: boolean) => { callback() })
    }
    .width('100%')
    .padding({ left: Spacing.lg, right: Spacing.lg, top: Spacing.md, bottom: Spacing.md })
    .backgroundColor(Colors.bgCard)
  }

  build() {
    Column() {
      this.HeaderBuilder()

      Scroll() {
        Column() {
          // 账号设置
          this.SectionTitle('账号设置')
          Column() {
            this.SettingItem('👤', '编辑个人资料', '修改昵称、头像、简介', () => { router.pushUrl({ url: 'pages/EditProfilePage' }) })
            Divider().color(Colors.divider).strokeWidth(0.5)
            this.SettingItem('🔒', '账号与安全', '修改密码、绑定手机')
            Divider().color(Colors.divider).strokeWidth(0.5)
            this.SettingItem('🎓', '校园认证', `${CurrentUser.campus} · ${CurrentUser.major}`)
          }
          .borderRadius(BorderRadius.lg)
          .clip(true)

          // 通知设置
          this.SectionTitle('通知设置')
          Column() {
            this.ToggleItem('🔔', '消息通知', '接收点赞、评论和星尘通知', this.notificationEnabled, () => {
              this.notificationEnabled = !this.notificationEnabled
            })
            Divider().color(Colors.divider).strokeWidth(0.5)
            this.ToggleItem('🔊', '提示音', '收到消息时播放提示音', this.soundEnabled, () => {
              this.soundEnabled = !this.soundEnabled
            })
          }
          .borderRadius(BorderRadius.lg)
          .clip(true)

          // 显示设置
          this.SectionTitle('显示设置')
          Column() {
            this.ToggleItem('🌙', '深色模式', 'Lumina专属暗色主题', this.darkMode, () => {
              this.darkMode = !this.darkMode
              if (this.darkMode) {
                ThemeManager.setMode(ThemeMode.DARK)
              } else {
                ThemeManager.setMode(ThemeMode.LIGHT)
              }
            })
          }
          .borderRadius(BorderRadius.lg)
          .clip(true)

          // 通用设置
          this.SectionTitle('通用')
          Column() {
            this.SettingItem('📦', '缓存管理', '清理缓存数据', () => {
              promptAction.showToast({ message: '缓存已清理' })
            })
            Divider().color(Colors.divider).strokeWidth(0.5)
            this.SettingItem('🌐', '语言', '简体中文')
            Divider().color(Colors.divider).strokeWidth(0.5)
            this.SettingItem('📖', '关于Lumina', '版本 1.0.0', () => { router.pushUrl({ url: 'pages/AboutPage' }) })
          }
          .borderRadius(BorderRadius.lg)
          .clip(true)

          // 退出登录按钮
          Button('退出登录')
            .fontSize(FontSize.title)
            .fontColor(Colors.likeRed)
            .backgroundColor(Colors.likeRed + '10')
            .borderRadius(BorderRadius.md)
            .width('100%')
            .height(48)
            .margin({ left: Spacing.lg, right: Spacing.lg, top: Spacing.xxl })
            .onClick(() => {
              CurrentUser.reset()
              ApiClient.authToken = ''
              AppStorage.setOrCreate('loginVersion', Date.now())
              router.back()
            })

          // 底部品牌
          Text('✨ Lumina - 以星尘之力连接每一个有趣的灵魂')
            .fontSize(FontSize.xs)
            .fontColor(Colors.textHint)
            .textAlign(TextAlign.Center)
            .width('100%')
            .margin({ top: Spacing.xl, bottom: Spacing.xxl })

          Blank().height(Spacing.xxl)
        }
        .width('100%')
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
