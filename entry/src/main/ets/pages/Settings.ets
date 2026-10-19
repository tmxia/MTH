import router from '@ohos.router';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import { LogStore, levelLabel } from '../common/LogStore';

@Entry
@Component
struct Settings {
  @State isDark: boolean = false;
  @State dimImages: boolean = false;
  @State cacheSize: string = '0 B';
  @State logCount: number = 0;

  aboutToAppear() {
    const d = AppStorage.get<boolean>('isDark');
    this.isDark = d === true;
    const dm = AppStorage.get<boolean>('dimImagesInDark');
    this.dimImages = dm === true;
    this.loadCacheSize();
    this.logCount = LogStore.getEntries().length;
  }

  loadCacheSize() {
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      const dir = ctx.cacheDir;
      let total = 0;
      const names = fs.listFileSync(dir);
      for (let i = 0; i < names.length; i++) {
        try {
          const st = fs.statSync(dir + '/' + names[i]);
          total += st.size;
        } catch (e) {}
      }
      this.cacheSize = this.formatSize(total);
    } catch (e) {
      this.cacheSize = '0 B';
    }
  }

  formatSize(bytes: number): string {
    if (!bytes || bytes <= 0) return '0 B';
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
    return (bytes / 1024 / 1024).toFixed(2) + ' MB';
  }

  toggleDark(v: boolean) {
    this.isDark = v;
    AppStorage.SetOrCreate('isDark', v);
  }

  toggleDim(v: boolean) {
    this.dimImages = v;
    AppStorage.SetOrCreate('dimImagesInDark', v);
  }

  async clearCache() {
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      await fs.rmdir(ctx.cacheDir);
    } catch (e) {}
    this.loadCacheSize();
  }

  confirmClearCache() {
    AlertDialog.show({
      title: '清理缓存',
      message: '当前缓存占用 ' + this.cacheSize + '，确定清除？',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '清除',
        fontColor: '#E53935',
        action: () => { this.clearCache(); }
      }
    });
  }

  build() {
    Column() {
      Row() {
        Text('< 返回').fontSize(16).fontColor('#333').onClick(() => router.back())
        Text('设置')
          .fontSize(18).fontWeight(FontWeight.Bold)
          .layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(40)
      }
      .width('100%').height(50)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column({ space: 8 }) {
          // ===== 主题与显示 =====
          Column() {
            Text('主题与显示')
              .fontSize(12).fontColor('#999').width('100%')
              .padding({ left: 14, top: 10, bottom: 6 })

            Row() {
              Column({ space: 2 }) {
                Text('深色模式').fontSize(15).fontColor('#333')
                Text('切换后立即生效').fontSize(11).fontColor('#999')
              }.layoutWeight(1).alignItems(HorizontalAlign.Start)
              Toggle({ type: ToggleType.Switch, isOn: this.isDark })
                .onChange((v: boolean) => this.toggleDark(v))
            }
            .width('100%').padding({ left: 14, right: 14, top: 10, bottom: 10 })

            Divider().color('#EEEEEE').margin({ left: 14, right: 14 })

            Row() {
              Column({ space: 2 }) {
                Text('深色压暗图片').fontSize(15).fontColor('#333')
                Text('关闭后帖子配图按原始亮度显示').fontSize(11).fontColor('#999')
              }.layoutWeight(1).alignItems(HorizontalAlign.Start)
              Toggle({ type: ToggleType.Switch, isOn: this.dimImages })
                .onChange((v: boolean) => this.toggleDim(v))
            }
            .width('100%').padding({ left: 14, right: 14, top: 10, bottom: 10 })
          }
          .width('100%').backgroundColor('#FFFFFF').borderRadius(8)

          // ===== 系统与诊断 =====
          Column() {
            Text('系统与诊断')
              .fontSize(12).fontColor('#999').width('100%')
              .padding({ left: 14, top: 10, bottom: 6 })

            Row() {
              Column({ space: 2 }) {
                Text('运行日志').fontSize(15).fontColor('#333')
                Text('当前等级 ' + levelLabel(LogStore.getLevel()) + ' · ' + this.logCount + ' 条')
                  .fontSize(11).fontColor('#999')
              }.layoutWeight(1).alignItems(HorizontalAlign.Start)
              Text('>').fontSize(14).fontColor('#CCC')
            }
            .width('100%').padding({ left: 14, right: 14, top: 10, bottom: 10 })
            .onClick(() => router.pushUrl({ url: 'pages/Logs' }))

            Divider().color('#EEEEEE').margin({ left: 14, right: 14 })

            Row() {
              Column({ space: 2 }) {
                Text('清理缓存').fontSize(15).fontColor('#333')
                Text('已占用 ' + this.cacheSize).fontSize(11).fontColor('#999')
              }.layoutWeight(1).alignItems(HorizontalAlign.Start)
              Text('>').fontSize(14).fontColor('#CCC')
            }
            .width('100%').padding({ left: 14, right: 14, top: 10, bottom: 10 })
            .onClick(() => this.confirmClearCache())

            Divider().color('#EEEEEE').margin({ left: 14, right: 14 })

            Row() {
              Column({ space: 2 }) {
                Text('人机验证').fontSize(15).fontColor('#333')
                Text('网络请求被 WAF 拦截时手动通过验证').fontSize(11).fontColor('#999')
              }.layoutWeight(1).alignItems(HorizontalAlign.Start)
              Text('>').fontSize(14).fontColor('#CCC')
            }
            .width('100%').padding({ left: 14, right: 14, top: 10, bottom: 10 })
            .onClick(() => router.pushUrl({ url: 'pages/WafVerification' }))
          }
          .width('100%').backgroundColor('#FFFFFF').borderRadius(8)

          // ===== 关于 =====
          Column() {
            Text('关于')
              .fontSize(12).fontColor('#999').width('100%')
              .padding({ left: 14, top: 10, bottom: 6 })

            Row() {
              Text('版本').fontSize(15).fontColor('#333').layoutWeight(1)
              Text('1.0.0 (HarmonyOS)').fontSize(13).fontColor('#666')
            }
            .width('100%').padding({ left: 14, right: 14, top: 10, bottom: 10 })

            Divider().color('#EEEEEE').margin({ left: 14, right: 14 })

            Row() {
              Text('来源').fontSize(15).fontColor('#333').layoutWeight(1)
              Text('MTF 移植版').fontSize(13).fontColor('#666')
            }
            .width('100%').padding({ left: 14, right: 14, top: 10, bottom: 10 })
          }
          .width('100%').backgroundColor('#FFFFFF').borderRadius(8)
        }
        .width('100%').padding({ left: 12, right: 12, top: 8, bottom: 16 })
      }
      .layoutWeight(1).width('100%').backgroundColor('#F5F5F5')
    }
    .width('100%').height('100%')
  }
}
