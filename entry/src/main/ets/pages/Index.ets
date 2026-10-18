import { HttpClient } from '../network/HttpClient';
import { CookieManager } from '../network/CookieManager';
import common from '@ohos.app.ability.common';

@Entry
@Component
struct Index {
  @State message: string = '正在连接 MTF 论坛...';
  @State responseText: string = '';

  async aboutToAppear() {
    let context = getContext(this) as common.UIAbilityContext;
    await CookieManager.init(context);
    
    try {
      // 测试请求论坛首页
      let result = await HttpClient.get('/');
      this.message = 'MTF 首页请求成功';
      this.responseText = result.substring(0, 200) + '...\n\n(已截取前200字)';
    } catch (e) {
      this.message = '网络请求失败';
      this.responseText = JSON.stringify(e);
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
