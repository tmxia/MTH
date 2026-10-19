import { forumRepository } from '../repo/ForumRepository';
import { ChatConversation, ChatMessage } from '../models/Models';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct Chat {
  @State conv: ChatConversation | null = null;
  @State isLoading: boolean = true;
  @State touid: string = '';
  @State targetName: string = '';
  @State replyText: string = '';
  @State isSending: boolean = false;

  async aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    if (params && params.touid) {
      this.touid = params.touid;
      this.targetName = params.name || '私信';
      await this.loadData();
    }
  }

  async loadData() {
    this.isLoading = true;
    try {
      this.conv = await forumRepository.fetchChat(this.touid);
    } catch (e) {
      console.error(e);
    } finally {
      this.isLoading = false;
    }
  }

  async sendMsg() {
    if (!this.replyText.trim() || !this.conv || !this.conv.formhash) return;
    this.isSending = true;
    try {
      let ok = await forumRepository.sendPm(this.touid, this.conv.formhash, this.replyText);
      if (ok) {
        promptAction.showToast({ message: '发送成功' });
        this.replyText = '';
        await this.loadData(); // 刷新
      } else {
        promptAction.showToast({ message: '发送失败' });
      }
    } catch (e) {
      promptAction.showToast({ message: '网络异常' });
    } finally {
      this.isSending = false;
    }
  }

  build() {
    Column() {
      Row() {
        Text('< 返回').fontSize(16).fontColor('#333').onClick(() => router.back())
        Text(this.targetName).fontSize(18).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(40)
      }.width('100%').height(50).padding({ left: 16, right: 16 }).backgroundColor('#FFFFFF')

      if (this.isLoading) {
        LoadingProgress().width(50).height(50).color('#4D6BFE').margin({ top: 100 })
      } else {
        List() {
          ForEach(this.conv?.messages || [], (item: ChatMessage) => {
            ListItem() {
              Row() {
                if (item.isSelf) {
                  Blank()
                  Text(item.text).fontSize(15).fontColor('#FFFFFF').backgroundColor('#4D6BFE').padding(12).borderRadius({ topLeft: 10, topRight: 10, bottomLeft: 10 })
                } else {
                  Text(item.text).fontSize(15).fontColor('#333').backgroundColor('#FFFFFF').padding(12).borderRadius({ topLeft: 10, topRight: 10, bottomRight: 10 })
                  Blank()
                }
              }.width('100%').padding({ left: 15, right: 15, top: 5, bottom: 5 })
            }
          }, (item: ChatMessage) => item.id)
        }.width('100%').layoutWeight(1).backgroundColor('#F0F0F0')

        Row({ space: 10 }) {
          TextInput({ placeholder: '输入消息...', text: this.replyText })
            .layoutWeight(1).height(40).backgroundColor('#FFFFFF').borderRadius(20)
            .onChange((val: string) => this.replyText = val)
          Button(this.isSending ? '发送中' : '发送').height(40).backgroundColor('#4D6BFE').enabled(!this.isSending)
            .onClick(() => this.sendMsg())
        }.width('100%').padding(10).backgroundColor('#FFFFFF').border({ width: { top: 0.5 }, color: '#EEEEEE' })
      }
    }.width('100%').height('100%')
  }
}
