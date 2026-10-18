import { forumRepository } from '../repo/ForumRepository';
import { UserProfile, MyThreadPage, Thread } from '../models/Models';
import router from '@ohos.router';

@Entry
@Component
struct UserProfilePage {
  @State profile: UserProfile | null = null;
  @State threads: Array<Thread> = [];
  @State isLoading: boolean = true;
  @State uid: string = '';

  async aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    if (params && params.uid) {
      this.uid = params.uid;
      await this.loadData();
    } else {
      this.isLoading = false;
    }
  }

  async loadData() {
    this.isLoading = true;
    try {
      this.profile = await forumRepository.fetchUserProfile(this.uid);
      const res = await forumRepository.userThreads(this.uid);
      this.threads = res.threads;
    } catch (e) {
      console.error(e);
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      Row() {
        Text('< 返回').fontSize(16).fontColor('#333').onClick(() => router.back())
        Text('用户主页').fontSize(18).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(40)
      }.width('100%').height(50).padding({ left: 16, right: 16 }).backgroundColor('#FFFFFF')

      if (this.isLoading) {
        LoadingProgress().width(50).height(50).color('#4D6BFE').margin({ top: 100 })
      } else if (this.profile) {
        List({ space: 10 }) {
          ListItem() {
            Column({ space: 15 }) {
              Row({ space: 15 }) {
                Image(this.profile.avatarUrl ? this.profile.avatarUrl : $r('app.media.icon'))
                  .width(70).height(70).borderRadius(35).backgroundColor('#EEEEEE')
                Column({ space: 5 }) {
                  Text(this.profile.name || '未知用户').fontSize(20).fontWeight(FontWeight.Bold)
                  Text(this.profile.groupName || '普通会员').fontSize(12).fontColor('#4D6BFE').backgroundColor('#E8F0FE').padding({ left: 6, right: 6, top: 2, bottom: 2 }).borderRadius(4)
                }.alignItems(HorizontalAlign.Start)
              }.width('100%')
              
              Row() {
                Column() { Text(`${this.profile.threads || 0}`).fontSize(16).fontWeight(FontWeight.Bold); Text('帖子').fontSize(12).fontColor('#999') }.layoutWeight(1)
                Column() { Text(`${this.profile.credits || 0}`).fontSize(16).fontWeight(FontWeight.Bold); Text('积分').fontSize(12).fontColor('#999') }.layoutWeight(1)
                Column() { Text(`${this.profile.gold || 0}`).fontSize(16).fontWeight(FontWeight.Bold); Text('金币').fontSize(12).fontColor('#999') }.layoutWeight(1)
              }.width('100%').padding({ top: 10, bottom: 10 }).backgroundColor('#F9F9F9').borderRadius(8)
            }.width('100%').padding(20).backgroundColor('#FFFFFF').borderRadius(12)
          }

          ListItem() {
            Text('TA 的帖子').fontSize(16).fontWeight(FontWeight.Bold).padding({ left: 10, top: 10, bottom: 5 })
          }
          ForEach(this.threads, (item: Thread) => {
            ListItem() {
              Column({ space: 8 }) {
                Text(item.subject).fontSize(15).fontWeight(FontWeight.Bold).maxLines(2)
                Row() {
                  Text(item.forumName || '').fontSize(12).fontColor('#4D6BFE')
                  Blank()
                  Text(`回复: ${item.replyCount || 0}`).fontSize(12).fontColor('#999')
                }.width('100%')
              }
              .width('100%').padding(15).backgroundColor('#FFFFFF').borderRadius(8)
              .onClick(() => router.pushUrl({ url: 'pages/ThreadDetail', params: { tid: item.tid } }))
            }
          }, (item: Thread) => item.tid)
          
          if (this.threads.length === 0) {
            ListItem() { Text('暂无发帖').fontSize(14).fontColor('#999').width('100%').textAlign(TextAlign.Center).padding(20) }
          }
        }
        .width('100%').layoutWeight(1).padding(10).backgroundColor('#F5F5F5')
      }
    }.width('100%').height('100%')
  }
}
