/**
 * 用户数据模型
 */
export class UserModel {
  id: string = ''
  username: string = ''
  nickname: string = ''
  avatar: string = ''
  bio: string = ''
  campus: string = ''
  major: string = ''
  grade: string = ''
  starDustBalance: number = 100
  totalStarDustReceived: number = 0
  postCount: number = 0
  followingCount: number = 0
  followerCount: number = 0
  joinDate: number = Date.now()
  level: number = 1
  levelTitle: string = '星尘新芽'
  skills: string[] = []
  email: string = ''
  projectCount: number = 0

  calculateLevel(): void {
    const dust = this.totalStarDustReceived
    if (dust >= 10000) { this.level = 6; this.levelTitle = '星海领主' }
    else if (dust >= 5000) { this.level = 5; this.levelTitle = '星尘大师' }
    else if (dust >= 2000) { this.level = 4; this.levelTitle = '星光使者' }
    else if (dust >= 500) { this.level = 3; this.levelTitle = '星辰旅者' }
    else if (dust >= 100) { this.level = 2; this.levelTitle = '星尘学徒' }
    else { this.level = 1; this.levelTitle = '星尘新芽' }
  }

  getLevelStars(): number {
    return Math.min(this.level, 6)
  }

  /**
   * 重置为未登录状态
   */
  reset(): void {
    this.id = ''
    this.username = ''
    this.nickname = ''
    this.avatar = ''
    this.bio = ''
    this.campus = ''
    this.major = ''
    this.grade = ''
    this.starDustBalance = 100
    this.totalStarDustReceived = 0
    this.postCount = 0
    this.followingCount = 0
    this.followerCount = 0
    this.joinDate = Date.now()
    this.level = 1
    this.levelTitle = '星尘新芽'
    this.skills = []
    this.email = ''
    this.projectCount = 0
  }
}

/**
 * 登录时用于传递用户数据的 DTO
 */
export class LoginUserData {
  id: string = ''
  nickname: string = ''
  avatar: string = ''
  bio: string = ''
  campus: string = ''
  major: string = ''
  grade: string = ''
  starDustBalance: number = -1
  totalStarDustReceived: number = -1
  postCount: number = -1
  followingCount: number = -1
  followerCount: number = -1
  joinDate: number = -1
  level: number = -1
  levelTitle: string = ''
  skills: string[] = []
  email: string = ''
  projectCount: number = -1
}

/**
 * 当前登录用户（全局单例）
 */
export let CurrentUser: UserModel = new UserModel()

/**
 * 登录成功后更新当前用户
 * @param data 后端返回的用户信息，至少包含 id
 */
export function loginCurrentUser(data: LoginUserData): void {
  CurrentUser.reset()
  if (data.id) CurrentUser.id = data.id
  if (data.nickname) CurrentUser.nickname = data.nickname
  if (data.avatar) CurrentUser.avatar = data.avatar
  if (data.bio) CurrentUser.bio = data.bio
  if (data.campus) CurrentUser.campus = data.campus
  if (data.major) CurrentUser.major = data.major
  if (data.grade) CurrentUser.grade = data.grade
  if (data.starDustBalance >= 0) CurrentUser.starDustBalance = data.starDustBalance
  if (data.totalStarDustReceived >= 0) CurrentUser.totalStarDustReceived = data.totalStarDustReceived
  if (data.postCount >= 0) CurrentUser.postCount = data.postCount
  if (data.followingCount >= 0) CurrentUser.followingCount = data.followingCount
  if (data.followerCount >= 0) CurrentUser.followerCount = data.followerCount
  if (data.joinDate >= 0) CurrentUser.joinDate = data.joinDate
  if (data.skills && data.skills.length > 0) CurrentUser.skills = data.skills
  if (data.email) CurrentUser.email = data.email
  if (data.projectCount >= 0) CurrentUser.projectCount = data.projectCount
  CurrentUser.calculateLevel()
}

/**
 * 检查是否已登录
 */
export function isUserLoggedIn(): boolean {
  return CurrentUser.id !== ''
}
