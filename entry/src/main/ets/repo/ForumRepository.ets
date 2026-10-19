import { HttpClient } from '../network/HttpClient';
import { 
  ForumGroup, Forum, Thread, ForumPage, ThreadPage, Post, 
  CheckInStatus, CheckInResult, LoginResult, UserProfile, ReplyResult, LikeResult, 
  SearchResult, HomeData, NoticePage, PmPage, ChatConversation, 
  FavoritePage, FriendUserPage, MyThreadPage, NewThreadPageData, 
  NewThreadResult, EditPostPageData, EditPostResult, ImageUpload 
} from '../models/Models';

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

  // --- 真实的网络请求逻辑 ---

  async home(): Promise<HomeData> {
    // 真实请求：对应 Android 端的 fetchHomeData
    try {
      let res = await HttpClient.get('/');
      // TODO: 调用 ForumParser 解析 HTML
      return new HomeData();
    } catch (e) {
      console.error('home error', e);
      return new HomeData();
    }
  }

  async forumGroups(): Promise<Array<ForumGroup>> {
    try {
      let res = await HttpClient.get('/forum.php?gid=1');
      return []; // TODO: 解析板块
    } catch (e) {
      return [];
    }
  }

  async threadPage(tid: string, page: number = 1): Promise<ThreadPage> {
    try {
      let res = await HttpClient.get(`/thread-${tid}-${page}-1.html`);
      return new ThreadPage(); // TODO: 解析详情
    } catch (e) {
      return new ThreadPage();
    }
  }

  async login(username: string, password: string, answer?: string, seccode?: string): Promise<LoginResult> {
    try {
      let body: Record<string, string> = {
        'username': username,
        'password': password,
        'fastloginfield': 'username',
        'cookietime': '2592000'
      };
      if (answer) body['answer'] = answer;
      if (seccode) body['seccodeverify'] = seccode;

      // 登录接口一般为 POST 表单
      let res = await HttpClient.post('/member.php?mod=logging&action=login&loginsubmit=yes&handlekey=login&loginhash=XXXX', body);
      
      // 判断返回的 HTML 里是否包含登录成功标志
      if (res.includes('欢迎您回来') || res.includes('登录成功')) {
        return { success: true, message: '登录成功' } as LoginResult;
      }
      return { success: false, message: '账号或密码错误' } as LoginResult;
    } catch (e) {
      return { success: false, message: '网络错误' } as LoginResult;
    }
  }

  async checkInStatus(): Promise<CheckInStatus> {
    try {
      let res = await HttpClient.get('/plugin.php?id=k_misign:sign');
      let hasSigned = res.includes('已签到') || res.includes('今日已签');
      let formhash = this.extractFormhash(res);
      return { hasSigned, formhash } as CheckInStatus;
    } catch (e) {
      return { hasSigned: false } as CheckInStatus;
    }
  }

  async submitCheckIn(formhash?: string): Promise<CheckInResult> {
    try {
      let res = await HttpClient.get(`/plugin.php?id=k_misign:sign&operation=qiandao&format=button&formhash=${formhash || ''}`);
      if (res.includes('签到成功')) {
        return { success: true, message: '签到成功' } as CheckInResult;
      }
      return { success: false, message: '签到失败' } as CheckInResult;
    } catch (e) {
      return { success: false, message: '网络错误' } as CheckInResult;
    }
  }

  // 辅助方法：从 HTML 提取 formhash
  extractFormhash(html: string): string {
    let match = html.match(/formhash["']?\s+value=["']([0-9a-fA-F]+)/);
    return match ? match[1] : '';
  }

  // 以下为占位方法，保持 UI 编译通过
  async me(): Promise<UserProfile> { return new UserProfile(); }
  async reply(tid: string, message: string, formhash?: string, captcha?: string): Promise<ReplyResult> { return new ReplyResult(); }
  async likeThread(tid: string, formhash?: string, action?: string | boolean): Promise<LikeResult> { return new LikeResult(); }
  async favoriteThread(tid: string, formhash?: string): Promise<ReplyResult> { return new ReplyResult(); }
  async forumPage(fid: string, page?: number, sort?: ForumSort | string): Promise<ForumPage> { return new ForumPage(); }
  async notices(tab?: string): Promise<NoticePage> { return new NoticePage(); }
  async myThreads(page?: number): Promise<MyThreadPage> { return new MyThreadPage(); }
  async myFavorites(page?: number): Promise<FavoritePage> { return new FavoritePage(); }
  async myFriends(page?: number): Promise<FriendUserPage> { return new FriendUserPage(); }
  async search(keyword: string, page?: number): Promise<SearchResult> { return new SearchResult(); }
  async fetchNewThreadInit(fid?: string): Promise<NewThreadPageData> { return new NewThreadPageData(); }
  async uploadImage(uri: string, hash?: string, uid?: string): Promise<ImageUpload> { return new ImageUpload(); }
  async newThread(fid: string, subject: string, message: string, typeId?: string, formhash?: string): Promise<NewThreadResult> { return new NewThreadResult(); }
  async fetchPms(page?: number): Promise<PmPage> { return new PmPage(); }
  async fetchChat(touid: string): Promise<ChatConversation> { return new ChatConversation(); }
  async sendPm(touid: string, message: string, formhash?: string): Promise<ReplyResult> { return new ReplyResult(); }
  async userThreads(uid: string, page?: number): Promise<MyThreadPage> { return new MyThreadPage(); }
}
export const forumRepository = ForumRepository.getInstance();
