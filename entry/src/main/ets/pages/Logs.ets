import router from '@ohos.router';
import { LogStore, LogEntry, LogLevel, levelLabel, levelColor } from '../common/LogStore';

@Entry
@Component
struct Logs {
  @State entries: LogEntry[] = [];
  @State filter: number = -1;
  @State currentLevel: LogLevel = LogLevel.INFO;

  onPageShow() {
    this.refresh();
  }

  refresh() {
    this.entries = LogStore.getEntries();
    this.currentLevel = LogStore.getLevel();
  }

  getShown(): LogEntry[] {
    if (this.filter < 0) return this.entries;
    const out: LogEntry[] = [];
    for (let i = 0; i < this.entries.length; i++) {
      if (this.entries[i].level === this.filter) out.push(this.entries[i]);
    }
    return out;
  }

  countLevel(l: LogLevel): number {
    let n = 0;
    for (let i = 0; i < this.entries.length; i++) {
      if (this.entries[i].level === l) n++;
    }
    return n;
  }

  formatTime(timestamp: number): string {
    if (!timestamp || timestamp <= 0) return '';
    const d = new Date(timestamp);
    const hh = d.getHours();
    const mi = d.getMinutes();
    const ss = d.getSeconds();
    const hhS = hh < 10 ? '0' + hh : '' + hh;
    const miS = mi < 10 ? '0' + mi : '' + mi;
    const ssS = ss < 10 ? '0' + ss : '' + ss;
    return hhS + ':' + miS + ':' + ssS;
  }

  openDetail(e: LogEntry) {
    router.pushUrl({ url: 'pages/LogDetail', params: { id: '' + e.id } });
  }

  showLevelPicker() {
    AlertDialog.show({
      title: '日志等级设置',
      message: '设为较高等级后，更低等级的日志将不再记录。当前：' + levelLabel(this.currentLevel),
      primaryButton: { value: 'Info', action: () => { this.setLevel(LogLevel.INFO); } },
      secondaryButton: { value: 'Warn', action: () => { this.setLevel(LogLevel.WARN); } }
    });
  }

  async setLevel(l: LogLevel) {
    await LogStore.setLevel(l);
    this.refresh();
  }

  confirmClear() {
    AlertDialog.show({
      title: '清空日志',
      message: '将删除全部内存中的日志记录。',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '确认清空',
        fontColor: '#E53935',
        action: () => {
          LogStore.clear();
          this.refresh();
        }
      }
    });
  }

  build() {
    Column() {
      Row() {
        Text('< 返回').fontSize(16).fontColor('#333').onClick(() => router.back())
        Text('日志')
          .fontSize(18).fontWeight(FontWeight.Bold)
          .layoutWeight(1).textAlign(TextAlign.Center)
        Text('清空').fontSize(13).fontColor('#E53935').onClick(() => this.confirmClear())
      }
      .width('100%').height(50)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      Row() {
        Text('记录等级: ' + levelLabel(this.currentLevel))
          .fontSize(12).fontColor('#4D6BFE').fontWeight(FontWeight.Medium)
        Text('  只记录该等级及以上').fontSize(11).fontColor('#999').layoutWeight(1)
        Text('设置').fontSize(12).fontColor('#4D6BFE').onClick(() => this.showLevelPicker())
      }
      .width('100%').padding({ left: 14, right: 14, top: 8, bottom: 8 })
      .backgroundColor('#F9F9F9')

      Row({ space: 6 }) {
        Text('全部 (' + this.entries.length + ')')
          .fontSize(11).padding({ top: 6, bottom: 6, left: 8, right: 8 })
          .borderRadius(12)
          .backgroundColor(this.filter < 0 ? '#E8EEFF' : '#F0F0F0')
          .fontColor(this.filter < 0 ? '#4D6BFE' : '#666')
          .onClick(() => { this.filter = -1; })
        Text('Info (' + this.countLevel(LogLevel.INFO) + ')')
          .fontSize(11).padding({ top: 6, bottom: 6, left: 8, right: 8 })
          .borderRadius(12)
          .backgroundColor(this.filter === LogLevel.INFO ? '#E8EEFF' : '#F0F0F0')
          .fontColor(this.filter === LogLevel.INFO ? '#4D6BFE' : '#666')
          .onClick(() => { this.filter = LogLevel.INFO; })
        Text('Warn (' + this.countLevel(LogLevel.WARN) + ')')
          .fontSize(11).padding({ top: 6, bottom: 6, left: 8, right: 8 })
          .borderRadius(12)
          .backgroundColor(this.filter === LogLevel.WARN ? '#FFF1DB' : '#F0F0F0')
          .fontColor(this.filter === LogLevel.WARN ? '#F5A623' : '#666')
          .onClick(() => { this.filter = LogLevel.WARN; })
        Text('Error (' + this.countLevel(LogLevel.ERROR) + ')')
          .fontSize(11).padding({ top: 6, bottom: 6, left: 8, right: 8 })
          .borderRadius(12)
          .backgroundColor(this.filter === LogLevel.ERROR ? '#FFE0E0' : '#F0F0F0')
          .fontColor(this.filter === LogLevel.ERROR ? '#E53935' : '#666')
          .onClick(() => { this.filter = LogLevel.ERROR; })
      }
      .width('100%').padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .backgroundColor('#FFFFFF')

      if (this.getShown().length === 0) {
        Column() {
          Text('暂无日志记录').fontSize(14).fontColor('#999')
          Text('网络请求、WAF 拦截与运行时错误会自动记录').fontSize(12).fontColor('#BBB').margin({ top: 8 })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List({ space: 1 }) {
          ForEach(this.getShown(), (item: LogEntry) => {
            ListItem() {
              Column({ space: 4 }) {
                Row() {
                  Text(levelLabel(item.level))
                    .fontSize(11).fontColor(levelColor(item.level))
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .borderRadius(4)
                    .backgroundColor('#F5F5F5')
                  Text('[' + item.tag + ']')
                    .fontSize(11).fontColor('#888').margin({ left: 6 })
                  Blank()
                  Text(this.formatTime(item.time)).fontSize(10).fontColor('#BBB')
                }.width('100%')
                Text(item.message)
                  .fontSize(13).fontColor('#333')
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%')
              }
              .width('100%').padding(12).backgroundColor('#FFFFFF')
              .alignItems(HorizontalAlign.Start)
            }
            .onClick(() => this.openDetail(item))
          }, (item: LogEntry) => '' + item.id)
        }
        .width('100%').layoutWeight(1).backgroundColor('#F5F5F5')
      }
    }
    .width('100%').height('100%')
  }
}
