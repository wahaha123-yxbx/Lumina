import { PostModel } from '../model/PostModel'
import { CommentModel } from '../model/CommentModel'
import { StarDustRecord } from '../model/StarDustModel'
import { UserModel } from '../model/UserModel'
import { ProjectModel, TaskModel, ApplicationModel, MatchCandidate, MemberModel } from '../model/ProjectModel'

// --- 辅助工厂函数 ---

function makePost(
  id: string, title: string, content: string, authorId: string,
  authorName: string, tag: string, createTime: number, likeCount: number,
  commentCount: number, starDustCount: number, viewCount: number,
  isHot: boolean, isTop: boolean
): PostModel {
  const p = new PostModel()
  p.id = id; p.title = title; p.content = content; p.authorId = authorId
  p.authorName = authorName; p.tag = tag; p.createTime = createTime
  p.likeCount = likeCount; p.commentCount = commentCount
  p.starDustCount = starDustCount; p.viewCount = viewCount
  p.isHot = isHot; p.isTop = isTop
  return p
}

function makeComment(
  id: string, postId: string, content: string, authorId: string,
  authorName: string, likeCount: number, createTime: number
): CommentModel {
  const c = new CommentModel()
  c.id = id; c.postId = postId; c.content = content
  c.authorId = authorId; c.authorName = authorName
  c.likeCount = likeCount; c.createTime = createTime
  return c
}

function makeStarDustRecord(
  id: string, fromUserId: string, fromUserName: string, toUserId: string,
  toUserName: string, postId: string, postTitle: string, amount: number,
  message: string, createTime: number
): StarDustRecord {
  const r = new StarDustRecord()
  r.id = id; r.fromUserId = fromUserId; r.fromUserName = fromUserName
  r.toUserId = toUserId; r.toUserName = toUserName
  r.postId = postId; r.postTitle = postTitle; r.amount = amount
  r.message = message; r.createTime = createTime
  return r
}

function makeUser(
  id: string, nickname: string, campus: string, major: string,
  grade: string, balance: number, received: number, followers: number,
  posts: number
): UserModel {
  const u = new UserModel()
  u.id = id; u.nickname = nickname; u.campus = campus; u.major = major
  u.grade = grade; u.starDustBalance = balance
  u.totalStarDustReceived = received; u.followerCount = followers
  u.postCount = posts
  return u
}

// --- 模拟数据 ---

const now = Date.now()

const mockUsers: UserModel[] = [
  makeUser('u_001', '星尘旅人', '星光大学城', '计算机科学与技术', '大三', 250, 1680, 128, 23),
  makeUser('u_002', '图书馆小仙女', '星光大学城', '汉语言文学', '大二', 520, 3200, 256, 45),
  makeUser('u_003', '代码诗人', '星光大学城', '软件工程', '大四', 180, 8500, 512, 89),
  makeUser('u_004', '食堂美食家', '星光大学城', '食品科学', '大三', 320, 1200, 89, 34),
  makeUser('u_005', '操场小旋风', '星光大学城', '体育教育', '大二', 90, 450, 67, 15),
  makeUser('u_006', '实验室狂魔', '星光大学城', '化学工程', '研一', 680, 5200, 198, 56),
]

const mockPosts: PostModel[] = [
  makePost('p_001', '期末复习资料大合集！数理统计+线代重点笔记',
    '整理了一份超全的期末复习资料，包含数理统计的重点公式推导和线性代数的核心题型解析。需要的同学自取，祝大家期末顺利！',
    'u_003', '代码诗人', '学习', now - 1200000, 328, 56, 42, 2890, true, true),
  makePost('p_002', '二食堂新开的麻辣香锅也太好吃了吧！',
    '二食堂三楼新开的麻辣香锅绝了！人均25，量超多，口味可以自选。强烈安利微辣+孜然，配上冰可乐简直人间美味',
    'u_004', '食堂美食家', '安利', now - 3600000, 256, 89, 18, 1560, true, false),
  makePost('p_003', '图书馆四楼靠窗位置，有人约自习吗？',
    '最近在准备考研，每天泡图书馆。四楼靠窗第三个位置，阳光刚好，安静又舒服。有没有一起努力的小伙伴？互相监督打卡！',
    'u_002', '图书馆小仙女', '生活', now - 7200000, 180, 45, 12, 980, false, false),
  makePost('p_004', '【求助】选修课《Python数据分析》怎么样？',
    '选课系统马上开了，想问下上过《Python数据分析》的同学，这门课水不水？老师给分怎么样？平时作业多吗？求真实评价！',
    'u_001', '星尘旅人', '求助', now - 18000000, 95, 72, 5, 1230, false, false),
  makePost('p_005', '【技术分享】手把手教你搭建个人博客网站',
    '最近用Vue3 + Vite搭了个博客，感觉效果还不错。整理了一个从零开始的教程，包括项目初始化、路由配置、Markdown渲染、自动化部署。代码放在GitHub上了！',
    'u_003', '代码诗人', '技术', now - 86400000, 420, 68, 56, 3450, true, false),
  makePost('p_006', '操场晚上有人一起跑步吗？',
    '天气暖和了，想每天晚上8点去操场跑5公里。一个人有点难坚持，找几个小伙伴一起呀！男女不限，配速6分左右',
    'u_005', '操场小旋风', '活动', now - 14400000, 78, 34, 3, 560, false, false),
  makePost('p_007', '有没有人捡到一副白色AirPods？',
    '昨天下午在图书馆二楼自习区丢了一副白色AirPods，外壳有贴一个星星贴纸。捡到的同学请联系我，请你喝奶茶！',
    'u_001', '星尘旅人', '生活', now - 3600000, 45, 23, 0, 320, false, false),
  makePost('p_008', '大四学长给新生的30条建议【建议收藏】',
    '四年大学时光转瞬即逝，总结了30条血泪经验送给学弟学妹们：大一就开始规划职业方向、多参加竞赛和项目、别只学习也要社交...',
    'u_003', '代码诗人', '学习', now - 172800000, 890, 120, 128, 8900, true, false),
]

// 用 Map 代替 Record 对象字面量
const commentMap: Map<string, CommentModel[]> = new Map()
commentMap.set('p_001', [
  makeComment('c_001', 'p_001', '太及时了！正好在复习数理统计，感谢学长！', 'u_002', '图书馆小仙女', 23, now - 600000),
  makeComment('c_002', 'p_001', '线代部分写得太清楚了，茅塞顿开！', 'u_004', '食堂美食家', 15, now - 300000),
  makeComment('c_003', 'p_001', '可以加一个概率论的部分吗？', 'u_005', '操场小旋风', 8, now - 100000),
])
commentMap.set('p_002', [
  makeComment('c_004', 'p_002', '今天中午就去试试！', 'u_001', '星尘旅人', 5, now - 1800000),
  makeComment('c_005', 'p_002', '微辣+孜然yyds！姐妹口味和我一样！', 'u_002', '图书馆小仙女', 12, now - 900000),
])
commentMap.set('p_005', [
  makeComment('c_006', 'p_005', '太强了！已经Star了，准备跟着教程搭一个', 'u_004', '食堂美食家', 28, now - 43200000),
  makeComment('c_007', 'p_005', '请问可以出一个Docker部署的部分吗？', 'u_005', '操场小旋风', 10, now - 21600000),
])

const starDustRecords: StarDustRecord[] = [
  makeStarDustRecord('s_001', 'u_002', '图书馆小仙女', 'u_003', '代码诗人',
    'p_001', '期末复习资料大合集', 10, '太有帮助了！', now - 600000),
  makeStarDustRecord('s_002', 'u_004', '食堂美食家', 'u_003', '代码诗人',
    'p_005', '手把手教你搭建个人博客网站', 20, '学到了！', now - 43200000),
]

// --- MockDataService ---

// ==================== 项目协作 Mock 数据 ====================

function makeMember(userId: string, nickname: string, avatar: string, role: string): MemberModel {
  const m = new MemberModel()
  m.userId = userId; m.nickname = nickname; m.avatar = avatar; m.role = role
  m.joinTime = now - 86400000 * 7
  return m
}

function makeProject(
  id: string, title: string, desc: string, category: string, tags: string[],
  leaderId: string, leaderName: string, leaderAvatar: string,
  members: MemberModel[], maxMem: number, status: string,
  taskCnt: number, doneCnt: number, views: number, created: number
): ProjectModel {
  const p = new ProjectModel()
  p.id = id; p.title = title; p.description = desc; p.category = category
  p.tags = tags; p.leaderId = leaderId; p.leaderName = leaderName
  p.leaderAvatar = leaderAvatar; p.members = members; p.maxMembers = maxMem
  p.status = status; p.taskCount = taskCnt; p.completedTaskCount = doneCnt
  p.viewCount = views; p.createTime = created; p.updateTime = now
  return p
}

function makeTask(
  id: string, projId: string, title: string, desc: string,
  status: string, priority: string, assigneeId: string,
  assigneeName: string, assigneeAvatar: string, deadline: number
): TaskModel {
  const t = new TaskModel()
  t.id = id; t.projectId = projId; t.title = title; t.description = desc
  t.status = status; t.priority = priority
  t.assigneeId = assigneeId; t.assigneeName = assigneeName
  t.assigneeAvatar = assigneeAvatar; t.deadline = deadline
  t.createTime = now - 86400000; t.updateTime = now
  return t
}

const mockProjects: ProjectModel[] = [
  makeProject(
    'proj_mock_1', '基于深度学习的校园垃圾智能分类',
    '本项目拟基于HarmonyOS平台，开发一款集图像识别、分类引导、积分激励于一体的智能垃圾分类应用。需要熟悉深度学习模型部署、ArkUI开发的同学加入。',
    '科研学术', ['深度学习', 'Python', '鸿蒙'],
    'u_003', '代码诗人', '🐱',
    [makeMember('u_003', '代码诗人', '🐱', '队长'),
     makeMember('u_001', '星尘旅人', '◎', '成员')],
    4, 'recruiting', 8, 3, 230, now - 86400000 * 3
  ),
  makeProject(
    'proj_mock_2', '校园二手交易平台（鸿蒙版）',
    '做一个鸿蒙原生二手交易小程序，包含商品发布、搜索、即时通讯、线下交易等功能。后端用Node.js，前端ArkUI。',
    '创业实践', ['鸿蒙', 'ArkUI', 'Node.js'],
    'u_001', '星尘旅人', '◎',
    [makeMember('u_001', '星尘旅人', '◎', '队长')],
    3, 'recruiting', 6, 1, 180, now - 86400000 * 5
  ),
  makeProject(
    'proj_mock_3', '大学生竞赛信息聚合与组队平台',
    '爬取各大竞赛平台信息，为校内同学提供竞赛日历、往届经验分享、队友匹配等一站式服务。前端考虑用小程序或鸿蒙。',
    '竞赛比赛', ['爬虫', '小程序', 'React'],
    'u_006', '实验室狂魔', '🧪',
    [makeMember('u_006', '实验室狂魔', '🧪', '队长'),
     makeMember('u_002', '图书馆小仙女', '📚', '成员'),
     makeMember('u_005', '操场小旋风', '🏃', '成员')],
    5, 'active', 12, 5, 420, now - 86400000 * 10
  ),
  makeProject(
    'proj_mock_4', '共建科幻小说《星际灯塔》',
    '多人协作创作一部科幻小说，设定在2200年的银河系边缘。需要世界观构建、人物设计、章节撰写等分工协作，不需要技术背景，有想象力就行！',
    '兴趣创作', ['写作', '科幻', '共创'],
    'u_002', '图书馆小仙女', '📚',
    [makeMember('u_002', '图书馆小仙女', '📚', '队长')],
    4, 'recruiting', 10, 4, 310, now - 86400000 * 7
  ),
  makeProject(
    'proj_mock_5', '期末复习资料共享计划',
    '组织各专业学霸整理期末重点笔记、真题解析、思维导图，分类上传到平台共享。利用星尘激励机制鼓励贡献。',
    '课程项目', ['学习', '资源共享', '协作'],
    'u_004', '食堂美食家', '🍔',
    [makeMember('u_004', '食堂美食家', '🍔', '队长'),
     makeMember('u_003', '代码诗人', '🐱', '成员')],
    6, 'recruiting', 5, 2, 150, now - 86400000 * 2
  ),
  makeProject(
    'proj_mock_6', '校园活动报名签到系统',
    '为学校社团活动提供在线报名、扫码签到、数据统计等服务。鸿蒙端用NFC能力实现一碰签到。',
    '课程项目', ['鸿蒙', 'NFC', 'ArkUI'],
    'u_005', '操场小旋风', '🏃',
    [makeMember('u_005', '操场小旋风', '🏃', '队长')],
    3, 'recruiting', 4, 0, 90, now - 86400000
  ),
]

// 按 projectId 存储的任务 Map
const taskMap: Map<string, TaskModel[]> = new Map()
taskMap.set('proj_mock_1', [
  makeTask('task_m1_1', 'proj_mock_1', '收集训练数据集', '需要标注5000张校园垃圾图片', 'done', 'high',
    'u_001', '星尘旅人', '◎', now + 86400000 * 3),
  makeTask('task_m1_2', 'proj_mock_1', '模型训练与调参', '基于ResNet进行迁移学习', 'inProgress', 'high',
    'u_003', '代码诗人', '🐱', now + 86400000 * 14),
  makeTask('task_m1_3', 'proj_mock_1', '前端UI设计', '设计垃圾分类拍照页面', 'inProgress', 'medium',
    '', '未分配', '', now + 86400000 * 10),
  makeTask('task_m1_4', 'proj_mock_1', 'API接口开发', '后端模型推理接口', 'todo', 'high',
    '', '未分配', '', now + 86400000 * 20),
  makeTask('task_m1_5', 'proj_mock_1', '积分系统设计', '垃圾正确分类获得积分', 'todo', 'medium',
    '', '未分配', '', now + 86400000 * 25),
  makeTask('task_m1_6', 'proj_mock_1', '用户反馈收集', '收集首批测试用户意见', 'todo', 'low',
    '', '未分配', '', now + 86400000 * 30),
  makeTask('task_m1_7', 'proj_mock_1', '部署测试环境', '在服务器上部署', 'done', 'urgent',
    'u_003', '代码诗人', '🐱', 0),
  makeTask('task_m1_8', 'proj_mock_1', '编写项目文档', '', 'done', 'low',
    'u_001', '星尘旅人', '◎', 0),
])
taskMap.set('proj_mock_3', [
  makeTask('task_m3_1', 'proj_mock_3', '爬虫框架搭建', '基于Puppeteer爬取竞赛信息', 'done', 'high',
    'u_006', '实验室狂魔', '🧪', 0),
  makeTask('task_m3_2', 'proj_mock_3', '数据清洗与入库', '对爬取数据进行结构化清洗', 'done', 'high',
    'u_002', '图书馆小仙女', '📚', 0),
  makeTask('task_m3_3', 'proj_mock_3', '前端首页开发', '竞赛日历视图', 'inProgress', 'high',
    'u_005', '操场小旋风', '🏃', now + 86400000 * 5),
  makeTask('task_m3_4', 'proj_mock_3', '用户系统开发', '注册登录+个人信息', 'inProgress', 'medium',
    'u_006', '实验室狂魔', '🧪', now + 86400000 * 10),
  makeTask('task_m3_5', 'proj_mock_3', '组队匹配功能', '基于标签的匹配算法', 'done', 'urgent',
    'u_006', '实验室狂魔', '🧪', 0),
  makeTask('task_m3_6', 'proj_mock_3', '消息通知系统', 'WebSocket实时推送', 'done', 'medium',
    'u_002', '图书馆小仙女', '📚', 0),
  makeTask('task_m3_7', 'proj_mock_3', '搜索功能', '全文检索竞赛信息', 'done', 'medium',
    'u_005', '操场小旋风', '🏃', 0),
  makeTask('task_m3_8', 'proj_mock_3', '移动端适配', '响应式布局调试', 'todo', 'medium',
    '', '未分配', '', now + 86400000 * 15),
  makeTask('task_m3_9', 'proj_mock_3', '性能优化', '首屏加载优化', 'todo', 'low',
    '', '未分配', '', now + 86400000 * 20),
  makeTask('task_m3_10', 'proj_mock_3', '测试用例编写', '', 'todo', 'medium',
    '', '未分配', '', now + 86400000 * 12),
  makeTask('task_m3_11', 'proj_mock_3', 'UI设计稿评审', '', 'inProgress', 'low',
    'u_002', '图书馆小仙女', '📚', now + 86400000 * 3),
  makeTask('task_m3_12', 'proj_mock_3', '上线部署', '', 'todo', 'high',
    '', '未分配', '', now + 86400000 * 30),
])

const mockApplications: ApplicationModel[] = []

const mockMatchCandidates: MatchCandidate[] = [
  { userId: 'u_005', nickname: '操场小旋风', avatar: '🏃', bio: '体育教育专业，但对AI也很感兴趣', major: '体育教育', level: 2, levelTitle: '星尘学徒', projectCount: 1, matchScore: 5 } as MatchCandidate,
  { userId: 'u_006', nickname: '实验室狂魔', avatar: '🧪', bio: '化学工程研一，熟悉Python和机器学习', major: '化学工程', level: 4, levelTitle: '星光使者', projectCount: 1, matchScore: 4 } as MatchCandidate,
  { userId: 'u_004', nickname: '食堂美食家', avatar: '🍔', bio: '食品科学专业，会一点前端', major: '食品科学', level: 3, levelTitle: '星辰旅者', projectCount: 1, matchScore: 2 } as MatchCandidate,
]

// ==================== Mock 项目服务 ====================

export class MockProjectService {
  static getProjects(category?: string): ProjectModel[] {
    const list: ProjectModel[] = []
    for (let i = 0; i < mockProjects.length; i++) {
      if (!category || category === '全部' || mockProjects[i].category === category) {
        list.push(mockProjects[i])
      }
    }
    list.sort((a, b) => {
      if (a.status === 'recruiting' && b.status !== 'recruiting') return -1
      if (a.status !== 'recruiting' && b.status === 'recruiting') return 1
      return b.updateTime - a.updateTime
    })
    return list
  }

  static getProjectById(id: string): ProjectModel | undefined {
    for (let i = 0; i < mockProjects.length; i++) {
      if (mockProjects[i].id === id) return mockProjects[i]
    }
    return undefined
  }

  static getHotProjects(limit: number = 3): ProjectModel[] {
    const recruiting: ProjectModel[] = []
    for (let i = 0; i < mockProjects.length; i++) {
      if (mockProjects[i].status === 'recruiting') recruiting.push(mockProjects[i])
    }
    recruiting.sort((a, b) => b.viewCount - a.viewCount)
    const result: ProjectModel[] = []
    const count = limit < recruiting.length ? limit : recruiting.length
    for (let i = 0; i < count; i++) result.push(recruiting[i])
    return result
  }

  static getNewProjects(limit: number = 3): ProjectModel[] {
    const sorted: ProjectModel[] = []
    for (let i = 0; i < mockProjects.length; i++) sorted.push(mockProjects[i])
    sorted.sort((a, b) => b.createTime - a.createTime)
    const result: ProjectModel[] = []
    const count = limit < sorted.length ? limit : sorted.length
    for (let i = 0; i < count; i++) result.push(sorted[i])
    return result
  }

  static getTasksByProject(projectId: string): TaskModel[] {
    return taskMap.get(projectId) || []
  }

  static getMatchCandidates(): MatchCandidate[] {
    return mockMatchCandidates
  }

  static getMyProjects(userId: string): ProjectModel[] {
    const result: ProjectModel[] = []
    for (let i = 0; i < mockProjects.length; i++) {
      const p = mockProjects[i]
      let found = false
      for (let j = 0; j < p.members.length; j++) {
        if (p.members[j].userId === userId) { found = true; break }
      }
      if (found) result.push(p)
    }
    return result
  }
}

// ==================== MockDataService (原有) ====================

export class MockDataService {
  static getHomePosts(): PostModel[] {
    const result: PostModel[] = []
    for (let i = 0; i < mockPosts.length; i++) {
      result.push(mockPosts[i])
    }
    result.sort((a: PostModel, b: PostModel) => b.createTime - a.createTime)
    return result
  }

  static getHotPosts(): PostModel[] {
    const result: PostModel[] = []
    for (let i = 0; i < mockPosts.length; i++) {
      result.push(mockPosts[i])
    }
    result.sort((a: PostModel, b: PostModel) => {
      const hotA = a.likeCount * 2 + a.commentCount * 3 + a.starDustCount * 5 + a.viewCount * 0.1
      const hotB = b.likeCount * 2 + b.commentCount * 3 + b.starDustCount * 5 + b.viewCount * 0.1
      return hotB - hotA
    })
    return result
  }

  static getPostById(id: string): PostModel | undefined {
    for (let i = 0; i < mockPosts.length; i++) {
      if (mockPosts[i].id === id) {
        return mockPosts[i]
      }
    }
    return undefined
  }

  static getCommentsByPostId(postId: string): CommentModel[] {
    const result = commentMap.get(postId)
    if (result) {
      return result
    }
    return []
  }

  static getStarDustRecordsByUserId(userId: string): StarDustRecord[] {
    const result: StarDustRecord[] = []
    for (let i = 0; i < starDustRecords.length; i++) {
      const r = starDustRecords[i]
      if (r.toUserId === userId || r.fromUserId === userId) {
        result.push(r)
      }
    }
    return result
  }

  static getPostsByTag(tag: string): PostModel[] {
    const result: PostModel[] = []
    for (let i = 0; i < mockPosts.length; i++) {
      if (tag === '全部' || mockPosts[i].tag === tag) {
        result.push(mockPosts[i])
      }
    }
    return result
  }

  static addStarDustRecord(record: StarDustRecord): void {
    starDustRecords.push(record)
  }

  static getStarDustRecords(): StarDustRecord[] {
    return starDustRecords
  }
}
