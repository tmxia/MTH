import { HttpClient } from '../network/HttpClient';
import { 
  ForumGroup, HomeData, ForumPage, Thread, ThreadPage, 
  LoginResult, UserProfile, CheckInStatus, CheckInResult, 
  NoticePage, ReplyResult 
} from '../models/Models';
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

  async forumPage(fid: string, page: number, sort: ForumSort = ForumSort.LATEST): Promise<ForumPage> {
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

  // 采用字符串拼接 body，彻底避开对象字面量检查
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
    
    const bodyStr = "formhash=" + encodeURIComponent(formhash) +
                    "&referer=" + encodeURIComponent(HttpClient.baseUrl) +
                    "&fastloginfield=username&cookietime=31104000" +
                    "&username=" + encodeURIComponent(username) +
                    "&password=" + encodeURIComponent(password) +
                    "&questionid=" + questionId +
                    "&answer=" + encodeURIComponent(answer) +
                    "&submit=true";

    const headers: Record<string, string> = {
      "Referer": HttpClient.baseUrl + loginUrl
    };

    const resultHtml = await HttpClient.post(submitUrl, bodyStr, headers);
    return ForumParser.parseLoginResult(resultHtml);
  }

  async me(): Promise<UserProfile> {
    const url = "home.php?mod=space&do=profile&mobile=2";
    const html = await HttpClient.get(url);
    return ForumParser.parseUserProfile(html);
  }

  async checkInStatus(): Promise<CheckInStatus> {
    const url = "k_misign-sign.html";
    const html = await HttpClient.get(url);
    return ForumParser.parseCheckInStatus(html);
  }

  async submitCheckIn(formhash: string): Promise<CheckInResult> {
    const url = `plugin.php?id=k_misign:sign&operation=qiandao&format=text&formhash=${formhash}`;
    const html = await HttpClient.get(url);
    return ForumParser.parseCheckInResponse(html);
  }

  async notices(): Promise<NoticePage> {
    const url = "home.php?mod=space&do=notice&view=mypost&mobile=2";
    const html = await HttpClient.get(url);
    return ForumParser.parseNoticePage(html);
  }

  // 同样用字符串拼接表单
  async reply(tid: string, fid: string, formhash: string, message: string): Promise<ReplyResult> {
    const url = `forum.php?mod=post&action=reply&fid=${fid}&tid=${tid}&extra=&replysubmit=yes&mobile=2`;
    const bodyStr = "formhash=" + encodeURIComponent(formhash) +
                    "&message=" + encodeURIComponent(message) +
                    "&replysubmit=yes";
    const headers: Record<string, string> = {
      "Referer": HttpClient.baseUrl + `forum.php?mod=viewthread&tid=${tid}`
    };
    const html = await HttpClient.post(url, bodyStr, headers);
    return ForumParser.parseReplyResponse(html);
  }
}

export const forumRepository = new ForumRepository();
