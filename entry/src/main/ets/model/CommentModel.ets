/**
 * 评论数据模型
 */
export class CommentModel {
  id: string = ''
  postId: string = ''
  content: string = ''
  authorId: string = ''
  authorName: string = ''
  authorAvatar: string = ''
  createTime: number = Date.now()
  likeCount: number = 0
  isLiked: boolean = false
  replyToId: string = ''
  replyToUserName: string = ''
  subComments: CommentModel[] = []

  getFormattedTime(): string {
    const now = Date.now()
    const diff = now - this.createTime
    const minute = 60 * 1000
    const hour = 60 * minute
    const day = 24 * hour
    if (diff < minute) return '刚刚'
    if (diff < hour) return Math.floor(diff / minute).toString() + '分钟前'
    if (diff < day) return Math.floor(diff / hour).toString() + '小时前'
    if (diff < 7 * day) return Math.floor(diff / day).toString() + '天前'
    const date = new Date(this.createTime)
    return date.getFullYear().toString() + '-' +
      (date.getMonth() + 1).toString().padStart(2, '0') + '-' +
      date.getDate().toString().padStart(2, '0')
  }
}
