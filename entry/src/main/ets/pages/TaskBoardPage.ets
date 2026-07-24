import { TaskModel, ProjectModel, MemberModel } from '../model/ProjectModel'
import { C, FontSize, Spacing, BorderRadius } from '../common/Constants'
import { CurrentUser } from '../model/UserModel'
import { ProjectApi, UpdateTaskBody } from '../common/ProjectApi'
import { MockProjectService } from '../common/MockData'
import { router, promptAction } from '@kit.ArkUI'

const STATUS_TODO = 'todo'
const STATUS_IN_PROGRESS = 'inProgress'
const STATUS_DONE = 'done'

/**
 * 任务看板页 — 三列 Kanban 视图
 * 支持：点击切换状态、长按删除、创建时指派成员
 */
@Entry
@Component
export struct TaskBoardPage {
  @State tasks: TaskModel[] = []
  @State todoTasks: TaskModel[] = []
  @State inProgressTasks: TaskModel[] = []
  @State doneTasks: TaskModel[] = []
  @State project: ProjectModel = new ProjectModel()
  @State showCreateDialog: boolean = false
  @State showActionDialog: boolean = false
  @State newTaskTitle: string = ''
  @State newTaskPriority: string = 'medium'
  @State newTaskAssigneeId: string = ''
  @State newTaskAssigneeName: string = '未分配'
  @State isCreating: boolean = false
  @State isUserMember: boolean = false
  @State isCheckingAccess: boolean = true
  @State selectedTask: TaskModel = new TaskModel()
  private projectId: string = ''
  private columnWidth: number = 0

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>
    if (params && params['projectId']) {
      this.projectId = params['projectId'] as string
      this.columnWidth = 280
      this.checkAccess()
    }
  }

  async checkAccess(): Promise<void> {
    this.isCheckingAccess = true
    const mock = MockProjectService.getProjectById(this.projectId)
    if (mock) {
      this.project = mock
      this.isUserMember = this.userIsMember(mock)
    }
    const proj = await ProjectApi.getProjectById(this.projectId)
    if (proj) {
      this.project = proj
      this.isUserMember = this.userIsMember(proj)
    }
    this.isCheckingAccess = false
    if (this.isUserMember) {
      this.loadData()
    }
  }

  userIsMember(proj: ProjectModel): boolean {
    if (!CurrentUser.id) return false
    for (let i = 0; i < proj.members.length; i++) {
      if (proj.members[i].userId === CurrentUser.id) return true
    }
    return false
  }

  async loadData(): Promise<void> {
    this.tasks = MockProjectService.getTasksByProject(this.projectId)
    this.splitTasks()
    const t = await ProjectApi.getTasks(this.projectId)
    if (t.length > 0) { this.tasks = t; this.splitTasks() }
  }

  async refreshTasks(): Promise<void> {
    this.tasks = MockProjectService.getTasksByProject(this.projectId)
    this.splitTasks()
    const t = await ProjectApi.getTasks(this.projectId)
    if (t.length > 0) { this.tasks = t; this.splitTasks() }
  }

  splitTasks(): void {
    const todos: TaskModel[] = []
    const inProgress: TaskModel[] = []
    const done: TaskModel[] = []
    for (let i = 0; i < this.tasks.length; i++) {
      const task = this.tasks[i]
      if (task.status === STATUS_TODO) todos.push(task)
      else if (task.status === STATUS_IN_PROGRESS) inProgress.push(task)
      else if (task.status === STATUS_DONE) done.push(task)
    }
    this.todoTasks = todos
    this.inProgressTasks = inProgress
    this.doneTasks = done
  }

  findTaskById(id: string): TaskModel | undefined {
    for (let i = 0; i < this.tasks.length; i++) {
      if (this.tasks[i].id === id) return this.tasks[i]
    }
    return undefined
  }

  /** 点击任务卡片 → 弹出操作菜单 */
  showTaskActions(task: TaskModel): void {
    this.selectedTask = task
    this.showActionDialog = true
  }

  /** 切换到下一状态 */
  async changeTaskStatus(taskId: string, newStatus: string): Promise<void> {
    const task = this.findTaskById(taskId)
    if (task) {
      task.status = newStatus
      this.splitTasks()
    }
    const body = new UpdateTaskBody()
    body.status = newStatus
    await ProjectApi.updateTask(taskId, body)
    this.showActionDialog = false
  }

  getNextStatus(current: string): string {
    if (current === STATUS_TODO) return STATUS_IN_PROGRESS
    if (current === STATUS_IN_PROGRESS) return STATUS_DONE
    return STATUS_TODO
  }

  getNextStatusLabel(current: string): string {
    if (current === STATUS_TODO) return '开始进行'
    if (current === STATUS_IN_PROGRESS) return '标记完成'
    return '重新打开'
  }

  async deleteSelectedTask(): Promise<void> {
    const ok = await ProjectApi.deleteTask(this.selectedTask.id)
    if (ok) {
      promptAction.showToast({ message: '任务已删除' })
      this.showActionDialog = false
      // 本地移除
      const newList: TaskModel[] = []
      for (let i = 0; i < this.tasks.length; i++) {
        if (this.tasks[i].id !== this.selectedTask.id) newList.push(this.tasks[i])
      }
      this.tasks = newList
      this.splitTasks()
    } else {
      promptAction.showToast({ message: '删除失败' })
    }
  }

  async createTask(): Promise<void> {
    if (!this.newTaskTitle.trim()) {
      promptAction.showToast({ message: '请输入任务名称' })
      return
    }
    this.isCreating = true
    const result = await ProjectApi.createTask(
      this.projectId, this.newTaskTitle.trim(), '',
      this.newTaskAssigneeId, this.newTaskPriority, 0
    )
    this.isCreating = false
    if (result) {
      promptAction.showToast({ message: '任务创建成功' })
      this.newTaskTitle = ''
      this.newTaskAssigneeId = ''
      this.newTaskAssigneeName = '未分配'
      this.newTaskPriority = 'medium'
      this.showCreateDialog = false
      this.refreshTasks()
    } else {
      promptAction.showToast({ message: '创建失败，请重试' })
    }
  }

  // ==================== UI 组件 ====================

  @Builder HeaderBar() {
    Row() {
      Text('←').fontSize(24).fontColor(C.textPrimary).onClick(() => { router.back() })
      Text('任务看板').fontSize(FontSize.lg).fontColor(C.textPrimary).fontWeight(FontWeight.Medium).margin({ left: Spacing.md })
      Blank()
      Text('＋').fontSize(24).fontColor(C.primary).fontWeight(FontWeight.Bold)
        .onClick(() => {
          this.newTaskAssigneeId = ''
          this.newTaskAssigneeName = '未分配'
          this.showCreateDialog = true
        })
    }
    .width('100%').height(48).padding({ left: Spacing.lg, right: Spacing.lg })
    .backgroundColor(C.bgCard)
  }

  @Builder ColumnHeader(title: string, count: number, color: string) {
    Row() {
      Text(title)
        .fontSize(FontSize.title).fontWeight(FontWeight.Bold).fontColor(C.textPrimary)
      Text(count.toString())
        .fontSize(12).fontColor(Color.White).backgroundColor(color)
        .borderRadius(8).padding({ left: 6, right: 6, top: 1, bottom: 1 })
        .margin({ left: Spacing.sm })
    }
    .width('100%').padding({ left: Spacing.md, top: Spacing.md, bottom: Spacing.sm })
  }

  @Builder TaskCard(task: TaskModel) {
    Column() {
      // 标题
      Text(task.title)
        .fontSize(FontSize.body).fontWeight(FontWeight.Medium).fontColor(C.textPrimary)
        .width('100%').maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })

      // 描述
      if (task.description) {
        Text(task.description)
          .fontSize(12).fontColor(C.textHint).maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 }).width('100%')
      }

      // 底部标签行
      Row() {
        // 优先级
        Text(task.getPriorityLabel())
          .fontSize(10).fontColor(task.getPriorityColor()).fontWeight(FontWeight.Bold)
          .padding({ left: 6, right: 6, top: 1, bottom: 1 })
          .borderRadius(3).backgroundColor(task.getPriorityColor() + '20')

        // 负责人
        if (task.assigneeName !== '未分配') {
          Text((task.assigneeAvatar || '👤') + ' ' + task.assigneeName)
            .fontSize(11).fontColor(C.textSecondary)
            .margin({ left: Spacing.sm }).maxLines(1)
        } else {
          Text('未分配')
            .fontSize(11).fontColor(C.textHint).margin({ left: Spacing.sm })
        }

        Blank()

        // 截止日期
        if (task.deadline > 0) {
          Text('📅' + task.getDeadlineText())
            .fontSize(10).fontColor(C.textHint)
        }

        // 删除按钮
        Text('✕')
          .fontSize(12).fontColor(C.textHint)
          .padding({ left: Spacing.sm })
          .onClick(() => {
            this.selectedTask = task
            this.deleteSelectedTask()
          })
      }
      .width('100%').margin({ top: Spacing.sm })
    }
    .width(this.columnWidth - Spacing.md * 2)
    .padding(Spacing.md).backgroundColor(C.bgCard).borderRadius(BorderRadius.md)
    .margin({ left: Spacing.md, right: Spacing.md, bottom: Spacing.sm })
    .shadow({ radius: 2, color: '#00000010', offsetY: 1 })
    .onClick(() => { this.showTaskActions(task) })
  }

  @Builder KanbanColumn(color: string, tasks: TaskModel[], status: string, title: string) {
    Column() {
      this.ColumnHeader(title, tasks.length, color)
      Scroll() {
        Column() {
          ForEach(tasks, (task: TaskModel) => {
            this.TaskCard(task)
          }, (task: TaskModel) => task.id)
        }
        .width(this.columnWidth)
      }
      .width(this.columnWidth).layoutWeight(1).scrollBar(BarState.Off)
    }
    .width(this.columnWidth).height('100%').backgroundColor(C.bg)
  }

  // ==================== 创建任务弹窗 ====================

  @Builder CreateDialog() {
    Column() {
      Column() {
        Text('新建任务').fontSize(FontSize.lg).fontWeight(FontWeight.Bold).fontColor(C.textPrimary)

        TextInput({ placeholder: '任务名称', text: this.newTaskTitle })
          .placeholderColor(C.textHint).fontSize(FontSize.body).fontColor(C.textPrimary)
          .backgroundColor(C.bgInput).borderRadius(BorderRadius.md)
          .width('100%').height(44).padding({ left: Spacing.md, right: Spacing.md })
          .margin({ top: Spacing.md })
          .onChange((v: string) => { this.newTaskTitle = v })

        // 优先级选择
        Row() {
          Text('优先级：').fontSize(FontSize.body).fontColor(C.textSecondary)
          ForEach(['low', 'medium', 'high', 'urgent'], (p: string) => {
            Text(p === 'low' ? '低' : p === 'medium' ? '中' : p === 'high' ? '高' : '紧急')
              .fontSize(13)
              .fontColor(this.newTaskPriority === p ? Color.White : C.textSecondary)
              .fontWeight(this.newTaskPriority === p ? FontWeight.Bold : FontWeight.Normal)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .borderRadius(BorderRadius.full)
              .backgroundColor(this.newTaskPriority === p ? C.primary : C.bgInput)
              .margin({ left: Spacing.sm })
              .onClick(() => { this.newTaskPriority = p })
          }, (p: string) => p)
        }
        .width('100%').margin({ top: Spacing.md })

        // 指派成员
        Column() {
          Text('指派给：').fontSize(FontSize.body).fontColor(C.textSecondary).width('100%')
          Row({ space: Spacing.sm }) {
            // "不分配" 选项
            Text('未分配')
              .fontSize(13)
              .fontColor(this.newTaskAssigneeId === '' ? Color.White : C.textSecondary)
              .fontWeight(this.newTaskAssigneeId === '' ? FontWeight.Bold : FontWeight.Normal)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .borderRadius(BorderRadius.full)
              .backgroundColor(this.newTaskAssigneeId === '' ? C.primary : C.bgInput)
              .onClick(() => {
                this.newTaskAssigneeId = ''
                this.newTaskAssigneeName = '未分配'
              })

            ForEach(this.project.members, (m: MemberModel) => {
              Text((m.avatar || '👤') + ' ' + m.nickname)
                .fontSize(13)
                .fontColor(this.newTaskAssigneeId === m.userId ? Color.White : C.textSecondary)
                .fontWeight(this.newTaskAssigneeId === m.userId ? FontWeight.Bold : FontWeight.Normal)
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .borderRadius(BorderRadius.full)
                .backgroundColor(this.newTaskAssigneeId === m.userId ? C.primary : C.bgInput)
                .onClick(() => {
                  this.newTaskAssigneeId = m.userId
                  this.newTaskAssigneeName = m.nickname
                })
            }, (m: MemberModel) => m.userId)
          }
          .width('100%')
        }
        .width('100%').margin({ top: Spacing.md })

        Row() {
          Button('取消')
            .fontSize(FontSize.body).fontColor(C.textSecondary).backgroundColor(C.bgInput)
            .borderRadius(BorderRadius.md).height(42).layoutWeight(1)
            .onClick(() => { this.showCreateDialog = false })

          Button('创建')
            .fontSize(FontSize.body).fontWeight(FontWeight.Bold).fontColor(Color.White)
            .backgroundColor(C.primary).borderRadius(BorderRadius.md)
            .height(42).layoutWeight(1).margin({ left: Spacing.md })
            .onClick(() => { this.createTask() })
        }
        .width('100%').margin({ top: Spacing.md })
      }
      .width('85%').padding(Spacing.xl).backgroundColor(C.bgCard).borderRadius(BorderRadius.xl)
    }
    .width('100%').height('100%').justifyContent(FlexAlign.Center)
    .backgroundColor(C.overlay)
    .onClick(() => { this.showCreateDialog = false })
  }

  // ==================== 任务操作弹窗 ====================

  @Builder ActionDialog() {
    Column() {
      Column() {
        Text(this.selectedTask.title)
          .fontSize(FontSize.lg).fontWeight(FontWeight.Bold).fontColor(C.textPrimary)
          .width('100%').maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })

        // 状态信息
        Row() {
          Text('当前状态：')
            .fontSize(FontSize.body).fontColor(C.textSecondary)
          Text(this.selectedTask.getStatusLabel())
            .fontSize(FontSize.body).fontWeight(FontWeight.Bold)
            .fontColor(this.selectedTask.status === STATUS_DONE ? C.successGreen :
              (this.selectedTask.status === STATUS_IN_PROGRESS ? '#FFC53D' : '#FF6B35'))
        }
        .width('100%').margin({ top: Spacing.md })

        // 负责人信息
        Text('负责人：' + (this.selectedTask.assigneeName || '未分配'))
          .fontSize(FontSize.sm).fontColor(C.textHint)
          .width('100%').margin({ top: Spacing.xs })

        Divider().color(C.divider).strokeWidth(0.5).margin({ top: Spacing.md, bottom: Spacing.sm })

        // 操作按钮
        Button(this.getNextStatusLabel(this.selectedTask.status))
          .fontSize(FontSize.body).fontWeight(FontWeight.Medium).fontColor(Color.White)
          .backgroundColor(C.primary).borderRadius(BorderRadius.md)
          .width('100%').height(44)
          .onClick(() => {
            this.changeTaskStatus(this.selectedTask.id, this.getNextStatus(this.selectedTask.status))
          })

        Button('删除任务')
          .fontSize(FontSize.body).fontColor(C.likeRed)
          .backgroundColor(C.bgInput).borderRadius(BorderRadius.md)
          .width('100%').height(44).margin({ top: Spacing.md })
          .onClick(() => { this.deleteSelectedTask() })

        Button('取消')
          .fontSize(FontSize.body).fontColor(C.textSecondary)
          .backgroundColor(C.bgInput).borderRadius(BorderRadius.md)
          .width('100%').height(40).margin({ top: Spacing.sm })
          .onClick(() => { this.showActionDialog = false })
      }
      .width('85%').padding(Spacing.xl).backgroundColor(C.bgCard).borderRadius(BorderRadius.xl)
    }
    .width('100%').height('100%').justifyContent(FlexAlign.Center)
    .backgroundColor(C.overlay)
    .onClick(() => { this.showActionDialog = false })
  }

  build() {
    Stack() {
      Column() {
        this.HeaderBar()

        if (this.isCheckingAccess) {
          Column() {
            LoadingProgress().width(40).height(40).color(C.primary)
            Text('验证访问权限...').fontSize(FontSize.body).fontColor(C.textHint).margin({ top: Spacing.md })
          }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
        } else if (!this.isUserMember) {
          Column() {
            Text('🔒').fontSize(56).opacity(0.5)
            Text('无权访问').fontSize(FontSize.lg).fontWeight(FontWeight.Bold).fontColor(C.textPrimary).margin({ top: Spacing.md })
            Text('仅项目成员可以查看任务看板').fontSize(FontSize.sm).fontColor(C.textHint).margin({ top: Spacing.xs })
            Text('请先加入项目后再访问').fontSize(FontSize.sm).fontColor(C.textHint).margin({ top: Spacing.xs })
            Button('返回项目详情')
              .fontSize(FontSize.body).fontColor(Color.White).fontWeight(FontWeight.Medium)
              .backgroundColor(C.primary).borderRadius(BorderRadius.md).height(44)
              .padding({ left: Spacing.xl, right: Spacing.xl }).margin({ top: Spacing.lg })
              .onClick(() => { router.back() })
          }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
        } else {
          Scroll() {
            Row() {
              this.KanbanColumn('#FF6B35', this.todoTasks, STATUS_TODO, '待办')
              Divider().vertical(true).height('100%').color(C.divider).strokeWidth(0.5)
              this.KanbanColumn('#FFC53D', this.inProgressTasks, STATUS_IN_PROGRESS, '进行中')
              Divider().vertical(true).height('100%').color(C.divider).strokeWidth(0.5)
              this.KanbanColumn('#2ED573', this.doneTasks, STATUS_DONE, '已完成')
            }
            .height('100%')
          }
          .width('100%').layoutWeight(1)
          .scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
        }
      }
      .width('100%').height('100%').backgroundColor(C.bg)

      if (this.showCreateDialog && this.isUserMember) {
        this.CreateDialog()
      }

      if (this.showActionDialog) {
        this.ActionDialog()
      }

      if (this.isCreating) {
        Column() {
          LoadingProgress().width(48).height(48).color(C.primary)
        }
        .width('100%').height('100%').justifyContent(FlexAlign.Center)
        .backgroundColor(C.overlay)
      }
    }
    .width('100%').height('100%')
  }
}
