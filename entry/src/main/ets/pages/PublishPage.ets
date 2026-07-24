import { PostTags, getTagColor } from '../model/PostModel'
import { CurrentUser } from '../model/UserModel'
import { PostApi } from '../common/PostApi'
import { C, FontSize, Spacing, BorderRadius } from '../common/Constants'
import { router, promptAction } from '@kit.ArkUI'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { BusinessError } from '@kit.BasicServicesKit'

@Entry
@Component
struct PublishPage {
  @State titleText: string = ''
  @State contentText: string = ''
  @State selectedTag: string = '学术讨论'
  @State isSubmitting: boolean = false
  @State showTagPicker: boolean = false
  @State selectedImages: Array<string> = []
  @State publishMode: number = 0  // 0=发帖子, 1=发项目

  @Builder HeaderBuilder() {
    Row() {
      Text('←').fontSize(24).fontColor(C.textPrimary).onClick(() => { router.back() })
      // Tab 切换
      Row() {
        Text('发帖子')
          .fontSize(FontSize.body)
          .fontWeight(this.publishMode === 0 ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.publishMode === 0 ? C.primary : C.textHint)
          .padding({ left: Spacing.md, right: Spacing.md, top: 4, bottom: 4 })
          .borderRadius(BorderRadius.full)
          .backgroundColor(this.publishMode === 0 ? C.primaryBg : Color.Transparent)
          .onClick(() => { this.publishMode = 0 })

        Text('发项目')
          .fontSize(FontSize.body)
          .fontWeight(this.publishMode === 1 ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.publishMode === 1 ? C.primary : C.textHint)
          .padding({ left: Spacing.md, right: Spacing.md, top: 4, bottom: 4 })
          .borderRadius(BorderRadius.full)
          .backgroundColor(this.publishMode === 1 ? C.primaryBg : Color.Transparent)
          .margin({ left: Spacing.sm })
          .onClick(() => { this.publishMode = 1 })
      }
      .margin({ left: Spacing.md })
      Blank()
      if (this.publishMode === 0) {
        Button('发布').fontSize(FontSize.body).fontColor(Color.White).fontWeight(FontWeight.Bold)
          .backgroundColor(this.titleText.trim().length > 0 ? C.primary : C.textHint)
          .borderRadius(BorderRadius.sm).height(34).padding({ left: Spacing.lg, right: Spacing.lg })
          .onClick(() => { this.publishPost() })
      } else {
        Button('发布项目').fontSize(FontSize.sm).fontColor(Color.White).fontWeight(FontWeight.Bold)
          .backgroundColor(C.primary).borderRadius(BorderRadius.sm).height(34)
          .padding({ left: Spacing.md, right: Spacing.md })
          .onClick(() => {
            router.pushUrl({ url: 'pages/PublishProjectPage' })
          })
      }
    }.width('100%').height(48).padding({ left: Spacing.lg, right: Spacing.lg }).backgroundColor(C.bgCard)
  }

  async publishPost(): Promise<void> {
    if (this.titleText.trim().length === 0) { promptAction.showToast({ message: '请输入标题' }); return }
    if (!CurrentUser.id) { promptAction.showToast({ message: '请先登录' }); return }
    this.isSubmitting = true
    const post = await PostApi.publishPost(this.titleText.trim(), this.contentText.trim(), CurrentUser.id, this.selectedTag, this.selectedImages)
    this.isSubmitting = false
    if (post) { promptAction.showToast({ message: '发布成功！' }); router.back() }
    else { promptAction.showToast({ message: '发布失败' }) }
  }

  async pickImages(): Promise<void> {
    try {
      const opt = new photoAccessHelper.PhotoSelectOptions()
      opt.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE
      opt.maxSelectNumber = 9 - this.selectedImages.length
      const picker = new photoAccessHelper.PhotoViewPicker()
      const result = await picker.select(opt)
      if (result.photoUris && result.photoUris.length > 0) {
        this.selectedImages = [...this.selectedImages, ...result.photoUris]
      }
    } catch (e) { console.info('picker cancelled') }
  }

  removeImage(idx: number): void {
    const arr = [...this.selectedImages]; arr.splice(idx, 1); this.selectedImages = arr
  }

  build() {
    Column() {
      this.HeaderBuilder()
      if (this.publishMode === 1) {
        // 发项目模式 → 引导到专门的发布项目页
        Column() {
          Column() {
            Text('📂').fontSize(56).opacity(0.6)
            Text('创建新项目').fontSize(FontSize.xl).fontWeight(FontWeight.Bold).fontColor(C.textPrimary).margin({ top: Spacing.md })
            Text('发起一个科研项目、竞赛组队、兴趣创作...').fontSize(FontSize.body).fontColor(C.textHint).margin({ top: Spacing.sm })
            Button('🚀 开始创建项目').fontSize(FontSize.body).fontWeight(FontWeight.Bold)
              .fontColor(Color.White).backgroundColor(C.primary)
              .borderRadius(BorderRadius.md).height(48)
              .padding({ left: Spacing.xxl, right: Spacing.xxl })
              .margin({ top: Spacing.lg })
              .onClick(() => { router.pushUrl({ url: 'pages/PublishProjectPage' }) })
          }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
        }
        .width('100%').layoutWeight(1).backgroundColor(C.bg)
      } else if (this.isSubmitting) {
        Column() {
          LoadingProgress().width(48).height(48).color(C.primary)
          Text('发布中...').fontSize(FontSize.body).fontColor(C.textHint).margin({ top: Spacing.lg })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            TextInput({ placeholder: '标题：分享你的见解…', text: this.titleText })
              .placeholderColor(C.textHint).fontSize(FontSize.xl).fontWeight(FontWeight.Bold)
              .fontColor(C.textPrimary).backgroundColor(C.bgCard).borderRadius(BorderRadius.md)
              .height(56).width('100%').padding({ left: Spacing.lg, right: Spacing.lg })
              .margin({ left: Spacing.md, right: Spacing.md, top: Spacing.md })
              .onChange((v: string) => { this.titleText = v })

            // Tag selector
            Row() {
              Text('分类').fontSize(FontSize.body).fontColor(C.textSecondary)
              Blank()
              Row() {
                Text(this.selectedTag).fontSize(FontSize.sm).fontColor(getTagColor(this.selectedTag)).fontWeight(FontWeight.Medium)
                Text(' ▼').fontSize(12).fontColor(getTagColor(this.selectedTag))
              }.padding({ left: Spacing.md, right: Spacing.md, top: Spacing.xs, bottom: Spacing.xs })
              .borderRadius(BorderRadius.sm).backgroundColor(getTagColor(this.selectedTag) + '18')
              .onClick(() => { this.showTagPicker = !this.showTagPicker })
            }.width('100%').padding({ left: Spacing.lg, right: Spacing.lg, top: Spacing.md, bottom: Spacing.md })
            .backgroundColor(C.bgCard).borderRadius(BorderRadius.md)
            .margin({ top: Spacing.md, left: Spacing.md, right: Spacing.md })

            if (this.showTagPicker) {
              Scroll() {
                Row() {
                  ForEach(PostTags.filter((t: string) => t !== '全部'), (tag: string) => {
                    Text(tag).fontSize(FontSize.sm)
                      .fontColor(this.selectedTag === tag ? Color.White : C.textSecondary)
                      .padding({ left: Spacing.md, right: Spacing.md, top: Spacing.xs, bottom: Spacing.xs })
                      .borderRadius(BorderRadius.full)
                      .backgroundColor(this.selectedTag === tag ? getTagColor(tag) : C.bgInput)
                      .margin({ right: Spacing.sm })
                      .onClick(() => { this.selectedTag = tag; this.showTagPicker = false })
                  })
                }.padding({ left: Spacing.lg, right: Spacing.lg })
              }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
              .width('100%').padding({ top: Spacing.sm, bottom: Spacing.sm })
              .backgroundColor(C.bgCard).margin({ left: Spacing.md, right: Spacing.md })
            }

            TextArea({ placeholder: '正文：尽情发挥吧...', text: this.contentText })
              .placeholderColor(C.textHint).fontSize(FontSize.body).fontColor(C.textPrimary)
              .backgroundColor(C.bgCard).borderRadius(BorderRadius.md)
              .constraintSize({ minHeight: 150 }).width('100%').padding(Spacing.lg)
              .margin({ left: Spacing.md, right: Spacing.md, top: Spacing.md })
              .onChange((v: string) => { this.contentText = v })

            if (this.selectedImages.length > 0) {
              Row() {
                ForEach(this.selectedImages, (uri: string, idx: number) => {
                  Column() {
                    Image(uri).width(80).height(80).borderRadius(BorderRadius.sm).objectFit(ImageFit.Cover)
                    Text('✕').fontSize(12).fontColor(Color.White).width(20).height(20).borderRadius(10)
                      .backgroundColor('rgba(0,0,0,0.5)').textAlign(TextAlign.Center)
                      .position({ x: 70, y: -4 }).onClick(() => { this.removeImage(idx) })
                  }.margin({ right: Spacing.sm })
                })
              }.width('100%').padding({ left: Spacing.lg, right: Spacing.lg }).margin({ top: Spacing.md })
            }

            if (this.selectedImages.length < 9) {
              Row() {
                Text('📷 添加图片').fontSize(FontSize.body).fontColor(C.primary)
                Text(` (${this.selectedImages.length}/9)`).fontSize(FontSize.xs).fontColor(C.textHint)
              }.width('100%').padding(Spacing.lg).backgroundColor(C.bgCard).borderRadius(BorderRadius.md)
              .margin({ left: Spacing.md, right: Spacing.md, top: Spacing.md })
              .onClick(() => { this.pickImages() })
            }

            Text('💡 优质内容会获得更多星尘赞赏').fontSize(FontSize.xs).fontColor(C.textHint).margin({ top: Spacing.lg })
          }.width('100%')
        }.width('100%').layoutWeight(1).scrollBar(BarState.Off)
      }
    }.width('100%').height('100%').backgroundColor(C.bg)
  }
}
