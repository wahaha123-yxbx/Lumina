import { CurrentUser } from '../model/UserModel'
import { ApiClient } from '../common/ApiClient'
import { C, FontSize, Spacing, BorderRadius } from '../common/Constants'
import { router } from '@kit.ArkUI'

class ChatNavParams {
  conversationId: string = ''
  otherUserId: string = ''
  otherUserName: string = ''
  otherAvatar: string = ''
}

class Conversation {
  conversationId: string = ''
  otherUserId: string = ''
  otherUserName: string = ''
  otherAvatar: string = ''
  lastMessage: string = ''
  lastTime: number = 0
  unreadCount: number = 0

  getTimeStr(): string {
    const d = Date.now() - this.lastTime
    if (d < 60000) return '刚刚'
    if (d < 3600000) return Math.floor(d/60000) + '分钟前'
    if (d < 86400000) return Math.floor(d/3600000) + '小时前'
    return Math.floor(d/86400000) + '天前'
  }
}

@Entry
@Component
struct ChatListPage {
  @State conversations: Conversation[] = []

  aboutToAppear(): void { this.load() }

  async load(): Promise<void> {
    const res = await ApiClient.get<Conversation[]>('/api/messages/conversations?userId=' + CurrentUser.id)
    if (res.code === 0 && res.data) {
      const mapped: Conversation[] = []
      for (let i = 0; i < res.data.length; i++) {
        const r = res.data[i]; const c = new Conversation()
        c.conversationId = r.conversationId; c.otherUserId = r.otherUserId
        c.otherUserName = r.otherUserName; c.otherAvatar = r.otherAvatar
        c.lastMessage = r.lastMessage; c.lastTime = r.lastTime; c.unreadCount = r.unreadCount
        mapped.push(c)
      }
      this.conversations = mapped
    }
  }

  build() {
    Column() {
      Row() {
        Text('←').fontSize(24).fontColor(C.textPrimary).onClick(() => { router.back() })
        Text('私信').fontSize(18).fontWeight(FontWeight.Bold).fontColor(C.textPrimary).margin({ left: 12 })
        Blank()
      }.width('100%').height(48).padding({ left: 16, right: 16 }).backgroundColor(C.bgCard)

      if (this.conversations.length === 0) {
        Column() {
          Text('暂无私信').fontSize(14).fontColor(C.textHint)
          Text('去关注列表找人聊天吧').fontSize(12).fontColor(C.textHint).margin({ top: 4 })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.conversations, (c: Conversation) => {
            ListItem() {
              Row() {
                Text(c.otherAvatar || c.otherUserName.substring(0, 1))
                  .fontSize(18).fontWeight(FontWeight.Bold).fontColor(Color.White)
                  .width(48).height(48).borderRadius(24)
                  .backgroundColor(C.primary).textAlign(TextAlign.Center)
                Column() {
                  Row() {
                    Text(c.otherUserName).fontSize(15).fontWeight(FontWeight.Medium).fontColor(C.textPrimary)
                    Blank()
                    Text(c.getTimeStr()).fontSize(11).fontColor(C.textHint)
                  }.width('100%')
                  Text(c.lastMessage).fontSize(13).fontColor(C.textHint).maxLines(1).margin({ top: 4 })
                }.alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: 12 })
                if (c.unreadCount > 0) {
                  Text(c.unreadCount.toString()).fontSize(11).fontColor(Color.White)
                    .backgroundColor(C.likeRed).borderRadius(10)
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                }
              }.width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 }).backgroundColor(C.bgCard)
              .onClick(() => {
                const cp = new ChatNavParams()
                cp.conversationId = c.conversationId
                cp.otherUserId = c.otherUserId
                cp.otherUserName = c.otherUserName
                cp.otherAvatar = c.otherAvatar
                router.pushUrl({ url: 'pages/ChatPage', params: cp })
              })
            }
          }, (c: Conversation) => c.conversationId)
        }.width('100%').layoutWeight(1)
        .divider({ strokeWidth: 0.5, color: C.divider, startMargin: 76, endMargin: 16 })
      }
    }.width('100%').height('100%').backgroundColor(C.bg)
  }
}
