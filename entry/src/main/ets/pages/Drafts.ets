import router from '@ohos.router';
import { DraftStore } from '../common/DraftStore';
import { PostDraft } from '../models/Models';

@Entry
@Component
struct Drafts {
  @State items: PostDraft[] = [];
  @State isLoading: boolean = true;

  onPageShow() {
    this.refresh();
  }

  refresh() {
    this.isLoading = true;
    this.items = DraftStore.getItems();
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

  openDraft(d: PostDraft) {
    router.pushUrl({
      url: 'pages/PostEdit',
      params: { fid: d.fid, name: d.forumName }
    });
  }

  async doDeleteOne(d: PostDraft) {
    await DraftStore.remove([d.fid]);
    this.refresh();
  }

  async doClear() {
    await DraftStore.clear();
    this.refresh();
  }

  confirmDeleteOne(d: PostDraft) {
    AlertDialog.show({
      title: '删除草稿',
      message: '删除该草稿？删除后无法恢复。',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '删除',
        fontColor: '#E53935',
        action: () => { this.doDeleteOne(d); }
      }
    });
  }

  confirmClear() {
    AlertDialog.show({
      title: '清空草稿箱',
      message: '确定清空全部 ' + this.items.length + ' 篇草稿吗？',
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
        Text('草稿箱')
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
          Text('暂无草稿').fontSize(14).fontColor('#999')
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List({ space: 1 }) {
          ForEach(this.items, (item: PostDraft) => {
            ListItem() {
              Row() {
                Column({ space: 6 }) {
                  Row() {
                    Text(item.forumName || ('版块 ' + item.fid))
                      .fontSize(12).fontColor('#999')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .layoutWeight(1)
                    Text(this.formatTime(item.savedAt || 0))
                      .fontSize(11).fontColor('#BBB').margin({ left: 8 })
                  }.width('100%')

                  Text(item.subject || '无标题')
                    .fontSize(15).fontWeight(FontWeight.Medium).fontColor('#333')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')

                  if (item.message) {
                    Text(item.message)
                      .fontSize(12).fontColor('#666')
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .width('100%')
                  }
                }
                .layoutWeight(1).alignItems(HorizontalAlign.Start)
                .onClick(() => this.openDraft(item))

                Text('删除')
                  .fontSize(12).fontColor('#E53935')
                  .padding({ left: 12, top: 4, bottom: 4, right: 4 })
                  .onClick(() => this.confirmDeleteOne(item))
              }
              .width('100%').padding(16).backgroundColor('#FFFFFF')
              .alignItems(VerticalAlign.Top)
            }
          }, (item: PostDraft) => item.fid)
        }
        .width('100%').layoutWeight(1).backgroundColor('#F5F5F5')
      }
    }
    .width('100%').height('100%')
  }
}
