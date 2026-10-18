import { cookieManager } from '../network/CookieManager';
import { forumRepository } from '../repo/ForumRepository';
import { Thread, ForumGroup, Forum } from '../models/Models';
import common from '@ohos.app.ability.common';
import router from '@ohos.router';

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
        Column() {
          Text('个人中心待开发').fontSize(16).fontColor('#999')
        }.width('100%').height('100%').justifyContent(FlexAlign.Center)
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
