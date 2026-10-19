import router from '@ohos.router';
import { downloadStore } from '../common/DownloadStore';
import { threadArchiveStore } from '../common/ThreadArchiveStore';
import { DownloadedThread } from '../models/Models';

@Entry
@Component
struct Downloads {
  @State items: DownloadedThread[] = [];
  @State isLoading: boolean = true;

  onPageShow() {
    this.refresh();
  }

  refresh() {
    this.isLoading = true;
    this.items = downloadStore.getItems();
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

  formatSize(bytes: number): string {
    if (!bytes || bytes <= 0) return '';
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
    return (bytes / 1024 / 1024).toFixed(2) + ' MB';
  }

  openThread(item: DownloadedThread) {
    router.pushUrl({
      url: 'pages/ThreadDetail',
      params: { tid: item.tid, offline: 'true' }
    });
  }

  async doDelete(item: DownloadedThread) {
    await downloadStore.remove(item.tid);
    await threadArchiveStore.delete(item.tid);
    this.refresh();
  }

  confirmDelete(item: DownloadedThread) {
    AlertDialog.show({
      title: '删除下载',
      message: '删除后无法离线阅读，确定删除？',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '删除',
        fontColor: '#E53935',
        action: () => { this.doDelete(item); }
      }
    });
  }

  build() {
    Column() {
      Row() {
        Text('< 返回').fontSize(16).fontColor('#333').onClick(() => router.back())
        Text('离线下载')
          .fontSize(18).fontWeight(FontWeight.Bold)
          .layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(40)
      }
      .width('100%').height(50)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      if (this.isLoading) {
        Column() { LoadingProgress().width(50).height(50).color('#4D6BFE') }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.items.length === 0) {
        Column() {
          Text('暂无离线下载').fontSize(14).fontColor('#999')
          Text('在帖子详情页点「下载」即可离线阅读').fontSize(12).fontColor('#BBB').margin({ top: 8 })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List({ space: 1 }) {
          ForEach(this.items, (item: DownloadedThread) => {
            ListItem() {
              Row() {
                Column({ space: 6 }) {
                  Row() {
                    Text(item.forumName || '版块')
                      .fontSize(12).fontColor('#999')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .layoutWeight(1)
                    Text(this.formatTime(item.savedAt || 0))
                      .fontSize(11).fontColor('#BBB').margin({ left: 8 })
                  }.width('100%')

                  Text(item.subject || '(无标题)')
                    .fontSize(15).fontWeight(FontWeight.Medium).fontColor('#333')
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')

                  Row() {
                    Text((item.replyCount || 0) + ' 楼')
                      .fontSize(11).fontColor('#999')
                    Text(this.formatSize(item.sizeBytes || 0))
                      .fontSize(11).fontColor('#999').margin({ left: 12 })
                  }.width('100%')
                }
                .layoutWeight(1).alignItems(HorizontalAlign.Start)
                .onClick(() => this.openThread(item))

                Text('删除')
                  .fontSize(12).fontColor('#E53935')
                  .padding({ left: 12, top: 4, bottom: 4, right: 4 })
                  .onClick(() => this.confirmDelete(item))
              }
              .width('100%').padding(16).backgroundColor('#FFFFFF')
              .alignItems(VerticalAlign.Top)
            }
          }, (item: DownloadedThread) => item.tid || '')
        }
        .width('100%').layoutWeight(1).backgroundColor('#F5F5F5')
      }
    }
    .width('100%').height('100%')
  }
}
