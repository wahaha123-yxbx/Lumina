import { ProjectModel, ProjectCategories, getCategoryColor } from '../model/ProjectModel'
import { C, FontSize, Spacing, BorderRadius } from '../common/Constants'
import { router } from '@kit.ArkUI'
import { ProjectApi } from '../common/ProjectApi'
import { MockProjectService } from '../common/MockData'

/**
 * 项目广场页 — 分类浏览所有项目
 */
@Entry
@Component
export struct ProjectSquarePage {
  @State projects: ProjectModel[] = []
  @State selectedCategory: string = '全部'
  @State isLoading: boolean = false

  aboutToAppear(): void {
    // 先用本地 Mock 数据立即渲染，后台尝试刷新
    this.projects = MockProjectService.getProjects(this.selectedCategory)
    this.isLoading = false
    this.tryLoadFromServer()
  }

  async tryLoadFromServer(): Promise<void> {
    const data = await ProjectApi.getProjects(
      this.selectedCategory === '全部' ? undefined : this.selectedCategory
    )
    if (data.length > 0) {
      this.projects = data
    }
  }

  onCategoryChange(cat: string): void {
    this.selectedCategory = cat
    this.projects = MockProjectService.getProjects(this.selectedCategory)
  }

  @Builder CategoryBar() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(ProjectCategories, (cat: string) => {
          Text(cat)
            .fontSize(13)
            .fontColor(this.selectedCategory === cat ? Color.White : C.textSecondary)
            .fontWeight(this.selectedCategory === cat ? FontWeight.Medium : FontWeight.Normal)
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .borderRadius(BorderRadius.full)
            .backgroundColor(this.selectedCategory === cat ? getCategoryColor(cat) : C.bgCard)
            .onClick(() => { this.onCategoryChange(cat) })
        }, (cat: string) => cat)
      }
      .padding({ left: Spacing.lg, right: Spacing.lg })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .padding({ top: Spacing.sm, bottom: Spacing.sm })
    .backgroundColor(C.bgCard)
  }

  @Builder ProjectCard(project: ProjectModel) {
    Column() {
      // 第一行：标题 + 状态标签
      Row() {
        Text(project.title)
          .fontSize(FontSize.title)
          .fontWeight(FontWeight.Bold)
          .fontColor(C.textPrimary)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(project.getStatusLabel())
          .fontSize(11)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .borderRadius(10)
          .backgroundColor(project.getStatusColor())
      }
      .width('100%')

      // 描述
      Text(project.description)
        .fontSize(FontSize.sm)
        .fontColor(C.textSecondary)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: Spacing.sm })
        .width('100%')

      // 标签行
      if (project.tags.length > 0) {
        Row({ space: 6 }) {
          ForEach(project.tags, (tag: string) => {
            Text('#' + tag)
              .fontSize(11)
              .fontColor(getCategoryColor(project.category))
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .borderRadius(4)
              .backgroundColor(getCategoryColor(project.category) + '15')
          }, (tag: string) => tag)
        }
        .margin({ top: Spacing.sm })
      }

      // 底部信息行
      Row() {
        // 队长
        Text((project.leaderAvatar || '👤') + ' ' + project.leaderName)
          .fontSize(12)
          .fontColor(C.textHint)

        Blank()

        // 人数
        Text('👥 ' + project.members.length + '/' + project.maxMembers + '人')
          .fontSize(12)
          .fontColor(C.textHint)
          .margin({ right: Spacing.md })

        // 任务进度
        Text('📋 ' + project.completedTaskCount + '/' + project.taskCount)
          .fontSize(12)
          .fontColor(C.textHint)

        // 分类标签
        Text(project.category)
          .fontSize(11)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .borderRadius(4)
          .backgroundColor(getCategoryColor(project.category))
          .margin({ left: Spacing.md })
      }
      .width('100%')
      .margin({ top: Spacing.md })

      // 进度条
      Row() {
        // 人数进度
        Row() {
          Row() {
          }
          .width(project.getMemberPercent().toString() + '%')
          .height('100%')
          .borderRadius(2)
          .backgroundColor('#FF6B35')
        }
        .width('50%')
        .height(4)
        .borderRadius(2)
        .backgroundColor(C.bgInput)

        // 任务进度
        Row() {
          Row() {
          }
          .width(project.getTaskPercent().toString() + '%')
          .height('100%')
          .borderRadius(2)
          .backgroundColor(C.primary)
        }
        .width('50%')
        .height(4)
        .borderRadius(2)
        .backgroundColor(C.bgInput)
        .margin({ left: Spacing.sm })
      }
      .width('100%')
      .margin({ top: Spacing.sm })
    }
    .width('100%')
    .padding(Spacing.lg)
    .backgroundColor(C.bgCard)
    .borderRadius(BorderRadius.lg)
    .margin({ left: Spacing.lg, right: Spacing.lg, top: Spacing.md })
    .onClick(() => {
      router.pushUrl({ url: 'pages/ProjectDetailPage', params: { projectId: project.id } })
    })
  }

  build() {
    Column() {
      // 顶部栏
      Row() {
        Text('←').fontSize(24).fontColor(C.textPrimary).onClick(() => { router.back() })
        Text('项目广场').fontSize(FontSize.lg).fontColor(C.textPrimary).fontWeight(FontWeight.Medium).margin({ left: Spacing.md })
        Blank()
        Text('🔍').fontSize(20).fontColor(C.textSecondary)
      }
      .width('100%').height(48).padding({ left: Spacing.lg, right: Spacing.lg })
      .backgroundColor(C.bgCard)

      // 分类栏
      this.CategoryBar()

      // 项目列表
      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40).color(C.primary)
          Text('加载中...').fontSize(FontSize.body).fontColor(C.textHint).margin({ top: Spacing.md })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.projects.length === 0) {
        Column() {
          Text('📂').fontSize(48).opacity(0.4)
          Text('暂无项目').fontSize(FontSize.body).fontColor(C.textHint).margin({ top: Spacing.md })
          Text('快来创建第一个项目吧！').fontSize(FontSize.sm).fontColor(C.textHint).margin({ top: 4 })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            ForEach(this.projects, (project: ProjectModel) => {
              this.ProjectCard(project)
            }, (project: ProjectModel) => project.id)

            Blank().height(Spacing.xxl)
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%').height('100%').backgroundColor(C.bg)
  }
}
