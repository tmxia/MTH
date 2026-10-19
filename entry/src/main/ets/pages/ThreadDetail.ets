import { forumRepository } from '../repo/ForumRepository';
import { ThreadPage, Post, RichTextNode } from '../models/Models';
import { ForumParser } from '../parser/ForumParser';
import { NetImage } from '../common/NetImage';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct ThreadDetail {
  @State tp: ThreadPage | null = null;
  @State isLoading: boolean = true;
  @State errorMsg: string = '';
  @State replyText: string = '';
  @State isSending: boolean = false;
  @State parsedRichText: Map<string, Array<RichTextNode>> = new Map();
  @State isLiked: boolean = false;
  @State isFavorited: boolean = false;

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
      
      // 初始化点赞/收藏状态
      this.isLiked = data.isLiked;
      this.isFavorited = data.isFavorited;

      const newMap = new Map<string, Array<RichTextNode>>();
      for (const post of data.posts) {
        newMap.set(post.pid, ForumParser.parseRichText(post.contentHtml));
      }
      this.parsedRichText = newMap;
    } catch (e) {
      this.errorMsg = (e as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  async submitReply() {
    if (!this.tp || !this.tp.formhash) return;
    this.isSending = true;
    try {
      const res = await forumRepository.reply(this.tp.tid, this.tp.fid || '0', this.tp.formhash, this.replyText);
      if (res.success) {
        promptAction.showToast({ message: '回复成功' });
        this.replyText = '';
        await this.loadData(this.tp.tid, this.tp.page);
      } else {
        promptAction.showToast({ message: res.message || '回复失败' });
      }
    } catch (e) {
      promptAction.showToast({ message: '网络异常' });
    } finally {
      this.isSending = false;
    }
  }

  async doLike() {
    if (!this.tp || !this.tp.formhash) return;
    try {
      const res = await forumRepository.likeThread(this.tp.tid, this.tp.formhash, !this.isLiked);
      if (res.success) {
        this.isLiked = !this.isLiked;
        promptAction.showToast({ message: this.isLiked ? '点赞成功' : '已取消' });
      } else {
        promptAction.showToast({ message: res.message || '操作受限' });
      }
    } catch (e) {
      promptAction.showToast({ message: '网络异常' });
    }
  }

  async doFavorite() {
    if (!this.tp || !this.tp.formhash) return;
    try {
      const res = await forumRepository.favoriteThread(this.tp.tid, this.tp.formhash);
      if (res.success) {
        this.isFavorited = !this.isFavorited;
        promptAction.showToast({ message: '收藏成功' });
      } else {
        promptAction.showToast({ message: res.message || '收藏失败' });
      }
    } catch (e) {
      promptAction.showToast({ message: '网络异常' });
    }
  }

  build() {
    Column() {
      Row() {
        Text('< 返回').fontSize(16).fontColor('#333').onClick(() => router.back())
        Text('帖子详情').fontSize(18).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(40)
      }.width('100%').height(50).padding({ left: 16, right: 16 }).backgroundColor('#FFFFFF')

      if (this.isLoading && !this.tp) {
        LoadingProgress().width(50).height(50).color('#4D6BFE').margin({ top: 100 })
      } else if (this.errorMsg !== '') {
        Text(this.errorMsg).fontSize(16).fontColor(Color.Red).margin({ top: 100 })
      } else if (this.tp) {
        Column() {
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

          // 底部交互栏 (回复 + 点赞 + 收藏)
          Row({ space: 10 }) {
            TextInput({ placeholder: '写点什么...', text: this.replyText })
              .layoutWeight(1).height(40).backgroundColor('#F0F0F0').borderRadius(20)
              .onChange((val: string) => this.replyText = val)
            
            Button('发送')
              .height(40).backgroundColor('#4D6BFE').fontColor('#FFFFFF')
              .enabled(!this.isSending && this.replyText.trim().length > 0)
              .onClick(() => this.submitReply())
              .margin({ right: 5 })

            Text(this.isLiked ? '❤️' : '🤍').fontSize(24).onClick(() => this.doLike())
            Text(this.isFavorited ? '⭐' : '☆').fontSize(24).onClick(() => this.doFavorite())
          }
          .width('100%').padding(10).backgroundColor('#FFFFFF').border({ width: { top: 0.5 }, color: '#EEEEEE' })
        }.layoutWeight(1)
      }
    }.width('100%').height('100%')
  }

  @Builder
  PostCard(post: Post) {
    Column({ space: 10 }) {
      Row({ space: 10 }) {
        Image(post.avatarUrl ? post.avatarUrl : $r('app.media.icon'))
          .width(36).height(36).borderRadius(18).backgroundColor('#EEEEEE')
          .onClick(() => {
            if (post.authorUid) {
              router.pushUrl({ url: 'pages/UserProfilePage', params: { uid: post.authorUid } });
            }
          })
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

      ForEach(this.parsedRichText.get(post.pid) || [], (node: RichTextNode) => {
        if (node.type === 'text') {
          Text(node.content).fontSize(15).fontColor('#333').lineHeight(24).copyOption(CopyOptions.LocalDevice).width('100%')
        } else if (node.type === 'image') {
          NetImage({ src: node.content, imgWidth: '100%', imgRadius: 6 })
            .margin({ top: 5, bottom: 5 })
        }
      }, (node: RichTextNode, index: number) => `${post.pid}-${index}`)
    }
    .width('100%').padding(16).backgroundColor('#FFFFFF').margin({ top: 8 })
  }
}
