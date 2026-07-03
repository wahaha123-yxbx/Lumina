import { CurrentUser, loginCurrentUser } from '../model/UserModel'
import { UserApi, LoginResult } from '../common/UserApi'
import { C, FontSize, Spacing, BorderRadius } from '../common/Constants'
import { router, promptAction } from '@kit.ArkUI'

/**
 * 登录页面 - 学号 + 密码登录
 */
@Entry
@Component
struct LoginPage {
  @State studentId: string = ''
  @State password: string = ''
  @State isLoading: boolean = false
  @State showPassword: boolean = false
  @State errorMsg: string = ''

  async doLogin(): Promise<void> {
    if (!this.studentId.trim() || !this.password.trim()) {
      this.errorMsg = '请输入学号和密码'
      return
    }
    if (this.password.trim().length < 6) {
      this.errorMsg = '密码至少6位'
      return
    }

    this.isLoading = true
    this.errorMsg = ''

    try {
      const result = await UserApi.login(this.studentId.trim(), this.password)
      this.isLoading = false

      if (result.success && result.data) {
        loginCurrentUser(result.data)
        AppStorage.setOrCreate('loginVersion', Date.now())
        promptAction.showToast({ message: '登录成功 ✨' })
        router.back()
      } else {
        this.errorMsg = result.message
      }
    } catch (err) {
      this.isLoading = false
      this.errorMsg = '登录异常，请重试'
    }
  }

  goRegister(): void {
    router.pushUrl({ url: 'pages/RegisterPage' })
  }

  build() {
    Column() {
      // 返回
      Row() {
        Text('←')
          .fontSize(24)
          .fontColor(C.textPrimary)
          .onClick(() => { router.back() })
      }
      .width('100%')
      .padding({ left: Spacing.lg, top: Spacing.lg })

      Scroll() {
        Column() {
          // 标题区
          Column() {
            Image($r('app.media.app_icon'))
              .width(72)
              .height(72)
              .borderRadius(18)

            Text('Lumina')
              .fontSize(32)
              .fontWeight(FontWeight.Bold)
              .fontColor(C.textPrimary)
              .fontFamily('sans-serif-medium')
              .margin({ top: Spacing.md })

            Text('登录你的校园账号')
              .fontSize(FontSize.body)
              .fontColor(C.textHint)
              .margin({ top: Spacing.sm })
          }
          .width('100%')
          .padding({ top: Spacing.xxl, bottom: Spacing.xl })

          // 表单
          Column() {
            // 学号
            TextInput({ placeholder: '请输入学号', text: this.studentId })
              .placeholderColor(C.textHint)
              .fontSize(FontSize.title)
              .fontColor(C.textPrimary)
              .backgroundColor(C.bgInput)
              .borderRadius(BorderRadius.md)
              .height(50)
              .width('100%')
              .padding({ left: Spacing.lg })
              .onChange((value: string) => { this.studentId = value; this.errorMsg = '' })

            // 密码
            Row() {
              TextInput({ placeholder: '请输入密码', text: this.password })
                .placeholderColor(C.textHint)
                .fontSize(FontSize.title)
                .fontColor(C.textPrimary)
                .backgroundColor(C.bgInput)
                .type(this.showPassword ? InputType.Normal : InputType.Password)
                .layoutWeight(1)
                .height(50)
                .padding({ left: Spacing.lg })
                .onChange((value: string) => { this.password = value; this.errorMsg = '' })

              Text(this.showPassword ? '🙈' : '👁')
                .fontSize(18)
                .padding({ left: Spacing.md, right: Spacing.md })
                .onClick(() => { this.showPassword = !this.showPassword })
            }
            .width('100%')
            .backgroundColor(C.bgInput)
            .borderRadius(BorderRadius.md)
            .margin({ top: Spacing.md })

            // 错误提示
            if (this.errorMsg) {
              Text(this.errorMsg)
                .fontSize(FontSize.sm)
                .fontColor(C.likeRed)
                .margin({ top: Spacing.md })
            }

            // 登录按钮
            Button() {
              if (this.isLoading) {
                LoadingProgress().width(22).height(22).color(Color.White)
              } else {
                Text('登 录')
                  .fontSize(FontSize.lg)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
              }
            }
            .width('100%')
            .height(50)
            .borderRadius(BorderRadius.md)
            .backgroundColor(
              this.studentId && this.password.length >= 6 ? C.primary : C.textHint
            )
            .margin({ top: Spacing.xl })
            .onClick(() => { this.doLogin() })
          }
          .width('100%')
          .padding({ left: Spacing.xl, right: Spacing.xl })

          // 注册入口
          Row() {
            Text('还没有账号？')
              .fontSize(FontSize.sm)
              .fontColor(C.textHint)
            Text('立即注册')
              .fontSize(FontSize.sm)
              .fontColor(C.primary)
              .onClick(() => { this.goRegister() })
          }
          .margin({ top: Spacing.xl })

          // 协议
          Text('登录即表示同意《用户协议》和《隐私政策》')
            .fontSize(FontSize.xs)
            .fontColor(C.textHint)
            .margin({ top: Spacing.xxl })
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
