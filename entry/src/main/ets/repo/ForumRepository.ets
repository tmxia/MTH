import { HttpClient } from '../network/HttpClient';
import { ForumParser } from '../parser/ForumParser';
import { 
  ForumGroup, Forum, Thread, ForumPage, ThreadPage, Post, 
  CheckInStatus, CheckInResult, LoginResult, UserProfile, 
  SearchResult, HomeData, NoticePage, PmPage, ChatConversation, 
  FavoritePage, FriendUserPage, MyThreadPage, NewThreadPageData, 
  NewThreadResult, EditPostPageData, EditPostResult, ImageUpload,
  ReplyResult, LikeResult
, AtUser, FollowUserPage} from '../models/Models';
import { BusinessError } from '@ohos.base';


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

  async fetchNewThreadInit(fid?: string): Promise<NewThreadPageData> { return new NewThreadPageData(); }
  async uploadImage(uri: string, hash?: string, uid?: string): Promise<ImageUpload> { return new ImageUpload(); }
  async newThread(fid: string, subject: string, message: string, typeId?: string, formhash?: string): Promise<NewThreadResult> { return new NewThreadResult(); }
  async fetchPms(page?: number): Promise<PmPage> { return new PmPage(); }
  async fetchChat(touid: string): Promise<ChatConversation> { return new ChatConversation(); }
  async sendPm(touid: string, message: string, formhash?: string): Promise<ReplyResult> { return new ReplyResult(); }

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

}
export const forumRepository = ForumRepository.getInstance();
