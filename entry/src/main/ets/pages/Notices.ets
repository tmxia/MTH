import { forumRepository } from '../repo/ForumRepository';
import { NoticePage, Notice } from '../models/Models';
import router from '@ohos.router';

@Entry
@Component
struct Notices {
  @State pageData: NoticePage | null = null;
  @State isLoading: boolean = true;

  async aboutToAppear() {
    await this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    try {
      this.pageData = await forumRepository.notices();
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
        Text('消息中心').fontSize(18).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(40)
      }.width('100%').height(50).padding({ left: 16, right: 16 }).backgroundColor('#FFFFFF')

      if (this.isLoading) {
        LoadingProgress().width(50).height(50).color('#4D6BFE').margin({ top: 100 })
      } else if (this.pageData && this.pageData.loggedOut) {
        Text('请先登录').fontSize(16).fontColor('#666').margin({ top: 100 })
      } else if (this.pageData && this.pageData.notices.length > 0) {
        List({ space: 1 }) {
          ForEach(this.pageData.notices, (item: Notice) => {
            ListItem() {
              Column({ space: 8 }) {
                Text(item.text).fontSize(15).fontColor('#333').maxLines(3).textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(item.timeText || '').fontSize(12).fontColor('#999')
              }
              .width('100%').padding(16).backgroundColor('#FFFFFF').alignItems(HorizontalAlign.Start)
            }
            .onClick(() => {
              if (item.tid) {
                router.pushUrl({ url: 'pages/ThreadDetail', params: { tid: item.tid } });
              }
            })
          }, (item: Notice) => item.id)
        }.width('100%').layoutWeight(1).backgroundColor('#F5F5F5')
      } else {
        Column() {
          Image($r('app.media.icon')).width(60).height(60).opacity(0.5)
          Text('暂无消息').fontSize(14).fontColor('#999').margin({ top: 10 })
        }.width('100%').height('100%').justifyContent(FlexAlign.Center)
      }
    }.width('100%').height('100%')
  }
}
