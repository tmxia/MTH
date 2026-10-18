import { cookieManager } from '../network/CookieManager';
import { forumRepository } from '../repo/ForumRepository';
import { Thread, ForumGroup, Forum } from '../models/Models';
import common from '@ohos.app.ability.common';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { UserProfile } from '../models/Models';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;

  build() {
    Tabs({ barPosition: BarPosition.End }) {
      // Tab 1: 热门首页
      TabContent() {
        HomeTab()
      }.tabBar('首页')

      // Tab 2: 版块导航
      TabContent() {
        ForumTab()
      }.tabBar('版块')

      // Tab 3: 我的
      TabContent() {
        ProfileTab()
      }.tabBar('我的')
    }
    .onChange((index: number) => {
      this.currentIndex = index;
    })
  }
}

// ==========================================
// 首页组件 (热门)
// ==========================================
@Component
struct HomeTab {
  @State threads: Array<Thread> = [];
  @State isLoading: boolean = true;
  @State errorMsg: string = '';

  async aboutToAppear() {
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    await cookieManager.init(context);
    await this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    this.errorMsg = '';
    try {
      let homeData = await forumRepository.home();
      this.threads = homeData.hotThreads;
    } catch (error) {
      this.errorMsg = (error as Error).message || '加载失败';
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      Row() {
        Text('MT论坛').fontSize(20).fontWeight(FontWeight.Bold).fontColor('#333')
        Blank()
        Text('去登录').fontSize(14).fontColor('#4D6BFE').onClick(() => {
          router.pushUrl({ url: 'pages/Login' });
        })
      }.width('100%').height(50).padding({ left: 16, right: 16 }).backgroundColor('#FFFFFF')

      if (this.isLoading) {
        LoadingProgress().width(50).height(50).color('#4D6BFE').margin({ top: 100 })
      } else if (this.errorMsg !== '') {
        Text(this.errorMsg).fontSize(16).fontColor(Color.Red).margin({ top: 100 })
      } else {
        List({ space: 10 }) {
          ForEach(this.threads, (item: Thread) => {
            ListItem() {
              this.ThreadCard(item)
            }
            .onClick(() => {
              router.pushUrl({ url: 'pages/ThreadDetail', params: { tid: item.tid } });
            })
          }, (item: Thread) => item.tid)
        }.width('100%').layoutWeight(1).padding(10).backgroundColor('#F5F5F5')
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
          Text(thread.authorName || '匿名用户').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#333')
          Text(thread.timeText || '刚刚').fontSize(11).fontColor('#999')
        }.alignItems(HorizontalAlign.Start)
      }.width('100%')

      Text(thread.subject).fontSize(16).fontWeight(FontWeight.Bold).fontColor('#111').maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })

      if (thread.imageUrls && thread.imageUrls.length > 0) {
        Image(thread.imageUrls[0]).width('100%').height(150).objectFit(ImageFit.Cover).borderRadius(6).backgroundColor('#EEEEEE')
      }

      Row({ space: 15 }) {
        Text(`阅读 ${thread.viewCount || 0}`).fontSize(12).fontColor('#999')
        Text(`回复 ${thread.replyCount || 0}`).fontSize(12).fontColor('#999')
        Blank()
      }.width('100%').margin({ top: 4 })
    }
    .width('100%').padding(12).backgroundColor('#FFFFFF').borderRadius(10)
    .shadow({ radius: 4, color: '#0A000000', offsetX: 0, offsetY: 2 })
  }
}

// ==========================================
// 版块导航组件
// ==========================================
@Component
struct ForumTab {
  @State groups: Array<ForumGroup> = [];
  @State isLoading: boolean = true;

  async aboutToAppear() {
    await this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    try {
      this.groups = await forumRepository.forumGroups();
    } catch (e) {
      console.error('Load forums failed', e);
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      Row() {
        Text('版块导航').fontSize(20).fontWeight(FontWeight.Bold).fontColor('#333')
      }.width('100%').height(50).padding({ left: 16 }).backgroundColor('#FFFFFF')

      if (this.isLoading) {
        LoadingProgress().width(50).height(50).color('#4D6BFE').margin({ top: 100 })
      } else {
        List({ space: 15 }) {
          ForEach(this.groups, (group: ForumGroup) => {
            ListItem() {
              Column({ space: 10 }) {
                Text(group.name).fontSize(16).fontWeight(FontWeight.Bold).fontColor('#4D6BFE').width('100%').margin({ bottom: 5 })
                
                ForEach(group.forums, (forum: Forum) => {
                  Row({ space: 10 }) {
                    if (forum.icon) {
                      Image(forum.icon).width(36).height(36).borderRadius(6)
                    } else {
                      Image($r('app.media.icon')).width(36).height(36).borderRadius(6)
                    }
                    
                    Column() {
                      Text(forum.name).fontSize(15).fontColor('#333').fontWeight(FontWeight.Medium)
                    }.alignItems(HorizontalAlign.Start).layoutWeight(1)

                    if (forum.todayPosts > 0) {
                      Text(`今日: ${forum.todayPosts}`).fontSize(12).fontColor('#FF5722')
                    }
                  }
                  .width('100%')
                  .padding(10)
                  .backgroundColor('#F9F9F9')
                  .borderRadius(8)
                  .onClick(() => {
                    router.pushUrl({ url: 'pages/ForumPageList', params: { fid: forum.fid, name: forum.name } });
                  })
                }, (forum: Forum) => forum.fid)
              }
              .width('100%').padding(15).backgroundColor('#FFFFFF').borderRadius(12)
            }
          }, (group: ForumGroup) => group.name)
        }
        .width('100%').layoutWeight(1).padding(15).backgroundColor('#F5F5F5')
      }
    }.width('100%').height('100%')
  }
}


// ==========================================
// 个人中心组件
// ==========================================
@Component
struct ProfileTab {
  @State profile: UserProfile | null = null;
  @State isLoading: boolean = true;
  @State checkInStatus: CheckInStatus | null = null;
  @State isCheckingIn: boolean = false;

  async aboutToAppear() {
    await this.loadData();
  }

  onPageShow() {
    // 从登录页返回时，重新拉取状态
    this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    try {
      this.profile = await forumRepository.me();
      if (this.profile.isLoggedIn) {
        this.checkInStatus = await forumRepository.checkInStatus();
      }
    } catch (e) {
      console.error('Failed to load profile', e);
    } finally {
      this.isLoading = false;
    }
  }

  async doLogout() {
    await cookieManager.clear();
    this.profile = null;
    promptAction.showToast({ message: '已退出登录' });
    // 刷新页面状态
    this.loadData();
  }

  build() {
    Column() {
      // 顶部标题
      Row() {
        Text('个人中心').fontSize(20).fontWeight(FontWeight.Bold).fontColor('#333')
      }.width('100%').height(50).padding({ left: 16 }).backgroundColor('#FFFFFF')

      if (this.isLoading) {
        LoadingProgress().width(50).height(50).color('#4D6BFE').margin({ top: 100 })
      } else if (this.profile && this.profile.isLoggedIn) {
        // 已登录 UI
        Column({ space: 15 }) {
          // 头部卡片
          Row({ space: 15 }) {
            Image(this.profile.avatarUrl ? this.profile.avatarUrl : $r('app.media.icon'))
              .width(60).height(60).borderRadius(30).backgroundColor('#EEEEEE')
            Column({ space: 5 }) {
              Text(this.profile.name || '未知用户').fontSize(18).fontWeight(FontWeight.Bold)
              Text(this.profile.groupName || '普通会员').fontSize(12).fontColor('#4D6BFE').backgroundColor('#E8F0FE').padding({ left: 6, right: 6, top: 2, bottom: 2 }).borderRadius(4)
            }.alignItems(HorizontalAlign.Start)
            Blank()
          }.width('100%').padding(20).backgroundColor('#FFFFFF').borderRadius(12)

          // 数据统计
          Row() {
            Column() { Text(`${this.profile.posts || 0}`).fontSize(16).fontWeight(FontWeight.Bold); Text('帖子').fontSize(12).fontColor('#999') }.layoutWeight(1)
            Column() { Text(`${this.profile.credits || 0}`).fontSize(16).fontWeight(FontWeight.Bold); Text('积分').fontSize(12).fontColor('#999') }.layoutWeight(1)
            Column() { Text(`${this.profile.gold || 0}`).fontSize(16).fontWeight(FontWeight.Bold); Text('金币').fontSize(12).fontColor('#999') }.layoutWeight(1)
          }.width('100%').padding({ top: 15, bottom: 15 }).backgroundColor('#FFFFFF').borderRadius(12)


          // 签到卡片
          Row() {
            Column() {
              Text('每日签到').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333')
              Text(this.checkInStatus?.hasSigned ? '今日已签到' : '签到获取积分').fontSize(12).fontColor('#999').margin({ top: 4 })
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)
            
            Button(this.checkInStatus?.hasSigned ? '已签到' : (this.isCheckingIn ? '签到中...' : '立即签到'))
              .backgroundColor(this.checkInStatus?.hasSigned ? '#CCCCCC' : '#FF5722')
              .fontColor('#FFFFFF')
              .enabled(!this.checkInStatus?.hasSigned && !this.isCheckingIn)
              .onClick(async () => {
                if (!this.checkInStatus?.formhash) return;
                this.isCheckingIn = true;
                try {
                  const res = await forumRepository.submitCheckIn(this.checkInStatus.formhash);
                  promptAction.showToast({ message: res.message });
                  if (res.success) {
                    await this.loadData(); // 刷新状态
                  }
                } catch (e) {
                  promptAction.showToast({ message: '签到失败' });
                } finally {
                  this.isCheckingIn = false;
                }
              })
          }.width('100%').padding(20).backgroundColor('#FFFFFF').borderRadius(12).margin({ bottom: 15 })

          // 菜单列表
          Column() {
            Row() { Text('我的帖子').fontSize(15); Blank(); Text('>').fontColor('#999') }.width('100%').padding(15).border({ width: { bottom: 0.5 }, color: '#EEEEEE' })
            Row() { Text('我的收藏').fontSize(15); Blank(); Text('>').fontColor('#999') }.width('100%').padding(15).border({ width: { bottom: 0.5 }, color: '#EEEEEE' })
            Row() { Text('我的好友').fontSize(15); Blank(); Text('>').fontColor('#999') }.width('100%').padding(15) }
          .width('100%').backgroundColor('#FFFFFF').borderRadius(12)

          // 退出登录按钮
          Button('退出登录')
            .width('100%').height(45).backgroundColor('#FF3B30').fontColor('#FFFFFF').margin({ top: 20 })
            .onClick(() => this.doLogout())
        }
        .width('90%').margin({ top: 20 })
      } else {
        // 未登录 UI
        Column({ space: 20 }) {
          Image($r('app.media.icon')).width(80).height(80).borderRadius(40).backgroundColor('#EEEEEE')
          Text('您尚未登录').fontSize(16).fontColor('#666')
          Button('立即登录')
            .width('60%').height(45).backgroundColor('#4D6BFE').fontColor('#FFFFFF')
            .onClick(() => {
              router.pushUrl({ url: 'pages/Login' });
            })
        }
        .width('100%').height('100%').justifyContent(FlexAlign.Center).margin({ top: -50 })
      }
    }.width('100%').height('100%').backgroundColor('#F5F5F5')
  }
}
