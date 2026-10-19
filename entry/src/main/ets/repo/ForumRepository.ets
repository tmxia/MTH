import { HttpClient } from '../network/HttpClient';
import { 
  ForumGroup, Forum, Thread, ForumPage, ThreadPage, Post, 
  ThreadSnapshot, DownloadedThread, LikeResult, ReplyResult, 
  CheckInStatus, CheckInResult, LoginResult, UserProfile, 
  SearchResult, HomeData, NoticePage, PmPage, ChatConversation, 
  FavoritePage, FollowUserPage, FriendUserPage, MyThreadPage, 
  NewThreadPageData, NewThreadResult, EditPostPageData, EditPostResult,
  ImageUpload, RichTextNode
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

  // --- 以下实现带参数对齐，以满足 ArkTS 严格编译要求 ---
  async home(): Promise<HomeData> { return new HomeData(); }
  async forumGroups(): Promise<Array<ForumGroup>> { return []; }
  async me(): Promise<UserProfile> { return new UserProfile(); }
  
  async checkInStatus(): Promise<CheckInStatus> { return new CheckInStatus(); }
  async submitCheckIn(formhash?: string): Promise<CheckInResult> { return new CheckInResult(); }
  
  async threadPage(tid: string, page?: number): Promise<ThreadPage> { return new ThreadPage(); }
  async reply(tid: string, message: string, formhash?: string, captcha?: string): Promise<ReplyResult> { return new ReplyResult(); }
  async likeThread(tid: string, formhash?: string, action?: string): Promise<LikeResult> { return new LikeResult(); }
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

  // 补上遗漏的 login
  async login(username: string, password: string, answer?: string, seccode?: string): Promise<LoginResult> { return new LoginResult(); }
}
export const forumRepository = ForumRepository.getInstance();
