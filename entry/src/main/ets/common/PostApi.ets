import { ApiClient } from './ApiClient'
import { PostModel } from '../model/PostModel'
import { CommentModel } from '../model/CommentModel'
import { StarDustRecord } from '../model/StarDustModel'

// --- 请求参数 DTO 类（ArkTS 要求显式类型） ---

class PublishPostBody {
  title: string = ''
  content: string = ''
  authorId: string = ''
  tag: string = ''
  images: string[] = []
}

class ToggleLikeBody {
  userId: string = ''
}

class LikeResult {
  isLiked: boolean = false
  likeCount: number = 0
}

class AddCommentBody {
  content: string = ''
  authorId: string = ''
}

class RewardBody {
  fromUserId: string = ''
  amount: number = 0
  message: string = ''
}

/**
 * 帖子相关 API
 */
export class PostApi {
  static async getPosts(tag?: string): Promise<PostModel[]> {
    let url = '/api/posts'
    if (tag && tag !== '全部') {
      url += '?tag=' + tag
    }
    const res = await ApiClient.get<PostModel[]>(url)
    if (res.code === 0 && res.data) {
      return PostApi.mapPosts(res.data)
    }
    return []
  }

  static async getHotPosts(): Promise<PostModel[]> {
    const res = await ApiClient.get<PostModel[]>('/api/posts/hot')
    if (res.code === 0 && res.data) {
      return PostApi.mapPosts(res.data)
    }
    return []
  }

  static async getPostById(id: string): Promise<PostModel | undefined> {
    const res = await ApiClient.get<PostModel>('/api/posts/' + id)
    if (res.code === 0 && res.data) {
      return PostApi.mapPost(res.data)
    }
    return undefined
  }

  static async publishPost(title: string, content: string, authorId: string, tag: string, images: string[] = []): Promise<PostModel | undefined> {
    const body = new PublishPostBody()
    body.title = title
    body.content = content
    body.authorId = authorId
    body.tag = tag
    body.images = images
    const res = await ApiClient.post<PostModel>('/api/posts', body)
    if (res.code === 0 && res.data) {
      return PostApi.mapPost(res.data)
    }
    return undefined
  }

  static async toggleLike(postId: string, userId: string): Promise<LikeResult | undefined> {
    const body = new ToggleLikeBody()
    body.userId = userId
    const res = await ApiClient.post<LikeResult>('/api/posts/' + postId + '/like', body)
    if (res.code === 0 && res.data) {
      return res.data
    }
    return undefined
  }

  static async getComments(postId: string): Promise<CommentModel[]> {
    const res = await ApiClient.get<CommentModel[]>('/api/posts/' + postId + '/comments')
    if (res.code === 0 && res.data) {
      return PostApi.mapComments(res.data)
    }
    return []
  }

  static async addComment(postId: string, content: string, authorId: string): Promise<CommentModel | undefined> {
    const body = new AddCommentBody()
    body.content = content
    body.authorId = authorId
    const res = await ApiClient.post<CommentModel>('/api/posts/' + postId + '/comments', body)
    if (res.code === 0 && res.data) {
      return PostApi.mapComment(res.data)
    }
    return undefined
  }

  static async rewardPost(postId: string, fromUserId: string, amount: number, message: string): Promise<StarDustRecord | undefined> {
    const body = new RewardBody()
    body.fromUserId = fromUserId
    body.amount = amount
    body.message = message
    const res = await ApiClient.post<StarDustRecord>('/api/posts/' + postId + '/reward', body)
    if (res.code === 0 && res.data) {
      return res.data
    }
    return undefined
  }

  static async search(keyword: string): Promise<PostModel[]> {
    const res = await ApiClient.get<PostModel[]>('/api/search?q=' + keyword)
    if (res.code === 0 && res.data) {
      return PostApi.mapPosts(res.data)
    }
    return []
  }

  // --- 内部映射方法 ---

  private static mapPost(raw: PostModel): PostModel {
    const p = new PostModel()
    p.id = raw.id
    p.title = raw.title
    p.content = raw.content
    p.images = raw.images || []
    p.authorId = raw.authorId
    p.authorName = raw.authorName
    p.authorAvatar = raw.authorAvatar
    p.tag = raw.tag
    p.createTime = raw.createTime
    p.updateTime = raw.updateTime
    p.likeCount = raw.likeCount
    p.commentCount = raw.commentCount
    p.starDustCount = raw.starDustCount
    p.viewCount = raw.viewCount
    p.isTop = raw.isTop
    p.isHot = raw.isHot
    p.campusId = raw.campusId
    return p
  }

  private static mapPosts(rawList: PostModel[]): PostModel[] {
    const result: PostModel[] = []
    for (let i = 0; i < rawList.length; i++) {
      result.push(PostApi.mapPost(rawList[i]))
    }
    return result
  }

  private static mapComment(raw: CommentModel): CommentModel {
    const c = new CommentModel()
    c.id = raw.id
    c.postId = raw.postId
    c.content = raw.content
    c.authorId = raw.authorId
    c.authorName = raw.authorName
    c.authorAvatar = raw.authorAvatar
    c.createTime = raw.createTime
    c.likeCount = raw.likeCount
    return c
  }

  private static mapComments(rawList: CommentModel[]): CommentModel[] {
    const result: CommentModel[] = []
    for (let i = 0; i < rawList.length; i++) {
      result.push(PostApi.mapComment(rawList[i]))
    }
    return result
  }
}
