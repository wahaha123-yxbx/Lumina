import {
  ProjectModel, TaskModel, ApplicationModel,
  MatchCandidate, MemberModel, getCategoryColor
} from '../model/ProjectModel'
import { C, FontSize, Spacing, BorderRadius } from '../common/Constants'
import { CurrentUser } from '../model/UserModel'
import { ProjectApi } from '../common/ProjectApi'
import { ApiClient } from '../common/ApiClient'
import { MockProjectService } from '../common/MockData'
import { router, promptAction } from '@kit.ArkUI'

// 仅用于状态更新的轻量 DTO（避免 UpdateProjectBody 默认值清空其他字段）
class StatusUpdateBody {
  status: string = ''
}

/**
 * 项目详情页 — 双视图：市场视图（非成员）vs 工作区视图（成员）
 *
 * 市场视图（非成员）：
 *   - 项目基本信息（标题、描述、分类、标签、队长）
 *   - 人数/任务统计数字
 *   - 申请加入按钮 / "已申请"状态
 *   - 不暴露：具体成员列表、任务详情、AI匹配
 *
 * 工作区视图（成员）：
 *   - 完整团队信息
 *   - 任务进度 + 进入看板入口
 *   - AI 推荐匹配
 *   - 队长：申请管理 + 项目状态管理
 */
@Entry
@Component
export struct ProjectDetailPage {
  @State project: ProjectModel = new ProjectModel()
  @State tasks: TaskModel[] = []
  @State matchCandidates: MatchCandidate[] = []
  @State applications: ApplicationModel[] = []
  @State isLoading: boolean = true
  @State isUserMember: boolean = false
  @State isUserLeader: boolean = false
  @State hasPendingApplication: boolean = false
  @State showApplyDialog: boolean = false
  @State showApplicationsPanel: boolean = false
  @State showStatusPicker: boolean = false
  @State applyMessage: string = '我想加入这个项目！'
  @State isApplying: boolean = false
  @State isProcessingApp: boolean = false
  private projectId: string = ''

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>
    if (params && params['projectId']) {
      this.projectId = params['projectId'] as string
      this.loadData()
    }
  }

  async loadData(): Promise<void> {
    // 先用本地 Mock 数据立即渲染
    const mock = MockProjectService.getProjectById(this.projectId)
    if (mock) this.project = mock
    this.tasks = MockProjectService.getTasksByProject(this.projectId)
    this.matchCandidates = MockProjectService.getMatchCandidates()
    this.checkMembership()
    this.isLoading = false

    // 后台尝试从服务器刷新
    const proj = await ProjectApi.getProjectById(this.projectId)
    if (proj) { this.project = proj; this.checkMembership() }
    const t = await ProjectApi.getTasks(this.projectId)
    if (t.length > 0) this.tasks = t
    const m = await ProjectApi.getMatchCandidates(this.projectId)
    if (m.length > 0) this.matchCandidates = m

    // 检查当前用户是否已申请
    this.checkApplicationStatus()
    // 队长加载申请列表
    if (this.isUserLeader) {
      this.loadApplications()
    }
  }

  /** 检查当前用户是否为项目成员 / 队长 */
  checkMembership(): void {
    if (!CurrentUser.id) {
      this.isUserMember = false
      this.isUserLeader = false
      return
    }
    let found = false
    for (let i = 0; i < this.project.members.length; i++) {
      if (this.project.members[i].userId === CurrentUser.id) {
        found = true
        break
      }
    }
    this.isUserMember = found
    this.isUserLeader = this.project.leaderId === CurrentUser.id
  }

  /** 检查当前用户是否已有 pending 申请 */
  async checkApplicationStatus(): Promise<void> {
    if (!CurrentUser.id || this.isUserMember) {
      this.hasPendingApplication = false
      return
    }
    const apps = await ProjectApi.getMyApplications(CurrentUser.id)
    for (let i = 0; i < apps.length; i++) {
      if (apps[i].projectId === this.projectId && apps[i].status === 'pending') {
        this.hasPendingApplication = true
        return
      }
    }
    this.hasPendingApplication = false
  }

  /** 队长加载申请列表 */
  async loadApplications(): Promise<void> {
    const apps = await ProjectApi.getApplications(this.projectId)
    this.applications = apps
  }

  countTasksByStatus(status: string): number {
    let count = 0
    for (let i = 0; i < this.tasks.length; i++) {
      if (this.tasks[i].status === status) count++
    }
    return count
  }

  countPendingApplications(): number {
    let count = 0
    for (let i = 0; i < this.applications.length; i++) {
      if (this.applications[i].status === 'pending') count++
    }
    return count
  }

  async doApply(): Promise<void> {
    if (!CurrentUser.id) {
      promptAction.showToast({ message: '请先登录' })
      return
    }
    this.isApplying = true
    const result = await ProjectApi.applyProject(this.projectId, CurrentUser.id, this.applyMessage)
    this.isApplying = false
    if (result) {
      this.hasPendingApplication = true
      promptAction.showToast({ message: '申请已发送！' })
      this.showApplyDialog = false
    } else {
      promptAction.showToast({ message: '申请失败，请重试' })
    }
  }

  /** 队长审批申请 */
  async handleApprove(appId: string, status: string): Promise<void> {
    this.isProcessingApp = true
    const result = await ProjectApi.approveApplication(appId, status)
    this.isProcessingApp = false
    if (result) {
      const label = status === 'approved' ? '已通过' : '已拒绝'
      promptAction.showToast({ message: '申请' + label })
      // 刷新申请列表和项目信息
      this.loadApplications()
      const proj = await ProjectApi.getProjectById(this.projectId)
      if (proj) { this.project = proj; this.checkMembership() }
    } else {
      promptAction.showToast({ message: '操作失败' })
    }
  }

  /** 队长变更项目状态 */
  async changeProjectStatus(newStatus: string): Promise<void> {
    const body = new StatusUpdateBody()
    body.status = newStatus
    const res = await ApiClient.put<ProjectModel>('/api/projects/' + this.projectId, body)
    if (res.code === 0) {
      this.project.status = newStatus
      promptAction.showToast({ message: '项目状态已更新' })
    }
    this.showStatusPicker = false
  }

  // ==================== 头部栏 ====================

  @Builder HeaderBar() {
    Row() {
      Text('←').fontSize(24).fontColor(C.textPrimary).onClick(() => { router.back() })
      Text(this.isUserMember ? '项目工作区' : '项目详情')
        .fontSize(FontSize.lg).fontColor(C.textPrimary).fontWeight(FontWeight.Medium)
        .margin({ left: Spacing.md })
      Blank()
      if (this.isUserLeader) {
        Text('⚙').fontSize(20).fontColor(C.textSecondary)
          .onClick(() => { this.showStatusPicker = true })
      }
    }
    .width('100%').height(48).padding({ left: Spacing.lg, right: Spacing.lg })
    .backgroundColor(C.bgCard)
  }

  // ==================== 项目基本信息 ====================

  @Builder ProjectInfo() {
    Column() {
      Row() {
        Text(this.project.title)
          .fontSize(FontSize.xl).fontWeight(FontWeight.Bold).fontColor(C.textPrimary)
          .layoutWeight(1).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.project.getStatusLabel())
          .fontSize(12).fontColor(Color.White)
          .padding({ left: 10, right: 10, top: 3, bottom: 3 })
          .borderRadius(10).backgroundColor(this.project.getStatusColor())
          .margin({ left: Spacing.sm })
      }
      .width('100%').alignItems(VerticalAlign.Top)

      Text(this.project.category + ' · 浏览 ' + this.project.viewCount + ' 次')
        .fontSize(FontSize.sm).fontColor(C.textHint).margin({ top: Spacing.sm }).width('100%')

      Text((this.project.leaderAvatar || '👤') + ' 队长：' + this.project.leaderName)
        .fontSize(FontSize.sm).fontColor(C.textSecondary).margin({ top: Spacing.sm }).width('100%')

      Text(this.project.description)
        .fontSize(FontSize.body).fontColor(C.textSecondary)
        .margin({ top: Spacing.md }).width('100%')

      if (this.project.tags.length > 0) {
        Row({ space: 6 }) {
          ForEach(this.project.tags, (tag: string) => {
            Text('#' + tag)
              .fontSize(11).fontColor(C.primary)
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .borderRadius(4).backgroundColor(C.primaryBg)
          }, (tag: string) => tag)
        }
        .margin({ top: Spacing.md })
      }
    }
    .width('100%').padding(Spacing.lg).backgroundColor(C.bgCard)
    .borderRadius(BorderRadius.lg)
    .margin({ left: Spacing.lg, right: Spacing.lg, top: Spacing.md })
  }

  // ==================== 统计卡片 ====================

  @Builder StatCard() {
    Row() {
      Column() {
        Text((this.project.leaderAvatar || '👤') + ' ' + this.project.members.length.toString())
          .fontSize(FontSize.lg).fontWeight(FontWeight.Bold).fontColor(C.textPrimary)
        Text('已加入 / ' + this.project.maxMembers + ' 人上限')
          .fontSize(11).fontColor(C.textHint).margin({ top: 2 })
      }.layoutWeight(1).alignItems(HorizontalAlign.Center)

      Divider().vertical(true).height(30).color(C.divider)

      Column() {
        Text(this.project.completedTaskCount + '/' + this.project.taskCount)
          .fontSize(FontSize.lg).fontWeight(FontWeight.Bold).fontColor(C.primary)
        Text('任务已完成').fontSize(11).fontColor(C.textHint).margin({ top: 2 })
      }.layoutWeight(1).alignItems(HorizontalAlign.Center)

      Divider().vertical(true).height(30).color(C.divider)

      Column() {
        Text(this.project.getStatusLabel())
          .fontSize(FontSize.lg).fontWeight(FontWeight.Bold).fontColor(this.project.getStatusColor())
        Text('项目状态').fontSize(11).fontColor(C.textHint).margin({ top: 2 })
      }.layoutWeight(1).alignItems(HorizontalAlign.Center)
    }
    .width('100%').padding(Spacing.lg).backgroundColor(C.bgCard)
    .borderRadius(BorderRadius.lg)
    .margin({ left: Spacing.lg, right: Spacing.lg, top: Spacing.md })
  }

  // ==================== 队长：申请管理 ====================

  @Builder ApplicationSection() {
    Column() {
      Row() {
        Text('📩 入队申请')
          .fontSize(FontSize.title).fontWeight(FontWeight.Bold).fontColor(C.textPrimary)
        Blank()
        if (this.countPendingApplications() > 0) {
          Text(this.countPendingApplications() + ' 条待审')
            .fontSize(12).fontColor(Color.White)
            .backgroundColor(C.likeRed).borderRadius(8)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
        }
        Text(this.showApplicationsPanel ? '收起 ▲' : '展开 ▼')
          .fontSize(FontSize.sm).fontColor(C.primary).margin({ left: Spacing.md })
          .onClick(() => { this.showApplicationsPanel = !this.showApplicationsPanel })
      }
      .width('100%')

      if (this.showApplicationsPanel) {
        if (this.applications.length === 0) {
          Text('暂无入队申请')
            .fontSize(FontSize.sm).fontColor(C.textHint)
            .margin({ top: Spacing.md }).width('100%')
        } else {
          ForEach(this.applications, (app: ApplicationModel) => {
            Row() {
              Column() {
                Text((app.userAvatar || '👤') + ' ' + app.userName)
                  .fontSize(FontSize.body).fontWeight(FontWeight.Medium).fontColor(C.textPrimary)
                Text(app.message || '我想加入这个项目！')
                  .fontSize(12).fontColor(C.textHint)
                  .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: 2 })
              }
              .alignItems(HorizontalAlign.Start).layoutWeight(1)

              if (app.status === 'pending') {
                Row() {
                  Text('✓')
                    .fontSize(14).fontColor(Color.White)
                    .width(32).height(32).borderRadius(16)
                    .backgroundColor(C.successGreen).textAlign(TextAlign.Center)
                    .onClick(() => { this.handleApprove(app.id, 'approved') })

                  Text('✕')
                    .fontSize(14).fontColor(Color.White)
                    .width(32).height(32).borderRadius(16)
                    .backgroundColor(C.likeRed).textAlign(TextAlign.Center)
                    .margin({ left: Spacing.sm })
                    .onClick(() => { this.handleApprove(app.id, 'rejected') })
                }
              } else {
                Text(app.getStatusLabel())
                  .fontSize(12)
                  .fontColor(app.status === 'approved' ? C.successGreen : C.likeRed)
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .borderRadius(4)
                  .backgroundColor(app.status === 'approved' ? C.successGreen + '15' : C.likeRed + '15')
              }
            }
            .width('100%')
            .padding({ top: Spacing.md, bottom: Spacing.md })
            .border({ width: { bottom: 0.5 }, color: C.divider })
          }, (app: ApplicationModel) => app.id)
        }
      }
    }
    .width('100%').padding(Spacing.lg).backgroundColor(C.bgCard)
    .borderRadius(BorderRadius.lg)
    .margin({ left: Spacing.lg, right: Spacing.lg, top: Spacing.md })
  }

  // ==================== 团队区域 ====================

  @Builder TeamSection() {
    Column() {
      Text('👥 团队成员（' + this.project.members.length + '/' + this.project.maxMembers + '）')
        .fontSize(FontSize.title).fontWeight(FontWeight.Bold).fontColor(C.textPrimary).width('100%')

      Row({ space: Spacing.md }) {
        ForEach(this.project.members, (member: MemberModel) => {
          Column() {
            Text(member.avatar || '👤')
              .fontSize(24).width(48).height(48).borderRadius(24)
              .backgroundColor(C.bgInput).textAlign(TextAlign.Center)
            Text(member.nickname)
              .fontSize(11).fontColor(C.textPrimary).maxLines(1)
              .margin({ top: 4 }).width(56).textAlign(TextAlign.Center)
            Text(member.role)
              .fontSize(10)
              .fontColor(member.role === '队长' ? C.primary : C.textHint)
              .padding({ left: 6, right: 6, top: 1, bottom: 1 })
              .borderRadius(3)
              .backgroundColor(member.role === '队长' ? C.primaryBg : C.bgInput)
          }.alignItems(HorizontalAlign.Center)
        }, (member: MemberModel) => member.userId)

        if (this.project.members.length < this.project.maxMembers) {
          ForEach(['1','2','3','4','5','6','7','8','9','10'], (slotId: string) => {
            if (parseInt(slotId) <= this.project.maxMembers - this.project.members.length) {
              Column() {
                Text('＋').fontSize(20).fontColor(C.textHint)
                  .width(48).height(48).borderRadius(24).backgroundColor(C.bgInput)
                  .border({ width: 1, color: C.divider, style: BorderStyle.Dashed })
                  .textAlign(TextAlign.Center)
                Text('虚位以待').fontSize(10).fontColor(C.textHint).margin({ top: 4 })
              }.alignItems(HorizontalAlign.Center)
            }
          }, (slotId: string) => 'empty' + slotId)
        }
      }
      .width('100%').margin({ top: Spacing.md })
    }
    .width('100%').padding(Spacing.lg).backgroundColor(C.bgCard)
    .borderRadius(BorderRadius.lg)
    .margin({ left: Spacing.lg, right: Spacing.lg, top: Spacing.md })
  }

  // ==================== 任务进度 ====================

  @Builder TaskProgress() {
    Column() {
      Row() {
        Text('📊 任务进度')
          .fontSize(FontSize.title).fontWeight(FontWeight.Bold).fontColor(C.textPrimary)
        Blank()
        Text(this.project.completedTaskCount + '/' + this.project.taskCount + ' 已完成')
          .fontSize(FontSize.sm).fontColor(C.textHint)
      }.width('100%')

      Row() {
        Row() {}
        .width(this.project.getTaskPercent().toString() + '%')
        .height(8).borderRadius(4).backgroundColor(C.primary)
      }
      .width('100%').height(8).borderRadius(4).backgroundColor(C.bgInput)
      .margin({ top: Spacing.md })

      Row({ space: 0 }) {
        Column() {
          Text(this.countTasksByStatus('todo').toString())
            .fontSize(FontSize.lg).fontWeight(FontWeight.Bold).fontColor('#FF6B35')
          Text('待办').fontSize(11).fontColor(C.textHint)
        }.layoutWeight(1).alignItems(HorizontalAlign.Center)
        Column() {
          Text(this.countTasksByStatus('inProgress').toString())
            .fontSize(FontSize.lg).fontWeight(FontWeight.Bold).fontColor('#FFC53D')
          Text('进行中').fontSize(11).fontColor(C.textHint)
        }.layoutWeight(1).alignItems(HorizontalAlign.Center)
        Column() {
          Text(this.countTasksByStatus('done').toString())
            .fontSize(FontSize.lg).fontWeight(FontWeight.Bold).fontColor('#2ED573')
          Text('已完成').fontSize(11).fontColor(C.textHint)
        }.layoutWeight(1).alignItems(HorizontalAlign.Center)
      }
      .width('100%').margin({ top: Spacing.md })

      Text('查看任务看板 →')
        .fontSize(FontSize.body).fontColor(C.primary).fontWeight(FontWeight.Medium)
        .padding({ top: Spacing.md, bottom: Spacing.sm }).width('100%')
        .onClick(() => {
          router.pushUrl({ url: 'pages/TaskBoardPage', params: { projectId: this.project.id } })
        })
    }
    .width('100%').padding(Spacing.lg).backgroundColor(C.bgCard)
    .borderRadius(BorderRadius.lg)
    .margin({ left: Spacing.lg, right: Spacing.lg, top: Spacing.md })
  }

  // ==================== AI 匹配 ====================

  @Builder MatchSection() {
    Column() {
      Text('🔍 AI 推荐匹配队员')
        .fontSize(FontSize.title).fontWeight(FontWeight.Bold).fontColor(C.textPrimary).width('100%')

      if (this.matchCandidates.length === 0) {
        Text('暂未找到匹配的候选人')
          .fontSize(FontSize.sm).fontColor(C.textHint).margin({ top: Spacing.sm }).width('100%')
      } else {
        ForEach(this.matchCandidates.slice(0, 3), (candidate: MatchCandidate) => {
          Row() {
            Text(candidate.avatar || '👤')
              .fontSize(22).width(44).height(44).borderRadius(22)
              .backgroundColor(C.bgInput).textAlign(TextAlign.Center)
            Column() {
              Row() {
                Text(candidate.nickname)
                  .fontSize(FontSize.body).fontWeight(FontWeight.Medium).fontColor(C.textPrimary)
                Text('Lv.' + candidate.level)
                  .fontSize(10).fontColor(C.primary).backgroundColor(C.primaryBg)
                  .borderRadius(3).padding({ left: 4, right: 4, top: 1, bottom: 1 })
                  .margin({ left: Spacing.sm })
              }
              Text(candidate.major + ' · ' + '参与' + candidate.projectCount + '个项目')
                .fontSize(11).fontColor(C.textHint).margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: Spacing.md })
            Text('匹配' + candidate.matchScore * 20 + '%')
              .fontSize(12).fontColor(C.primary).fontWeight(FontWeight.Bold)
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .borderRadius(8).backgroundColor(C.primaryBg)
          }
          .width('100%').padding({ top: Spacing.md, bottom: Spacing.md })
          .border({ width: { bottom: 0.5 }, color: C.divider })
        }, (candidate: MatchCandidate) => candidate.userId)
      }
    }
    .width('100%').padding(Spacing.lg).backgroundColor(C.bgCard)
    .borderRadius(BorderRadius.lg)
    .margin({ left: Spacing.lg, right: Spacing.lg, top: Spacing.md })
  }

  // ==================== 底部按钮 ====================

  @Builder BottomButton() {
    if (this.isUserMember) {
      Column() {
        Text(this.isUserLeader ? '你是项目队长' : '你已是项目成员')
          .fontSize(FontSize.sm).fontColor(C.textHint).margin({ top: Spacing.xs })
      }
      .width('100%').alignItems(HorizontalAlign.Center)
      .margin({ top: Spacing.lg, bottom: Spacing.xxl })
    } else if (this.project.status === 'recruiting') {
      if (this.hasPendingApplication) {
        // 已申请
        Row() {
          Text('⏳').fontSize(18)
          Text('申请已提交，等待队长审核')
            .fontSize(FontSize.body).fontColor(C.primary).fontWeight(FontWeight.Medium)
            .margin({ left: Spacing.sm })
        }
        .width('90%').height(48).justifyContent(FlexAlign.Center)
        .backgroundColor(C.primaryBg).borderRadius(BorderRadius.md)
        .margin({ top: Spacing.lg, bottom: Spacing.xxl })
      } else {
        // 未申请
        Button('📩 申请加入此项目')
          .fontSize(FontSize.body).fontWeight(FontWeight.Bold).fontColor(Color.White)
          .backgroundColor(C.primary).borderRadius(BorderRadius.md)
          .width('90%').height(48)
          .margin({ top: Spacing.lg, bottom: Spacing.xxl })
          .onClick(() => { this.showApplyDialog = true })
      }
    } else {
      Text('该项目当前不开放招募')
        .fontSize(FontSize.sm).fontColor(C.textHint)
        .margin({ top: Spacing.lg, bottom: Spacing.xxl })
    }
  }

  // ==================== 市场视图提示 ====================

  @Builder MarketplaceBanner() {
    Row() {
      Text('🔒').fontSize(16)
      Text('加入项目后即可查看团队成员、任务进度等详细信息')
        .fontSize(12).fontColor(C.textHint).layoutWeight(1).margin({ left: Spacing.sm })
    }
    .width('100%').padding({ left: Spacing.lg, right: Spacing.lg, top: Spacing.sm, bottom: Spacing.sm })
    .backgroundColor(C.primaryBg).borderRadius(BorderRadius.md)
    .margin({ left: Spacing.lg, right: Spacing.lg, top: Spacing.md })
  }

  // ==================== 申请弹窗 ====================

  @Builder ApplyDialog() {
    Column() {
      Column() {
        Text('申请加入项目').fontSize(FontSize.lg).fontWeight(FontWeight.Bold).fontColor(C.textPrimary)
        Text('给队长留言').fontSize(FontSize.sm).fontColor(C.textHint).margin({ top: Spacing.xs })

        TextArea({ placeholder: '介绍一下自己，说明你能为项目做什么...', text: this.applyMessage })
          .placeholderColor(C.textHint).fontSize(FontSize.body).fontColor(C.textPrimary)
          .backgroundColor(C.bgInput).borderRadius(BorderRadius.md)
          .width('100%').constraintSize({ minHeight: 80 })
          .padding(Spacing.md).margin({ top: Spacing.md })
          .onChange((v: string) => { this.applyMessage = v })

        Row() {
          Button('取消')
            .fontSize(FontSize.body).fontColor(C.textSecondary).backgroundColor(C.bgInput)
            .borderRadius(BorderRadius.md).height(42).layoutWeight(1)
            .onClick(() => { this.showApplyDialog = false })

          Button('提交申请')
            .fontSize(FontSize.body).fontWeight(FontWeight.Bold).fontColor(Color.White)
            .backgroundColor(C.primary).borderRadius(BorderRadius.md)
            .height(42).layoutWeight(1).margin({ left: Spacing.md })
            .onClick(() => { this.doApply() })
        }
        .width('100%').margin({ top: Spacing.md })
      }
      .width('85%').padding(Spacing.xl).backgroundColor(C.bgCard).borderRadius(BorderRadius.xl)
    }
    .width('100%').height('100%').justifyContent(FlexAlign.Center)
    .backgroundColor(C.overlay).onClick(() => { this.showApplyDialog = false })
  }

  // ==================== 状态选择弹窗 ====================

  @Builder StatusPickerDialog() {
    Column() {
      Column() {
        Text('变更项目状态').fontSize(FontSize.lg).fontWeight(FontWeight.Bold).fontColor(C.textPrimary)
        Text('当前：' + this.project.getStatusLabel())
          .fontSize(FontSize.sm).fontColor(C.textHint).margin({ top: Spacing.xs })

        Button('招募中 (recruiting)')
          .fontSize(FontSize.body)
          .fontColor(this.project.status === 'recruiting' ? Color.White : C.textPrimary)
          .backgroundColor(this.project.status === 'recruiting' ? C.primary : C.bgInput)
          .borderRadius(BorderRadius.md).width('100%').height(44)
          .margin({ top: Spacing.md })
          .onClick(() => { this.changeProjectStatus('recruiting') })

        Button('进行中 (active)')
          .fontSize(FontSize.body)
          .fontColor(this.project.status === 'active' ? Color.White : C.textPrimary)
          .backgroundColor(this.project.status === 'active' ? C.primary : C.bgInput)
          .borderRadius(BorderRadius.md).width('100%').height(44)
          .margin({ top: Spacing.sm })
          .onClick(() => { this.changeProjectStatus('active') })

        Button('已完成 (completed)')
          .fontSize(FontSize.body)
          .fontColor(this.project.status === 'completed' ? Color.White : C.textPrimary)
          .backgroundColor(this.project.status === 'completed' ? C.primary : C.bgInput)
          .borderRadius(BorderRadius.md).width('100%').height(44)
          .margin({ top: Spacing.sm })
          .onClick(() => { this.changeProjectStatus('completed') })

        Button('取消')
          .fontSize(FontSize.body).fontColor(C.textSecondary)
          .backgroundColor(C.bgInput).borderRadius(BorderRadius.md)
          .width('100%').height(40).margin({ top: Spacing.md })
          .onClick(() => { this.showStatusPicker = false })
      }
      .width('85%').padding(Spacing.xl).backgroundColor(C.bgCard).borderRadius(BorderRadius.xl)
    }
    .width('100%').height('100%').justifyContent(FlexAlign.Center)
    .backgroundColor(C.overlay).onClick(() => { this.showStatusPicker = false })
  }

  // ==================== 主构建 ====================

  build() {
    Stack() {
      Column() {
        this.HeaderBar()

        if (this.isLoading) {
          Column() {
            LoadingProgress().width(40).height(40).color(C.primary)
            Text('加载中...').fontSize(FontSize.body).fontColor(C.textHint).margin({ top: Spacing.md })
          }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
        } else {
          Scroll() {
            Column() {
              this.ProjectInfo()

              if (this.isUserMember) {
                // 工作区视图
                if (this.isUserLeader) {
                  this.ApplicationSection()
                }
                this.TeamSection()
                this.TaskProgress()
                this.MatchSection()
              } else {
                // 市场视图
                this.MarketplaceBanner()
                this.StatCard()
              }

              this.BottomButton()
              Blank().height(Spacing.xxl)
            }
            .width('100%')
          }
          .width('100%').layoutWeight(1).scrollBar(BarState.Off)
        }
      }
      .width('100%').height('100%').backgroundColor(C.bg)

      if (this.isApplying) {
        Column() {
          LoadingProgress().width(48).height(48).color(C.primary)
        }
        .width('100%').height('100%').justifyContent(FlexAlign.Center)
        .backgroundColor(C.overlay)
      }

      if (this.isProcessingApp) {
        Column() {
          LoadingProgress().width(48).height(48).color(C.primary)
          Text('处理中...').fontSize(FontSize.body).fontColor(C.textHint).margin({ top: Spacing.md })
        }
        .width('100%').height('100%').justifyContent(FlexAlign.Center)
        .backgroundColor(C.overlay)
      }

      if (this.showApplyDialog) {
        this.ApplyDialog()
      }

      if (this.showStatusPicker) {
        this.StatusPickerDialog()
      }
    }
    .width('100%').height('100%')
  }
}
