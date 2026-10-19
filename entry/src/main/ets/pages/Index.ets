import { forumRepository } from '../repo/ForumRepository';
import { Thread } from '../models/Models';
import router from '@ohos.router';

@Entry
@Component
struct Index {
  @State threads: Array<Thread> = [];
  @State isLoading: boolean = false;
  @State errorMsg: string = '';

  async aboutToAppear() {
    await this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    this.errorMsg = '';
    try {
      let res = await forumRepository.home();
      this.threads = res.hotThreads;
    } catch (e) {
      this.errorMsg = (e as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      Row() {
        Text('首页').fontSize(20).fontWeight(FontWeight.Bold)
        Blank()
        Text('草稿').fontSize(14).fontColor('#4D6BFE')
          .padding({ left: 8, right: 8, top: 6, bottom: 6 })
          .onClick(() => router.pushUrl({ url: 'pages/Drafts' }))
        Text('历史').fontSize(14).fontColor('#4D6BFE')
          .padding({ left: 8, right: 8, top: 6, bottom: 6 })
          .onClick(() => router.pushUrl({ url: 'pages/History' }))
        Button('刷新').onClick(() => {
          this.loadData();
        })
      }.width('100%').padding(10)

      if (this.isLoading) {
        LoadingProgress().width(50).height(50).margin({ top: 20 })
      } else if (this.errorMsg) {
        Text(this.errorMsg).fontColor(Color.Red).margin({ top: 20 })
      } else {
        List() {
          ForEach(this.threads, (thread: Thread) => {
            ListItem() {
              Column() {
                Text(thread.subject || '无标题')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(thread.authorName || '匿名')
                  .fontSize(12)
                  .fontColor(Color.Gray)
              }
              .alignItems(HorizontalAlign.Start)
              .padding(10)
            }
            .onClick(() => {
              if (thread.tid) {
                router.pushUrl({ url: 'pages/ThreadDetail', params: { tid: thread.tid } });
              }
            })
          }, (thread: Thread) => thread.tid)
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
  }
}
