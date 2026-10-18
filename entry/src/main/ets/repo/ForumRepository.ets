import { HttpClient } from '../network/HttpClient';
import { ForumGroup, HomeData, ForumPage, Thread, ThreadPage } from '../models/Models';
import { ForumParser } from '../parser/ForumParser';

export enum ForumSort {
  LATEST = "最新",
  HOT = "热门",
  DIGEST = "精华",
  POLL = "投票"
}

const GUIDE_VIEW_PORTAL = "hot";

export class ForumRepository {
  private http: typeof HttpClient;
  
  public blockedUidsProvider: () => Set<string> = () => new Set<string>();

  constructor(http: typeof HttpClient) {
    this.http = http;
  }

  private currentBlocked(): Set<string> {
    return this.blockedUidsProvider();
  }

  async forumGroups(): Promise<Array<ForumGroup>> {
    const url = "forum.php?forumlist=1&mobile=2";
    const html = await this.http.get(url);
    return ForumParser.parseForumList(html);
  }

  async home(): Promise<HomeData> {
    const url = "forum.php?mod=guide&view=hot&mobile=2";
    const html = await this.http.get(url);
    const data = ForumParser.parseHome(html);
    
    const blocked = this.currentBlocked();
    if (blocked.size === 0) {
      return data;
    } else {
      data.hotThreads = data.hotThreads.filter((thread: Thread) => {
        return !(thread.authorUid && blocked.has(thread.authorUid));
      });
      return data;
    }
  }

  async guideFeed(view: string, page: number): Promise<ForumPage> {
    const blocked = this.currentBlocked();
    
    if (view === GUIDE_VIEW_PORTAL) {
      const url = `plugin.php?id=comiis_app_portal&pid=1&page=${page}&inajax=1`;
      const html = await this.http.get(url);
      const threads = ForumParser.parsePortalFeed(html);
      
      const fp = new ForumPage();
      fp.forumName = null;
      fp.announcements = [];
      fp.threads = blocked.size === 0 ? threads : threads.filter((t: Thread) => !(t.authorUid && blocked.has(t.authorUid)));
      fp.page = page;
      fp.hasNext = threads.length > 0;
      return fp;
    } else {
      const url = `forum.php?mod=guide&view=${view}&page=${page}&mobile=2`;
      const html = await this.http.get(url);
      const fp = ForumParser.parseForumPage(html, page);
      
      if (blocked.size === 0) {
        return fp;
      } else {
        fp.announcements = fp.announcements.filter((t: Thread) => !(t.authorUid && blocked.has(t.authorUid)));
        fp.threads = fp.threads.filter((t: Thread) => !(t.authorUid && blocked.has(t.authorUid)));
        return fp;
      }
    }
  }

  // 修复：确保此方法在类内部且语法正确
  async threadPage(tid: string, page: number, orderType: number = 0, authorId: string | null = null): Promise<ThreadPage> {
    let orderStr = orderType === 1 ? "&ordertype=1" : "";
    let authorStr = (authorId && authorId.trim() !== "") ? `&authorid=${authorId}` : "";
    const url = `forum.php?mod=viewthread&tid=${tid}&page=${page}${orderStr}${authorStr}&mobile=2`;
    const html = await this.http.get(url);
    const tp = ForumParser.parseThreadPage(html, page);
    
    const blocked = this.currentBlocked();
    if (blocked.size > 0) {
      tp.posts = tp.posts.filter((post) => !(post.authorUid && blocked.has(post.authorUid)));
    }
    return tp;
  }
}

export const forumRepository = new ForumRepository(HttpClient);
