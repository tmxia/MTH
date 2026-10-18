import { forumRepository } from '../repo/ForumRepository';
import { LoginResult } from '../models/Models';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct Login {
  @State username: string = '';
  @State password: string = '';
  @State isLoading: boolean = false;

  async doLogin() {
    if (!this.username || !this.password) {
      promptAction.showToast({ message: '请输入账号和密码' });
      return;
    }

    this.isLoading = true;
    try {
      const result: LoginResult = await forumRepository.login(this.username, this.password);
      if (result.success) {
        promptAction.showToast({ message: '登录成功' });
        router.back();
      } else {
        promptAction.showToast({ message: result.message || '登录失败' });
      }
    } catch (e) {
      promptAction.showToast({ message: '网络请求失败' });
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column({ space: 20 }) {
      // 顶部导航
      Row() {
        Text('< 返回').fontSize(16).fontColor('#333').onClick(() => router.back())
        Text('登录 MT论坛').fontSize(18).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(40)
      }
      .width('100%').height(50).padding({ left: 16, right: 16 }).backgroundColor('#FFFFFF')

      Column({ space: 20 }) {
        TextInput({ placeholder: '请输入用户名' })
          .type(InputType.Normal)
          .onChange((value: string) => this.username = value)
          .height(50)
          .backgroundColor('#F5F5F5')

        TextInput({ placeholder: '请输入密码' })
          .type(InputType.Password)
          .onChange((value: string) => this.password = value)
          .height(50)
          .backgroundColor('#F5F5F5')

        Button(this.isLoading ? '正在登录...' : '立即登录')
          .width('100%')
          .height(50)
          .backgroundColor('#4D6BFE')
          .fontColor('#FFFFFF')
          .enabled(!this.isLoading)
          .onClick(() => {
            this.doLogin();
          })
      }
      .width('90%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(10)
      .margin({ top: 30 })
      .shadow({ radius: 10, color: '#0A000000', offsetX: 0, offsetY: 4 })
      
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
