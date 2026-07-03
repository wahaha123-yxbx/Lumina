/**
 * 帖子数据模型
 */
export class PostModel {
  id: string = ''
  title: string = ''
  content: string = ''
  images: string[] = []
  authorId: string = ''
  authorName: string = ''
  authorAvatar: string = ''
  tag: string = ''
  createTime: number = Date.now()
  updateTime: number = Date.now()
  likeCount: number = 0
  commentCount: number = 0
  starDustCount: number = 0
  isLiked: boolean = false
  isStarred: boolean = false
  viewCount: number = 0
  isTop: boolean = false
  isHot: boolean = false
  campusId: string = 'main'

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

  static formatCount(count: number): string {
    if (count >= 10000) return (count / 10000).toFixed(1) + 'w'
    if (count >= 1000) return (count / 1000).toFixed(1) + 'k'
    return count.toString()
  }
}

// 知识型学术社区标签
export const PostTags: string[] = [
  '全部', '学术讨论', '科技前沿', '人文社科', '职业发展',
  '课程交流', '读书分享', '校园生活', '问答求助', '观点争鸣'
]

export function getTagColor(tag: string): string {
  switch (tag) {
    case '学术讨论': return '#2E7D32'
    case '科技前沿': return '#0277BD'
    case '人文社科': return '#6A1B9A'
    case '职业发展': return '#E65100'
    case '课程交流': return '#00838F'
    case '读书分享': return '#C62828'
    case '校园生活': return '#FF8F00'
    case '问答求助': return '#D32F2F'
    case '观点争鸣': return '#4527A0'
    default: return '#0066FF'
  }
}
