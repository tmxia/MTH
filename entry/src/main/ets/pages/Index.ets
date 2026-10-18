import { cookieManager } from '../network/CookieManager';
import { forumRepository } from '../repo/ForumRepository';
import { Thread } from '../models/Models';
import common from '@ohos.app.ability.common';
import router from '@ohos.router';

@Entry
@Component
struct Index {
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
      let err = error as Error;
      this.errorMsg = err.message || '加载失败';
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
      }
      .width('100%')
      .height(50)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      if (this.isLoading) {
        Column() {
          LoadingProgress().width(50).height(50).color('#4D6BFE')
          Text('正在加载热门帖子...').fontSize(14).fontColor('#999').margin({ top: 10 })
        }.width('100%').height('100%').justifyContent(FlexAlign.Center)
      } else if (this.errorMsg !== '') {
        Column() {
          Text('加载出错').fontSize(18).fontColor(Color.Red)
          Text(this.errorMsg).fontSize(14).fontColor('#666').margin({ top: 8 })
        }.width('100%').height('100%').justifyContent(FlexAlign.Center)
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
        }
        .width('100%')
        .layoutWeight(1)
        .padding(10)
        .backgroundColor('#F5F5F5')
      }
    }
    .width('100%')
    .height('100%')
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

      if (thread.excerpt) {
        Text(thread.excerpt).fontSize(13).fontColor('#666').maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
      }

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
