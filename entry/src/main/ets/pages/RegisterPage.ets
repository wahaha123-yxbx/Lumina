import { CurrentUser, loginCurrentUser } from '../model/UserModel'
import { UserApi, LoginResult } from '../common/UserApi'
import { C, FontSize, Spacing, BorderRadius } from '../common/Constants'
import { router, promptAction } from '@kit.ArkUI'

/**
 * 注册页面
 */
@Entry
@Component
struct RegisterPage {
  @State studentId: string = ''
  @State password: string = ''
  @State confirmPassword: string = ''
  @State nickname: string = ''
  @State isLoading: boolean = false
  @State errorMsg: string = ''

  async doRegister(): Promise<void> {
    if (!this.studentId.trim()) {
      this.errorMsg = '请输入学号'
      return
    }
    if (!this.password || this.password.length < 6) {
      this.errorMsg = '密码至少6位'
      return
    }
    if (this.password !== this.confirmPassword) {
      this.errorMsg = '两次密码不一致'
      return
    }

    this.isLoading = true
    this.errorMsg = ''

    const result = await UserApi.register(
      this.studentId.trim(),
      this.password,
      this.nickname.trim() || '星尘旅人'
    )

    this.isLoading = false

    if (result.success && result.data) {
      // 注册成功，自动登录
      loginCurrentUser(result.data)
      AppStorage.setOrCreate('loginVersion', Date.now())
      promptAction.showToast({ message: '注册成功！欢迎加入 Lumina ✨' })
      router.back()
    } else {
      this.errorMsg = result.message
    }
  }

  build() {
    Column() {
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
          Column() {
            Text('📝')
              .fontSize(56)

            Text('创建 Lumina 账号')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor(C.textPrimary)
              .fontFamily('sans-serif-medium')
              .margin({ top: Spacing.md })

            Text('加入校园论坛，点亮星尘之旅')
              .fontSize(FontSize.body)
              .fontColor(C.textHint)
              .margin({ top: Spacing.sm })
          }
          .width('100%')
          .padding({ top: Spacing.xxl, bottom: Spacing.xl })

          // 表单
          Column() {
            this.InputField('学号', this.studentId, (v) => { this.studentId = v; this.errorMsg = '' })
            this.InputField('密码（至少6位）', this.password, (v) => { this.password = v; this.errorMsg = '' }, true)
            this.InputField('确认密码', this.confirmPassword, (v) => { this.confirmPassword = v; this.errorMsg = '' }, true)
            this.InputField('昵称（选填）', this.nickname, (v) => { this.nickname = v })

            if (this.errorMsg) {
              Text(this.errorMsg)
                .fontSize(FontSize.sm)
                .fontColor(C.likeRed)
                .margin({ top: Spacing.md })
            }

            Button() {
              if (this.isLoading) {
                LoadingProgress().width(22).height(22).color(Color.White)
              } else {
                Text('注 册')
                  .fontSize(FontSize.lg)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
              }
            }
            .width('100%')
            .height(50)
            .borderRadius(BorderRadius.md)
            .backgroundColor(C.primary)
            .margin({ top: Spacing.xl })
            .onClick(() => { this.doRegister() })
          }
          .width('100%')
          .padding({ left: Spacing.xl, right: Spacing.xl })

          // 去登录
          Row() {
            Text('已有账号？')
              .fontSize(FontSize.sm)
              .fontColor(C.textHint)
            Text('去登录')
              .fontSize(FontSize.sm)
              .fontColor(C.primary)
              .onClick(() => { router.back() })
          }
          .margin({ top: Spacing.xl })
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

  @Builder InputField(label: string, value: string, onChange: (v: string) => void, isPassword?: boolean) {
    TextInput({ placeholder: label, text: value })
      .placeholderColor(C.textHint)
      .fontSize(FontSize.title)
      .fontColor(C.textPrimary)
      .backgroundColor(C.bgInput)
      .borderRadius(BorderRadius.md)
      .height(50)
      .width('100%')
      .padding({ left: Spacing.lg })
      .type(isPassword ? InputType.Password : InputType.Normal)
      .margin({ top: Spacing.md })
      .onChange(onChange)
  }
}
