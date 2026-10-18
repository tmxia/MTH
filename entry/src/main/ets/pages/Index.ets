import { HttpClient } from '../network/HttpClient';
import { cookieManager } from '../network/CookieManager';
import common from '@ohos.app.ability.common';

@Entry
@Component
struct Index {
  @State message: string = '正在连接 MTF 论坛...';
  @State responseText: string = '';

  async aboutToAppear() {
    // 修复 getContext 弃用，使用新的获取上下文方式
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    await cookieManager.init(context);
    
    try {
      let result = await HttpClient.get('/');
      this.message = 'MTF 首页请求成功';
      this.responseText = result.substring(0, 200) + '...\n\n(已截取前200字)';
    } catch (error) {
      this.message = '网络请求失败';
      this.responseText = String(error);
    }
  }

  build() {
    Column({ space: 20 }) {
      Text(this.message)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.message.includes('失败') ? Color.Red : Color.Green)
      
      Scroll() {
        Text(this.responseText)
          .fontSize(14)
          .fontColor('#666666')
          .padding(10)
      }
      .width('90%')
      .height('60%')
      .backgroundColor('#F5F5F5')
      .borderRadius(10)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
