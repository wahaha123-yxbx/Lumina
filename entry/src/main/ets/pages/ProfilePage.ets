import { CurrentUser, UserModel } from '../model/UserModel'
import { StarDustRecord } from '../model/StarDustModel'
import { UserApi } from '../common/UserApi'
import { ApiClient } from '../common/ApiClient'
import { Colors, C, FontSize, Spacing, BorderRadius } from '../common/Constants'
import { ProjectApi } from '../common/ProjectApi'
import { ProjectModel, getCategoryColor } from '../model/ProjectModel'
import { MockProjectService } from '../common/MockData'
import { router } from '@kit.ArkUI'

/**
 * 我的页面 - 个人中心
 */
@Component
export struct ProfilePage {
  @State user: UserModel = new UserModel()
  @State isLoggedIn: boolean = false
  @State starDustRecords: StarDustRecord[] = []
  @State showStardustDetail: boolean = false
  @State myProjects: ProjectModel[] = []
  @StorageLink('loginVersion') @Watch('checkLoginState') loginVersion: number = 0

  aboutToAppear(): void {
    this.checkLoginState()
  }

  getMyRoleInProject(proj: ProjectModel): string {
    for (let i = 0; i < proj.members.length; i++) {
      if (proj.members[i].userId === CurrentUser.id) return proj.members[i].role
    }
    return '成员'
  }

  async loadMyProjects(): Promise<void> {
    if (!CurrentUser.id) return
    this.myProjects = MockProjectService.getMyProjects(CurrentUser.id)
    const data = await ProjectApi.getMyProjects(CurrentUser.id)
    if (data.length > 0) this.myProjects = data
  }

  // 每次渲染时由 @StorageLink 触发
  checkLoginState(): void {
    const loggedIn = CurrentUser.id !== ''
    if (loggedIn !== this.isLoggedIn) {
      this.isLoggedIn = loggedIn
      if (loggedIn) {
        this.user = CurrentUser
        this.loadFullUserData()
        this.loadMyProjects()
      } else {
        this.user = new UserModel()
      }
    }
  }

  async loadFullUserData(): Promise<void> {
    if (!CurrentUser.id) return
    const fresh = await UserApi.getUserById(CurrentUser.id)
    if (fresh) {
      CurrentUser.nickname = fresh.nickname
      CurrentUser.avatar = fresh.avatar
      CurrentUser.bio = fresh.bio
      CurrentUser.campus = fresh.campus
      CurrentUser.major = fresh.major
      CurrentUser.grade = fresh.grade
      CurrentUser.starDustBalance = fresh.starDustBalance
      CurrentUser.totalStarDustReceived = fresh.totalStarDustReceived
      CurrentUser.postCount = fresh.postCount
      CurrentUser.followingCount = fresh.followingCount
      CurrentUser.followerCount = fresh.followerCount
      CurrentUser.level = fresh.level
      CurrentUser.levelTitle = fresh.levelTitle
      CurrentUser.joinDate = fresh.joinDate
      this.user = fresh
    }
    if (CurrentUser.id) {
      const rawRecords = await UserApi.getRewardRecords(CurrentUser.id)
      // 映射 JSON → 类实例，防止调用方法时崩溃
      const mapped: StarDustRecord[] = []
      for (let i = 0; i < rawRecords.length; i++) {
        const r = rawRecords[i]
        const s = new StarDustRecord()
        s.id = r.id; s.fromUserId = r.fromUserId; s.fromUserName = r.fromUserName
        s.fromUserAvatar = r.fromUserAvatar; s.toUserId = r.toUserId; s.toUserName = r.toUserName
        s.postId = r.postId; s.postTitle = r.postTitle
        s.amount = r.amount; s.message = r.message; s.createTime = r.createTime
        mapped.push(s)
      }
      this.starDustRecords = mapped
    }
  }

  @Builder UserInfoCard() {
    Row() {
      // 头像
      Column() {
        Text(this.user.avatar || '◎')
          .fontSize(30)
      }
      .width(64)
      .height(64)
      .borderRadius(32)
      .backgroundColor(C.bgInput)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      // 信息
      Column() {
        Row() {
          Text(this.user.nickname || '未登录')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(C.textPrimary)

          if (this.user.level > 0) {
            Text(`Lv.${this.user.level}`)
              .fontSize(10)
              .fontColor(C.primary)
              .backgroundColor(C.primaryBg)
              .borderRadius(4)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .margin({ left: 8 })
          }
        }

        Text(this.user.bio || '在Lumina，每一个灵魂都是一颗星尘')
          .fontSize(13)
          .fontColor(C.textHint)
          .margin({ top: 4 })
          .maxLines(1)
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 14 })
      .layoutWeight(1)

      Text('›')
        .fontSize(20)
        .fontColor(C.textHint)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(C.bgCard)
    .borderRadius(12)
    .onClick(() => {
      if (this.isLoggedIn) {
        router.pushUrl({ url: 'pages/UserProfilePage' })
      }
    })
  }

  @Builder StatsRow() {
    Column() {
      // 第一行：星尘 + 帖子
      Row() {
        Column() {
          Row() {
            Text('✨')
              .fontSize(FontSize.title)
            Text(this.user.starDustBalance.toString())
              .fontSize(FontSize.xl)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.stardustGold)
              .margin({ left: Spacing.xs })
          }
          Text('星尘余额')
            .fontSize(FontSize.xs)
            .fontColor(Colors.textHint)
            .margin({ top: Spacing.xs })
        }
        .layoutWeight(1).alignItems(HorizontalAlign.Center)
        .onClick(() => { this.showStardustDetail = !this.showStardustDetail })

        Divider().vertical(true).height(30).color(C.divider)

        Column() {
          Text(this.myProjects.length.toString())
            .fontSize(FontSize.xl)
            .fontWeight(FontWeight.Bold)
            .fontColor(C.textPrimary)
          Text('项目')
            .fontSize(FontSize.xs)
            .fontColor(C.textHint)
            .margin({ top: Spacing.xs })
        }
        .layoutWeight(1).alignItems(HorizontalAlign.Center)

        Divider().vertical(true).height(30).color(C.divider)

        Column() {
          Text(this.user.postCount.toString())
            .fontSize(FontSize.xl)
            .fontWeight(FontWeight.Bold)
            .fontColor(C.textPrimary)
          Text('帖子')
            .fontSize(FontSize.xs)
            .fontColor(C.textHint)
            .margin({ top: Spacing.xs })
        }
        .layoutWeight(1).alignItems(HorizontalAlign.Center)

        Divider().vertical(true).height(30).color(C.divider)

        Column() {
          Text(this.user.followerCount.toString())
            .fontSize(FontSize.xl)
            .fontWeight(FontWeight.Bold)
            .fontColor(C.textPrimary)
          Text('粉丝')
            .fontSize(FontSize.xs)
            .fontColor(C.textHint)
            .margin({ top: Spacing.xs })
        }
        .layoutWeight(1).alignItems(HorizontalAlign.Center)
      }
      .width('100%')
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .backgroundColor(C.bgCard)
    .borderRadius(12)
    .margin({ top: 12 })
  }

  @Builder MyProjectsSection() {
    Column() {
      Row() {
        Text('📂 我的项目')
          .fontSize(FontSize.title)
          .fontWeight(FontWeight.Bold)
          .fontColor(C.textPrimary)
        Blank()
        Text('全部 →')
          .fontSize(FontSize.xs)
          .fontColor(C.primary)
          .onClick(() => { router.pushUrl({ url: 'pages/ProjectSquarePage' }) })
      }
      .width('100%')

      if (this.myProjects.length === 0) {
        Text('还没有参与任何项目')
          .fontSize(FontSize.sm)
          .fontColor(C.textHint)
          .margin({ top: Spacing.md })
        Text('去项目广场探索感兴趣的项目吧！')
          .fontSize(FontSize.xs)
          .fontColor(C.primary)
          .margin({ top: Spacing.xs })
          .onClick(() => { router.pushUrl({ url: 'pages/ProjectSquarePage' }) })
      } else {
        ForEach(this.myProjects, (proj: ProjectModel) => {
          Row() {
            Column() {
              Text(proj.title)
                .fontSize(FontSize.body)
                .fontWeight(FontWeight.Medium)
                .fontColor(C.textPrimary)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Row() {
                Text(this.getMyRoleInProject(proj))
                  .fontSize(10)
                  .fontColor(proj.leaderId === CurrentUser.id ? '#FF6B35' : C.primary)
                  .padding({ left: 6, right: 6, top: 1, bottom: 1 })
                  .borderRadius(3)
                  .backgroundColor(proj.leaderId === CurrentUser.id ? '#FF6B3518' : C.primaryBg)

                Text(proj.completedTaskCount + '/' + proj.taskCount + ' 任务')
                  .fontSize(11)
                  .fontColor(C.textHint)
                  .margin({ left: Spacing.sm })
              }
              .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text('›')
              .fontSize(18)
              .fontColor(C.textHint)
          }
          .width('100%')
          .padding({ top: Spacing.md, bottom: Spacing.md })
          .border({ width: { bottom: 0.5 }, color: C.divider })
          .onClick(() => {
            router.pushUrl({ url: 'pages/ProjectDetailPage', params: { projectId: proj.id } })
          })
        }, (proj: ProjectModel) => proj.id)
      }
    }
    .width('100%')
    .padding(Spacing.lg)
    .backgroundColor(C.bgCard)
    .borderRadius(12)
    .margin({ top: 12 })
  }

  @Builder MenuSectionBuilder() {
    Column() {
      this.MenuItemBuilder('my_stardust', '✦', '我的星尘', '查看星尘记录和明细')
      Divider().color(C.divider).strokeWidth(0.5)
      this.MenuItemBuilder('my_posts', '☰', '我的帖子', `已发布 ${this.user.postCount} 篇`)
      Divider().color(C.divider).strokeWidth(0.5)
      this.MenuItemBuilder('rules', '?', '星尘规则', '了解如何获取和使用星尘')
      Divider().color(C.divider).strokeWidth(0.5)
      this.MenuItemBuilder('settings', '⚙', '设置', '个性化设置和账号管理')
    }
    .width('100%')
    .backgroundColor(C.bgCard)
    .borderRadius(12)
    .margin({ top: 12 })
  }

  @Builder MenuItemBuilder(action: string, iconChar: string, title: string, subtitle: string) {
    Row() {
      Text(iconChar)
        .fontSize(18)
        .fontColor(C.textSecondary)
        .width(28)
        .textAlign(TextAlign.Center)

      Column() {
        Text(title)
          .fontSize(15)
          .fontColor(C.textPrimary)
        Text(subtitle)
          .fontSize(11)
          .fontColor(C.textHint)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })

      Blank()

      Text('›')
        .fontSize(18)
        .fontColor(C.textHint)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .onClick(() => {
      if (action === 'my_stardust') {
        this.showStardustDetail = true
      } else if (action === 'my_posts') {
        router.pushUrl({ url: 'pages/UserProfilePage' })
      } else if (action === 'rules') {
        router.pushUrl({ url: 'pages/StarDustRulesPage' })
      } else if (action === 'settings') {
        router.pushUrl({ url: 'pages/SettingsPage' })
      }
    })
  }

  @Builder StarDustDetailSheet() {
    Column() {
      // 拖拽条
      Divider().width(36).height(4).color(C.divider).strokeWidth(4).borderRadius(2).margin({ top: 8, bottom: 8 })

      Row() {
        Text('星尘明细').fontSize(18).fontWeight(FontWeight.Bold).fontColor(C.textPrimary)
        Blank()
        Text('关闭').fontSize(14).fontColor(C.primary)
          .onClick(() => { this.showStardustDetail = false })
      }
      .width('100%').padding({ left: 20, right: 20 })

      // 余额卡片
      Row() {
        Column() {
          Text(this.user.starDustBalance.toString())
            .fontSize(36).fontWeight(FontWeight.Bold).fontColor(C.stardustGold)
          Text('当前星尘余额').fontSize(12).fontColor(C.textHint).margin({ top: 4 })
        }.alignItems(HorizontalAlign.Start)

        Blank()

        Column() {
          Text(`Lv.${this.user.level}`).fontSize(16).fontWeight(FontWeight.Bold).fontColor(C.primary)
          Text(this.user.levelTitle).fontSize(11).fontColor(C.textHint).margin({ top: 2 })
        }.alignItems(HorizontalAlign.End)
      }
      .width('100%').padding(20).backgroundColor(C.bgInput).borderRadius(12)
      .margin({ left: 20, right: 20, top: 16 })

      Text('收支记录').fontSize(14).fontWeight(FontWeight.Bold).fontColor(C.textPrimary)
        .width('100%').padding({ left: 20, right: 20, top: 20, bottom: 8 })

      if (this.starDustRecords.length === 0) {
        Column() {
          Text('暂无星尘记录').fontSize(14).fontColor(C.textHint)
          Text('发布优质内容，获得他人赞赏！').fontSize(12).fontColor(C.textHint).margin({ top: 4 })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.starDustRecords, (record: StarDustRecord) => {
            ListItem() {
              Row() {
                Column() {
                  Text(record.fromUserName.substring(0, 1))
                    .fontSize(16).fontWeight(FontWeight.Bold).fontColor(Color.White)
                    .width(40).height(40).borderRadius(20)
                    .backgroundColor(C.primary).textAlign(TextAlign.Center)
                }

                Column() {
                  Row() {
                    Text(record.fromUserName).fontSize(14).fontColor(C.textPrimary)
                    Text(' → ').fontSize(12).fontColor(C.textHint)
                    Text(record.toUserName).fontSize(14).fontColor(C.textPrimary)
                  }
                  Text(record.message || '支持优质内容').fontSize(12).fontColor(C.textHint).maxLines(1).margin({ top: 2 })
                  Text(record.getFormattedTime()).fontSize(11).fontColor(C.textHint).margin({ top: 2 })
                }
                .alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: 12 })

                Text(`+${record.amount}`)
                  .fontSize(16).fontWeight(FontWeight.Bold).fontColor(C.stardustGold)
              }
              .width('100%').padding({ left: 20, right: 20, top: 12, bottom: 12 })
            }
          }, (record: StarDustRecord) => record.id)
        }
        .width('100%').layoutWeight(1)
        .divider({ strokeWidth: 0.5, color: C.divider, startMargin: 72, endMargin: 20 })
      }
    }
    .width('100%').height('55%').backgroundColor(C.bg)
    .borderRadius({ topLeft: 16, topRight: 16 })
  }

  build() {
    Stack() {
      // 主内容区
      Scroll() {
        Column() {
      Text('我的')
        .fontSize(FontSize.xxl)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.textPrimary)
        .width('100%')
        .padding({ left: Spacing.lg, top: Spacing.md, bottom: Spacing.xs })

      if (this.isLoggedIn) {
        // --- 已登录状态 ---
        this.UserInfoCard()
        this.StatsRow()
        this.MyProjectsSection()
        this.MenuSectionBuilder()
      } else {
        // --- 未登录状态 ---
        Column() {
          Text('👤')
            .fontSize(56)
            .opacity(0.5)

          Text('点击登录，开启星尘之旅')
            .fontSize(FontSize.body)
            .fontColor(Colors.textHint)
            .margin({ top: Spacing.md })

          Button('登录 / 注册')
            .fontSize(FontSize.body)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
            .backgroundColor(Colors.primary)
            .borderRadius(BorderRadius.md)
            .height(44)
            .padding({ left: Spacing.xl, right: Spacing.xl })
            .margin({ top: Spacing.lg })
            .onClick(() => {
              router.pushUrl({ url: 'pages/LoginPage' })
            })
        }
        .width('100%')
        .padding({ top: Spacing.xxl, bottom: Spacing.xxl })
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(Colors.bgCard)
        .borderRadius(BorderRadius.lg)

        // 未登录也能看的菜单
        this.MenuSectionBuilder()

        // 退出按钮
        Button('退出登录')
          .fontSize(14)
          .fontColor(C.textHint)
          .backgroundColor(C.bgCard)
          .borderRadius(10)
          .width('100%')
          .height(44)
          .margin({ top: 12 })
          .onClick(() => {
            CurrentUser.reset()
            this.isLoggedIn = false
            this.user = new UserModel()
            this.starDustRecords = []
            ApiClient.authToken = ''
            AppStorage.setOrCreate('loginVersion', Date.now())
          })
      }

      // 底部安全区
      Blank()
        .height(Spacing.xxl)
    }
    .padding({ left: Spacing.md, right: Spacing.md })
    .width('100%')
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)

      // 星尘明细弹出层
      if (this.showStardustDetail) {
        Column() {
          Blank()
          this.StarDustDetailSheet()
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Colors.overlay)
        .onClick(() => { this.showStardustDetail = false })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(C.bg)
  }
}
