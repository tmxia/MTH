export class ForumGroup {
  name: string = "";
  forums: Array<Forum> = [];
}
export class Forum {
  fid: string = "";
  name: string = "";
  icon?: string | null = null;
  todayPosts: number = 0;
}
export class Thread {
  tid: string = "";
  subject: string = "";
  authorName?: string | null = null;
  authorUid?: string | null = null;
  avatarUrl?: string | null = null;
  level?: string | null = null;
  timeText?: string | null = null;
  replyCount?: string | null = null;
  viewCount?: string | null = null;
  excerpt?: string | null = null;
  isAnnouncement: boolean = false;
  forumName?: string | null = null;
  imageUrls: Array<string> = [];
  likeCount?: string | null = null;
  isSticky: boolean = false;
}
export class ForumPage {
  forumName?: string | null = null;
  announcements: Array<Thread> = [];
  threads: Array<Thread> = [];
  page: number = 0;
  hasNext: boolean = false;
}
export class ThreadPage {
  tid: string = "";
  subject?: string | null = null;
  forumName?: string | null = null;
  posts: Array<Post> = [];
  page: number = 0;
  totalPages: number = 0;
  formhash?: string | null = null;
  replyUrl?: string | null = null;
  noticeAuthor?: string | null = null;
  fid?: string | null = null;
  opUid?: string | null = null;
  totalReplies?: number | null = null;
  likeCount?: number | null = null;
  favoriteCount?: number | null = null;
  isLiked: boolean = false;
  likedStateKnown: boolean = false;
  isFavorited: boolean = false;
  favoritedStateKnown: boolean = false;
  isFollowingOp: boolean = false;
  followingStateKnown: boolean = false;
  uploadUid?: string | null = null;
  uploadHash?: string | null = null;
}
export class Post {
  pid: string = "";
  authorName: string = "";
  authorUid?: string | null = null;
  avatarUrl?: string | null = null;
  level?: string | null = null;
  timeText?: string | null = null;
  location?: string | null = null;
  contentHtml: string = "";
  isOp: boolean = false;
  isFirstPost: boolean = false;
  floor?: number | null = null;
  floorLabel?: string | null = null;
  quote?: PostQuote | null = null;
  editedText?: string | null = null;
  hasHiddenContent: boolean = false;
  sticky: boolean = false;
  imageUrls: Array<string> = [];
}
export class PostQuote {
  author?: string | null = null;
  time?: string | null = null;
  text: string = "";
  pid?: string | null = null;
}
export class RichTextNode {
  type: string = "text";
  content: string = "";
  src?: string;
  href?: string;
}
export class HomeData {
  hotForums: Array<Forum> = [];
  hotThreads: Array<Thread> = [];
}
export class UserProfile {
  uid?: string | null = null;
  name?: string | null = null;
  avatarUrl?: string | null = null;
  level?: string | null = null;
  groupName?: string | null = null;
  threads?: number | null = null;
  posts?: number | null = null;
  friends?: number | null = null;
  following?: number | null = null;
  followers?: number | null = null;
  credits?: number | null = null;
  gold?: number | null = null;
  onlineTime?: string | null = null;
  isFollowing?: boolean | null = null;
  formhash?: string | null = null;
  get isLoggedIn(): boolean { return !!this.uid && this.uid !== "0"; }
}
export class SearchResult { threads: Array<Thread> = []; nextUrl?: string | null = null; get hasNext(): boolean { return this.nextUrl !== null && this.nextUrl !== undefined; } }
export class NoticePage { loggedOut: boolean = false; notices: Array<Notice> = []; totalPages: number = 1; }
export class Notice { id: string = ""; text: string = ""; timeText?: string | null = null; tid?: string | null = null; avatarUrl?: string | null = null; uid?: string | null = null; }
export class PmPage { loggedOut: boolean = false; messages: Array<PrivateMessage> = []; }
export class PrivateMessage { plid?: string | null = null; touid?: string | null = null; username: string = ""; avatarUrl?: string | null = null; summary: string = ""; timeText?: string | null = null; unread: boolean = false; }
export class ChatMessage { id: string = ""; text: string = ""; time?: string | null = null; isSelf: boolean = false; avatarUrl?: string | null = null; contentHtml?: string | null = null; sending: boolean = false; }
export class ChatConversation { touid: string = ""; targetName?: string | null = null; messages: Array<ChatMessage> = []; formhash?: string | null = null; targetOnline?: boolean | null = null; }
export class FavoritePage { items: Array<FavoriteItem> = []; page: number = 0; hasNext: boolean = false; }
export class FavoriteItem { favid: string = ""; id: string = ""; title: string = ""; description?: string | null = null; dateText?: string | null = null; type: string = "thread"; }
export class FriendUserPage { users: Array<FriendUserItem> = []; page: number = 0; hasNext: boolean = false; }
export class FriendUserItem { uid: string = ""; username: string = ""; avatarUrl?: string | null = null; description?: string | null = null; }
export class MyThreadPage { threads: Array<Thread> = []; page: number = 0; hasNext: boolean = false; }
export class NewThreadPageData { formhash: string = ""; posttime?: string | null = null; uploadUid?: string | null = null; uploadHash?: string | null = null; types: Array<ThreadType> = []; permissionDenied?: string | null = null; }
export class NewThreadResult { success: boolean = false; tid?: string | null = null; message?: string | null = null; }
export class ThreadType { id: string = ""; name: string = ""; }
export class EditPostPageData { formhash: string = ""; subject?: string | null = null; message: string = ""; attachments: Array<EditAttachment> = []; uploadUid?: string | null = null; uploadHash?: string | null = null; types: Array<ThreadType> = []; permissionDenied?: string | null = null; }
export class EditAttachment { aid: string = ""; url: string = ""; fileName: string = ""; }
export class EditPostResult { success: boolean = false; message?: string | null = null; }
export class CheckInStatus { hasSigned: boolean = false; formhash?: string | null = null; }
export class CheckInResult { success: boolean = false; message: string = ""; }
export class LoginResult { success: boolean = false; message?: string | null = null; needsCaptcha: boolean = false; captchaUrl?: string | null = null; }
export class ReplyResult { success: boolean = false; message?: string | null = null; }
export class LikeResult { success: boolean = false; remainingToday?: number | null = null; serverCount?: number | null = null; message?: string | null = null; }
export class ImageUpload { aid: string = ""; url: string = ""; fileName: string = ""; }
export class ActionState {
  liked: boolean = false;
  likedKnown: boolean = false;
  favorited: boolean = false;
  favoritedKnown: boolean = false;
}

// ===== 自动对齐:安卓有、鸿蒙无 =====

export class AtUser {
  uid?: string;
  name?: string;
  avatarUrl?: string;
  subtitle?: string;
}

export class DownloadedThread {
  tid?: string;
  subject?: string;
  forumName?: string;
  fileName?: string;
  uri?: string;
  savedAt?: number;
  replyCount?: number;
  sizeBytes?: number;
}

export class FollowUserItem {
  uid?: string;
  username?: string;
  avatarUrl?: string;
  fansCount?: string;
  followCount?: string;
  isFollowing?: boolean;
  remark?: string;
}

export class FollowUserPage {
  users?: Array<FollowUserItem>;
  page?: number;
  hasNext?: boolean;
}

export class FriendRequestItem {
  uid?: string;
  username?: string;
  avatarUrl?: string;
  description?: string;
}

export class FriendRequestPage {
  requests?: Array<FriendRequestItem>;
  page?: number;
  hasNext?: boolean;
  formhash?: string;
}

export class HistoryItem {
  tid?: string;
  title?: string;
  author?: string;
  avatarUrl?: string;
  forumName?: string;
  viewedAt?: number;
  type?: string;
}

export class LikeUser {
  uid?: string;
  name?: string;
  avatarUrl?: string;
}

export class PageProgress {
  authorId?: string;
  maxPage?: number;
  totalPages?: number;
}

export class PostDraft {
  fid?: string;
  forumName?: string;
  subject?: string;
  message?: string;
  typeId?: string;
  savedAt?: number;
}

export class ThreadSnapshot {
  subject?: string;
  forumName?: string;
  opUid?: string;
  fid?: string;
  totalReplies?: number;
  posts?: Array<Post>;
  progress?: Array<PageProgress>;

export class Smiley {
  code: string = "";
  url: string = "";
}

export class SmileyPack {
  id: string = "";
  name: string = "";
  folder: string = "";
  items: Array<Smiley> = [];
}

}
