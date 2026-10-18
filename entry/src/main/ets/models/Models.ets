// 自动从 Kotlin Models.kt 转译生成，100% 匹配原版结构
// 注意：ArkTS 严格区分 undefined 和 null，这里统一使用 null 并给出初始值

export class ForumGroup {
  name: string = "";
  forums: Array<Forum> = [];
}

export class Forum {
  fid: string = "";
  name: string = "";
  icon: string | null = null;
  todayPosts: number = 0;
}

export class Thread {
  tid: string = "";
  subject: string = "";
  authorName: string | null = null;
  authorUid: string | null = null;
  avatarUrl: string | null = null;
  level: string | null = null;
  timeText: string | null = null;
  replyCount: string | null = null;
  viewCount: string | null = null;
  excerpt: string | null = null;
  isAnnouncement: boolean = false;
  forumName: string | null = null;
  imageUrls: Array<string> = [];
  likeCount: string | null = null;
  isSticky: boolean = false;
}

export class ForumPage {
  forumName: string | null = null;
  announcements: Array<Thread> = [];
  threads: Array<Thread> = [];
  page: number = 1;
  hasNext: boolean = false;
}

export class PostQuote {
  author: string | null = null;
  time: string | null = null;
  text: string = "";
  pid: string | null = null;
}

export class Post {
  pid: string = "";
  authorName: string = "";
  authorUid: string | null = null;
  avatarUrl: string | null = null;
  level: string | null = null;
  timeText: string | null = null;
  location: string | null = null;
  contentHtml: string = "";
  isOp: boolean = false;
  isFirstPost: boolean = false;
  floor: number | null = null;
  floorLabel: string | null = null;
  quote: PostQuote | null = null;
  editedText: string | null = null;
  hasHiddenContent: boolean = false;
  sticky: boolean = false;
  imageUrls: Array<string> = [];
}

export class ThreadPage {
  tid: string = "";
  subject: string | null = null;
  forumName: string | null = null;
  posts: Array<Post> = [];
  page: number = 1;
  totalPages: number = 1;
  formhash: string | null = null;
  replyUrl: string | null = null;
  noticeAuthor: string | null = null;
  fid: string | null = null;
  opUid: string | null = null;
  totalReplies: number | null = null;
  likeCount: number | null = null;
  favoriteCount: number | null = null;
  isLiked: boolean = false;
  likedStateKnown: boolean = false;
  isFavorited: boolean = false;
  favoritedStateKnown: boolean = false;
  isFollowingOp: boolean = false;
  followingStateKnown: boolean = false;
  uploadUid: string | null = null;
  uploadHash: string | null = null;
}

export class PageProgress {
  authorId: string | null = null;
  maxPage: number = 0;
  totalPages: number = 0;
}

export class ThreadSnapshot {
  subject: string | null = null;
  forumName: string | null = null;
  opUid: string | null = null;
  fid: string | null = null;
  totalReplies: number | null = null;
  posts: Array<Post> = [];
  progress: Array<PageProgress> = [];
}

export class DownloadedThread {
  tid: string = "";
  subject: string = "";
  forumName: string | null = null;
  fileName: string = "";
  uri: string = "";
  savedAt: number = 0;
  replyCount: number | null = null;
  sizeBytes: number = 0;
}

export class LikeUser {
  uid: string = "";
  name: string = "";
  avatarUrl: string | null = null;
}

export class LikeResult {
  success: boolean = false;
  remainingToday: number | null = null;
  serverCount: number | null = null;
  message: string | null = null;
}

export class ReplyResult {
  success: boolean = false;
  message: string | null = null;
}

export class CheckInStatus {
  hasSigned: boolean = false;
  formhash: string | null = null;
}

export class CheckInResult {
  success: boolean = false;
  message: string = "";
}

export class LoginResult {
  success: boolean = false;
  message: string | null = null;
  needsCaptcha: boolean = false;
  captchaUrl: string | null = null;
}

export class UserProfile {
  uid: string | null = null;
  name: string | null = null;
  avatarUrl: string | null = null;
  level: string | null = null;
  groupName: string | null = null;
  threads: number | null = null;
  posts: number | null = null;
  friends: number | null = null;
  following: number | null = null;
  followers: number | null = null;
  credits: number | null = null;
  gold: number | null = null;
  onlineTime: string | null = null;
  isFollowing: boolean | null = null;
  formhash: string | null = null;

  get isLoggedIn(): boolean {
    return this.uid !== null && this.uid !== "" && this.uid !== "0";
  }
}

export class SearchResult {
  threads: Array<Thread> = [];
  nextUrl: string | null = null;

  get hasNext(): boolean {
    return this.nextUrl !== null;
  }
}

export class HomeData {
  hotForums: Array<Forum> = [];
  hotThreads: Array<Thread> = [];
}

export class Notice {
  id: string = "";
  text: string = "";
  timeText: string | null = null;
  tid: string | null = null;
  avatarUrl: string | null = null;
  uid: string | null = null;
}

export class NoticePage {
  loggedOut: boolean = false;
  notices: Array<Notice> = [];
  totalPages: number = 1;
}

export class AtUser {
  uid: string = "";
  name: string = "";
  avatarUrl: string | null = null;
  subtitle: string = "";
}

// === 复杂枚举/对象转换 ===
export enum NoticeGroup {
  PM = "我的消息",
  FANS = "我的粉丝",
  MY_POST = "我的帖子",
  INTERACTIVE = "坛友互动",
  SYSTEM = "系统提醒",
  APP = "应用提醒"
}

export class NoticeTab {
  title: string;
  group: NoticeGroup;
  view: string | null = null;
  type: string | null = null;
  pmFilter: string | null = null;
  key: string;

  constructor(key: string, title: string, group: NoticeGroup, view: string | null = null, type: string | null = null, pmFilter: string | null = null) {
    this.key = key;
    this.title = title;
    this.group = group;
    this.view = view;
    this.type = type;
    this.pmFilter = pmFilter;
  }

  static PM_PRIVATE = new NoticeTab("PM_PRIVATE", "私人消息", NoticeGroup.PM, null, null, "privatepm");
  static PM_ANNOUNCE = new NoticeTab("PM_ANNOUNCE", "公共消息", NoticeGroup.PM, null, null, "announcepm");
  static POST = new NoticeTab("POST", "帖子", NoticeGroup.MY_POST, "mypost", "post");
  static PCOMMENT = new NoticeTab("PCOMMENT", "点评", NoticeGroup.MY_POST, "mypost", "pcomment");
  static ACTIVITY = new NoticeTab("ACTIVITY", "活动", NoticeGroup.MY_POST, "mypost", "activity");
  static REWARD = new NoticeTab("REWARD", "悬赏", NoticeGroup.MY_POST, "mypost", "reward");
  static GOODS = new NoticeTab("GOODS", "商品", NoticeGroup.MY_POST, "mypost", "goods");
  static AT = new NoticeTab("AT", "提到我的", NoticeGroup.MY_POST, "mypost", "at");
  static POKE = new NoticeTab("POKE", "打招呼", NoticeGroup.INTERACTIVE, "interactive", "poke");
  static FRIEND = new NoticeTab("FRIEND", "好友", NoticeGroup.INTERACTIVE, "interactive", "friend");
  static WALL = new NoticeTab("WALL", "留言", NoticeGroup.INTERACTIVE, "interactive", "wall");
  static COMMENT = new NoticeTab("COMMENT", "评论", NoticeGroup.INTERACTIVE, "interactive", "comment");
  static CLICK = new NoticeTab("CLICK", "挺你", NoticeGroup.INTERACTIVE, "interactive", "click");
  static SHARE = new NoticeTab("SHARE", "分享", NoticeGroup.INTERACTIVE, "interactive", "sharenotice");
  static SYSTEM = new NoticeTab("SYSTEM", "系统提醒", NoticeGroup.SYSTEM, "system");
  static APP = new NoticeTab("APP", "应用提醒", NoticeGroup.APP, "app");

  static values(): Array<NoticeTab> {
    return [
      NoticeTab.PM_PRIVATE, NoticeTab.PM_ANNOUNCE, NoticeTab.POST, NoticeTab.PCOMMENT,
      NoticeTab.ACTIVITY, NoticeTab.REWARD, NoticeTab.GOODS, NoticeTab.AT,
      NoticeTab.POKE, NoticeTab.FRIEND, NoticeTab.WALL, NoticeTab.COMMENT,
      NoticeTab.CLICK, NoticeTab.SHARE, NoticeTab.SYSTEM, NoticeTab.APP
    ];
  }
}

export function getNoticeGroupTabs(group: NoticeGroup): Array<NoticeTab> {
  return NoticeTab.values().filter(tab => tab.group === group);
}

export const PREFETCH_TABS: Array<NoticeTab> = [
  NoticeTab.POST, NoticeTab.PCOMMENT, NoticeTab.ACTIVITY, NoticeTab.REWARD,
  NoticeTab.GOODS, NoticeTab.AT, NoticeTab.PM_PRIVATE, NoticeTab.PM_ANNOUNCE
];

export const BACKGROUND_TABS: Array<NoticeTab> = PREFETCH_TABS;

export class PmPage {
  loggedOut: boolean = false;
  messages: Array<PrivateMessage> = [];
}

export class PrivateMessage {
  plid: string | null = null;
  touid: string | null = null;
  username: string = "";
  avatarUrl: string | null = null;
  summary: string = "";
  timeText: string | null = null;
  unread: boolean = false;
}

export class ChatMessage {
  id: string = "";
  text: string = "";
  time: string | null = null;
  isSelf: boolean = false;
  avatarUrl: string | null = null;
  contentHtml: string | null = null;
  sending: boolean = false;
}

export class ChatConversation {
  touid: string = "";
  targetName: string | null = null;
  messages: Array<ChatMessage> = [];
  formhash: string | null = null;
  targetOnline: boolean | null = null;
}

export class FollowUserItem {
  uid: string = "";
  username: string = "";
  avatarUrl: string | null = null;
  fansCount: string | null = null;
  followCount: string | null = null;
  isFollowing: boolean = false;
  remark: string | null = null;
}

export class FollowUserPage {
  users: Array<FollowUserItem> = [];
  page: number = 1;
  hasNext: boolean = false;
}

export class FriendUserItem {
  uid: string = "";
  username: string = "";
  avatarUrl: string | null = null;
  description: string | null = null;
}

export class FriendUserPage {
  users: Array<FriendUserItem> = [];
  page: number = 1;
  hasNext: boolean = false;
}

export class FavoriteItem {
  favid: string = "";
  id: string = "";
  title: string = "";
  description: string | null = null;
  dateText: string | null = null;
  type: string = "thread";
}

export class FavoritePage {
  items: Array<FavoriteItem> = [];
  page: number = 1;
  hasNext: boolean = false;
}

export class MyThreadPage {
  threads: Array<Thread> = [];
  page: number = 1;
  hasNext: boolean = false;
}

export class ThreadType {
  id: string = "";
  name: string = "";
}





export class EditAttachment {
  aid: string = "";
  url: string = "";
  fileName: string = "";
}

export class EditPostPageData {
  formhash: string = "";
  subject: string | null = null;
  message: string = "";
  attachments: Array<EditAttachment> = [];
  uploadUid: string | null = null;
  uploadHash: string | null = null;
  types: Array<ThreadType> = [];
  permissionDenied: string | null = null;
}

export class EditPostResult {
  success: boolean = false;
  message: string | null = null;
}

export class PostDraft {
  fid: string = "";
  forumName: string = "";
  subject: string = "";
  message: string = "";
  typeId: string | null = null;
  savedAt: number = 0;
}

export class HistoryItem {
  tid: string = "";
  title: string = "";
  author: string = "";
  avatarUrl: string | null = null;
  forumName: string | null = null;
  viewedAt: number = 0;
  type: string = "thread";
}








// === 发帖相关模型 (最终去重版) ===
export class ImageUpload {
  aid: string = "";
  path: string = "";
}

export class NewThreadPageData {
  formhash: string = "";
  posttime: string | null = null;
  uploadUid: string | null = null;
  uploadHash: string | null = null;
}

export class NewThreadResult {
  success: boolean = false;
  tid: string | null = null;
  message: string | null = null;
}

export class RichTextNode {
  type: string = ""; // "text" | "image"
  content: string = "";
}
