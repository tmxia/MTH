import { forumRepository } from '../repo/ForumRepository';
import { ThreadPage, Post } from '../models/Models';
import router from '@ohos.router';

@Entry
@Component
struct ThreadDetail {
  @State tp: ThreadPage | null = null;
  @State isLoading: boolean = true;
  @State errorMsg: string = '';

  async aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    if (params && params.tid) {
      await this.loadData(params.tid, 1);
    } else {
      this.errorMsg = "未找到帖子ID";
      this.isLoading = false;
    }
  }

  async loadData(tid: string, page: number) {
    this.isLoading = true;
    try {
      const data = await forumRepository.threadPage(tid, page);
      this.tp = data;
    } catch (e) {
      this.errorMsg = (e as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      Row() {
        Text('< 返回').fontSize(16).fontColor('#333').onClick(() => {
          router.back();
        })
        Text('帖子详情').fontSize(18).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(40)
      }
      .width('100%').height(50).padding({ left: 16, right: 16 }).backgroundColor('#FFFFFF')

      if (this.isLoading) {
        LoadingProgress().width(50).height(50).color('#4D6BFE').margin({ top: 100 })
      } else if (this.errorMsg !== '') {
        Text(this.errorMsg).fontSize(16).fontColor(Color.Red).margin({ top: 100 })
      } else if (this.tp) {
        List() {
          ListItem() {
            Column({ space: 8 }) {
              Text(this.tp.subject || '无标题').fontSize(20).fontWeight(FontWeight.Bold).fontColor('#111')
              Row() {
                Text(this.tp.forumName || '未知版块').fontSize(12).fontColor('#4D6BFE')
                Blank()
                Text(`共 ${this.tp.totalReplies || 0} 回复`).fontSize(12).fontColor('#999')
              }.width('100%')
            }
            .width('100%').padding(16).backgroundColor('#FFFFFF').alignItems(HorizontalAlign.Start)
          }

          ForEach(this.tp.posts, (post: Post) => {
            ListItem() {
              this.PostCard(post)
            }
          }, (post: Post) => post.pid)
        }
        .width('100%').layoutWeight(1).backgroundColor('#F5F5F5')
      }
    }
    .width('100%').height('100%')
  }

  @Builder
  PostCard(post: Post) {
    Column({ space: 10 }) {
      Row({ space: 10 }) {
        Image(post.avatarUrl ? post.avatarUrl : $r('app.media.icon'))
          .width(36).height(36).borderRadius(18).backgroundColor('#EEEEEE')
        Column() {
          Text(post.authorName || '匿名').fontSize(14).fontWeight(FontWeight.Medium)
          Text(post.timeText || '刚刚').fontSize(11).fontColor('#999')
        }.alignItems(HorizontalAlign.Start)
        Blank()
        if (post.isOp) {
          Text('楼主').fontSize(10).fontColor('#FFFFFF').backgroundColor('#4D6BFE').padding({ left: 4, right: 4, top: 1, bottom: 1 }).borderRadius(4)
        }
        Text(post.floorLabel || '').fontSize(12).fontColor('#999')
      }.width('100%')

      Text(post.contentHtml || '（暂无内容）').fontSize(15).fontColor('#333').lineHeight(24).copyOption(CopyOptions.LocalDevice)

      Row() {
        Text('回复').fontSize(12).fontColor('#666')
        Blank()
        Text('点赞').fontSize(12).fontColor('#666')
      }
      .width('100%').margin({ top: 10 }).padding({ top: 10 }).border({ width: { top: 0.5 }, color: '#EEEEEE' })
    }
    .width('100%').padding(16).backgroundColor('#FFFFFF').margin({ top: 8 })
  }
}
