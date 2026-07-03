import { CurrentUser, UserModel } from '../model/UserModel'
import { StarDustRecord } from '../model/StarDustModel'
import { PostModel } from '../model/PostModel'
import { UserApi } from '../common/UserApi'
import { Colors, C, FontSize, Spacing, BorderRadius } from '../common/Constants'
import { PostCard } from '../components/PostCard'
import { router } from '@kit.ArkUI'

/**
 * 用户个人主页（查看他人或自己的主页）
 */
@Entry
@Component
struct UserProfilePage {
  @State user: UserModel = CurrentUser
  @State userPosts: PostModel[] = []
  @State rewardRecords: StarDustRecord[] = []
  @State selectedTab: number = 0
  @State isCurrentUser: boolean = true

  async aboutToAppear(): Promise<void> {
    this.userPosts = await UserApi.getUserPosts(this.user.id)
    this.rewardRecords = await UserApi.getRewardRecords(this.user.id)
  }

  @Builder HeaderBuilder() {
    Row() {
      Text('←')
        .width(24)
        .height(24)
        .fontColor(Colors.textPrimary)
        .onClick(() => { router.back() })

      Text(this.user.nickname)
        .fontSize(FontSize.lg)
        .fontColor(Colors.textPrimary)
        .fontWeight(FontWeight.Medium)
        .margin({ left: Spacing.md })

      Blank()

      if (!this.isCurrentUser) {
        Text('⋯')
          .width(24)
          .height(24)
          .fontColor(Colors.textPrimary)
      }
    }
    .width('100%')
    .height(48)
    .padding({ left: Spacing.lg, right: Spacing.lg })
    .backgroundColor(C.bg)
  }

  @Builder ProfileHeader() {
    Column() {
      // 头像
      Text(this.user.avatar || '◎')
        .fontSize(36)
        .width(80)
        .height(80)
        .borderRadius(40)
        .backgroundColor(C.bgInput)
        .textAlign(TextAlign.Center)

      // 昵称和等级
      Row() {
        Text(this.user.nickname)
          .fontSize(FontSize.xxl)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.textPrimary)

        Text(` Lv.${this.user.level} `)
          .fontSize(FontSize.xs)
          .fontColor(Colors.stardustGold)
          .backgroundColor(Colors.stardustGold + '20')
          .borderRadius(BorderRadius.sm)
          .padding({ left: Spacing.xs, right: Spacing.xs, top: 1, bottom: 1 })
          .margin({ left: Spacing.sm })
      }
      .margin({ top: Spacing.md })

      Text(this.user.levelTitle)
        .fontSize(FontSize.sm)
        .fontColor(Colors.primaryLight)
        .margin({ top: Spacing.xs })

      Text(this.user.bio)
        .fontSize(FontSize.body)
        .fontColor(Colors.textSecondary)
        .margin({ top: Spacing.sm })
        .textAlign(TextAlign.Center)
        .padding({ left: Spacing.xxl, right: Spacing.xxl })

      // 信息标签
      Row({ space: Spacing.lg }) {
        Row() {
          Text('🏫')
            .fontSize(FontSize.sm)
          Text(this.user.campus)
            .fontSize(FontSize.xs)
            .fontColor(Colors.textHint)
            .margin({ left: Spacing.xs })
        }
        Row() {
          Text('📚')
            .fontSize(FontSize.sm)
          Text(this.user.major)
            .fontSize(FontSize.xs)
            .fontColor(Colors.textHint)
            .margin({ left: Spacing.xs })
        }
        Row() {
          Text('🎓')
            .fontSize(FontSize.sm)
          Text(this.user.grade)
            .fontSize(FontSize.xs)
            .fontColor(Colors.textHint)
            .margin({ left: Spacing.xs })
        }
      }
      .margin({ top: Spacing.md })

      // 数据统计
      Row() {
        Column() { Text(this.user.postCount.toString()).fontSize(FontSize.lg).fontWeight(FontWeight.Bold).fontColor(Colors.textPrimary)
          Text('帖子').fontSize(FontSize.xs).fontColor(Colors.textHint).margin({ top: 2 }) }
        .layoutWeight(1).alignItems(HorizontalAlign.Center)

        Divider().vertical(true).height(30).color(Colors.divider)

        Column() { Text(this.user.followingCount.toString()).fontSize(FontSize.lg).fontWeight(FontWeight.Bold).fontColor(Colors.textPrimary)
          Text('关注').fontSize(FontSize.xs).fontColor(Colors.textHint).margin({ top: 2 }) }
        .layoutWeight(1).alignItems(HorizontalAlign.Center)

        Divider().vertical(true).height(30).color(Colors.divider)

        Column() { Text(this.user.followerCount.toString()).fontSize(FontSize.lg).fontWeight(FontWeight.Bold).fontColor(Colors.textPrimary)
          Text('粉丝').fontSize(FontSize.xs).fontColor(Colors.textHint).margin({ top: 2 }) }
        .layoutWeight(1).alignItems(HorizontalAlign.Center)

        Divider().vertical(true).height(30).color(Colors.divider)

        Column() {
          Row() {
            Text('✨').fontSize(FontSize.sm)
            Text(this.user.totalStarDustReceived.toString()).fontSize(FontSize.lg).fontWeight(FontWeight.Bold).fontColor(Colors.stardustGold).margin({ left: 2 })
          }
          Text('收到星尘').fontSize(FontSize.xs).fontColor(Colors.textHint).margin({ top: 2 })
        }
        .layoutWeight(1).alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .margin({ top: Spacing.lg })
    }
    .width('100%')
    .padding({ top: Spacing.lg, bottom: Spacing.lg, left: Spacing.lg, right: Spacing.lg })
    .backgroundColor(Colors.bgCard)
    .borderRadius(BorderRadius.lg)
  }

  @Builder TabContentBuilder() {
    Column() {
      // Tab切换
      Row() {
        Text('帖子')
          .fontSize(FontSize.title)
          .fontWeight(this.selectedTab === 0 ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.selectedTab === 0 ? Colors.primary : Colors.textHint)
          .padding({ bottom: Spacing.xs })
          .border({ width: { bottom: this.selectedTab === 0 ? 2 : 0 }, color: Colors.primary })
          .onClick(() => { this.selectedTab = 0 })
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('星尘记录')
          .fontSize(FontSize.title)
          .fontWeight(this.selectedTab === 1 ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.selectedTab === 1 ? Colors.primary : Colors.textHint)
          .padding({ bottom: Spacing.xs })
          .border({ width: { bottom: this.selectedTab === 1 ? 2 : 0 }, color: Colors.primary })
          .onClick(() => { this.selectedTab = 1 })
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .padding({ top: Spacing.md })

      if (this.selectedTab === 0) {
        // 帖子列表
        List() {
          ForEach(this.userPosts, (post: PostModel) => {
            ListItem() {
              PostCard({ post: post })
            }
            .margin({ bottom: Spacing.sm })
          })
        }
        .width('100%')
        .margin({ top: Spacing.sm })
      } else {
        // 星尘记录（简化版）
        List() {
          ForEach(this.rewardRecords, (record: StarDustRecord) => {
            ListItem() {
              Row() {
                Text('✨').fontSize(FontSize.xl)
                Column() {
                  Text(`${record.fromUserName} → ${record.toUserName}`)
                    .fontSize(FontSize.body).fontColor(Colors.textPrimary)
                  Text(`${record.message}`)
                    .fontSize(FontSize.xs).fontColor(Colors.textHint).margin({ top: 2 })
                }
                .alignItems(HorizontalAlign.Start).margin({ left: Spacing.md }).layoutWeight(1)
                Text(`+${record.amount}`).fontSize(FontSize.title).fontColor(Colors.stardustGold).fontWeight(FontWeight.Bold)
              }
              .width('100%').padding(Spacing.md)
            }
          })
        }
        .width('100%').margin({ top: Spacing.sm })
      }
    }
    .width('100%')
    .padding({ left: Spacing.md, right: Spacing.md })
    .margin({ top: Spacing.md })
  }

  build() {
    Column() {
      this.HeaderBuilder()

      Scroll() {
        Column() {
          this.ProfileHeader()
          this.TabContentBuilder()
          Blank().height(Spacing.xxl)
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(C.bg)
  }
}
