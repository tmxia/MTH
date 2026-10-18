import { forumRepository } from '../repo/ForumRepository';
import { PmPage, PrivateMessage } from '../models/Models';
import router from '@ohos.router';

@Entry
@Component
struct PmList {
  @State pageData: PmPage | null = null;
  @State isLoading: boolean = true;

  async aboutToAppear() {
    await this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    try {
      this.pageData = await forumRepository.fetchPms();
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
        Text('私信列表').fontSize(18).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(40)
      }.width('100%').height(50).padding({ left: 16, right: 16 }).backgroundColor('#FFFFFF')

      if (this.isLoading) {
        LoadingProgress().width(50).height(50).color('#4D6BFE').margin({ top: 100 })
      } else if (this.pageData && this.pageData.messages.length > 0) {
        List({ space: 1 }) {
          ForEach(this.pageData.messages, (item: PrivateMessage) => {
            ListItem() {
              Row({ space: 15 }) {
                Image(item.avatarUrl ? item.avatarUrl : $r('app.media.icon')).width(45).height(45).borderRadius(22.5)
                Column({ space: 5 }) {
                  Text(item.username).fontSize(16).fontWeight(FontWeight.Medium)
                  Text(item.summary || '无消息内容').fontSize(13).fontColor('#999').maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                Text(item.timeText || '').fontSize(12).fontColor('#999')
              }
              .width('100%').padding(15).backgroundColor('#FFFFFF')
              .onClick(() => router.pushUrl({ url: 'pages/Chat', params: { touid: item.touid, name: item.username } }))
            }
          }, (item: PrivateMessage) => item.plid || item.touid)
        }.width('100%').layoutWeight(1).backgroundColor('#F5F5F5')
      } else {
        Text('暂无消息').fontSize(16).fontColor('#666').margin({ top: 100 })
      }
    }.width('100%').height('100%')
  }
}
