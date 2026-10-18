import { forumRepository } from '../repo/ForumRepository';
import { MyThreadPage } from '../models/Models';
import router from '@ohos.router';

@Entry
@Component
struct MyPosts {
  @State items: Array<any> = [];
  @State isLoading: boolean = true;
  @State page: number = 1;
  @State hasNext: boolean = true;

  async aboutToAppear() {
    await this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    try {
      const res = await forumRepository.myThreads(this.page);
      this.items = this.items.concat(res.threads);
      this.hasNext = res.hasNext;
    } catch (e) {
      console.error(e);
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      Row() {
        Text('< 返回').fontSize(16).fontColor('#333').onClick(() => router.back())
        Text('我的帖子').fontSize(18).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(40)
      }.width('100%').height(50).padding({ left: 16, right: 16 }).backgroundColor('#FFFFFF')

      if (this.isLoading && this.items.length === 0) {
        LoadingProgress().width(50).height(50).color('#4D6BFE').margin({ top: 100 })
      } else if (this.items.length === 0) {
        Text('暂无数据').fontSize(16).fontColor('#666').margin({ top: 100 })
      } else {
        List({ space: 10 }) {
          ForEach(this.items, (item: any) => {
            ListItem() {
              
    Column({ space: 8 }) {
      Text(item.subject).fontSize(15).fontWeight(FontWeight.Bold).maxLines(2)
      Row() {
        Text(item.forumName || '').fontSize(12).fontColor('#4D6BFE')
        Blank()
        Text(`回复: ${item.replyCount || 0}`).fontSize(12).fontColor('#999')
      }.width('100%')
    }
    .width('100%').padding(12).backgroundColor('#FFFFFF').borderRadius(8)
    .onClick(() => router.pushUrl({ url: 'pages/ThreadDetail', params: { tid: item.tid } }))
    
            }
          })
        }
        .width('100%').layoutWeight(1).padding(10).backgroundColor('#F5F5F5')
      }
    }.width('100%').height('100%')
  }
}
