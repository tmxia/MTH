import router from '@ohos.router';
import { historyStore } from '../common/HistoryStore';
import { HistoryItem } from '../models/Models';

@Entry
@Component
struct History {
  @State items: HistoryItem[] = [];
  @State isLoading: boolean = true;

  onPageShow() {
    this.refresh();
  }

  refresh() {
    this.isLoading = true;
    this.items = historyStore.getItems();
    this.isLoading = false;
  }

  formatTime(timestamp: number): string {
    if (!timestamp || timestamp <= 0) return '';
    const d = new Date(timestamp);
    const yyyy = d.getFullYear();
    const mm = d.getMonth() + 1;
    const dd = d.getDate();
    const hh = d.getHours();
    const mi = d.getMinutes();
    const mmS = mm < 10 ? '0' + mm : '' + mm;
    const ddS = dd < 10 ? '0' + dd : '' + dd;
    const hhS = hh < 10 ? '0' + hh : '' + hh;
    const miS = mi < 10 ? '0' + mi : '' + mi;
    return yyyy + '-' + mmS + '-' + ddS + ' ' + hhS + ':' + miS;
  }

  openItem(item: HistoryItem) {
    if (item.type === 'thread' || !item.type) {
      router.pushUrl({ url: 'pages/ThreadDetail', params: { tid: item.tid } });
    } else if (item.type === 'user') {
      router.pushUrl({ url: 'pages/UserProfilePage', params: { uid: item.tid } });
    }
  }

  async doDeleteOne(item: HistoryItem) {
    await historyStore.remove(item.tid, item.type || 'thread');
    this.refresh();
  }

  async doClear() {
    await historyStore.clear();
    this.refresh();
  }

  confirmDeleteOne(item: HistoryItem) {
    AlertDialog.show({
      title: '删除记录',
      message: '删除这条浏览记录？',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '删除',
        fontColor: '#E53935',
        action: () => { this.doDeleteOne(item); }
      }
    });
  }

  confirmClear() {
    AlertDialog.show({
      title: '清空浏览记录',
      message: '确定清空全部 ' + this.items.length + ' 条记录吗？',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '清空',
        fontColor: '#E53935',
        action: () => { this.doClear(); }
      }
    });
  }

  build() {
    Column() {
      Row() {
        Text('< 返回').fontSize(16).fontColor('#333').onClick(() => router.back())
        Text('浏览记录')
          .fontSize(18).fontWeight(FontWeight.Bold)
          .layoutWeight(1).textAlign(TextAlign.Center)
        if (this.items.length > 0) {
          Text('清空').fontSize(14).fontColor('#E53935').onClick(() => this.confirmClear())
        } else {
          Blank().width(28)
        }
      }
      .width('100%').height(50)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      if (this.isLoading) {
        Column() { LoadingProgress().width(50).height(50).color('#4D6BFE') }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.items.length === 0) {
        Column() {
          Text('暂无浏览记录').fontSize(14).fontColor('#999')
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List({ space: 1 }) {
          ForEach(this.items, (item: HistoryItem) => {
            ListItem() {
              Row() {
                Column({ space: 6 }) {
                  Row() {
                    Text(item.forumName || (item.type === 'user' ? '用户' : '版块'))
                      .fontSize(12).fontColor('#999')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .layoutWeight(1)
                    Text(this.formatTime(item.viewedAt || 0))
                      .fontSize(11).fontColor('#BBB').margin({ left: 8 })
                  }.width('100%')

                  Text(item.title || '(无标题)')
                    .fontSize(15).fontWeight(FontWeight.Medium).fontColor('#333')
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')

                  if (item.author) {
                    Text('作者: ' + item.author)
                      .fontSize(12).fontColor('#666')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .width('100%')
                  }
                }
                .layoutWeight(1).alignItems(HorizontalAlign.Start)
                .onClick(() => this.openItem(item))

                Text('删除')
                  .fontSize(12).fontColor('#E53935')
                  .padding({ left: 12, top: 4, bottom: 4, right: 4 })
                  .onClick(() => this.confirmDeleteOne(item))
              }
              .width('100%').padding(16).backgroundColor('#FFFFFF')
              .alignItems(VerticalAlign.Top)
            }
          }, (item: HistoryItem) => item.tid + '::' + (item.type || 'thread'))
        }
        .width('100%').layoutWeight(1).backgroundColor('#F5F5F5')
      }
    }
    .width('100%').height('100%')
  }
}
