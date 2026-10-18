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
  public blockedUidsProvider: () => Set<string> = () => new Set<string>();

  constructor() {}

  private currentBlocked(): Set<string> {
    return this.blockedUidsProvider();
  }

  async forumGroups(): Promise<Array<ForumGroup>> {
    const url = "forum.php?forumlist=1&mobile=2";
    const html = await HttpClient.get(url);
    return ForumParser.parseForumList(html);
  }

  async home(): Promise<HomeData> {
    const url = "forum.php?mod=guide&view=hot&mobile=2";
    const html = await HttpClient.get(url);
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
      const html = await HttpClient.get(url);
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
      const html = await HttpClient.get(url);
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

  async threadPage(tid: string, page: number, orderType: number = 0, authorId: string | null = null): Promise<ThreadPage> {
    let orderStr = orderType === 1 ? "&ordertype=1" : "";
    let authorStr = (authorId && authorId.trim() !== "") ? `&authorid=${authorId}` : "";
    const url = `forum.php?mod=viewthread&tid=${tid}&page=${page}${orderStr}${authorStr}&mobile=2`;
    const html = await HttpClient.get(url);
    const tp = ForumParser.parseThreadPage(html, page);
    
    const blocked = this.currentBlocked();
    if (blocked.size > 0) {
      tp.posts = tp.posts.filter((post) => !(post.authorUid && blocked.has(post.authorUid)));
    }
    return tp;
  }

  // 登录接口
  async login(username: string, password: string, questionId: number = 0, answer: string = ""): Promise<LoginResult> {
    const loginUrl = "member.php?mod=logging&action=login&mobile=2";
    const loginPageHtml = await HttpClient.get(loginUrl);
    
    const loginhash = ForumParser.extractLoginHash(loginPageHtml);
    const formhash = ForumParser.extractLoginFormhash(loginPageHtml) || "";
    
    if (!loginhash) {
      const failRes = new LoginResult();
      failRes.success = false;
      failRes.message = "无法获取登录令牌（可能被风控拦截）";
      return failRes;
    }

    const submitUrl = `member.php?mod=logging&action=login&loginsubmit=yes&loginhash=${loginhash}`;
    const body = {
      "formhash": formhash,
      "referer": HttpClient['baseUrl'], // 访问基类静态属性
      "fastloginfield": "username",
      "cookietime": "31104000", // 一年免登录
      "username": username,
      "password": password,
      "questionid": questionId.toString(),
      "answer": answer,
      "submit": "true"
    };

    const headers = {
      "Referer": HttpClient['baseUrl'] + loginUrl
    };

    const resultHtml = await HttpClient.post(submitUrl, body, headers);
    return ForumParser.parseLoginResult(resultHtml);
  }

  // 获取特定版块的帖子列表
  async forumPage(fid: string, page: number, sort: ForumSort = ForumSort.LATEST): Promise<ForumPage> {
    // 对齐原版：拼装排序参数
    let sortParam = "";
    if (sort === ForumSort.HOT) sortParam = "&orderby=hot";
    else if (sort === ForumSort.DIGEST) sortParam = "&filter=digest";
    else if (sort === ForumSort.POLL) sortParam = "&filter=poll";
    
    const url = `forum.php?mod=forumdisplay&fid=${fid}&page=${page}${sortParam}&mobile=2`;
    const html = await HttpClient.get(url);
    const fp = ForumParser.parseForumPage(html, page);
    
    const blocked = this.currentBlocked();
    if (blocked.size > 0) {
      fp.announcements = fp.announcements.filter((t: Thread) => !(t.authorUid && blocked.has(t.authorUid)));
      fp.threads = fp.threads.filter((t: Thread) => !(t.authorUid && blocked.has(t.authorUid)));
    }
    return fp;
  }

  // 获取当前登录用户信息
  async me(): Promise<UserProfile> {
    const url = "home.php?mod=space&do=profile&mobile=2";
    const html = await HttpClient.get(url);
    return ForumParser.parseUserProfile(html);
  }
}




export const forumRepository = new ForumRepository();
