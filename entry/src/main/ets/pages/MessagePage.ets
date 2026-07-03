import { CurrentUser } from '../model/UserModel'
import { ApiClient } from '../common/ApiClient'
import { C, FontSize, Spacing, BorderRadius } from '../common/Constants'
import { router } from '@kit.ArkUI'

class NotificationItem {
  id: string = ''; type: string = ''; fromUserId: string = ''; fromUserName: string = ''
  toUserId: string = ''; postId: string = ''; postTitle: string = ''; content: string = ''
  isRead: boolean = false; createTime: number = 0

  getTimeStr(): string {
    const d = Date.now() - this.createTime
    if (d < 60000) return '刚刚'
    if (d < 3600000) return Math.floor(d/60000) + '分钟前'
    if (d < 86400000) return Math.floor(d/3600000) + '小时前'
    return Math.floor(d/86400000) + '天前'
  }
}

class RawNotification {
  id: string = ''; type: string = ''; fromUserId: string = ''; fromUserName: string = ''
  toUserId: string = ''; postId: string = ''; postTitle: string = ''; content: string = ''
  isRead: boolean = false; createTime: number = 0
}

class ReadAllBody { userId: string = '' }

@Component
export struct MessagePage {
  @State allNotifs: NotificationItem[] = []
  @State selectedTab: number = 0
  @State isLoggedIn: boolean = false
  @State showOfficialDetail: boolean = false
  @State officialTitle: string = ''
  @State officialContent: string = ''
  @StorageLink('loginVersion') @Watch('onLoginChanged') loginVersion: number = 0

  private tabs: string[] = ['全部', '赞', '评论', '官方', '私信']

  aboutToAppear(): void { this.checkAndLoad() }
  onLoginChanged(): void { this.checkAndLoad() }

  checkAndLoad(): void {
    this.isLoggedIn = CurrentUser.id !== ''
    if (this.isLoggedIn) this.loadNotifications()
  }

  async loadNotifications(): Promise<void> {
    try {
      const res = await ApiClient.get<RawNotification[]>('/api/notifications?userId=' + CurrentUser.id)
      if (res.code === 0 && res.data) {
        const mapped: NotificationItem[] = []
        for (let i = 0; i < res.data.length; i++) {
          const r = res.data[i]; const item = new NotificationItem()
          item.id = r.id; item.type = r.type; item.fromUserId = r.fromUserId
          item.fromUserName = r.fromUserName; item.toUserId = r.toUserId
          item.postId = r.postId; item.postTitle = r.postTitle; item.content = r.content
          item.isRead = r.isRead; item.createTime = r.createTime
          mapped.push(item)
        }
        this.allNotifs = mapped
      }
    } catch (e) {}
  }

  getFiltered(): NotificationItem[] {
    if (this.selectedTab === 0) return this.allNotifs
    const typeMap = ['', 'like', 'comment', 'official', '']
    return this.allNotifs.filter(n => n.type === typeMap[this.selectedTab])
  }

  async markAllRead(): Promise<void> {
    const body = new ReadAllBody(); body.userId = CurrentUser.id
    await ApiClient.post<ReadAllBody>('/api/notifications/read', body)
    this.allNotifs.forEach(n => { n.isRead = true })
  }

  build() {
    Stack() {
    Column() {
      // 标题
      Row() {
        Text('消息').fontSize(22).fontWeight(FontWeight.Bold).fontColor(C.textPrimary)
        Blank()
        if (this.allNotifs.length > 0) {
          Text('全部已读').fontSize(13).fontColor(C.primary)
            .onClick(() => { this.markAllRead() })
        }
      }
      .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 4 }).backgroundColor(C.bg)

      if (!this.isLoggedIn) {
        Column() {
          Text('登录后查看消息').fontSize(14).fontColor(C.textHint).margin({ top: 60 })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        // Tab 栏
        Row() {
          ForEach(this.tabs, (tab: string, idx: number) => {
            Text(tab)
              .fontSize(14)
              .fontWeight(this.selectedTab === idx ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.selectedTab === idx ? C.primary : C.textSecondary)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .onClick(() => { this.selectedTab = idx })
          })
        }
        .width('100%').padding({ left: 8, top: 4, bottom: 4 }).backgroundColor(C.bg)

        // 私信占位
        if (this.selectedTab === 4) {
          Column() {
            Button('进入私信').fontSize(15).fontColor(Color.White).backgroundColor(C.primary)
              .borderRadius(20).height(44).padding({ left: 24, right: 24 })
              .onClick(() => { router.pushUrl({ url: 'pages/ChatListPage' }) })
          }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
        } else {
          // 通知列表
          if (this.getFiltered().length === 0) {
            Column() {
              Text('暂无消息').fontSize(14).fontColor(C.textHint)
            }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
          } else {
            List() {
              ForEach(this.getFiltered(), (item: NotificationItem) => {
                ListItem() {
                  Row() {
                    Text(item.fromUserName.substring(0, 1))
                      .fontSize(16).fontWeight(FontWeight.Bold).fontColor(Color.White)
                      .width(42).height(42).borderRadius(21)
                      .backgroundColor(item.isRead ? C.textHint : C.primary)
                      .textAlign(TextAlign.Center)

                    Column() {
                      Row() {
                        Text(item.fromUserName)
                          .fontSize(14).fontWeight(item.isRead ? FontWeight.Normal : FontWeight.Bold)
                          .fontColor(C.textPrimary)
                        Blank()
                        Text(item.getTimeStr()).fontSize(11).fontColor(C.textHint)
                      }.width('100%')

                      Text(item.type === 'like' ? '赞了你的帖子' :
                           item.type === 'comment' ? `评论：${item.content || item.postTitle}` :
                           item.type === 'reward' ? '赞赏了你的帖子' :
                           item.type === 'official' ? item.postTitle : item.postTitle)
                        .fontSize(13).fontColor(item.type === 'official' ? C.primary : C.textSecondary)
                        .maxLines(1).margin({ top: 4 })

                      if (item.type === 'official' && item.content) {
                        Text(item.content).fontSize(12).fontColor(C.textHint).maxLines(2).margin({ top: 2 })
                      }
                    }
                    .alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: 12 })

                    if (!item.isRead) {
                      Circle({ width: 7, height: 7 }).fill(C.likeRed)
                    }
                  }
                  .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
                  .backgroundColor(C.bgCard)
                  .onClick(() => {
                    if (item.type === 'official') {
                      this.officialTitle = item.postTitle
                      this.officialContent = item.content
                      this.showOfficialDetail = true
                    } else if (item.postId) {
                      router.pushUrl({ url: 'pages/PostDetailPage', params: { postId: item.postId } })
                    }
                  })
                }
              }, (item: NotificationItem) => item.id)
            }
            .width('100%').layoutWeight(1)
            .divider({ strokeWidth: 0.5, color: C.divider, startMargin: 70, endMargin: 16 })
          }
        }
      }
    }
    .width('100%').height('100%').backgroundColor(C.bg)

    // 官方消息详情弹窗
    if (this.showOfficialDetail) {
      Column() {
        Column() {
          Text('Lumina 官方').fontSize(13).fontColor(C.primary).margin({ bottom: 12 })
          Text(this.officialTitle).fontSize(18).fontWeight(FontWeight.Bold).fontColor(C.textPrimary).width('100%')
          Text(this.officialContent).fontSize(15).fontColor(C.textSecondary).lineHeight(24).margin({ top: 16 }).width('100%')
          Button('我知道了').fontSize(15).fontColor(Color.White).backgroundColor(C.primary)
            .borderRadius(20).height(42).width('100%').margin({ top: 24 })
            .onClick(() => { this.showOfficialDetail = false })
        }
        .padding(24).backgroundColor(C.bgCard).borderRadius(16).width('90%')
      }
      .width('100%').height('100%').backgroundColor(C.overlay)
      .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      .onClick(() => { this.showOfficialDetail = false })
    }
    }
    .width('100%').height('100%')
  }
}
