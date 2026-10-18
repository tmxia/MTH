import { forumRepository } from '../repo/ForumRepository';
import { ForumPage, Thread } from '../models/Models';
import router from '@ohos.router';

@Entry
@Component
struct ForumPageList {
  @State fp: ForumPage | null = null;
  @State isLoading: boolean = true;
  @State errorMsg: string = '';
  @State fid: string = '';
  @State title: string = '';

  async aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    if (params && params.fid) {
      this.fid = params.fid;
      this.title = params.name || '版块列表';
      await this.loadData(this.fid, 1);
    } else {
      this.errorMsg = "未找到版块ID";
      this.isLoading = false;
    }
  }

  async loadData(fid: string, page: number) {
    this.isLoading = true;
    try {
      const data = await forumRepository.forumPage(fid, page);
      this.fp = data;
    } catch (e) {
      this.errorMsg = (e as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      Row() {
        Text('< 返回').fontSize(16).fontColor('#333').onClick(() => router.back())
        Text(this.title).fontSize(18).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(40)
      }.width('100%').height(50).padding({ left: 16, right: 16 }).backgroundColor('#FFFFFF')

      if (this.isLoading) {
        LoadingProgress().width(50).height(50).color('#4D6BFE').margin({ top: 100 })
      } else if (this.errorMsg !== '') {
        Text(this.errorMsg).fontSize(16).fontColor(Color.Red).margin({ top: 100 })
      } else if (this.fp) {
        List({ space: 10 }) {
          // 如果有公告
          if (this.fp.announcements.length > 0) {
            ListItem() {
              Text('版块公告').fontSize(14).fontWeight(FontWeight.Bold).fontColor('#FF5722').padding({ left: 16, top: 10, bottom: 5 })
            }
          }
          ForEach(this.fp.announcements, (item: Thread) => {
            ListItem() {
              this.ThreadCard(item, true)
            }
          }, (item: Thread) => item.tid)

          // 普通帖子
          ForEach(this.fp.threads, (item: Thread) => {
            ListItem() {
              this.ThreadCard(item, false)
            }
            .onClick(() => {
              router.pushUrl({ url: 'pages/ThreadDetail', params: { tid: item.tid } });
            })
          }, (item: Thread) => item.tid)
        }
        .width('100%').layoutWeight(1).padding(10).backgroundColor('#F5F5F5')
      }
    }
    .width('100%').height('100%')
  }

  @Builder
  ThreadCard(thread: Thread, isAnnouncement: boolean) {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Image(thread.avatarUrl ? thread.avatarUrl : $r('app.media.icon'))
          .width(30).height(30).borderRadius(15).backgroundColor('#EEEEEE')
        Column() {
          Text(thread.authorName || '匿名用户').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#333')
          Text(thread.timeText || '刚刚').fontSize(11).fontColor('#999')
        }.alignItems(HorizontalAlign.Start)
        Blank()
        if (isAnnouncement) {
          Text('公告').fontSize(10).fontColor('#FFFFFF').backgroundColor('#FF5722').padding({ left: 4, right: 4, top: 1, bottom: 1 }).borderRadius(4)
        }
      }.width('100%')

      Text(thread.subject).fontSize(16).fontWeight(FontWeight.Bold).fontColor('#111').maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })

      if (thread.excerpt) {
        Text(thread.excerpt).fontSize(13).fontColor('#666').maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
      }

      Row({ space: 15 }) {
        Text(`阅读 ${thread.viewCount || 0}`).fontSize(12).fontColor('#999')
        Text(`回复 ${thread.replyCount || 0}`).fontSize(12).fontColor('#999')
        Blank()
      }.width('100%').margin({ top: 4 })
    }
    .width('100%').padding(12).backgroundColor('#FFFFFF').borderRadius(10)
  }
}
