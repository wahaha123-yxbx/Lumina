import { ApiClient } from './ApiClient'
import {
  ProjectModel, TaskModel, ApplicationModel,
  MatchCandidate, DiscoverResult, MemberModel
} from '../model/ProjectModel'

// --- DTO 类 ---

class CreateProjectBody {
  title: string = ''
  description: string = ''
  category: string = ''
  leaderId: string = ''
  tags: string[] = []
  maxMembers: number = 5
}

export class UpdateProjectBody {
  title: string = ''
  description: string = ''
  category: string = ''
  tags: string[] = []
  maxMembers: number = 5
  status: string = ''
}

class CreateTaskBody {
  title: string = ''
  description: string = ''
  assigneeId: string = ''
  priority: string = 'medium'
  deadline: number = 0
}

export class UpdateTaskBody {
  title: string = ''
  description: string = ''
  status: string = ''
  assigneeId: string = ''
  priority: string = ''
  deadline: number = 0
}

class ApplyBody {
  userId: string = ''
  message: string = ''
}

class ApproveBody {
  status: string = ''
}

/**
 * 项目 / 任务 / 招募 API
 * 风格与 PostApi / UserApi 保持一致
 */
export class ProjectApi {

  // ==================== 项目管理 ====================

  static async getProjects(category?: string, status?: string): Promise<ProjectModel[]> {
    let url = '/api/projects'
    const params: string[] = []
    if (category && category !== '全部') params.push('category=' + category)
    if (status) params.push('status=' + status)
    if (params.length > 0) url += '?' + params.join('&')

    const res = await ApiClient.get<ProjectModel[]>(url)
    if (res.code === 0 && res.data) {
      return ProjectApi.mapProjects(res.data)
    }
    return []
  }

  static async getProjectById(id: string): Promise<ProjectModel | undefined> {
    const res = await ApiClient.get<ProjectModel>('/api/projects/' + id)
    if (res.code === 0 && res.data) {
      return ProjectApi.mapProject(res.data)
    }
    return undefined
  }

  static async createProject(
    title: string, description: string, category: string,
    leaderId: string, tags: string[], maxMembers: number
  ): Promise<ProjectModel | undefined> {
    const body = new CreateProjectBody()
    body.title = title
    body.description = description
    body.category = category
    body.leaderId = leaderId
    body.tags = tags
    body.maxMembers = maxMembers

    const res = await ApiClient.post<ProjectModel>('/api/projects', body)
    if (res.code === 0 && res.data) {
      return ProjectApi.mapProject(res.data)
    }
    return undefined
  }

  static async updateProject(id: string, fields: UpdateProjectBody): Promise<ProjectModel | undefined> {
    const res = await ApiClient.put<ProjectModel>('/api/projects/' + id, fields)
    if (res.code === 0 && res.data) {
      return ProjectApi.mapProject(res.data)
    }
    return undefined
  }

  static async deleteProject(id: string): Promise<boolean> {
    const res = await ApiClient.delete<Object>('/api/projects/' + id)
    return res.code === 0
  }

  // ==================== 任务管理 ====================

  static async getTasks(projectId: string): Promise<TaskModel[]> {
    const res = await ApiClient.get<TaskModel[]>('/api/projects/' + projectId + '/tasks')
    if (res.code === 0 && res.data) {
      return ProjectApi.mapTasks(res.data)
    }
    return []
  }

  static async createTask(
    projectId: string, title: string, description: string,
    assigneeId: string, priority: string, deadline: number
  ): Promise<TaskModel | undefined> {
    const body = new CreateTaskBody()
    body.title = title
    body.description = description
    body.assigneeId = assigneeId
    body.priority = priority
    body.deadline = deadline

    const res = await ApiClient.post<TaskModel>('/api/projects/' + projectId + '/tasks', body)
    if (res.code === 0 && res.data) {
      return res.data
    }
    return undefined
  }

  static async updateTask(taskId: string, updates: UpdateTaskBody): Promise<TaskModel | undefined> {
    const res = await ApiClient.put<TaskModel>('/api/tasks/' + taskId, updates)
    if (res.code === 0 && res.data) {
      return res.data
    }
    return undefined
  }

  static async deleteTask(taskId: string): Promise<boolean> {
    const res = await ApiClient.delete<Object>('/api/tasks/' + taskId)
    return res.code === 0
  }

  // ==================== 队员招募 ====================

  static async applyProject(projectId: string, userId: string, message: string): Promise<ApplicationModel | undefined> {
    const body = new ApplyBody()
    body.userId = userId
    body.message = message

    const res = await ApiClient.post<ApplicationModel>('/api/projects/' + projectId + '/apply', body)
    if (res.code === 0 && res.data) {
      return res.data
    }
    return undefined
  }

  static async getApplications(projectId: string): Promise<ApplicationModel[]> {
    const res = await ApiClient.get<ApplicationModel[]>('/api/projects/' + projectId + '/applications')
    if (res.code === 0 && res.data) {
      return res.data
    }
    return []
  }

  static async approveApplication(appId: string, status: string): Promise<ApplicationModel | undefined> {
    const body = new ApproveBody()
    body.status = status
    const res = await ApiClient.put<ApplicationModel>('/api/applications/' + appId, body)
    if (res.code === 0 && res.data) {
      return res.data
    }
    return undefined
  }

  static async getMyApplications(userId: string): Promise<ApplicationModel[]> {
    const res = await ApiClient.get<ApplicationModel[]>('/api/users/' + userId + '/applications')
    if (res.code === 0 && res.data) {
      return res.data
    }
    return []
  }

  static async getMyProjects(userId: string): Promise<ProjectModel[]> {
    const res = await ApiClient.get<ProjectModel[]>('/api/users/' + userId + '/projects')
    if (res.code === 0 && res.data) {
      return ProjectApi.mapProjects(res.data)
    }
    return []
  }

  // ==================== AI 匹配 ====================

  static async getMatchCandidates(projectId: string): Promise<MatchCandidate[]> {
    const res = await ApiClient.get<MatchCandidate[]>('/api/projects/' + projectId + '/match')
    if (res.code === 0 && res.data) {
      return res.data
    }
    return []
  }

  static async getRecommendProjects(userId: string): Promise<ProjectModel[]> {
    const res = await ApiClient.get<ProjectModel[]>('/api/users/' + userId + '/recommend-projects')
    if (res.code === 0 && res.data) {
      return res.data
    }
    return []
  }

  // ==================== 发现流 ====================

  static async getDiscover(): Promise<DiscoverResult | undefined> {
    const res = await ApiClient.get<DiscoverResult>('/api/discover')
    if (res.code === 0 && res.data) {
      const d = new DiscoverResult()
      if (res.data.hotProjects) d.hotProjects = ProjectApi.mapProjects(res.data.hotProjects)
      if (res.data.newProjects) d.newProjects = ProjectApi.mapProjects(res.data.newProjects)
      if (res.data.hotPosts) d.hotPosts = res.data.hotPosts
      return d
    }
    return undefined
  }

  // ==================== 内部映射 ====================

  private static mapProject(raw: ProjectModel): ProjectModel {
    const p = new ProjectModel()
    p.id = raw.id; p.title = raw.title; p.description = raw.description
    p.category = raw.category; p.tags = raw.tags || []
    p.leaderId = raw.leaderId; p.leaderName = raw.leaderName; p.leaderAvatar = raw.leaderAvatar
    p.members = raw.members || []; p.maxMembers = raw.maxMembers
    p.status = raw.status; p.taskCount = raw.taskCount || 0
    p.completedTaskCount = raw.completedTaskCount || 0
    p.viewCount = raw.viewCount || 0
    p.createTime = raw.createTime; p.updateTime = raw.updateTime
    return p
  }

  private static mapProjects(rawList: ProjectModel[]): ProjectModel[] {
    const result: ProjectModel[] = []
    for (let i = 0; i < rawList.length; i++) {
      result.push(ProjectApi.mapProject(rawList[i]))
    }
    return result
  }

  private static mapTask(raw: TaskModel): TaskModel {
    const t = new TaskModel()
    t.id = raw.id; t.projectId = raw.projectId
    t.title = raw.title; t.description = raw.description
    t.status = raw.status; t.priority = raw.priority
    t.assigneeId = raw.assigneeId; t.assigneeName = raw.assigneeName
    t.assigneeAvatar = raw.assigneeAvatar; t.deadline = raw.deadline
    t.createTime = raw.createTime; t.updateTime = raw.updateTime
    return t
  }

  private static mapTasks(rawList: TaskModel[]): TaskModel[] {
    const result: TaskModel[] = []
    for (let i = 0; i < rawList.length; i++) {
      result.push(ProjectApi.mapTask(rawList[i]))
    }
    return result
  }
}
