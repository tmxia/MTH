import { forumRepository } from '../repo/ForumRepository';
import { FriendUserPage } from '../models/Models';
import router from '@ohos.router';

@Entry
@Component
struct MyFriends {
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
      const res = await forumRepository.myFriends(this.page);
      this.items = this.items.concat(res.users);
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
        Text('我的好友').fontSize(18).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center)
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
              
    Row({ space: 10 }) {
      Image($r('app.media.icon')).width(40).height(40).borderRadius(20)
      Text(item.username).fontSize(15).fontWeight(FontWeight.Medium)
      Blank()
    }
    .width('100%').padding(12).backgroundColor('#FFFFFF').borderRadius(8)
    
            }
          })
        }
        .width('100%').layoutWeight(1).padding(10).backgroundColor('#F5F5F5')
      }
    }.width('100%').height('100%')
  }
}
