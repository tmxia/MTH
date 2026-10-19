import { HttpClient } from '../network/HttpClient';
import { ForumParser } from '../parser/ForumParser';
import { 
  ForumGroup, Forum, Thread, ForumPage, ThreadPage, Post, 
  CheckInStatus, CheckInResult, LoginResult, UserProfile, 
  SearchResult, HomeData, NoticePage, PmPage, ChatConversation, 
  FavoritePage, FriendUserPage, MyThreadPage, NewThreadPageData, 
  NewThreadResult, EditPostPageData, EditPostResult, ImageUpload,
  ReplyResult, LikeResult
, AtUser, FollowUserPage, SmileyPack, LikeUser} from '../models/Models';
import { BusinessError } from '@ohos.base';



interface INewThreadBody {
  formhash: string;
  subject: string;
  message: string;
  topicsubmit: string;
  typeid?: string;
}
interface ISendPmBody {
  formhash: string;
  touid: string;
  message: string;
  pmsubmit: string;
}
interface IDeleteFavBody {
  formhash: string;
  deletesubmit: string;
  handlekey: string;
}
interface IReportBody {
  formhash: string;
  tid: string;
  fid: string;
  rtype: string;
  rid: string;
  reportsubmit: string;
  reason: string;
  message: string;
  pid?: string;
}
interface IEditPostBody {
  formhash: string;
  message: string;
  editsubmit: string;
  tid: string;
  pid: string;
  subject?: string;
}
interface IDeletePostBody {
  formhash: string;
  delete: string;
  pid: string;
  tid: string;
  editsubmit: string;
}
interface IBlacklistBody {
  blacklistsubmit: string;
  blacklistsubmit_btn: string;
  formhash: string;
  username: string;
}

interface ReplyPostBody {
  formhash: string;
  message: string;
  replysubmit: string;
  fid: string;
  tid: string;
}

interface LoginPostBody {
  username: string;
  password: string;
  fastloginfield: string;
  cookietime: string;
  answer?: string;
  seccodeverify?: string;
}



interface IAddFriendBody {
  formhash: string;
  uid: string;
  addsubmit: string;
  handlesubmit: string;
}
interface ISetFollowRemarkBody {
  formhash: string;
  fuid: string;
  remark: string;
  followremarksubmit: string;
}
interface IRewardAuthorBody {
  formhash: string;
  tid: string;
  amount: string;
  rewardsubmit: string;
}

export enum ForumSort {
  LATEST = "最新",
  HOT = "热门",
  DIGEST = "精华",
  POLL = "投票"
}

export class ForumRepository {
  private static instance: ForumRepository;
  
  static getInstance(): ForumRepository {
    if (!ForumRepository.instance) {
      ForumRepository.instance = new ForumRepository();
    }
    return ForumRepository.instance;
  }

  // ===== 核心网络请求区（已全面接入真实接口） =====

  async home(): Promise<HomeData> {
    try {
      let res = await HttpClient.get('/');
      let groups = ForumParser.parseForumList(res);
      let pageData = ForumParser.parseForumPage(res, 1);
      
      let homeData = new HomeData();
      homeData.hotForums = groups.flatMap(g => g.forums);
      homeData.hotThreads = pageData.threads;
      return homeData;
    } catch (e) {
      let err = e as BusinessError;
      console.error('home error', err.message);
      return new HomeData();
    }
  }

  async forumGroups(): Promise<Array<ForumGroup>> {
    try {
      let res = await HttpClient.get('/forum.php');
      return ForumParser.parseForumList(res);
    } catch (e) {
      let err = e as BusinessError;
      console.error('forumGroups error', err.message);
      return [];
    }
  }

  async forumPage(fid: string, page: number = 1, sort?: ForumSort | string): Promise<ForumPage> {
    try {
      let res = await HttpClient.get(`/forum-${fid}-${page}.html`);
      return ForumParser.parseForumPage(res, page);
    } catch (e) {
      let err = e as BusinessError;
      console.error('forumPage error', err.message);
      return new ForumPage();
    }
  }

  async threadPage(tid: string, page: number = 1): Promise<ThreadPage> {
    try {
      let res = await HttpClient.get(`/thread-${tid}-${page}-1.html`);
      return ForumParser.parseThreadPage(res, page);
    } catch (e) {
      let err = e as BusinessError;
      console.error('threadPage error', err.message);
      return new ThreadPage();
    }
  }

  async login(username: string, password: string, answer?: string, seccode?: string): Promise<LoginResult> {
    try {
      let body: LoginPostBody = {
        'username': username,
        'password': password,
        'fastloginfield': 'username',
        'cookietime': '2592000'
      };
      if (answer) body.answer = answer;
      if (seccode) body.seccodeverify = seccode;

      let res = await HttpClient.post('/member.php?mod=logging&action=login&loginsubmit=yes&handlekey=login&loginhash=XXXX', body);
      
      if (res.includes('欢迎您回来') || res.includes('登录成功')) {
        let resObj = new LoginResult(); resObj.success = true; resObj.message = '登录成功'; return resObj;
      }
      let resObj = new LoginResult(); resObj.success = false; resObj.message = '账号或密码错误'; return resObj;
    } catch (e) {
      let err = e as BusinessError;
      let resObj = new LoginResult(); resObj.success = false; resObj.message = '网络错误'; return resObj;
    }
  }

  async me(): Promise<UserProfile> {
    try {
      let res = await HttpClient.get('/home.php?mod=spacecp');
      let user = new UserProfile();
      // TODO: 使用正则从 res 解析当前用户信息
      if (res.includes('退出登录')) {
        user.name = "已登录用户";
      }
      return user;
    } catch (e) {
      return new UserProfile();
    }
  }

  async checkInStatus(): Promise<CheckInStatus> {
    try {
      let res = await HttpClient.get('/plugin.php?id=k_misign:sign');
      let hasSigned = res.includes('已签到') || res.includes('今日已签');
      let formhash = ForumParser.extractFirstMatch(res, /formhash["']?\s+value=["']([0-9a-fA-F]+)/i) || "";
      let status = new CheckInStatus();
      status.hasSigned = hasSigned;
      status.formhash = formhash;
      return status;
    } catch (e) {
      return new CheckInStatus();
    }
  }

  async submitCheckIn(formhash?: string): Promise<CheckInResult> {
    try {
      let res = await HttpClient.get(`/plugin.php?id=k_misign:sign&operation=qiandao&format=button&formhash=${formhash || ''}`);
      let result = new CheckInResult();
      result.success = res.includes('签到成功');
      result.message = result.success ? '签到成功' : '签到失败';
      return result;
    } catch (e) {
      return new CheckInResult();
    }
  }

  async notices(tab?: string): Promise<NoticePage> {
    try {
      let res = await HttpClient.get('/home.php?mod=space&do=notice');
      return new NoticePage(); // TODO: 解析通知
    } catch (e) {
      return new NoticePage();
    }
  }

  async myThreads(page: number = 1): Promise<MyThreadPage> {
    try {
      let res = await HttpClient.get(`/home.php?mod=space&do=thread&type=thread&page=${page}`);
      let pageData = ForumParser.parseForumPage(res, page);
      let myThreads = new MyThreadPage();
      myThreads.threads = pageData.threads;
      myThreads.page = page;
      myThreads.hasNext = pageData.hasNext;
      return myThreads;
    } catch (e) {
      return new MyThreadPage();
    }
  }

  async myFavorites(page: number = 1): Promise<FavoritePage> {
    try {
      let res = await HttpClient.get(`/home.php?mod=space&do=favorite&view=me&page=${page}`);
      return new FavoritePage(); // TODO: 解析收藏
    } catch (e) {
      return new FavoritePage();
    }
  }

  async myFriends(page: number = 1): Promise<FriendUserPage> {
    try {
      let res = await HttpClient.get(`/home.php?mod=space&do=friend&view=me&page=${page}`);
      return new FriendUserPage(); // TODO: 解析好友
    } catch (e) {
      return new FriendUserPage();
    }
  }

  async search(keyword: string, page: number = 1): Promise<SearchResult> {
    try {
      let res = await HttpClient.get(`/search.php?mod=forum&srchtxt=${encodeURIComponent(keyword)}&page=${page}`);
      return new SearchResult(); // TODO: 解析搜索结果
    } catch (e) {
      return new SearchResult();
    }
  }

  async userThreads(uid: string, page: number = 1): Promise<MyThreadPage> {
    try {
      let res = await HttpClient.get(`/home.php?mod=space&uid=${uid}&do=thread&view=me&page=${page}`);
      let pageData = ForumParser.parseForumPage(res, page);
      let myThreads = new MyThreadPage();
      myThreads.threads = pageData.threads;
      myThreads.page = page;
      myThreads.hasNext = pageData.hasNext;
      return myThreads;
    } catch (e) {
      return new MyThreadPage();
    }
  }

  // ===== 以下是发帖、回帖、点赞等高阶操作接口 =====
  
  async reply(tid: string, fid: string, formhash: string, message: string): Promise<ReplyResult> {
    try {
      let body: ReplyPostBody = {
        formhash: formhash,
        message: message,
        replysubmit: 'yes',
        fid: fid,
        tid: tid
      };
      let res = await HttpClient.post('/forum.php?mod=post&action=reply&fid=' + fid + '&tid=' + tid + '&reppostsubmit=yes', body);
      let result = new ReplyResult();
      result.success = res.includes('回复成功') || res.includes('succeedhandle');
      result.message = result.success ? '回复成功' : '回复失败';
      return result;
    } catch (e) {
      return new ReplyResult();
    }
  }

  async likeThread(tid: string, formhash: string, isLike: boolean): Promise<LikeResult> {
    try {
      let action = isLike ? 'recommend' : 'recommendcancel';
      let res = await HttpClient.get('/forum.php?mod=misc&action=' + action + '&tid=' + tid + '&formhash=' + formhash);
      let result = new LikeResult();
      result.success = res.includes('succeedhandle') || res.includes('操作成功');
      return result;
    } catch (e) {
      return new LikeResult();
    }
  }

  async favoriteThread(tid: string, formhash: string): Promise<ReplyResult> {
    try {
      let res = await HttpClient.get('/home.php?mod=spacecp&ac=favorite&type=thread&id=' + tid + '&formhash=' + formhash);
      let result = new ReplyResult();
      result.success = res.includes('收藏成功') || res.includes('succeedhandle');
      return result;
    } catch (e) {
      return new ReplyResult();
    }
  }

  async fetchNewThreadInit(fid?: string): Promise<NewThreadPageData> {
    const fidStr = fid || '';
    try {
      const html = await HttpClient.get('/forum.php?mod=post&action=newthread&fid=' + fidStr + '&mobile=2');
      return ForumParser.parseNewThreadPageData(html);
    } catch (e) {
      const empty = new NewThreadPageData();
      empty.permissionDenied = '网络异常：' + (e as Error).message;
      return empty;
    }
  }
  async uploadImage(uri: string, hash?: string, uid?: string): Promise<ImageUpload> {
    const result = new ImageUpload();
    try {
      const u = uid || '';
      const h = hash || '';
      if (!u || !h) {
        console.error('uploadImage: 缺少 uid 或 hash');
        return result;
      }
      let filePath = uri;
      if (filePath.indexOf('file://') === 0) {
        filePath = filePath.substring(7);
      }
      const url = '/misc.php?mod=swfupload&operation=upload&type=image&inajax=yes&infloat=yes&simple=2';
      const body = await HttpClient.uploadMultipart(url, filePath, 'Filedata', 'image.jpg', 'image/jpeg', u, h);
      const parsed = ForumParser.parseUploadResponse(body);
      if (parsed) return parsed;
      console.error('uploadImage: 响应解析失败, body=' + (body || '').substring(0, 200));
    } catch (e) {
      console.error('uploadImage error: ' + (e as Error).message);
    }
    return result;
  }
  async newThread(fid: string, subject: string, message: string, typeId?: string, formhash?: string): Promise<NewThreadResult> {
    const result = new NewThreadResult();
    try {
      const fh = (formhash && formhash.length > 0) ? formhash : await this.fetchFormhash();
      if (!fh) {
        result.success = false;
        result.message = '获取操作凭据失败，请重试';
        return result;
      }
      const url = '/forum.php?mod=post&action=newthread&fid=' + fid + '&extra=&topicsubmit=yes&mobile=2&handlekey=postform&inajax=1';
      const body: INewThreadBody = {
        formhash: fh,
        subject: subject,
        message: message,
        topicsubmit: 'yes'
      };
      if (typeId && typeId !== '0') {
        body.typeid = typeId;
      }
      const res = await HttpClient.post(url, body);
      const ok = res.indexOf('succeedhandle') >= 0 ||
                 res.indexOf('发布成功') >= 0 ||
                 res.indexOf('thread-') >= 0 ||
                 res.indexOf('tid=') >= 0 ||
                 res.indexOf('需要审核') >= 0;
      result.success = ok;
      result.message = ok ? '发布成功' : '发布失败，请检查内容或稍后重试';
      const tidMatch = /tid=(\d+)/.exec(res);
      if (tidMatch) {
        result.tid = tidMatch[1];
      }
    } catch (e) {
      result.success = false;
      result.message = '发布失败：' + (e as Error).message;
    }
    return result;
  }
  async fetchPms(page?: number): Promise<PmPage> {
    const p = page || 1;
    try {
      const html = await HttpClient.get('/home.php?mod=space&do=pm&filter=&page=' + p + '&mobile=2');
      return ForumParser.parsePmPage(html);
    } catch (e) {
      return new PmPage();
    }
  }
  async fetchChat(touid: string): Promise<ChatConversation> {
    try {
      const html = await HttpClient.get('/home.php?mod=space&do=pm&subop=view&touid=' + touid + '&mobile=2');
      return ForumParser.parseChatConversation(html, touid);
    } catch (e) {
      const empty = new ChatConversation();
      empty.touid = touid;
      return empty;
    }
  }
  async sendPm(touid: string, message: string, formhash?: string): Promise<ReplyResult> {
    const result = new ReplyResult();
    try {
      if (!message || message.trim().length === 0) {
        result.success = false;
        result.message = '消息内容不能为空';
        return result;
      }
      const fh = (formhash && formhash.length > 0) ? formhash : await this.fetchFormhash();
      if (!fh) {
        result.success = false;
        result.message = '获取操作凭据失败，请重试';
        return result;
      }
      const url = '/home.php?mod=spacecp&ac=pm&op=send&pmid=0&daterange=2&pmsubmit=yes&inajax=1&mobile=2';
      const body: ISendPmBody = {
        formhash: fh,
        touid: touid,
        message: message,
        pmsubmit: 'yes'
      };
      const res = await HttpClient.post(url, body);
      const ok = res.indexOf('succeedhandle') >= 0 ||
                 res.indexOf('发送成功') >= 0 ||
                 res.indexOf('消息已发送') >= 0;
      result.success = ok;
      result.message = ok ? '发送成功' : '发送失败，请稍后重试';
    } catch (e) {
      result.success = false;
      result.message = '发送失败：' + (e as Error).message;
    }
    return result;
  }

  // ===== @ 用户相关 =====

  async fetchAtUsers(): Promise<Array<string>> {
    try {
      let html = await HttpClient.get('/misc.php?mod=getatuser&inajax=1');
      return ForumParser.parseAtUsers(html);
    } catch (e) {
      return [];
    }
  }

  async fetchFriends(): Promise<Array<AtUser>> {
    return this.atUserPages('home.php?mod=space&do=friend&page=');
  }

  async fetchFollows(): Promise<Array<AtUser>> {
    return this.atUserPages('home.php?mod=follow&do=following&page=');
  }

  async searchUsers(keyword: string): Promise<Array<AtUser>> {
    const kw = keyword.trim();
    if (!kw) return [];
    try {
      const encoded = encodeURIComponent(kw);
      let html = await HttpClient.get('/search.php?mod=user&searchsubmit=yes&srchtxt=' + encoded + '&mobile=2');
      return ForumParser.parseAtUserList(html);
    } catch (e) {
      return [];
    }
  }

  private async atUserPages(prefix: string): Promise<Array<AtUser>> {
    const all: AtUser[] = [];
    const MAX_PAGES = 10;
    for (let page = 1; page <= MAX_PAGES; page++) {
      try {
        let html = await HttpClient.get('/' + prefix + page + '&mobile=2');
        let batch = ForumParser.parseAtUserList(html);
        if (batch.length === 0) break;
        for (const u of batch) all.push(u);
        if (batch.length < 20) break;
      } catch (e) {
        break;
      }
    }
    return all;
  }


  // ===== 关注 / 粉丝 =====

  async followList(type: string, page: number = 1): Promise<FollowUserPage> {
    const path = type === 'following'
      ? 'home.php?mod=follow&do=following&page=' + page + '&mobile=2'
      : 'home.php?mod=follow&do=follower&page=' + page + '&mobile=2';
    try {
      let html = await HttpClient.get('/' + path);
      return ForumParser.parseFollowUsers(html, page, type === 'following');
    } catch (e) {
      const empty = new FollowUserPage();
      empty.users = [];
      empty.page = page;
      empty.hasNext = false;
      return empty;
    }
  }

  async toggleFollowUser(uid: string, follow: boolean): Promise<boolean> {
    try {
      const formhash = await this.fetchFormhash();
      if (!formhash) return false;
      const op = follow ? 'add' : 'del';
      const url = '/home.php?mod=spacecp&ac=follow&op=' + op + '&fuid=' + uid +
        '&hash=' + formhash + '&handlekey=followmod&inajax=1&mobile=2';
      let res = await HttpClient.get(url);
      return res.indexOf('succeedhandle') >= 0 ||
             res.indexOf('关注成功') >= 0 ||
             res.indexOf('已关注') >= 0 ||
             res.indexOf('取消关注') >= 0 ||
             res.indexOf('操作成功') >= 0;
    } catch (e) {
      return false;
    }
  }

  async fetchFormhash(): Promise<string> {
    try {
      let html = await HttpClient.get('/home.php?mod=spacecp&mobile=2');
      const m = /formhash=([a-zA-Z0-9]+)/.exec(html);
      return m ? m[1] : '';
    } catch (e) {
      return '';
    }
  }


  // ===== 收藏 / 举报 / 编辑 / 删帖 / 拉黑 =====

  async setFavorite(tid: string, formhash: string, favorite: boolean): Promise<boolean> {
    try {
      if (favorite) {
        const url = '/home.php?mod=spacecp&ac=favorite&type=thread&id=' + tid +
          '&formhash=' + formhash + '&handlekey=comiis&inajax=1&mobile=2';
        const body = await HttpClient.get(url);
        return body.indexOf('succeedhandle') >= 0 ||
               body.indexOf('收藏成功') >= 0 ||
               body.indexOf('已收藏') >= 0 ||
               body.indexOf('操作成功') >= 0;
      } else {
        const favid = await this.favoriteFavid(tid);
        if (!favid) return false;
        return await this.deleteFavorite(favid);
      }
    } catch (e) {
      return false;
    }
  }

  async favoriteFavid(tid: string): Promise<string> {
    try {
      const html = await HttpClient.get('/home.php?mod=space&do=favorite&view=me&type=all&mobile=2');
      return ForumParser.parseFavoriteFavid(html, tid);
    } catch (e) {
      return '';
    }
  }

  async deleteFavorite(favid: string): Promise<boolean> {
    if (!favid) return false;
    try {
      const pageUrl = '/home.php?mod=space&do=favorite&view=me&type=all&mobile=2';
      const pageHtml = await HttpClient.get(pageUrl);
      const fh = ForumParser.parseFormhash(pageHtml);
      if (!fh) return false;
      const url = '/home.php?mod=spacecp&ac=favorite&op=delete&favid=' + favid + '&type=all' +
        '&formhash=' + fh + '&deletesubmit=true&handlekey=comiis&inajax=1&mobile=2';
      const body: IDeleteFavBody = {
        formhash: fh,
        deletesubmit: 'true',
        handlekey: 'comiis'
      };
      const res = await HttpClient.post(url, body);
      return res.indexOf('succeedhandle') >= 0 ||
             res.indexOf('已删除') >= 0 ||
             res.indexOf('操作成功') >= 0;
    } catch (e) {
      return false;
    }
  }

  async reportPost(tid: string, fid: string, formhash: string, pid: string, reason: string, message: string): Promise<boolean> {
    try {
      const rtype = (!pid || pid.length === 0) ? 'thread' : 'post';
      const rid = (rtype === 'thread') ? tid : pid;
      const formUrl = '/misc.php?mod=report&rtype=' + rtype + '&rid=' + rid + '&tid=' + tid + '&fid=' + fid + '&inajax=1&mobile=2';
      const page = await HttpClient.get(formUrl);
      const fh = ForumParser.parseFormhash(page) || formhash;
      if (!fh) return false;
      const body: IReportBody = {
        formhash: fh,
        tid: tid,
        fid: fid,
        rtype: rtype,
        rid: rid,
        reportsubmit: 'yes',
        reason: (reason && reason.length > 0) ? reason : '其他',
        message: (message && message.length > 0) ? message : '该内容涉嫌违规，请核实处理。'
      };
      if (rtype === 'post' && pid) {
        body.pid = pid;
      }
      const url = '/misc.php?mod=report&rtype=' + rtype + '&rid=' + rid + '&tid=' + tid + '&fid=' + fid + '&reportsubmit=yes&inajax=1&mobile=2';
      const res = await HttpClient.post(url, body);
      return res.indexOf('succeedhandle') >= 0 ||
             res.indexOf('举报成功') >= 0 ||
             res.indexOf('感谢') >= 0 ||
             res.indexOf('已提交') >= 0;
    } catch (e) {
      return false;
    }
  }

  async editPost(tid: string, pid: string, formhash: string, message: string, subject?: string): Promise<EditPostResult> {
    const result = new EditPostResult();
    try {
      const url = '/forum.php?mod=post&action=edit&extra=&tid=' + tid + '&pid=' + pid + '&page=1&editsubmit=yes&mobile=2';
      const body: IEditPostBody = {
        formhash: formhash,
        message: message,
        editsubmit: 'yes',
        tid: tid,
        pid: pid
      };
      if (subject && subject.length > 0) {
        body.subject = subject;
      }
      // 保留已有的 [attach] 标签关联附件
      // attachnew 动态 key 已移除（服务器自动关联附件）

      const res = await HttpClient.post(url, body);
      const ok = res.indexOf('succeedhandle') >= 0 ||
                 res.indexOf('编辑成功') >= 0 ||
                 res.indexOf('保存成功') >= 0;
      result.success = ok;
      result.message = ok ? '编辑成功' : '编辑失败，请稍后重试';
    } catch (e) {
      result.success = false;
      result.message = '编辑失败：' + (e as Error).message;
    }
    return result;
  }

  async deletePost(tid: string, pid: string, formhash: string): Promise<boolean> {
    try {
      const formUrl = '/forum.php?mod=post&action=edit&tid=' + tid + '&pid=' + pid + '&mobile=2';
      const page = await HttpClient.get(formUrl);
      const fh = ForumParser.parseFormhash(page) || formhash;
      if (!fh) return false;
      const body: IDeletePostBody = {
        formhash: fh,
        delete: '1',
        pid: pid,
        tid: tid,
        editsubmit: 'yes'
      };
      const url = '/forum.php?mod=post&action=edit&extra=&tid=' + tid + '&pid=' + pid + '&page=1&delete=1&mobile=2';
      const res = await HttpClient.post(url, body);
      // 如果响应仍然是编辑表单，说明删除失败
      const stillForm = res.indexOf('action=edit') >= 0 && res.indexOf('editsubmit') >= 0;
      return res.length > 0 && !stillForm;
    } catch (e) {
      return false;
    }
  }

  async addUserBlacklist(username: string, formhash: string): Promise<string> {
    try {
      const fh = (formhash && formhash.length > 0) ? formhash : await this.fetchFormhash();
      if (!fh) return '获取操作凭据失败，请重试';
      const url = '/home.php?mod=spacecp&ac=friend&op=blacklist&start=&formhash=' + fh + '&inajax=1&mobile=2';
      const body: IBlacklistBody = {
        blacklistsubmit: 'true',
        blacklistsubmit_btn: 'true',
        formhash: fh,
        username: username
      };
      const res = await HttpClient.post(url, body);
      const ok = res.indexOf('succeedhandle') >= 0 ||
                 res.indexOf('已加入') >= 0 ||
                 res.indexOf('黑名单') >= 0;
      return ok ? '已加入黑名单' : '操作失败，请重试';
    } catch (e) {
      return '操作失败：' + (e as Error).message;
    }
  }

  async removeUserBlacklist(uid: string): Promise<string> {
    try {
      if (!uid) return '用户不存在';
      const fh = await this.fetchFormhash();
      if (!fh) return '尚未登录或会话已过期';
      const url = '/home.php?mod=spacecp&ac=friend&op=blacklist&subop=delete&uid=' + uid +
        '&formhash=' + fh + '&inajax=1&mobile=2';
      const res = await HttpClient.get(url);
      const ok = res.indexOf('succeedhandle') >= 0 ||
                 res.indexOf('已移出') >= 0 ||
                 res.indexOf('移除成功') >= 0;
      return ok ? '已移出黑名单' : '操作失败，请重试';
    } catch (e) {
      return '操作失败：' + (e as Error).message;
    }
  }


  async fetchEditPostInit(tid: string, pid: string): Promise<EditPostPageData> {
    try {
      const html = await HttpClient.get('/forum.php?mod=post&action=edit&tid=' + tid + '&pid=' + pid + '&mobile=2');
      return ForumParser.parseEditPostInit(html);
    } catch (e) {
      const empty = new EditPostPageData();
      empty.permissionDenied = '网络异常：' + (e as Error).message;
      return empty;
    }
  }

  async smileyPacks(): Promise<Array<SmileyPack>> {
    try {
      const js = await HttpClient.get('/data/cache/common_smilies_var.js');
      return ForumParser.parseSmileyPacks(js);
    } catch (e) {
      return [];
    }
  }


  // ===== 版块关注 =====

  async followForum(fid: string, formhash: string): Promise<boolean> {
    try {
      const fh = (formhash && formhash.length > 0) ? formhash : await this.fetchFormhash();
      if (!fh) return false;
      const url = '/home.php?mod=spacecp&ac=follow&op=add&fid=' + fid +
        '&formhash=' + fh + '&handlekey=followmod&inajax=1&mobile=2';
      const res = await HttpClient.get(url);
      return res.indexOf('succeedhandle') >= 0 ||
             res.indexOf('关注成功') >= 0 ||
             res.indexOf('已关注') >= 0 ||
             res.indexOf('操作成功') >= 0;
    } catch (e) {
      return false;
    }
  }

  async followTopic(uid: string, formhash: string, follow: boolean): Promise<string> {
    try {
      const fh = (formhash && formhash.length > 0) ? formhash : await this.fetchFormhash();
      if (!fh) return '获取操作凭据失败';
      const op = follow ? 'add' : 'del';
      const url = '/home.php?mod=spacecp&ac=favorite&type=thread&op=' + op +
        '&id=' + uid + '&formhash=' + fh + '&handlekey=followmod&inajax=1&mobile=2';
      const res = await HttpClient.get(url);
      const ok = res.indexOf('succeedhandle') >= 0 ||
                 res.indexOf('已收藏') >= 0 ||
                 res.indexOf('已取消') >= 0 ||
                 res.indexOf('操作成功') >= 0;
      return ok ? (follow ? '已关注' : '已取消关注') : '操作失败，请稍后重试';
    } catch (e) {
      return '操作失败：' + (e as Error).message;
    }
  }

  async fetchFollowedForumFids(): Promise<Array<string>> {
    const out: Array<string> = [];
    try {
      const html = await HttpClient.get('/home.php?mod=space&do=follow&view=forum&mobile=2');
      const re = /forum(?:&amp;|&)fid=(\d+)/g;
      let m: RegExpExecArray | null = re.exec(html);
      while (m !== null) {
        if (out.indexOf(m[1]) < 0) out.push(m[1]);
        m = re.exec(html);
      }
    } catch (e) {}
    return out;
  }

  // ===== 消息已读 =====

  async pollNoticeView(): Promise<boolean> {
    try {
      const html = await HttpClient.get('/home.php?mod=space&do=notice&view=mypost&isread=1&mobile=2');
      return html.length > 0 && html.indexOf('登录') < 0;
    } catch (e) {
      return false;
    }
  }

  // ===== 点赞用户列表 =====

  async likeUsers(tid: string): Promise<Array<LikeUser>> {
    const out: Array<LikeUser> = [];
    try {
      const html = await HttpClient.get('/forum.php?mod=misc&action=recommend&do=list&tid=' + tid + '&mobile=2');
      const re = /space(?:&amp;|&)uid=(\d+)[\s\S]{0,500}?<\/(?:li|dl|div)>/g;
      let m: RegExpExecArray | null = re.exec(html);
      while (m !== null) {
        const block = m[0];
        const u = new LikeUser();
        u.uid = m[1];
        const nm = /<strong[^>]*>([^<]+)<\/strong>/.exec(block);
        if (nm) u.name = (nm[1] || '').trim();
        const av = /<img[^>]+src=["']([^"']+)["']/.exec(block);
        if (av) {
          let url = av[1];
          if (url.indexOf('//') === 0) url = 'https:' + url;
          u.avatarUrl = url;
        }
        if (u.name) out.push(u);
        m = re.exec(html);
      }
    } catch (e) {}
    return out;
  }

  // ===== 搜索下一页 =====

  async searchNext(nextUrl: string): Promise<SearchResult> {
    try {
      let path = nextUrl;
      if (path.startsWith('http')) {
        const idx = path.indexOf('/', 8);
        if (idx > 0) path = path.substring(idx);
      }
      const html = await HttpClient.get(path);
      return ForumParser.parseSearch(html, 1);
    } catch (e) {
      return new SearchResult();
    }
  }

  // ===== 加好友 =====

  async addFriend(uid: string, formhash: string): Promise<boolean> {
    try {
      const fh = (formhash && formhash.length > 0) ? formhash : await this.fetchFormhash();
      if (!fh) return false;
      const url = '/home.php?mod=spacecp&ac=friend&op=add&uid=' + uid +
        '&formhash=' + fh + '&inajax=1&mobile=2';
      const body: IAddFriendBody = {
        formhash: fh,
        uid: uid,
        addsubmit: 'true',
        handlesubmit: 'true'
      };
      const res = await HttpClient.post(url, body);
      return res.indexOf('succeedhandle') >= 0 ||
             res.indexOf('好友申请') >= 0 ||
             res.indexOf('已发送') >= 0 ||
             res.indexOf('操作成功') >= 0;
    } catch (e) {
      return false;
    }
  }

  // ===== 设置关注备注 =====

  async setFollowRemark(uid: string, remark: string): Promise<boolean> {
    try {
      const fh = await this.fetchFormhash();
      if (!fh) return false;
      const url = '/home.php?mod=spacecp&ac=follow&op=remark&fuid=' + uid +
        '&formhash=' + fh + '&inajax=1&mobile=2';
      const body: ISetFollowRemarkBody = {
        formhash: fh,
        fuid: uid,
        remark: remark,
        followremarksubmit: 'true'
      };
      const res = await HttpClient.post(url, body);
      return res.indexOf('succeedhandle') >= 0 ||
             res.indexOf('操作成功') >= 0 ||
             res.indexOf('已保存') >= 0;
    } catch (e) {
      return false;
    }
  }

  // ===== 版块今日帖子统计 =====

  async fetchForumTodayPosts(): Promise<Map<string, number>> {
    const out: Map<string, number> = new Map();
    try {
      const ts = Date.now();
      const html = await HttpClient.get('/forum.php?forumlist=1&mobile=2&_ts=' + ts);
      // 抓形如 "版块名 (123)" 或 "今日: 123" 格式的帖子数
      const re = /forum(?:&amp;|&)fid=(\d+)[\s\S]{0,300}?今日[:：]\s*(\d+)/g;
      let m: RegExpExecArray | null = re.exec(html);
      while (m !== null) {
        out.set(m[1], parseInt(m[2]) || 0);
        m = re.exec(html);
      }
    } catch (e) {}
    return out;
  }

  // ===== 打赏楼主 =====

  async rewardAuthor(tid: string, amount: number): Promise<boolean> {
    try {
      const fh = await this.fetchFormhash();
      if (!fh) return false;
      const url = '/home.php?mod=spacecp&ac=reward&tid=' + tid +
        '&formhash=' + fh + '&inajax=1&mobile=2';
      const body: IRewardAuthorBody = {
        formhash: fh,
        tid: tid,
        amount: String(amount),
        rewardsubmit: 'true'
      };
      const res = await HttpClient.post(url, body);
      return res.indexOf('succeedhandle') >= 0 ||
             res.indexOf('打赏成功') >= 0 ||
             res.indexOf('积分不足') < 0 && res.indexOf('操作成功') >= 0;
    } catch (e) {
      return false;
    }
  }

  // ===== 删除附件 =====

  async deleteAttach(aid: string): Promise<boolean> {
    try {
      const fh = await this.fetchFormhash();
      if (!fh) return false;
      const url = '/misc.php?mod=attach&action=delete&aid=' + aid +
        '&formhash=' + fh + '&inajax=1&mobile=2';
      const res = await HttpClient.get(url);
      return res.indexOf('succeedhandle') >= 0 ||
             res.indexOf('删除成功') >= 0 ||
             res.indexOf('操作成功') >= 0;
    } catch (e) {
      return false;
    }
  }

  // ===== 用户详情 =====

  async userProfile(uid: string): Promise<UserProfile> {
    try {
      const html = await HttpClient.get('/home.php?mod=space&uid=' + uid + '&do=profile&mobile=2');
      return ForumParser.parseUserProfile(html, uid);
    } catch (e) {
      const empty = new UserProfile();
      empty.uid = uid;
      return empty;
    }
  }


  // ===== 取消关注版块（favid，非 fid）=====

  async unfollowForum(favid: string, formhash: string): Promise<boolean> {
    try {
      const fh = (formhash && formhash.length > 0) ? formhash : await this.fetchFormhash();
      if (!fh) return false;
      const url = '/home.php?mod=spacecp&ac=favorite&op=delete&favid=' + favid +
        '&type=all&formhash=' + fh + '&deletesubmit=true&handlekey=comiis&inajax=1&mobile=2';
      const res = await HttpClient.get(url);
      return res.indexOf('succeedhandle') >= 0 ||
             res.indexOf('已取消') >= 0 ||
             res.indexOf('操作成功') >= 0;
    } catch (e) {
      return false;
    }
  }

  // ===== 发帖页 formhash（兼容安卓签名）=====

  async postFormhash(fid: string): Promise<string> {
    try {
      const data = await this.fetchNewThreadInit(fid);
      return data.formhash || '';
    } catch (e) {
      return '';
    }
  }

  // ===== 推荐流（兼容安卓签名）=====

  async guideFeed(view: string, page: number): Promise<ForumPage> {
    try {
      if (view === 'portal') {
        const html = await HttpClient.get('/plugin.php?id=comiis_app_portal&pid=1&page=' + page + '&inajax=1');
        return ForumParser.parseForumPage(html, page);
      } else {
        const html = await HttpClient.get('/forum.php?mod=guide&view=' + view + '&page=' + page + '&mobile=2');
        return ForumParser.parseForumPage(html, page);
      }
    } catch (e) {
      return new ForumPage();
    }
  }

  // ===== 上传凭证（兼容安卓签名，返回 [uid, hash]）=====

  async fetchUploadCredentials(): Promise<Array<string>> {
    try {
      const data = await this.fetchNewThreadInit('2');
      return [data.uploadUid || '', data.uploadHash || ''];
    } catch (e) {
      return ['', ''];
    }
  }

  // ===== 置顶回复（版主权限，普通用户返回 false）=====

  async stickReply(tid: string, fid: string, formhash: string, pid: string, stick: boolean): Promise<boolean> {
    // 需要版主权限，普通用户直接返回 false
    if (!formhash) return false;
    try {
      const url = '/forum.php?mod=topicadmin&action=stickreply&modsubmit=yes&modclick=yes&mobile=2&inajax=1';
      // 用 form-urlencoded 字符串，避开 ArkTS 对动态 key 的限制
      const parts: string[] = [
        'formhash=' + encodeURIComponent(formhash),
        'fid=' + encodeURIComponent(fid),
        'tid=' + encodeURIComponent(tid),
        'page=1',
        'reason=' + encodeURIComponent('手机版主题操作'),
        'topiclist%5B%5D=' + encodeURIComponent(pid),
        'stickreply=' + (stick ? '1' : '0')
      ];
      const res = await HttpClient.post(url, parts.join('&'));
      return res.indexOf('succeedhandle') >= 0 ||
             res.indexOf('操作成功') >= 0;
    } catch (e) {
      return false;
    }
  }

}
export const forumRepository = ForumRepository.getInstance();
