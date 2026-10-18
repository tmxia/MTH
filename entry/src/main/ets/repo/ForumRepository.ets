import { HttpClient } from '../network/HttpClient';
import { ForumGroup, HomeData, ForumPage, Thread } from '../models/Models';
import { ForumParser } from '../parser/ForumParser';

// ==========================================
// 1. 枚举和常量
// ==========================================
export enum ForumSort {
  LATEST = "最新",
  HOT = "热门",
  DIGEST = "精华",
  POLL = "投票"
}

const GUIDE_VIEW_PORTAL = "hot";

// ==========================================
// 2. 业务仓库类
// ==========================================
export class ForumRepository {
  private http: typeof HttpClient;
  
  // 预留扩展属性，默认为空集合
  public blockedUidsProvider: () => Set<string> = () => new Set<string>();

  constructor(http: typeof HttpClient) {
    this.http = http;
  }

  private currentBlocked(): Set<string> {
    return this.blockedUidsProvider();
  }

  // 获取版块列表
  async forumGroups(): Promise<Array<ForumGroup>> {
    const url = "forum.php?forumlist=1&mobile=2";
    const html = await this.http.get(url);
    return ForumParser.parseForumList(html);
  }

  // 获取首页推荐数据 (热门)
  async home(): Promise<HomeData> {
    const url = "forum.php?mod=guide&view=hot&mobile=2";
    const html = await this.http.get(url);
    const data = ForumParser.parseHome(html);
    
    const blocked = this.currentBlocked();
    if (blocked.size === 0) {
      return data;
    } else {
      // 过滤被屏蔽用户的热帖
      data.hotThreads = data.hotThreads.filter((thread: Thread) => {
        return !(thread.authorUid && blocked.has(thread.authorUid));
      });
      return data;
    }
  }

  // 获取导读流 (最新/热门/精华/回复)
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
}

// 导出单例
export const forumRepository = new ForumRepository(HttpClient);
