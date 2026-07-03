import { CurrentUser } from '../model/UserModel'
import { ApiClient } from '../common/ApiClient'
import { C, FontSize, Spacing, BorderRadius } from '../common/Constants'
import { router } from '@kit.ArkUI'

class ChatMsg {
  id: string = ''
  conversationId: string = ''
  fromUserId: string = ''
  toUserId: string = ''
  content: string = ''
  createTime: number = 0
  isSentByMe(): boolean { return this.fromUserId === CurrentUser.id }
}

class ChatParams { conversationId: string = ''; otherUserId: string = ''; otherUserName: string = ''; otherAvatar: string = '' }

class SendBody { fromUserId: string = ''; toUserId: string = ''; content: string = '' }

@Entry
@Component
struct ChatPage {
  @State messages: ChatMsg[] = []
  @State inputText: string = ''
  private convId: string = ''
  private otherUserId: string = ''
  private otherUserName: string = ''
  private otherAvatar: string = ''

  aboutToAppear(): void {
    const p = router.getParams() as ChatParams
    if (p) {
      this.convId = p.conversationId; this.otherUserId = p.otherUserId
      this.otherUserName = p.otherUserName; this.otherAvatar = p.otherAvatar
      this.loadMessages()
    }
  }

  async loadMessages(): Promise<void> {
    if (!this.convId) return
    try {
      const res = await ApiClient.get<ChatMsg[]>('/api/messages/' + this.convId + '?userId=' + CurrentUser.id)
      if (res.code === 0 && res.data) this.messages = res.data
    } catch (e) {}
  }

  async sendMessage(): Promise<void> {
    const text = this.inputText.trim()
    if (!text) return
    try {
      const body = new SendBody()
      body.fromUserId = CurrentUser.id; body.toUserId = this.otherUserId; body.content = text
      const res = await ApiClient.post<ChatMsg>('/api/messages/send', body)
      if (res.code === 0 && res.data) {
        this.messages = [...this.messages, res.data]
        // 新会话：保存返回的 conversationId
        if (!this.convId && res.data.conversationId) {
          this.convId = res.data.conversationId
        }
      }
    } catch (e) {}
    this.inputText = ''
  }

  build() {
    Column() {
      Row() {
        Text('←').fontSize(24).fontColor(C.textPrimary).onClick(() => { router.back() })
        Text(this.otherAvatar || '◎').fontSize(20).width(32).height(32).borderRadius(16)
          .backgroundColor(C.bgInput).textAlign(TextAlign.Center).margin({ left: 8 })
        Text(this.otherUserName).fontSize(16).fontWeight(FontWeight.Bold).fontColor(C.textPrimary).margin({ left: 8 })
        Blank()
      }.width('100%').height(48).padding({ left: 16, right: 16 }).backgroundColor(C.bgCard)

      List() {
        ForEach(this.messages, (msg: ChatMsg) => {
          ListItem() {
            Row() {
              if (msg.isSentByMe()) Blank()
              Column() {
                Text(msg.content)
                  .fontSize(15).fontColor(msg.isSentByMe() ? Color.White : C.textPrimary)
                  .padding({ left: 14, right: 14, top: 10, bottom: 10 })
                  .borderRadius(16)
                  .backgroundColor(msg.isSentByMe() ? C.primary : C.bgCard)
                  .constraintSize({ maxWidth: '75%' })
              }
              if (!msg.isSentByMe()) Blank()
            }.width('100%').padding({ left: 16, right: 16, top: 6, bottom: 6 })
            .justifyContent(msg.isSentByMe() ? FlexAlign.End : FlexAlign.Start)
          }
        }, (msg: ChatMsg) => msg.id)
      }.width('100%').layoutWeight(1).backgroundColor(C.bg)

      Row() {
        TextInput({ placeholder: '输入消息...', text: this.inputText })
          .placeholderColor(C.textHint).fontSize(15).fontColor(C.textPrimary)
          .backgroundColor(C.bgInput).borderRadius(20).height(40).layoutWeight(1)
          .padding({ left: 16, right: 16 })
          .onChange((v: string) => { this.inputText = v })
        Button('发送').fontSize(14).fontColor(Color.White).backgroundColor(C.primary)
          .borderRadius(20).height(40).padding({ left: 16, right: 16 }).margin({ left: 8 })
          .onClick(() => { this.sendMessage() })
      }.width('100%').padding({ left: 12, right: 12, top: 8, bottom: 8 }).backgroundColor(C.bgCard)
    }.width('100%').height('100%').backgroundColor(C.bg)
  }
}
