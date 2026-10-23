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
  @State myUid: string = '';
  @State myName: string = '';

  async aboutToAppear() {
    // 先读缓存
    const cachedUid = AppStorage.Get<string>('currentUid');
    const cachedName = AppStorage.Get<string>('currentName');
    if (cachedUid) {
      this.myUid = cachedUid;
      this.myName = cachedName || '';
    } else {
      try {
        const p = await forumRepository.me();
        this.myUid = p.uid || '';
        this.myName = p.name || '';
        AppStorage.SetOrCreate('currentUid', this.myUid);
        AppStorage.SetOrCreate('currentName', this.myName);
      } catch (e) {}
    }
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
      promptAction.showToast({ message: '正在下载图片…' });
      await threadArchiveStore.inlineImages(snapshot);
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

  showPostMenu(post: Post) {
    const isMine = this.myUid && post.authorUid === this.myUid;
    if (isMine) {
      AlertDialog.show({
        title: '操作',
        message: '选择对这条内容的操作',
        primaryButton: {
          value: '编辑',
          action: () => this.goEdit(post)
        },
        secondaryButton: {
          value: '删除',
          fontColor: '#E53935',
          action: () => this.confirmDelete(post)
        }
      });
    } else {
      AlertDialog.show({
        title: '操作',
        message: '选择操作',
        primaryButton: {
          value: '举报',
          action: () => this.doReport(post)
        },
        secondaryButton: {
          value: '拉黑作者',
          fontColor: '#E53935',
          action: () => this.doBlockAuthor(post)
        }
      });
    }
  }

  goEdit(post: Post) {
    // 需要把纯文本从 contentHtml 里提出来
    const plain = (post.contentHtml || '').replace(/<br\s*\/?>/gi, '\n').replace(/<[^>]+>/g, '');
    router.pushUrl({
      url: 'pages/PostEdit',
      params: {
        tid: this.currentTid,
        pid: post.pid,
        fid: this.tp ? (this.tp.fid || '') : '',
        forumName: this.tp ? (this.tp.forumName || '') : '',
        subject: this.tp ? (this.tp.subject || '') : '',
        message: plain
      }
    });
  }

  async confirmDelete(post: Post) {
    AlertDialog.show({
      title: '删除帖子',
      message: '删除后无法恢复，确定删除？',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '删除',
        fontColor: '#E53935',
        action: async () => {
          if (!this.tp) return;
          const fh = (this.tp.formhash as string) || '';
          const ok = await forumRepository.deletePost(this.currentTid, post.pid, fh);
          promptAction.showToast({ message: ok ? '删除成功' : '删除失败' });
          if (ok) {
            // 重新加载
            await this.loadData(this.currentTid, 1);
          }
        }
      }
    });
  }

  async doReport(post: Post) {
    if (!this.tp) return;
    const fid = this.tp.fid || '';
    const fh = (this.tp.formhash as string) || '';
    const ok = await forumRepository.reportPost(this.currentTid, fid, fh, post.pid, '其他', '该内容涉嫌违规，请核实处理。');
    promptAction.showToast({ message: ok ? '举报成功' : '举报失败，请稍后重试' });
  }

  async doBlockAuthor(post: Post) {
    const name = post.authorName || '';
    if (!name) {
      promptAction.showToast({ message: '无法获取用户名' });
      return;
    }
    const res = await forumRepository.addUserBlacklist(name, '');
    promptAction.showToast({ message: res || '操作完成' });

    // 核心修复：拉黑成功后立即在本地过滤掉该作者的帖子，避免闪烁等待
    if (this.tp && this.tp.posts) {
      const originalCount = this.tp.posts.length;
      const filtered = this.tp.posts.filter((p: Post) => p.authorName !== name);
      
      if (filtered.length !== originalCount) {
        this.tp.posts = filtered;
        
        // 重新构建富文本 Map，确保 UI 响应刷新
        const newMap = new Map<string, Array<RichTextNode>>();
        for (let i = 0; i < filtered.length; i++) {
          const p = filtered[i];
          newMap.set(p.pid, ForumParser.parseRichText(p.contentHtml));
        }
        this.parsedRichText = newMap;
      }
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
                Row() {
                  Text(post.authorName).fontWeight(FontWeight.Medium).layoutWeight(1)
                  Text('···')
                    .fontSize(16).fontColor('#999')
                    .padding({ left: 8, right: 4, top: 0, bottom: 0 })
                    .onClick(() => this.showPostMenu(post))
                }.width('100%')
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
