/**
 * 星尘打赏记录模型
 * Lumina的投币机制 — 用户可以用星尘打赏优质内容
 */
export class StarDustRecord {
  id: string = ''
  fromUserId: string = ''
  fromUserName: string = ''
  fromUserAvatar: string = ''
  toUserId: string = ''
  toUserName: string = ''
  postId: string = ''
  postTitle: string = ''
  amount: number = 0
  message: string = ''
  createTime: number = Date.now()

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

/**
 * 星尘获取规则项
 */
export class StarDustRuleItem {
  key: string = ''
  amount: number = 0
  desc: string = ''

  constructor(key: string, amount: number, desc: string) {
    this.key = key
    this.amount = amount
    this.desc = desc
  }
}

/**
 * 星尘获取规则列表
 */
export function getStarDustRules(): StarDustRuleItem[] {
  return [
    new StarDustRuleItem('每日登录', 5, '每天首次登录获得5星尘'),
    new StarDustRuleItem('发布帖子', 2, '每发布一篇帖子获得2星尘'),
    new StarDustRuleItem('帖子被点赞', 1, '每获得10个赞获得1星尘'),
    new StarDustRuleItem('被评论', 1, '帖子每收到5条评论获得1星尘'),
    new StarDustRuleItem('登上热榜', 10, '帖子登上热榜获得10星尘'),
  ]
}

/**
 * 打赏金额预设选项
 */
export const REWARD_AMOUNTS: number[] = [1, 5, 10, 20, 50, 100]

/**
 * 打赏留言预设
 */
export const REWARD_MESSAGES: string[] = [
  '写得太好了！',
  '感谢分享！',
  '很有帮助，谢谢！',
  '这才是好内容！',
  '太强了！',
  '学到很多，打赏支持！'
]
