import { forumRepository } from '../repo/ForumRepository';
import { ThreadPage, Post, RichTextNode } from '../models/Models';
import { ForumParser } from '../parser/ForumParser';
import router from '@ohos.router';
import { historyStore } from '../common/HistoryStore';
import { HistoryItem, ThreadSnapshot, DownloadedThread } from '../models/Models';
import { threadArchiveStore } from '../common/ThreadArchiveStore';
import { downloadStore } from '../common/DownloadStore';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct ThreadDetail {
  @State tp: ThreadPage | null = null;
  @State isLoading: boolean = true;
  @State errorMsg: string = '';
  @State parsedRichText: Map<string, Array<RichTextNode>> = new Map();
  @State isOffline: boolean = false;
  @State currentTid: string = '';
  @State downloading: boolean = false;

  async aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    if (params && params.tid) {
      this.currentTid = params.tid;
      if (params.offline === 'true') {
        await this.loadOffline(params.tid);
      } else {
        await this.loadData(params.tid, 1);
      }
    } else {
      this.errorMsg = '未找到帖子ID';
      this.isLoading = false;
    }
  }

  async loadOffline(tid: string): Promise<void> {
    this.isLoading = true;
    try {
      const snapshot = await threadArchiveStore.read(tid);
      if (!snapshot) {
        this.errorMsg = '存档不存在或已被删除';
        return;
      }
      const tp = new ThreadPage();
      tp.tid = tid;
      tp.subject = snapshot.subject || '';
      tp.forumName = snapshot.forumName || '';
      tp.posts = snapshot.posts || [];
      tp.page = 1;
      tp.totalPages = 1;
      tp.fid = snapshot.fid || null;
      tp.opUid = snapshot.opUid || null;
      tp.totalReplies = snapshot.totalReplies || 0;
      this.tp = tp;
      this.isOffline = true;
      const newMap = new Map<string, Array<RichTextNode>>();
      for (const post of tp.posts) {
        newMap.set(post.pid, ForumParser.parseRichText(post.contentHtml));
      }
      this.parsedRichText = newMap;
    } catch (e) {
      this.errorMsg = (e as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  async downloadAll(): Promise<void> {
    if (!this.currentTid || !this.tp || this.downloading) return;
    const total = this.tp.totalPages || 1;
    this.downloading = true;
    promptAction.showToast({ message: '开始下载（共 ' + total + ' 页）' });
    try {
      const allPosts: Post[] = [];
      let firstPage: ThreadPage | null = null;
      for (let p = 1; p <= total; p++) {
        const page = await forumRepository.threadPage(this.currentTid, p);
        if (p === 1) firstPage = page;
        for (const post of page.posts) {
          let exists = false;
          for (const x of allPosts) {
            if (x.pid === post.pid) { exists = true; break; }
          }
          if (!exists) allPosts.push(post);
        }
      }
      if (!firstPage) {
        promptAction.showToast({ message: '下载失败：无数据' });
        return;
      }
      const snapshot = new ThreadSnapshot();
      snapshot.subject = firstPage.subject || '';
      snapshot.forumName = firstPage.forumName || '';
      snapshot.fid = firstPage.fid || '';
      snapshot.opUid = firstPage.opUid || '';
      snapshot.totalReplies = firstPage.totalReplies || 0;
      snapshot.posts = allPosts;
      await threadArchiveStore.archive(this.currentTid, snapshot);

      const entry = new DownloadedThread();
      entry.tid = this.currentTid;
      entry.subject = firstPage.subject || 'MTF 帖子';
      entry.forumName = firstPage.forumName || '';
      entry.fileName = '';
      entry.uri = '';
      entry.savedAt = Date.now();
      entry.replyCount = allPosts.length - 1;
      entry.sizeBytes = JSON.stringify(snapshot).length;
      await downloadStore.upsert(entry);

      promptAction.showToast({ message: '下载完成（' + allPosts.length + ' 楼）' });
    } catch (e) {
      promptAction.showToast({ message: '下载失败：' + (e as Error).message });
    } finally {
      this.downloading = false;
    }
  }

  async loadData(tid: string, page: number) {
    this.isLoading = true;
    try {
      const data = await forumRepository.threadPage(tid, page);
      this.tp = data;
      if (page === 1 && data) {
        const h = new HistoryItem();
        h.tid = tid;
        h.title = (data.subject as string) || '';
        h.forumName = (data.forumName as string) || '';
        h.author = '';
        h.avatarUrl = '';
        if (data.posts && data.posts.length > 0) {
          h.author = data.posts[0].authorName || '';
          h.avatarUrl = (data.posts[0].avatarUrl as string) || '';
        }
        h.viewedAt = Date.now();
        h.type = 'thread';
        historyStore.add(h).catch((e: Error) => {
          console.error('add history error: ' + e.message);
        });
      }
      
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

  build() {
    Column() {
      Row() {
        Text('详情').fontSize(20).fontWeight(FontWeight.Bold)
        Blank()
        if (this.isOffline) {
          Text('离线阅读').fontSize(12).fontColor('#4D6BFE')
        } else if (this.downloading) {
          Text('下载中…').fontSize(14).fontColor('#999')
        } else {
          Text('下载').fontSize(14).fontColor('#4D6BFE')
            .padding({ left: 8, right: 8, top: 6, bottom: 6 })
            .onClick(() => this.downloadAll())
        }
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
