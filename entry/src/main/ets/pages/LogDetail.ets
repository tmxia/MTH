import router from '@ohos.router';
import { LogStore, LogEntry, levelLabel, levelColor } from '../common/LogStore';

@Entry
@Component
struct LogDetail {
  @State entry: LogEntry | null = null;
  @State errorMsg: string = '';

  aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    if (params && params.id) {
      const id = parseInt(params.id);
      const e = LogStore.getById(id);
      if (e) {
        this.entry = e;
      } else {
        this.errorMsg = '日志记录不存在';
      }
    } else {
      this.errorMsg = '缺少参数';
    }
  }

  formatTime(timestamp: number): string {
    if (!timestamp || timestamp <= 0) return '';
    const d = new Date(timestamp);
    const yyyy = d.getFullYear();
    const mm = d.getMonth() + 1;
    const dd = d.getDate();
    const hh = d.getHours();
    const mi = d.getMinutes();
    const ss = d.getSeconds();
    const ms = d.getMilliseconds();
    const pad = (n: number, len: number): string => {
      let s = '' + n;
      while (s.length < len) s = '0' + s;
      return s;
    };
    return yyyy + '-' + pad(mm, 2) + '-' + pad(dd, 2) + ' ' +
      pad(hh, 2) + ':' + pad(mi, 2) + ':' + pad(ss, 2) + '.' + pad(ms, 3);
  }

  build() {
    Column() {
      Row() {
        Text('< 返回').fontSize(16).fontColor('#333').onClick(() => router.back())
        Text('日志详情')
          .fontSize(18).fontWeight(FontWeight.Bold)
          .layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(40)
      }
      .width('100%').height(50)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      if (this.errorMsg) {
        Text(this.errorMsg).fontSize(14).fontColor('#999').margin({ top: 100 })
      } else if (this.entry) {
        Scroll() {
          Column({ space: 12 }) {
            Row({ space: 8 }) {
              Text(levelLabel(this.entry.level))
                .fontSize(12).fontColor(levelColor(this.entry.level))
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .borderRadius(4).backgroundColor('#F5F5F5')
              Text('[' + this.entry.tag + ']')
                .fontSize(12).fontColor('#666')
            }.width('100%')

            Text('时间')
              .fontSize(11).fontColor('#999').width('100%')
            Text(this.formatTime(this.entry.time))
              .fontSize(13).fontColor('#333').width('100%')

            Text('消息')
              .fontSize(11).fontColor('#999').width('100%').margin({ top: 8 })
            Text(this.entry.message)
              .fontSize(14).fontColor('#333').width('100%')
              .copyOption(CopyOptions.LocalDevice)

            if (this.entry.detail) {
              Text('详情')
                .fontSize(11).fontColor('#999').width('100%').margin({ top: 8 })
              Text(this.entry.detail)
                .fontSize(12).fontColor('#666').width('100%')
                .copyOption(CopyOptions.LocalDevice)
            }
          }
          .width('100%').padding(16).alignItems(HorizontalAlign.Start)
        }
        .width('100%').layoutWeight(1).backgroundColor('#F5F5F5')
      }
    }
    .width('100%').height('100%')
  }
}
