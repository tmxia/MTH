import { HttpClient } from '../network/HttpClient';
import { ForumGroup, HomeData, ForumPage, Thread, ThreadPage, LoginResult, UserProfile, CheckInStatus, CheckInResult, NoticePage, ReplyResult, SearchResult, MyThreadPage, FavoritePage, FriendUserPage, NewThreadPageData, NewThreadResult, ImageUpload, PmPage, ChatConversation } from '../models/Models';
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

  // 搜索帖子
  async search(keyword: string, page: number = 1): Promise<SearchResult> {
    const url = `search.php?mod=forum&srchtxt=${encodeURIComponent(keyword)}&searchsubmit=yes&page=${page}&mobile=2`;
    const html = await HttpClient.get(url);
    return ForumParser.parseSearchResult(html);
  }

  // 我的帖子
  async myThreads(page: number = 1): Promise<MyThreadPage> {
    const url = `home.php?mod=space&do=thread&view=me&type=thread&page=${page}&mobile=2`;
    const html = await HttpClient.get(url);
    return ForumParser.parseMyThreads(html, page);
  }

  // 我的收藏
  async myFavorites(page: number = 1): Promise<FavoritePage> {
    const url = `home.php?mod=space&do=favorite&view=me&type=all&page=${page}&mobile=2`;
    const html = await HttpClient.get(url);
    return ForumParser.parseFavorites(html, page);
  }

  // 我的好友
  async myFriends(page: number = 1): Promise<FriendUserPage> {
    const url = `home.php?mod=space&do=friend&page=${page}&mobile=2`;
    const html = await HttpClient.get(url);
    return ForumParser.parseFriends(html, page);
  }

  async fetchNewThreadInit(fid: string): Promise<NewThreadPageData> {
    const url = `forum.php?mod=post&action=newthread&fid=${fid}&mobile=2`;
    const html = await HttpClient.get(url);
    return ForumParser.parseNewThreadInit(html);
  }

  async uploadImage(filePath: string, uid: string, hash: string): Promise<ImageUpload | null> {
    const url = "misc.php?mod=swfupload&operation=upload&type=image&inajax=yes&infloat=yes&simple=2";
    const formData: Record<string, string> = { "uid": uid, "hash": hash };
    
    // 注意：鸿蒙原生上传回调获取服务器返回内容较复杂，这里先作为上传成功处理
    // 实际项目中需要通过 request.uploadFile 的回调或临时文件读取服务器返回
    const res: string = await HttpClient.uploadFile(url, filePath, formData);
    if (res === "UPLOAD_SUCCESS") {
       // 此处需配合真实抓包，由于暂时拿不到服务器返回的 aid 和 path，给默认值
       const img = new ImageUpload();
       img.aid = "0";
       img.path = filePath;
       return img;
    }
    return null;
  }

  async newThread(fid: string, formhash: string, posttime: string, subject: string, message: string): Promise<NewThreadResult> {
    const url = `forum.php?mod=post&action=newthread&fid=${fid}&extra=&topicsubmit=yes&mobile=2`;
    const bodyStr = "formhash=" + encodeURIComponent(formhash) +
                    "&posttime=" + encodeURIComponent(posttime) +
                    "&subject=" + encodeURIComponent(subject) +
                    "&message=" + encodeURIComponent(message) +
                    "&usesig=1&save=1";
    const headers: Record<string, string> = {
      "Referer": HttpClient.baseUrl + `forum.php?mod=post&action=newthread&fid=${fid}`
    };
    const html = await HttpClient.post(url, bodyStr, headers);
    return ForumParser.parseNewThreadResult(html);
  }

  async fetchPms(): Promise<PmPage> {
    const url = "home.php?mod=space&do=pm&mobile=2";
    const html = await HttpClient.get(url);
    return ForumParser.parsePmPage(html);
  }

  async fetchChat(touid: string): Promise<ChatConversation> {
    const url = `home.php?mod=space&do=pm&subop=view&touid=${touid}&mobile=2`;
    const html = await HttpClient.get(url);
    return ForumParser.parseChatConversation(html, touid);
  }

  async sendPm(touid: string, formhash: string, message: string): Promise<boolean> {
    const url = `home.php?mod=spacecp&ac=pm&op=send&touid=${touid}&mobile=2`;
    const bodyStr = "formhash=" + encodeURIComponent(formhash) +
                    "&message=" + encodeURIComponent(message) +
                    "&pmsubmit=yes";
    const html = await HttpClient.post(url, bodyStr, { "Referer": HttpClient.baseUrl + `home.php?mod=space&do=pm&subop=view&touid=${touid}` });
    return html.includes("发送成功") || html.includes("succeedhandle");
  }

  async toggleLike(tid: string, formhash: string, like: boolean): Promise<boolean> {
    const url = `forum.php?mod=misc&action=recommend&do=add&tid=${tid}&formhash=${formhash}&mobile=2`;
    // Discuz 点赞/取消点赞通常也是 GET
    const html = await HttpClient.get(url);
    return html.includes("succeedhandle") || html.includes("推荐成功") || html.includes("已取消");
  }

  async toggleFavorite(tid: string, formhash: string, fav: boolean): Promise<boolean> {
    const action = fav ? "favorite" : "unfavorite";
    const url = `home.php?mod=spacecp&ac=favorite&type=thread&id=${tid}&formhash=${formhash}&mobile=2&op=${action}`;
    const html = await HttpClient.get(url);
    return html.includes("succeedhandle") || html.includes("收藏成功") || html.includes("取消收藏");
  }
}





export const forumRepository = new ForumRepository();
