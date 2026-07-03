import { PostModel } from '../model/PostModel'
import { CommentModel } from '../model/CommentModel'
import { StarDustRecord } from '../model/StarDustModel'
import { UserModel } from '../model/UserModel'

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
