import { ProjectCategories, getCategoryColor } from '../model/ProjectModel'
import { CurrentUser } from '../model/UserModel'
import { C, FontSize, Spacing, BorderRadius } from '../common/Constants'
import { ProjectApi } from '../common/ProjectApi'
import { router, promptAction } from '@kit.ArkUI'

/**
 * 发布项目页 — 创建新项目
 */
@Entry
@Component
export struct PublishProjectPage {
  @State titleText: string = ''
  @State descText: string = ''
  @State selectedCategory: string = '科研学术'
  @State maxMembers: number = 5
  @State tagsText: string = ''
  @State isSubmitting: boolean = false
  @State showCategoryPicker: boolean = false

  @Builder HeaderBuilder() {
    Row() {
      Text('←').fontSize(24).fontColor(C.textPrimary).onClick(() => { router.back() })
      Text('发布项目').fontSize(FontSize.lg).fontColor(C.textPrimary).fontWeight(FontWeight.Medium).margin({ left: Spacing.md })
      Blank()
      Button('发布')
        .fontSize(FontSize.body).fontColor(Color.White).fontWeight(FontWeight.Bold)
        .backgroundColor(this.titleText.trim().length > 0 ? C.primary : C.textHint)
        .borderRadius(BorderRadius.sm).height(34).padding({ left: Spacing.lg, right: Spacing.lg })
        .onClick(() => { this.publishProject() })
    }
    .width('100%').height(48).padding({ left: Spacing.lg, right: Spacing.lg }).backgroundColor(C.bgCard)
  }

  async publishProject(): Promise<void> {
    if (!this.titleText.trim()) { promptAction.showToast({ message: '请输入项目名称' }); return }
    if (!CurrentUser.id) { promptAction.showToast({ message: '请先登录' }); return }

    this.isSubmitting = true
    // 解析标签（手写 filter 兼容 ArkTS）
    const rawTags = this.tagsText.trim() ? this.tagsText.split(/[，,、\s]+/) : []
    const tags: string[] = []
    for (let i = 0; i < rawTags.length; i++) {
      if (rawTags[i].length > 0) tags.push(rawTags[i])
    }
    if (tags.length === 0) tags.push(this.selectedCategory)

    const result = await ProjectApi.createProject(
      this.titleText.trim(),
      this.descText.trim(),
      this.selectedCategory,
      CurrentUser.id,
      tags,
      this.maxMembers
    )
    this.isSubmitting = false
    if (result) {
      promptAction.showToast({ message: '项目创建成功！' })
      router.back()
    } else {
      promptAction.showToast({ message: '发布失败，请重试' })
    }
  }

  build() {
    Column() {
      this.HeaderBuilder()

      if (this.isSubmitting) {
        Column() {
          LoadingProgress().width(48).height(48).color(C.primary)
          Text('发布中...').fontSize(FontSize.body).fontColor(C.textHint).margin({ top: Spacing.lg })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            // 项目名称
            TextInput({ placeholder: '项目名称：给你的项目起个名字', text: this.titleText })
              .placeholderColor(C.textHint).fontSize(FontSize.xl).fontWeight(FontWeight.Bold)
              .fontColor(C.textPrimary).backgroundColor(C.bgCard).borderRadius(BorderRadius.md)
              .height(56).width('100%').padding({ left: Spacing.lg, right: Spacing.lg })
              .margin({ left: Spacing.md, right: Spacing.md, top: Spacing.md })
              .onChange((v: string) => { this.titleText = v })

            // 分类选择
            Row() {
              Text('项目分类').fontSize(FontSize.body).fontColor(C.textSecondary)
              Blank()
              Row() {
                Text(this.selectedCategory)
                  .fontSize(FontSize.sm)
                  .fontColor(getCategoryColor(this.selectedCategory))
                  .fontWeight(FontWeight.Medium)
                Text(' ▼').fontSize(12).fontColor(getCategoryColor(this.selectedCategory))
              }
              .padding({ left: Spacing.md, right: Spacing.md, top: Spacing.xs, bottom: Spacing.xs })
              .borderRadius(BorderRadius.sm)
              .backgroundColor(getCategoryColor(this.selectedCategory) + '18')
              .onClick(() => { this.showCategoryPicker = !this.showCategoryPicker })
            }
            .width('100%')
            .padding({ left: Spacing.lg, right: Spacing.lg, top: Spacing.md, bottom: Spacing.md })
            .backgroundColor(C.bgCard).borderRadius(BorderRadius.md)
            .margin({ top: Spacing.md, left: Spacing.md, right: Spacing.md })

            if (this.showCategoryPicker) {
              Scroll() {
                Row() {
                  ForEach(ProjectCategories, (cat: string) => {
                    if (cat !== '全部') {
                      Text(cat)
                        .fontSize(FontSize.sm)
                        .fontColor(this.selectedCategory === cat ? Color.White : C.textSecondary)
                        .padding({ left: Spacing.md, right: Spacing.md, top: Spacing.xs, bottom: Spacing.xs })
                        .borderRadius(BorderRadius.full)
                        .backgroundColor(this.selectedCategory === cat ? getCategoryColor(cat) : C.bgInput)
                        .margin({ right: Spacing.sm })
                        .onClick(() => { this.selectedCategory = cat; this.showCategoryPicker = false })
                    }
                  }, (cat: string) => cat)
                }
                .padding({ left: Spacing.lg, right: Spacing.lg })
              }
              .scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
              .width('100%').padding({ top: Spacing.sm, bottom: Spacing.sm })
              .backgroundColor(C.bgCard).margin({ left: Spacing.md, right: Spacing.md })
            }

            // 项目描述
            TextArea({ placeholder: '项目描述：介绍项目目标、需要的技能、预期成果...', text: this.descText })
              .placeholderColor(C.textHint).fontSize(FontSize.body).fontColor(C.textPrimary)
              .backgroundColor(C.bgCard).borderRadius(BorderRadius.md)
              .constraintSize({ minHeight: 120 }).width('100%').padding(Spacing.lg)
              .margin({ left: Spacing.md, right: Spacing.md, top: Spacing.md })
              .onChange((v: string) => { this.descText = v })

            // 标签
            TextInput({ placeholder: '标签：用逗号或空格分隔，如 深度学习, Python, 鸿蒙', text: this.tagsText })
              .placeholderColor(C.textHint).fontSize(FontSize.body).fontColor(C.textPrimary)
              .backgroundColor(C.bgCard).borderRadius(BorderRadius.md)
              .height(44).width('100%').padding({ left: Spacing.lg, right: Spacing.lg })
              .margin({ left: Spacing.md, right: Spacing.md, top: Spacing.md })
              .onChange((v: string) => { this.tagsText = v })

            // 招募人数
            Row() {
              Text('招募人数').fontSize(FontSize.body).fontColor(C.textSecondary)
              Blank()
              Row({ space: 8 }) {
                Text('－')
                  .fontSize(20).fontColor(C.textPrimary)
                  .width(32).height(32).borderRadius(16)
                  .backgroundColor(C.bgInput).textAlign(TextAlign.Center)
                  .onClick(() => { if (this.maxMembers > 2) this.maxMembers-- })

                Text(this.maxMembers.toString())
                  .fontSize(FontSize.lg).fontWeight(FontWeight.Bold)
                  .fontColor(C.textPrimary).width(32).textAlign(TextAlign.Center)

                Text('＋')
                  .fontSize(20).fontColor(C.textPrimary)
                  .width(32).height(32).borderRadius(16)
                  .backgroundColor(C.bgInput).textAlign(TextAlign.Center)
                  .onClick(() => { if (this.maxMembers < 20) this.maxMembers++ })
              }
            }
            .width('100%')
            .padding({ left: Spacing.lg, right: Spacing.lg, top: Spacing.md, bottom: Spacing.md })
            .backgroundColor(C.bgCard).borderRadius(BorderRadius.md)
            .margin({ left: Spacing.md, right: Spacing.md, top: Spacing.md })

            // 提示
            Text('💡 项目发布后会自动进入"招募中"状态，你将成为项目队长')
              .fontSize(FontSize.xs).fontColor(C.textHint)
              .width('100%').padding({ left: Spacing.lg, right: Spacing.lg })
              .margin({ top: Spacing.lg })

            Blank().height(Spacing.xxl)
          }
          .width('100%')
        }
        .width('100%').layoutWeight(1).scrollBar(BarState.Off)
      }
    }
    .width('100%').height('100%').backgroundColor(C.bg)
  }
}
