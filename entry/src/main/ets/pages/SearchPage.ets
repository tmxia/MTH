import { forumRepository } from '../repo/ForumRepository';
import { Thread } from '../models/Models';
import router from '@ohos.router';

@Entry
@Component
struct SearchPage {
  @State keyword: string = '';
  @State threads: Array<Thread> = [];
  @State isLoading: boolean = false;

  async doSearch() {
    if (!this.keyword.trim()) return;
    this.isLoading = true;
    try {
      const res = await forumRepository.search(this.keyword);
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
        Text('全站搜索').fontSize(18).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(40)
      }.width('100%').height(50).padding({ left: 16, right: 16 }).backgroundColor('#FFFFFF')

      Row({ space: 10 }) {
        TextInput({ placeholder: '输入关键字搜索', text: this.keyword })
          .layoutWeight(1).height(40).backgroundColor('#F0F0F0').borderRadius(20)
          .onChange((val: string) => this.keyword = val)
        Button('搜索').height(40).backgroundColor('#4D6BFE').onClick(() => this.doSearch())
      }.width('100%').padding(15).backgroundColor('#FFFFFF')

      if (this.isLoading) {
        LoadingProgress().width(50).height(50).color('#4D6BFE').margin({ top: 100 })
      } else {
        List({ space: 10 }) {
          ForEach(this.threads, (item: Thread) => {
            ListItem() {
              Column({ space: 8 }) {
                Text(item.subject).fontSize(15).fontWeight(FontWeight.Bold).maxLines(2)
                Row() {
                  Text(item.authorName || '').fontSize(12).fontColor('#4D6BFE')
                  Blank()
                  Text(item.timeText || '').fontSize(12).fontColor('#999')
                }.width('100%')
              }.width('100%').padding(12).backgroundColor('#FFFFFF').borderRadius(8)
              .onClick(() => router.pushUrl({ url: 'pages/ThreadDetail', params: { tid: item.tid } }))
            }
          }, (item: Thread) => item.tid)
        }.width('100%').layoutWeight(1).padding(10).backgroundColor('#F5F5F5')
      }
    }.width('100%').height('100%')
  }
}
