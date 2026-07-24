/**
 * 项目/任务/申请 数据模型
 */

// ---- 团队成员 ----
export class MemberModel {
  userId: string = ''
  nickname: string = ''
  avatar: string = ''
  role: string = ''      // '队长' | '成员'
  joinTime: number = 0
}

// ---- 项目 ----
export class ProjectModel {
  id: string = ''
  title: string = ''
  description: string = ''
  category: string = '科研学术'
  tags: string[] = []
  leaderId: string = ''
  leaderName: string = ''
  leaderAvatar: string = ''
  members: MemberModel[] = []
  maxMembers: number = 5
  status: string = 'recruiting'
  taskCount: number = 0
  completedTaskCount: number = 0
  viewCount: number = 0
  createTime: number = Date.now()
  updateTime: number = Date.now()

  /** 人数进度百分比 */
  getMemberPercent(): number {
    if (this.maxMembers <= 0) return 100
    return Math.min(100, Math.round(this.members.length / this.maxMembers * 100))
  }

  /** 任务进度百分比 */
  getTaskPercent(): number {
    if (this.taskCount <= 0) return 0
    return Math.min(100, Math.round(this.completedTaskCount / this.taskCount * 100))
  }

  /** 状态标签文本 */
  getStatusLabel(): string {
    switch (this.status) {
      case 'recruiting': return '招募中'
      case 'active': return '进行中'
      case 'completed': return '已完成'
      default: return this.status
    }
  }

  /** 状态标签颜色 */
  getStatusColor(): string {
    switch (this.status) {
      case 'recruiting': return '#FF6B35'
      case 'active': return '#2ED573'
      case 'completed': return '#999999'
      default: return '#999999'
    }
  }

  getFormattedTime(): string {
    const diff = Date.now() - this.createTime
    const day = 86400000
    if (diff < day) return '今天'
    if (diff < 2 * day) return '昨天'
    if (diff < 7 * day) return Math.floor(diff / day) + '天前'
    const d = new Date(this.createTime)
    return (d.getMonth() + 1) + '/' + d.getDate()
  }
}

// ---- 任务 ----
export class TaskModel {
  id: string = ''
  projectId: string = ''
  title: string = ''
  description: string = ''
  status: string = 'todo'       // 'todo' | 'inProgress' | 'done'
  priority: string = 'medium'   // 'low' | 'medium' | 'high' | 'urgent'
  assigneeId: string = ''
  assigneeName: string = '未分配'
  assigneeAvatar: string = ''
  deadline: number = 0
  createTime: number = Date.now()
  updateTime: number = Date.now()

  getStatusLabel(): string {
    switch (this.status) {
      case 'todo': return '待办'
      case 'inProgress': return '进行中'
      case 'done': return '已完成'
      default: return this.status
    }
  }

  getPriorityLabel(): string {
    switch (this.priority) {
      case 'low': return '低'
      case 'medium': return '中'
      case 'high': return '高'
      case 'urgent': return '紧急'
      default: return this.priority
    }
  }

  getPriorityColor(): string {
    switch (this.priority) {
      case 'low': return '#2ED573'
      case 'medium': return '#FFC53D'
      case 'high': return '#FF6B35'
      case 'urgent': return '#FF4757'
      default: return '#999999'
    }
  }

  getDeadlineText(): string {
    if (!this.deadline) return ''
    const d = new Date(this.deadline)
    return (d.getMonth() + 1) + '/' + d.getDate()
  }
}

// ---- 申请 ----
export class ApplicationModel {
  id: string = ''
  projectId: string = ''
  projectTitle: string = ''
  userId: string = ''
  userName: string = ''
  userAvatar: string = ''
  message: string = ''
  status: string = 'pending'   // 'pending' | 'approved' | 'rejected'
  createTime: number = Date.now()

  getStatusLabel(): string {
    switch (this.status) {
      case 'pending': return '待审核'
      case 'approved': return '已通过'
      case 'rejected': return '已拒绝'
      default: return this.status
    }
  }
}

// ---- 匹配候选人 ----
export class MatchCandidate {
  userId: string = ''
  nickname: string = ''
  avatar: string = ''
  bio: string = ''
  major: string = ''
  level: number = 1
  levelTitle: string = ''
  projectCount: number = 0
  matchScore: number = 0
}

// ---- 发现流结果 ----
export class DiscoverResult {
  hotProjects: ProjectModel[] = []
  newProjects: ProjectModel[] = []
  hotPosts: Object[] = []
}

// ---- 项目分类 ----
export const ProjectCategories: string[] = [
  '全部', '科研学术', '竞赛比赛', '兴趣创作', '创业实践', '课程项目'
]

// ---- 分类颜色 ----
export function getCategoryColor(cat: string): string {
  switch (cat) {
    case '科研学术': return '#2E7D32'
    case '竞赛比赛': return '#0277BD'
    case '兴趣创作': return '#6A1B9A'
    case '创业实践': return '#E65100'
    case '课程项目': return '#00838F'
    default: return '#0066FF'
  }
}
