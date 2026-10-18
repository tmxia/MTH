import { forumRepository } from '../repo/ForumRepository';
import { FavoritePage, FavoriteItem } from '../models/Models';
import router from '@ohos.router';

@Entry
@Component
struct MyFavorites {
  @State items: Array<FavoriteItem> = [];
  @State isLoading: boolean = true;

  async aboutToAppear() {
    await this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    try {
      const res = await forumRepository.myFavorites(1);
      this.items = res.items;
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
        Text('我的收藏').fontSize(18).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(40)
      }.width('100%').height(50).padding({ left: 16, right: 16 }).backgroundColor('#FFFFFF')

      if (this.isLoading && this.items.length === 0) {
        LoadingProgress().width(50).height(50).color('#4D6BFE').margin({ top: 100 })
      } else if (this.items.length === 0) {
        Text('暂无数据').fontSize(16).fontColor('#666').margin({ top: 100 })
      } else {
        List({ space: 10 }) {
          ForEach(this.items, (item: FavoriteItem) => {
            ListItem() {
              Column({ space: 8 }) {
                Text(item.title).fontSize(15).fontWeight(FontWeight.Bold).maxLines(2)
              }
              .width('100%').padding(12).backgroundColor('#FFFFFF').borderRadius(8)
              .onClick(() => router.pushUrl({ url: 'pages/ThreadDetail', params: { tid: item.id } }))
            }
          }, (item: FavoriteItem) => item.id)
        }.width('100%').layoutWeight(1).padding(10).backgroundColor('#F5F5F5')
      }
    }.width('100%').height('100%')
  }
}
