import { HttpClient } from '../network/HttpClient';

// ==========================================
// 1. 枚举和常量
// ==========================================
export enum ForumSort {
  LATEST = "最新",
  HOT = "热门",
  DIGEST = "精华",
  POLL = "投票"
}

// 正则转换：使用原生 RegExp
const REPLY_ERROR_PATTERN = new RegExp("抱歉|非 法操作|请先登录|需要先登录|没有权限|审核");
const LOGIN_DIAG_HINTS = [
  "密码错误", "密码不正确", "密码为空", "用户名不存在", "账号不存在", "该用户不存在",
  "需要验证码", "请填写验证码", "验证码错误", "请输入验证码", "seccode",
  "失败次数", "次数过多", "请稍后再试", "请稍后重试", "锁定", "安全提问", "answer"
];
const LIKE_ERROR_PATTERN = new RegExp("没有点赞权限|不能点赞|今日评价机会已用完|关 闭的主题|请先登录|formhash错误|非法操作|不能收藏|submit_invalid|errorhandle_");
const REPORT_ERROR_PATTERN = new RegExp("举报理由|action=login|请先登录");
const DELETE_FORM_ACTION = new RegExp("action=edit");
const DELETE_FORM_SUBMIT = new RegExp("editsubmit");
const REWARD_SUCCESS_PATTERN = new RegExp("succeedhandle_rate|rate_success|评分成功|打赏成功|评价成功|您已成功评分");
const REWARD_FAIL_PATTERN = new RegExp("24小时|24 小时|已经评分|已评价|已评分|重复评分|评分失败|积分不足|余额不足|formhash错误|非法操作|没有权限|请先登录");
const TOPICADMIN_SUCCESS = new RegExp("管理操作 成功");

const SMILEY_URL = HttpClient['baseUrl'] + "data/cache/common_smilies_var.js";
const SMILEY_REVALIDATE_INTERVAL_MS = 12 * 60 * 60 * 1000;
const RE_ATTACHIMG_AID = new RegExp("\\[attachimg\\](\\d+)\\[/attachimg\\]", "gi");
const RE_EDIT_QUOTE_TAG = new RegExp("\\[/?(?:quote|size)\\b[^\\]]*]", "gi");
const GUIDE_VIEW_PORTAL = "hot";
const ATTACHMENT_CDN = "https://cdn.binmt.cc/";

// ==========================================
// 2. 工具函数
// ==========================================
export function rawSnippet(body: string, key: string, radius: number = 250): string | null {
  const i = body.indexOf(key);
  if (i < 0) return null;
  const start = Math.max(i - radius, 0);
  const end = Math.min(i + radius, body.length);
  return body.substring(start, end);
}

export function protectQuoteTagsOnEdit(message: string): string {
  return message.replace(RE_EDIT_QUOTE_TAG, (match: string) => {
    return match.toUpperCase();
  });
}

// ==========================================
// 3. 业务仓库类
// ==========================================
export class ForumRepository {
  private http: HttpClient;
  
  // 预留的扩展属性
  public blockedUidsProvider: () => Set<string> = () => new Set<string>();

  constructor(http: HttpClient) {
    this.http = http;
  }

  private currentBlocked(): Set<string> {
    return this.blockedUidsProvider();
  }

  // 提取帖子内容中的图片附件 AID
  private attachAids(message: string): Array<string> {
    const aids: Set<string> = new Set<string>();
    let match: RegExpExecArray | null;
    
    // 重置正则的 lastIndex，防止多次调用出错
    RE_ATTACHIMG_AID.lastIndex = 0;
    
    while ((match = RE_ATTACHIMG_AID.exec(message)) !== null) {
      if (match[1]) {
        aids.add(match[1]);
      }
    }
    return Array.from(aids);
  }
}

// 导出单例供全局使用（依赖注入留空）
export const forumRepository = new ForumRepository(HttpClient as unknown as HttpClient);
