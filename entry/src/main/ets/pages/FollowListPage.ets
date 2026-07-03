import { CurrentUser } from '../model/UserModel'
import { ApiClient } from '../common/ApiClient'
import { C, FontSize, Spacing, BorderRadius } from '../common/Constants'
import { router } from '@kit.ArkUI'

class FollowUser {
  id: string = ''; nickname: string = ''; avatar: string = ''
  bio: string = ''; studentId: string = ''
}

class FollowParams { userId: string = ''; type: string = '' }

class ChatNavParams {
  conversationId: string = ''
  otherUserId: string = ''
  otherUserName: string = ''
  otherAvatar: string = ''
}

@Entry
@Component
struct FollowListPage {
  @State users: FollowUser[] = []
  @State title: string = ''
  @State isLoading: boolean = true
  private userId: string = ''
  private listType: string = ''

  aboutToAppear(): void {
    const p = router.getParams() as FollowParams
    if (p) {
      this.userId = p.userId; this.listType = p.type
      this.title = p.type === 'followers' ? '粉丝' : '关注'
      this.loadList()
    }
  }

  async loadList(): Promise<void> {
    this.isLoading = true
    const res = await ApiClient.get<FollowUser[]>('/api/users/' + this.userId + '/' + this.listType)
    this.isLoading = false
    if (res.code === 0 && res.data) this.users = res.data
  }

  build() {
    Column() {
      Row() {
        Text('←').fontSize(24).fontColor(C.textPrimary).onClick(() => { router.back() })
        Text(this.title).fontSize(18).fontWeight(FontWeight.Bold).fontColor(C.textPrimary).margin({ left: 12 })
        Blank()
      }.width('100%').height(48).padding({ left: 16, right: 16 }).backgroundColor(C.bgCard)

      if (this.users.length === 0 && !this.isLoading) {
        Column() {
          Text('暂无' + this.title).fontSize(14).fontColor(C.textHint)
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.users, (user: FollowUser) => {
            ListItem() {
              Row() {
                Text(user.avatar || '◎').fontSize(22)
                  .width(48).height(48).borderRadius(24)
                  .backgroundColor(C.bgInput).textAlign(TextAlign.Center)
                Column() {
                  Text(user.nickname).fontSize(15).fontWeight(FontWeight.Medium).fontColor(C.textPrimary)
                  if (user.bio) {
                    Text(user.bio).fontSize(12).fontColor(C.textHint).maxLines(1).margin({ top: 2 })
                  }
                }.alignItems(HorizontalAlign.Start).margin({ left: 12 }).layoutWeight(1)
                Button('私信').fontSize(12).fontColor(C.primary)
                  .backgroundColor(C.primaryBg).borderRadius(12).height(30)
                  .padding({ left: 12, right: 12 })
                  .onClick(() => {
                    const cp = new ChatNavParams()
                    cp.otherUserId = user.id
                    cp.otherUserName = user.nickname
                    cp.otherAvatar = user.avatar
                    router.pushUrl({ url: 'pages/ChatPage', params: cp })
                  })
              }.width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 }).backgroundColor(C.bgCard)
            }
          }, (user: FollowUser) => user.id)
        }.width('100%').layoutWeight(1)
        .divider({ strokeWidth: 0.5, color: C.divider, startMargin: 76, endMargin: 16 })
      }
    }.width('100%').height('100%').backgroundColor(C.bg)
  }
}
