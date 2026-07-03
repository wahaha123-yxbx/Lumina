import { ApiClient } from './ApiClient'
import { UserModel, LoginUserData } from '../model/UserModel'
import { StarDustRecord } from '../model/StarDustModel'
import { PostModel } from '../model/PostModel'

// --- 请求参数 DTO 类 ---

class LoginBody {
  studentId: string = ''
  password: string = ''
}

class RegisterBody {
  studentId: string = ''
  password: string = ''
  nickname: string = ''
}

class AuthResult {
  token: string = ''
  user: UserModel | null = null
  message: string = ''
}

export class LoginResult {
  success: boolean = false
  data: LoginUserData | null = null
  message: string = ''
}

class UpdateAvatarBody {
  avatar: string = ''
}

class UpdateUserBody {
  nickname: string = ''
  bio: string = ''
  campus: string = ''
  major: string = ''
  grade: string = ''
}

class CheckInResult {
  balance: number = 0
}

/**
 * 用户相关 API
 */
export class UserApi {
  /**
   * 学号 + 密码登录
   */
  static async login(studentId: string, password: string): Promise<LoginResult> {
    const result = new LoginResult()
    const body = new LoginBody()
    body.studentId = studentId
    body.password = password
    const res = await ApiClient.post<AuthResult>('/api/auth/login', body)
    if (res.code === 0 && res.data) {
      ApiClient.authToken = res.data.token
      if (res.data.user) {
        result.success = true
        result.data = UserApi.mapToLoginData(res.data.user)
        result.message = res.message || '登录成功'
        return result
      }
    }
    result.message = res.message || '登录失败，请检查学号和密码'
    return result
  }

  /**
   * 注册
   */
  static async register(studentId: string, password: string, nickname: string): Promise<LoginResult> {
    const result = new LoginResult()
    const body = new RegisterBody()
    body.studentId = studentId
    body.password = password
    body.nickname = nickname
    const res = await ApiClient.post<AuthResult>('/api/auth/register', body)
    if (res.code === 0 && res.data) {
      ApiClient.authToken = res.data.token
      if (res.data.user) {
        result.success = true
        result.data = UserApi.mapToLoginData(res.data.user)
        result.message = '注册成功'
        return result
      }
    }
    result.message = res.message || '注册失败，请重试'
    return result
  }

  static async getUserById(id: string): Promise<UserModel | undefined> {
    const res = await ApiClient.get<UserModel>('/api/users/' + id)
    if (res.code === 0 && res.data) {
      return UserApi.mapUser(res.data)
    }
    return undefined
  }

  static async updateAvatar(id: string, avatar: string): Promise<boolean> {
    const body = new UpdateAvatarBody()
    body.avatar = avatar
    const res = await ApiClient.put<UpdateAvatarBody>('/api/users/' + id, body)
    return res.code === 0
  }

  static async updateUser(id: string, nickname: string, bio: string, campus: string = '', major: string = '', grade: string = ''): Promise<UserModel | undefined> {
    const body = new UpdateUserBody()
    body.nickname = nickname
    body.bio = bio
    body.campus = campus
    body.major = major
    body.grade = grade
    const res = await ApiClient.put<UserModel>('/api/users/' + id, body)
    if (res.code === 0 && res.data) {
      return UserApi.mapUser(res.data)
    }
    return undefined
  }

  static async checkIn(id: string): Promise<number> {
    const res = await ApiClient.post<CheckInResult>('/api/users/' + id + '/checkin')
    if (res.code === 0 && res.data) {
      return res.data.balance
    }
    return -1
  }

  static async getUserPosts(id: string): Promise<PostModel[]> {
    const res = await ApiClient.get<PostModel[]>('/api/users/' + id + '/posts')
    if (res.code === 0 && res.data) {
      return res.data
    }
    return []
  }

  static async getRewardRecords(userId: string): Promise<StarDustRecord[]> {
    const res = await ApiClient.get<StarDustRecord[]>('/api/users/' + userId + '/rewards')
    if (res.code === 0 && res.data) {
      return res.data
    }
    return []
  }

  private static mapToLoginData(raw: UserModel): LoginUserData {
    const d = new LoginUserData()
    d.id = raw.id
    d.nickname = raw.nickname
    d.avatar = raw.avatar
    d.bio = raw.bio
    d.campus = raw.campus
    d.major = raw.major
    d.grade = raw.grade
    d.starDustBalance = raw.starDustBalance
    d.totalStarDustReceived = raw.totalStarDustReceived
    d.postCount = raw.postCount
    d.followingCount = raw.followingCount
    d.followerCount = raw.followerCount
    d.joinDate = raw.joinDate
    return d
  }

  private static mapUser(raw: UserModel): UserModel {
    const u = new UserModel()
    u.id = raw.id
    u.username = raw.username
    u.nickname = raw.nickname
    u.avatar = raw.avatar
    u.bio = raw.bio
    u.campus = raw.campus
    u.major = raw.major
    u.grade = raw.grade
    u.starDustBalance = raw.starDustBalance
    u.totalStarDustReceived = raw.totalStarDustReceived
    u.postCount = raw.postCount
    u.followingCount = raw.followingCount
    u.followerCount = raw.followerCount
    u.level = raw.level
    u.levelTitle = raw.levelTitle
    return u
  }
}
