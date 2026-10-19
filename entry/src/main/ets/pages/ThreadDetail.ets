import { forumRepository } from '../repo/ForumRepository';
import { ThreadPage, Post, RichTextNode } from '../models/Models';
import { ForumParser } from '../parser/ForumParser';
import router from '@ohos.router';

@Entry
@Component
struct ThreadDetail {
  @State tp: ThreadPage | null = null;
  @State isLoading: boolean = true;
  @State errorMsg: string = '';
  @State parsedRichText: Map<string, Array<RichTextNode>> = new Map();

  async aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    if (params && params.tid) {
      await this.loadData(params.tid, 1);
    } else {
      this.errorMsg = '未找到帖子ID';
      this.isLoading = false;
    }
  }

  async loadData(tid: string, page: number) {
    this.isLoading = true;
    try {
      const data = await forumRepository.threadPage(tid, page);
      this.tp = data;
      
      const newMap = new Map<string, Array<RichTextNode>>();
      for (const post of data.posts) {
        newMap.set(post.pid, ForumParser.parseRichText(post.contentHtml));
      }
      this.parsedRichText = newMap;
    } catch (e: Error) {
      this.errorMsg = e.message;
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      Row() {
        Text('详情').fontSize(20).fontWeight(FontWeight.Bold)
      }.width('100%').padding(10)

      if (this.isLoading) {
        LoadingProgress().width(50).height(50).margin({ top: 20 })
      } else if (this.errorMsg) {
        Text(this.errorMsg).fontColor(Color.Red).margin({ top: 20 })
      } else if (this.tp) {
        List() {
          ForEach(this.tp.posts, (post: Post) => {
            ListItem() {
              Column() {
                Text(post.authorName).fontWeight(FontWeight.Medium)
                ForEach(this.parsedRichText.get(post.pid) || [], (node: RichTextNode) => {
                  if (node.type === 'text') {
                    Text(node.content).fontSize(15).lineHeight(24)
                  }
                })
              }.alignItems(HorizontalAlign.Start).padding(10)
            }
          }, (post: Post) => post.pid)
        }.layoutWeight(1).width('100%')
      }
    }.width('100%').height('100%')
  }
}
