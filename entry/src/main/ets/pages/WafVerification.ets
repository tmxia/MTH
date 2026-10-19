import router from '@ohos.router';
import webview from '@ohos.web.webview';
import { cookieManager } from '../network/CookieManager';
import { LogStore, LogLevel } from '../common/LogStore';

@Entry
@Component
struct WafVerification {
  @State currentUrl: string = 'https://bbs.binmt.cc/';
  @State solved: boolean = false;
  @State statusMsg: string = '正在加载站点验证…';
  controller: webview.WebviewController = new webview.WebviewController();
  private timer: number = -1;

  aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    if (params && params.url) {
      this.currentUrl = params.url;
    }
    this.timer = setInterval(() => {
      this.checkCookie();
    }, 1500);
  }

  aboutToDisappear() {
    if (this.timer > 0) {
      clearInterval(this.timer);
      this.timer = -1;
    }
  }

  async checkCookie() {
    if (this.solved) return;
    try {
      const cookie = await webview.WebCookieManager.fetchCookie(this.currentUrl);
      if (cookie && cookie.indexOf('acw_sc__v2') >= 0) {
        this.solved = true;
        this.statusMsg = '✅ 验证通过，正在保存 cookie';
        // 合并到现有 cookie
        const existing = cookieManager.get();
        const clean = existing || '';
        const merged = clean ? clean + '; ' + cookie : cookie;
        await cookieManager.save(merged);
        LogStore.add(LogLevel.INFO, 'WAF', '人机验证通过，cookie 已保存');
        this.statusMsg = '✅ 验证通过，可以返回重试';
      }
    } catch (e) {
      // 忽略
    }
  }

  build() {
    Column() {
      Row() {
        Text('< 返回').fontSize(16).fontColor('#333').onClick(() => router.back())
        Text('人机验证')
          .fontSize(18).fontWeight(FontWeight.Bold)
          .layoutWeight(1).textAlign(TextAlign.Center)
        if (this.solved) {
          Text('完成').fontSize(14).fontColor('#4CAF50').onClick(() => router.back())
        } else {
          Blank().width(28)
        }
      }
      .width('100%').height(50)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      Text(this.statusMsg)
        .fontSize(12)
        .fontColor(this.solved ? '#4CAF50' : '#666')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .width('100%')
        .backgroundColor(this.solved ? '#E8F5E9' : '#F5F5F5')

      Web({ src: this.currentUrl, controller: this.controller })
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .fileAccess(false)
        .imageAccess(true)
        .zoomAccess(false)
        .layoutWeight(1)
        .width('100%')
        .onPageEnd(() => {
          this.statusMsg = '页面加载完成，检测验证状态…';
          this.checkCookie();
        })
    }
    .width('100%').height('100%')
  }
}
