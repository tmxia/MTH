// 对应安卓端的数据模型
export interface User {
  uid: string;
  username: string;
  avatarUrl: string;
}

export interface Thread {
  tid: string;
  title: string;
  author: User;
  replyCount: number;
  viewCount: number;
  postTime: string;
  lastReplyTime: string;
}

export interface NoticeGroup {
  title: string;
  count: number;
  id: string;
}
