import { HomePage } from './HomePage'
import { ProjectSquarePage } from './ProjectSquarePage'
import { MessagePage } from './MessagePage'
import { ProfilePage } from './ProfilePage'
import { C, FontSize, Spacing } from '../common/Constants'
import { ApiClient } from '../common/ApiClient'
import { CurrentUser } from '../model/UserModel'
import { router } from '@kit.ArkUI'

class UnreadResult {
  count: number = 0
}

/**
 * Lumina 主页面 — 底部导航 + 中间发布按钮
 */
@Entry
@Component
struct Index {
  @State currentTabIndex: number = 0
  @State unreadMessageCount: number = 0
  @StorageLink('loginVersion') @Watch('onLoginChanged') loginVersion: number = 0

  aboutToAppear(): void {
    this.fetchUnreadCount()
  }

  onLoginChanged(): void {
    this.fetchUnreadCount()
  }

  async fetchUnreadCount(): Promise<void> {
    if (!CurrentUser.id) {
      this.unreadMessageCount = 0
      return
    }
    const res = await ApiClient.get<UnreadResult>('/api/notifications/unread-count?userId=' + CurrentUser.id)
    if (res.code === 0 && res.data) {
      this.unreadMessageCount = res.data.count
    }
  }

  private tabIcons: string[] = ['⌂', '▣', '', '◈', '◎']
  private tabLabels: string[] = ['首页', '项目', '', '消息', '我的']

  @Builder TabBarBuilder(index: number) {
    Column() {
      if (index === 2) {
        // --- 中间发布按钮 ---
        Column() {
          Text('+')
            .fontSize(26)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Regular)
        }
        .width(44)
        .height(44)
        .borderRadius(22)
        .backgroundColor(C.primary)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .shadow({ radius: 8, color: C.primary + '60', offsetX: 0, offsetY: 2 })
        .margin({ bottom: 16 })
      } else {
        // 消息红点
        if (index === 3 && this.unreadMessageCount > 0) {
          Text(this.unreadMessageCount > 99 ? '99+' : this.unreadMessageCount.toString())
            .fontSize(9)
            .fontColor(Color.White)
            .backgroundColor(C.likeRed)
            .borderRadius(7)
            .padding({ left: 4, right: 4, top: 0, bottom: 0 })
            .position({ x: '58%', y: -4 })
            .zIndex(1)
        }

        Text(this.tabIcons[index])
          .fontSize(22)
          .opacity(this.currentTabIndex === index ? 1.0 : 0.55)

        Text(this.tabLabels[index])
          .fontSize(10)
          .fontWeight(this.currentTabIndex === index ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.currentTabIndex === index ? C.tabActive : C.tabInactive)
          .margin({ top: 2 })
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      if (index === 2) {
        router.pushUrl({ url: 'pages/PublishPage' })
      } else {
        this.currentTabIndex = index
      }
    })
  }

  build() {
    Column() {
      Tabs({ index: this.currentTabIndex, controller: new TabsController() }) {
        TabContent() { HomePage() }
        .tabBar(this.TabBarBuilder(0))

        TabContent() { ProjectSquarePage() }
        .tabBar(this.TabBarBuilder(1))

        TabContent() { Column() {} }
        .tabBar(this.TabBarBuilder(2))

        TabContent() { MessagePage() }
        .tabBar(this.TabBarBuilder(3))

        TabContent() { ProfilePage() }
        .tabBar(this.TabBarBuilder(4))
      }
      .barHeight(56)
      .barMode(BarMode.Fixed)
      .barPosition(BarPosition.End)
      .barBackgroundColor(C.bottomBar)
      .onChange((index: number) => {
        if (index !== 2) {
          this.currentTabIndex = index
        }
      })
      .layoutWeight(1)
      .scrollable(false)
      .animationDuration(150)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(C.bg)
  }
}
