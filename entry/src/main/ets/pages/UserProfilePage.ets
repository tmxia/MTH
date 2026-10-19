import { forumRepository } from '../repo/ForumRepository';
import { MyThreadPage, Thread } from '../models/Models';
import router from '@ohos.router';

@Entry
@Component
struct UserProfilePage {
  @State threads: Array<Thread> = [];
  @State isLoading: boolean = true;
  @State uid: string = '';

  async aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    if (params && params.uid) {
      this.uid = params.uid;
      await this.loadData();
    } else {
      this.isLoading = false;
    }
  }

  async loadData() {
    this.isLoading = true;
    try {
      const res = await forumRepository.userThreads(this.uid);
      this.threads = res.threads;
    } catch (e) {
      console.error(JSON.stringify(e));
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      Row() {
        Text('< 返回').fontSize(16).fontColor('#333').onClick(() => router.back())
        Text('Ta 的主页').fontSize(18).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(40)
      }.width('100%').height(50).padding({ left: 16, right: 16 }).backgroundColor('#FFFFFF')

      if (this.isLoading) {
        LoadingProgress().width(50).height(50).color('#4D6BFE').margin({ top: 100 })
      } else if (this.threads.length === 0) {
        Text('Ta 还没有发过帖子').fontSize(16).fontColor('#999').margin({ top: 100 })
      } else {
        List({ space: 10 }) {
          ForEach(this.threads, (item: Thread) => {
            ListItem() {
              Column({ space: 8 }) {
                Text(item.subject).fontSize(15).fontWeight(FontWeight.Bold).maxLines(2)
                Row() {
                  Text(item.forumName || '').fontSize(12).fontColor('#4D6BFE')
                  Blank()
                  Text(item.timeText || '').fontSize(12).fontColor('#999')
                }.width('100%')
              }
              .width('100%').padding(12).backgroundColor('#FFFFFF').borderRadius(8)
              .onClick(() => router.pushUrl({ url: 'pages/ThreadDetail', params: { tid: item.tid } }))
            }
          }, (item: Thread) => item.tid)
        }.width('100%').layoutWeight(1).padding(10).backgroundColor('#F5F5F5')
      }
    }.width('100%').height('100%')
  }
}
