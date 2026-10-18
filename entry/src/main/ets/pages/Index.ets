import { cookieManager } from '../network/CookieManager';
import { forumRepository } from '../repo/ForumRepository';
import { Thread, ForumGroup, Forum, UserProfile, CheckInStatus } from '../models/Models';
import { NetImage } from '../common/NetImage';
import common from '@ohos.app.ability.common';
import { MtfColors, CARD_SHADOW } from '../common/Theme';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  aboutToAppear() {
    AppStorage.setOrCreate('isDark', false);
  }

  build() {
    Tabs({ barPosition: BarPosition.End }) {
      TabContent() { HomeTab() }.tabBar('首页')
      TabContent() { ForumTab() }.tabBar('版块')
      TabContent() { ProfileTab() }.tabBar('我的')
    }
    .onChange((index: number) => { this.currentIndex = index; })
  }
}

@Component
struct HomeTab {
  @State threads: Array<Thread> = [];
  @State isLoading: boolean = false;
  @State isLoadingMore: boolean = false;
  @State errorMsg: string = '';
  @State page: number = 1;
  @State hasNext: boolean = true;

  async aboutToAppear() {
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    await cookieManager.init(context);
    await this.refreshData();
  }

  async refreshData() {
    if (this.isLoading) return;
    this.isLoading = true;
    this.page = 1;
    this.hasNext = true;
    try {
      let homeData = await forumRepository.home();
      this.threads = homeData.hotThreads;
    } catch (error) {
      this.errorMsg = (error as Error).message || '加载失败';
    } finally {
      this.isLoading = false;
    }
  }

  async loadMore() {
    if (!this.hasNext || this.isLoadingMore) return;
    this.isLoadingMore = true;
    this.page++;
    try {
      // 借用 guideFeed 拉取下一页热帖
      let res = await forumRepository.guideFeed('hot', this.page);
      if (res.threads.length > 0) {
        this.threads = this.threads.concat(res.threads);
        this.hasNext = res.hasNext;
      } else {
        this.hasNext = false;
      }
    } catch (e) {
      console.error(e);
    } finally {
      this.isLoadingMore = false;
    }
  }

  build() {
    Column() {
      Row() {
        Text('MT论坛').fontSize(20).fontWeight(FontWeight.Bold).fontColor(MtfColors.textMain)
        Blank()
        Text('搜索').fontSize(14).fontColor(MtfColors.primary).margin({ right: 15 }).onClick(() => router.pushUrl({ url: 'pages/SearchPage' }))
        Text('去登录').fontSize(14).fontColor(MtfColors.primary).onClick(() => router.pushUrl({ url: 'pages/Login' }))
      }.width('100%').height(50).padding({ left: 16, right: 16 }).backgroundColor(MtfColors.bgWhite)

      if (this.isLoading && this.threads.length === 0) {
        LoadingProgress().width(50).height(50).color(MtfColors.primary).margin({ top: 100 })
      } else if (this.errorMsg !== '') {
        Text(this.errorMsg).fontSize(16).fontColor(Color.Red).margin({ top: 100 })
      } else {
        Refresh({ refreshing: $$this.isLoading }) {
          List({ space: 10 }) {
            ForEach(this.threads, (item: Thread) => {
              ListItem() {
                this.ThreadCard(item)
              }
              .onClick(() => router.pushUrl({ url: 'pages/ThreadDetail', params: { tid: item.tid } }))
            }, (item: Thread) => item.tid)
            
            // 底部加载更多状态
            if (this.isLoadingMore) {
              ListItem() {
                Row() { LoadingProgress().width(24).height(24); Text('加载中...').fontSize(12).fontColor(MtfColors.textLight).margin({left: 10}) }
                .width('100%').justifyContent(FlexAlign.Center).padding(10)
              }
            } else if (!this.hasNext && this.threads.length > 0) {
              ListItem() {
                Text('没有更多了').fontSize(12).fontColor(MtfColors.textLight).width('100%').textAlign(TextAlign.Center).padding(15)
              }
            }
          }
          .width('100%')
          .layoutWeight(1)
          .padding(10)
          .backgroundColor(MtfColors.bgLight)
          .onReachEnd(() => {
            this.loadMore();
          })
        }
        .onRefreshing(() => this.refreshData())
        .width('100%')
        .layoutWeight(1)
      }
    }.width('100%').height('100%')
  }

  @Builder
  ThreadCard(thread: Thread) {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Image(thread.avatarUrl ? thread.avatarUrl : $r('app.media.icon'))
          .width(30).height(30).borderRadius(15).backgroundColor('#EEEEEE')
        Column() {
          Text(thread.authorName || '匿名用户').fontSize(14).fontWeight(FontWeight.Medium).fontColor(MtfColors.textMain)
          Text(thread.timeText || '刚刚').fontSize(11).fontColor(MtfColors.textLight)
        }.alignItems(HorizontalAlign.Start)
      }.width('100%')

      Text(thread.subject).fontSize(16).fontWeight(FontWeight.Bold).fontColor('#111').maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })

      if (thread.imageUrls && thread.imageUrls.length > 0) {
        NetImage({ src: thread.imageUrls[0], imgWidth: '100%', imgHeight: 150, imgRadius: 6 })
      }

      Row({ space: 15 }) {
        Text(`阅读 ${thread.viewCount || 0}`).fontSize(12).fontColor(MtfColors.textLight)
        Text(`回复 ${thread.replyCount || 0}`).fontSize(12).fontColor(MtfColors.textLight)
        Blank()
      }.width('100%').margin({ top: 4 })
    }
    .width('100%').padding(12).backgroundColor(MtfColors.bgWhite).borderRadius(10)
    .shadow({ radius: 4, color: '#0A000000', offsetX: 0, offsetY: 2 })
  }
}

@Component
struct ForumTab {
  @State groups: Array<ForumGroup> = [];
  @State isLoading: boolean = true;

  async aboutToAppear() { await this.loadData(); }

  async loadData() {
    this.isLoading = true;
    try { this.groups = await forumRepository.forumGroups(); } 
    catch (e) { console.error(e); } 
    finally { this.isLoading = false; }
  }

  build() {
    Column() {
      Row() { Text('版块导航').fontSize(20).fontWeight(FontWeight.Bold).fontColor(MtfColors.textMain) }
      .width('100%').height(50).padding({ left: 16 }).backgroundColor(MtfColors.bgWhite)

      if (this.isLoading) {
        LoadingProgress().width(50).height(50).color(MtfColors.primary).margin({ top: 100 })
      } else {
        List({ space: 15 }) {
          ForEach(this.groups, (group: ForumGroup) => {
            ListItem() {
              Column({ space: 10 }) {
                Text(group.name).fontSize(16).fontWeight(FontWeight.Bold).fontColor(MtfColors.primary).width('100%').margin({ bottom: 5 })
                ForEach(group.forums, (forum: Forum) => {
                  Row({ space: 10 }) {
                    if (forum.icon) { Image(forum.icon).width(36).height(36).borderRadius(6) } 
                    else { Image($r('app.media.icon')).width(36).height(36).borderRadius(6) }
                    Column() { Text(forum.name).fontSize(15).fontColor(MtfColors.textMain).fontWeight(FontWeight.Medium) }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                    if (forum.todayPosts > 0) { Text(`今日: ${forum.todayPosts}`).fontSize(12).fontColor('#FF5722') }
                  }
                  .width('100%').padding(10).backgroundColor('#F9F9F9').borderRadius(8)
                  .onClick(() => router.pushUrl({ url: 'pages/ForumPageList', params: { fid: forum.fid, name: forum.name } }))
                }, (forum: Forum) => forum.fid)
              }.width('100%').padding(15).backgroundColor(MtfColors.bgWhite).borderRadius(12)
            }
          }, (group: ForumGroup) => group.name)
        }.width('100%').layoutWeight(1).padding(15).backgroundColor(MtfColors.bgLight)
      }
    }.width('100%').height('100%')
  }
}

@Component
struct ProfileTab {
  @StorageLink('isDark') isDark: boolean = false;
  @State profile: UserProfile | null = null;
  @State isLoading: boolean = true;
  @State checkInStatus: CheckInStatus | null = null;
  @State isCheckingIn: boolean = false;

  async aboutToAppear() { await this.loadData(); }
  onPageShow() { this.loadData(); }

  async loadData() {
    this.isLoading = true;
    try {
      this.profile = await forumRepository.me();
      if (this.profile.isLoggedIn) { this.checkInStatus = await forumRepository.checkInStatus(); }
    } catch (e) { console.error(e); } 
    finally { this.isLoading = false; }
  }

  async doLogout() {
    await cookieManager.clear();
    this.profile = null;
    promptAction.showToast({ message: '已退出登录' });
    this.loadData();
  }

  build() {
    Column() {
      Row() { Text('个人中心').fontSize(20).fontWeight(FontWeight.Bold).fontColor(MtfColors.textMain) }
      .width('100%').height(50).padding({ left: 16 }).backgroundColor(MtfColors.bgWhite)

      if (this.isLoading) {
        LoadingProgress().width(50).height(50).color(MtfColors.primary).margin({ top: 100 })
      } else if (this.profile && this.profile.isLoggedIn) {
        Column({ space: 15 }) {
          Row({ space: 15 }) {
            Image(this.profile.avatarUrl ? this.profile.avatarUrl : $r('app.media.icon')).width(60).height(60).borderRadius(30).backgroundColor('#EEEEEE')
            Column({ space: 5 }) {
              Text(this.profile.name || '未知用户').fontSize(18).fontWeight(FontWeight.Bold)
              Text(this.profile.groupName || '普通会员').fontSize(12).fontColor(MtfColors.primary).backgroundColor('#E8F0FE').padding({ left: 6, right: 6, top: 2, bottom: 2 }).borderRadius(4)
            }.alignItems(HorizontalAlign.Start)
            Blank()
          }.width('100%').padding(20).backgroundColor(MtfColors.bgWhite).borderRadius(12)

          Row() {
            Column() { Text(`${this.profile.posts || 0}`).fontSize(16).fontWeight(FontWeight.Bold); Text('帖子').fontSize(12).fontColor(MtfColors.textLight) }.layoutWeight(1)
            Column() { Text(`${this.profile.credits || 0}`).fontSize(16).fontWeight(FontWeight.Bold); Text('积分').fontSize(12).fontColor(MtfColors.textLight) }.layoutWeight(1)
            Column() { Text(`${this.profile.gold || 0}`).fontSize(16).fontWeight(FontWeight.Bold); Text('金币').fontSize(12).fontColor(MtfColors.textLight) }.layoutWeight(1)
          }.width('100%').padding({ top: 15, bottom: 15 }).backgroundColor(MtfColors.bgWhite).borderRadius(12)

          // 签到卡片
          Row() {
            Column() {
              Text('每日签到').fontSize(16).fontWeight(FontWeight.Bold).fontColor(MtfColors.textMain)
              Text(this.checkInStatus?.hasSigned ? '今日已签到' : '签到获取积分').fontSize(12).fontColor(MtfColors.textLight).margin({ top: 4 })
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)
            Button(this.checkInStatus?.hasSigned ? '已签到' : (this.isCheckingIn ? '签到中...' : '立即签到'))
              .backgroundColor(this.checkInStatus?.hasSigned ? '#CCCCCC' : '#FF5722').fontColor(MtfColors.bgWhite)
              .enabled(!this.checkInStatus?.hasSigned && !this.isCheckingIn)
              .onClick(async () => {
                if (!this.checkInStatus?.formhash) return;
                this.isCheckingIn = true;
                try {
                  const res = await forumRepository.submitCheckIn(this.checkInStatus.formhash);
                  promptAction.showToast({ message: res.message });
                  if (res.success) await this.loadData();
                } catch (e) { promptAction.showToast({ message: '签到失败' }); } 
                finally { this.isCheckingIn = false; }
              })
          }.width('100%').padding(20).backgroundColor(MtfColors.bgWhite).borderRadius(12).margin({ bottom: 15 })

          // 菜单列表
          Column() {
            Row() { Text('消息通知').fontSize(15); Blank(); Text('>').fontColor(MtfColors.textLight) }.width('100%').padding(15).border({ width: { bottom: 0.5 }, color: '#EEEEEE' }).onClick(() => router.pushUrl({ url: 'pages/Notices' }))
            Row() { Text('我的私信').fontSize(15); Blank(); Text('>').fontColor(MtfColors.textLight) }.width('100%').padding(15).border({ width: { bottom: 0.5 }, color: '#EEEEEE' }).onClick(() => router.pushUrl({ url: 'pages/PmList' }))
            Row() { Text('我的帖子').fontSize(15); Blank(); Text('>').fontColor(MtfColors.textLight) }.width('100%').padding(15).border({ width: { bottom: 0.5 }, color: '#EEEEEE' }).onClick(() => router.pushUrl({ url: 'pages/MyPosts' }))
            Row() { Text('我的收藏').fontSize(15); Blank(); Text('>').fontColor(MtfColors.textLight) }.width('100%').padding(15).border({ width: { bottom: 0.5 }, color: '#EEEEEE' }).onClick(() => router.pushUrl({ url: 'pages/MyFavorites' }))
            Row() { Text('我的好友').fontSize(15); Blank(); Text('>').fontColor(MtfColors.textLight) }.width('100%').padding(15).onClick(() => router.pushUrl({ url: 'pages/MyFriends' }))
          }.width('100%').backgroundColor(MtfColors.bgWhite).borderRadius(12)

          Button('退出登录').width('100%').height(45).backgroundColor('#FF3B30').fontColor(MtfColors.bgWhite).margin({ top: 20 }).onClick(() => this.doLogout())
        }.width('90%').margin({ top: 20 })
      } else {
        Column({ space: 20 }) {
          Image($r('app.media.icon')).width(80).height(80).borderRadius(40).backgroundColor('#EEEEEE')
          Text('您尚未登录').fontSize(16).fontColor('#666')
          Button('立即登录').width('60%').height(45).backgroundColor(MtfColors.primary).fontColor(MtfColors.bgWhite).onClick(() => router.pushUrl({ url: 'pages/Login' }))
        }.width('100%').height('100%').justifyContent(FlexAlign.Center).margin({ top: -50 })
      }
    }.width('100%').height('100%').backgroundColor(MtfColors.bgLight)
  }
}
