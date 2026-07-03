import { CurrentUser, loginCurrentUser, LoginUserData } from '../model/UserModel'
import { UserApi } from '../common/UserApi'
import { C, FontSize, Spacing, BorderRadius } from '../common/Constants'
import { router, promptAction } from '@kit.ArkUI'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { BusinessError } from '@kit.BasicServicesKit'

// 默认头像选项
const DEFAULT_AVATARS: string[] = ['👤', '🦊', '🐱', '🐶', '🐼', '🐨', '🦁', '🐰']

/**
 * 编辑个人资料
 */
@Entry
@Component
struct EditProfilePage {
  @State nickname: string = CurrentUser.nickname
  @State bio: string = CurrentUser.bio
  @State campus: string = CurrentUser.campus
  @State major: string = CurrentUser.major
  @State grade: string = CurrentUser.grade
  @State avatar: string = CurrentUser.avatar
  @State isSaving: boolean = false
  @State showAvatarPicker: boolean = false

  async saveProfile(): Promise<void> {
    this.isSaving = true
    const updated = await UserApi.updateUser(
      CurrentUser.id, this.nickname, this.bio, this.campus, this.major, this.grade
    )
    // 头像单独更新
    if (this.avatar) {
      await UserApi.updateAvatar(CurrentUser.id, this.avatar)
    }
    this.isSaving = false
    if (updated) {
      const data = new LoginUserData()
      data.id = CurrentUser.id
      data.nickname = this.nickname
      data.bio = this.bio
      data.campus = this.campus
      data.major = this.major
      data.grade = this.grade
      data.avatar = this.avatar
      loginCurrentUser(data)
      AppStorage.setOrCreate('loginVersion', Date.now())
      promptAction.showToast({ message: '保存成功' })
      router.back()
    } else {
      promptAction.showToast({ message: '保存失败，请重试' })
    }
  }

  selectDefaultAvatar(emoji: string): void {
    this.avatar = emoji
    this.showAvatarPicker = false
  }

  async uploadCustomAvatar(): Promise<void> {
    try {
      const options = new photoAccessHelper.PhotoSelectOptions()
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE
      options.maxSelectNumber = 1

      const picker = new photoAccessHelper.PhotoViewPicker()
      const result = await picker.select(options)

      if (result.photoUris && result.photoUris.length > 0) {
        this.avatar = result.photoUris[0]
        this.showAvatarPicker = false
      }
    } catch (err) {
      const error = err as BusinessError
      console.info('Avatar picker:', error.message)
    }
  }

  @Builder Field(label: string, value: string, onChange: (v: string) => void, placeholder?: string) {
    Row() {
      Text(label)
        .fontSize(FontSize.body)
        .fontColor(C.textSecondary)
        .width(72)

      TextInput({ placeholder: placeholder || label, text: value })
        .placeholderColor(C.textHint)
        .fontSize(FontSize.body)
        .fontColor(C.textPrimary)
        .backgroundColor(C.bgInput)
        .borderRadius(BorderRadius.sm)
        .height(42)
        .layoutWeight(1)
        .padding({ left: Spacing.md, right: Spacing.md })
        .onChange(onChange)
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

        Text('编辑个人资料')
          .fontSize(FontSize.lg)
          .fontColor(C.textPrimary)
          .fontWeight(FontWeight.Medium)
          .margin({ left: Spacing.md })

        Blank()

        Text('保存')
          .fontSize(FontSize.body)
          .fontColor(C.primary)
          .fontWeight(FontWeight.Bold)
          .onClick(() => { this.saveProfile() })
      }
      .width('100%')
      .height(48)
      .padding({ left: Spacing.lg, right: Spacing.lg })
      .backgroundColor(C.bgCard)

      Column() {
        // 头像区域
        Row() {
          Text('头像')
            .fontSize(FontSize.body)
            .fontColor(C.textSecondary)
            .width(72)

          if (this.avatar) {
            Text(this.avatar)
              .fontSize(36)
              .width(56)
              .height(56)
              .borderRadius(28)
              .backgroundColor(C.bgInput)
              .textAlign(TextAlign.Center)
          } else {
            Text('👤')
              .fontSize(36)
              .width(56)
              .height(56)
              .borderRadius(28)
              .backgroundColor(C.bgInput)
              .textAlign(TextAlign.Center)
          }

          Text('更换头像 →')
            .fontSize(FontSize.sm)
            .fontColor(C.primary)
            .margin({ left: Spacing.md })
        }
        .width('100%')
        .padding({ top: Spacing.md, bottom: Spacing.md })
        .onClick(() => { this.showAvatarPicker = !this.showAvatarPicker })

        // 头像选择面板
        if (this.showAvatarPicker) {
          Column() {
            Text('选择默认头像')
              .fontSize(FontSize.sm)
              .fontColor(C.textHint)
              .width('100%')
              .margin({ bottom: Spacing.sm })

            Row() {
              ForEach(DEFAULT_AVATARS, (emoji: string) => {
                Text(emoji)
                  .fontSize(28)
                  .width(44)
                  .height(44)
                  .borderRadius(22)
                  .backgroundColor(this.avatar === emoji ? C.primaryBg : C.bgInput)
                  .textAlign(TextAlign.Center)
                  .margin({ right: Spacing.sm })
                  .onClick(() => { this.selectDefaultAvatar(emoji) })
              })
            }
            .width('100%')

            Row() {
              Text('📷 从相册上传')
                .fontSize(FontSize.sm)
                .fontColor(C.primary)
            }
            .width('100%')
            .padding({ top: Spacing.md })
            .onClick(() => { this.uploadCustomAvatar() })
          }
          .width('100%')
          .padding(Spacing.lg)
          .backgroundColor(C.bgInput)
          .borderRadius(BorderRadius.md)
          .margin({ top: Spacing.sm })
        }

        Divider().color(C.divider).strokeWidth(0.5)
        this.Field('昵称', this.nickname, (v) => { this.nickname = v }, '你的昵称')
        Divider().color(C.divider).strokeWidth(0.5)
        this.Field('简介', this.bio, (v) => { this.bio = v }, '介绍一下自己')
        Divider().color(C.divider).strokeWidth(0.5)
        this.Field('学校', this.campus, (v) => { this.campus = v }, '你的学校')
        Divider().color(C.divider).strokeWidth(0.5)
        this.Field('专业', this.major, (v) => { this.major = v }, '你的专业')
        Divider().color(C.divider).strokeWidth(0.5)
        this.Field('年级', this.grade, (v) => { this.grade = v }, '你的年级')
      }
      .width('100%')
      .padding({ left: Spacing.lg, right: Spacing.lg, top: Spacing.lg })
      .backgroundColor(C.bgCard)
      .borderRadius(BorderRadius.lg)
      .margin({ top: Spacing.md, left: Spacing.md, right: Spacing.md })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(C.bg)
  }
}
