import { Thread, ThreadPage, Post, RichTextNode, ActionState, ForumGroup, ForumPage , FollowUserItem, FollowUserPage, NewThreadPageData, ThreadType, PmPage, PrivateMessage, ChatConversation, ChatMessage} from '../models/Models';

import { AtUser } from '../models/Models';
export class ForumParser {
  static stripHtmlTags(html: string): string {
    if (!html) return "";
    let text = html.replace(/<[^>]+>/g, '');
    return text.replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').trim();
  }

  static extractFirstMatch(html: string, regex: RegExp): string | null {
    let match = html.match(regex);
    return match ? match[1] : null;
  }

  static numberFromText(text: string): number | null {
    let match = text.match(/(\d+)/);
    return match ? parseInt(match[1]) : null;
  }

  static parseForumList(html: string): Array<ForumGroup> { return []; }
  static parseForumPage(html: string, page: number): ForumPage { return new ForumPage(); }

  static parseThreadPage(html: string, page: number): ThreadPage {
    let tp = new ThreadPage();
    tp.page = page;
    tp.posts = [];

    let titleMatch = ForumParser.extractFirstMatch(html, /<title>(.*?)<\/title>/i);
    if (titleMatch) {
      tp.subject = titleMatch.replace('- MT论坛', '').trim();
    }

    let tidMatch = ForumParser.extractFirstMatch(html, /thread-(\d+)/);
    if (tidMatch) {
      tp.tid = tidMatch;
    }

    tp.formhash = ForumParser.extractFirstMatch(html, /formhash["']?\s+value=["']([0-9a-fA-F]+)/i);
    tp.opUid = ForumParser.extractFirstMatch(html, /authorid\s*=\s*['"](\d+)['"]/i);

    let parts = html.split('<div class="comiis_postli"');
    for (let i = 1; i < parts.length; i++) {
      let liHtml = parts[i];
      let nextDivIndex = liHtml.indexOf('<div class="comiis_postli"');
      if (nextDivIndex !== -1) {
        liHtml = liHtml.substring(0, nextDivIndex);
      }

      let post = ForumParser.parsePost(liHtml, tp.opUid);
      if (post) {
        tp.posts.push(post);
      }
    }
    return tp;
  }

  static parsePost(liHtml: string, opUid: string | null): Post | null {
    let post = new Post();
    let pidMatch = ForumParser.extractFirstMatch(liHtml, /id="pid(\d+)"/i);
    if (!pidMatch) return null;
    post.pid = pidMatch;

    let authorMatch = ForumParser.extractFirstMatch(liHtml, /<a[^>]*class="[^"]*xw1[^"]*"[^>]*>(.*?)<\/a>/i) || ForumParser.extractFirstMatch(liHtml, /<div class="comiis_postli_topv1">[\s\S]*?<a[^>]*>(.*?)<\/a>/i);
    if (authorMatch) post.authorName = ForumParser.stripHtmlTags(authorMatch);

    post.authorUid = ForumParser.extractFirstMatch(liHtml, /href="[^"]*uid=(\d+)[^"]*"/i);
    post.avatarUrl = ForumParser.extractFirstMatch(liHtml, /<img[^>]*src="([^"]+)"[^>]*class="[^"]*avatar[^"]*"/i) || ForumParser.extractFirstMatch(liHtml, /<div class="avatar">[\s\S]*?<img[^>]*src="([^"]+)"/i);
    post.timeText = ForumParser.extractFirstMatch(liHtml, /<span[^>]*title="([^"]+)"[^>]*>.*?发表于/i);

    let floorTextMatch = ForumParser.extractFirstMatch(liHtml, /<span class="f_d y">(.*?)<\/span>/i);
    if (floorTextMatch) {
      post.floorLabel = ForumParser.stripHtmlTags(floorTextMatch);
      let numMatch = post.floorLabel.match(/^(\d+)/);
      if (numMatch) post.floor = parseInt(numMatch[1]);
    }

    if (opUid && post.authorUid === opUid) post.isOp = true;

    let contentMatch = ForumParser.extractFirstMatch(liHtml, /<td[^>]*class="[^"]*t_f[^"]*"[^>]*>([\s\S]*?)<\/td>/i) || ForumParser.extractFirstMatch(liHtml, /<div class="comiis_postmessage">([\s\S]*?)<\/div>/i);
    if (contentMatch) {
      post.contentHtml = contentMatch.trim();
      if (post.contentHtml.includes('回复可见') || post.contentHtml.includes('隐藏内容') || post.contentHtml.includes('查看本帖隐藏内容')) {
        post.hasHiddenContent = true;
      }
    } else {
      post.contentHtml = "<p>暂无内容</p>";
    }
    return post;
  }

  static parseRichText(html: string): Array<RichTextNode> {
    let nodes: Array<RichTextNode> = [];
    if (!html) return nodes;

    let text = html.replace(/<br\s*\/?>/gi, '\n')
                   .replace(/<\/(p|div|li|h[1-6])>/gi, '\n')
                   .replace(/<[^>]+>/g, '')
                   .replace(/&nbsp;/g, ' ')
                   .replace(/&amp;/g, '&')
                   .replace(/&lt;/g, '<')
                   .replace(/&gt;/g, '>')
                   .replace(/\n{3,}/g, '\n\n');

    let textTrim = text.trim();
    if (textTrim.length > 0) {
      let node = new RichTextNode();
      node.type = 'text';
      node.content = textTrim;
      nodes.push(node);
    }
    return nodes;
  }

  static parseActionState(html: string): ActionState {
    return new ActionState();
  }

  static parseFollowState(html: string): boolean[] {
    return [false, false];
  }

  // ===== @ 用户相关解析 =====

  // misc.php?mod=getatuser&inajax=1 返回 JS 数组，提取用户名
  static parseAtUsers(html: string): string[] {
    const names: string[] = [];
    if (!html) return names;
    // 格式：{'uid':'123','username':'xxx'} 或 {'uid':123,'name':'xxx'}
    const re1 = /['"]username['"]\s*:\s*['"]([^'"]+)['"]/g;
    let m;
    while ((m = re1.exec(html)) !== null) {
      if (m[1] && m[1].indexOf('\\') < 0) names.push(m[1]);
    }
    if (names.length === 0) {
      const re2 = /['"]name['"]\s*:\s*['"]([^'"]+)['"]/g;
      while ((m = re2.exec(html)) !== null) {
        if (m[1]) names.push(m[1]);
      }
    }
    // 去重
    const out: string[] = [];
    const seen = new Set<string>();
    for (const n of names) {
      if (!seen.has(n)) { seen.add(n); out.push(n); }
    }
    return out;
  }

  // home.php 好友/关注页 / search.php 用户搜索页，提取 AtUser 列表
  static parseAtUserList(html: string): AtUser[] {
    const list: AtUser[] = [];
    if (!html) return list;
    // 每个用户块：含 uid 链接 + 用户名 + 可选头像
    // 常见形态：<a href="...space&uid=123...">...<img src="avatar">...<strong>name</strong>
    const blockRe = /space(?:&amp;|&)uid=(\d+)[\s\S]{0,800}?<\/(?:li|dl|div)>/g;
    let m;
    while ((m = blockRe.exec(html)) !== null) {
      const block = m[0];
      const uid = m[1];
      // 从块内提取用户名
      let name = '';
      const nameRe = /<strong[^>]*>([^<]+)<\/strong>/;
      const nm = nameRe.exec(block);
      if (nm) { name = nm[1].trim(); }
      if (!name) {
        // 退化：找 alt 属性
        const altRe = /alt=["']([^"']+)["']/;
        const am = altRe.exec(block);
        if (am) name = am[1].trim();
      }
      if (!name) continue;
      // 头像
      let avatar = '';
      const avRe = /<img[^>]+src=["']([^"']+)["']/;
      const avm = avRe.exec(block);
      if (avm) avatar = avm[1];
      // 副标题：版块/等级/状态
      let subtitle = '';
      const subRe = /<span[^>]*class=["'][^"']*(?:xg1|note)[^"']*["'][^>]*>([^<]+)<\/span>/;
      const sm = subRe.exec(block);
      if (sm) subtitle = sm[1].trim();
      const u = new AtUser();
      u.uid = uid;
      u.name = name;
      u.avatarUrl = avatar || '';
      u.subtitle = subtitle || '';
      list.push(u);
    }
    return list;
  }


  // 解析 home.php?mod=follow&do=following|follower 页面
  static parseFollowUsers(html: string, page: number, defaultIsFollowing: boolean): FollowUserPage {
    const out = new FollowUserPage();
    out.users = [];
    out.page = page;
    out.hasNext = false;
    if (!html) return out;

    // 每项块：含 uid 链接
    const blockRe = /space(?:&amp;|&)uid=(\d+)[\s\S]{0,1200}?<\/(?:li|dl|div)>/g;
    let m: RegExpExecArray | null = blockRe.exec(html);
    while (m !== null) {
      const block = m[0];
      const uid = m[1];
      const item = new FollowUserItem();
      item.uid = uid;
      item.isFollowing = defaultIsFollowing;

      const nameRe = /<strong[^>]*>([^<]+)<\/strong>/;
      const nm = nameRe.exec(block);
      if (nm) item.username = nm[1].trim();

      const avRe = /<img[^>]+src=["']([^"']+)["']/;
      const av = avRe.exec(block);
      if (av) {
        let u = av[1];
        if (u.indexOf('//') === 0) u = 'https:' + u;
        item.avatarUrl = u;
      }

      // 粉丝/关注数（"xx 粉丝" / "xx 关注"）
      const fansRe = /(\d+)\s*粉丝/;
      const fm = fansRe.exec(block);
      if (fm) item.fansCount = fm[1];
      const folRe = /(\d+)\s*关注/;
      const flm = folRe.exec(block);
      if (flm) item.followCount = flm[1];

      // 是否有"已关注"文字
      if (block.indexOf('已关注') >= 0 || block.indexOf('取消关注') >= 0) {
        item.isFollowing = true;
      } else if (block.indexOf('关注') >= 0 && block.indexOf('关注 Ta') >= 0) {
        item.isFollowing = false;
      }

      out.users.push(item);
      m = blockRe.exec(html);
    }

    // 是否有下一页
    out.hasNext = html.indexOf('下一页') >= 0 || html.indexOf('next') >= 0;
    return out;
  }


  // ===== 发帖 / PM / 聊天 =====

  static parseNewThreadPageData(html: string): NewThreadPageData {
    const out = new NewThreadPageData();
    if (!html) return out;

    const fhRe = /name="formhash"\s+value="([a-zA-Z0-9]+)"/;
    const fhM = fhRe.exec(html);
    if (fhM) out.formhash = fhM[1];

    const ptRe = /name="posttime"\s+value="([^"]+)"/;
    const ptM = ptRe.exec(html);
    if (ptM) out.posttime = ptM[1];

    const uidRe = /uploadUid\s*[:=]\s*['"]?(\d+)/;
    const uidM = uidRe.exec(html);
    if (uidM) out.uploadUid = uidM[1];

    const hashRe = /uploadHash\s*[:=]\s*['"]([a-zA-Z0-9]+)['"]/;
    const hashM = hashRe.exec(html);
    if (hashM) out.uploadHash = hashM[1];

    const selectRe = /<select[^>]+name="typeid"[^>]*>([\s\S]*?)<\/select>/;
    const selM = selectRe.exec(html);
    if (selM) {
      const optRe = /<option\s+value="(\d+)"[^>]*>([^<]+)<\/option>/g;
      let om: RegExpExecArray | null = optRe.exec(selM[1]);
      while (om !== null) {
        if (om[1] !== '0') {
          const t = new ThreadType();
          t.id = om[1];
          t.name = om[2].trim();
          out.types.push(t);
        }
        om = optRe.exec(selM[1]);
      }
    }

    if (html.indexOf('没有权限') >= 0 || html.indexOf('权限不足') >= 0 || html.indexOf('无法发帖') >= 0) {
      out.permissionDenied = '没有发帖权限';
    }

    return out;
  }

  static parsePmPage(html: string): PmPage {
    const out = new PmPage();
    if (!html) return out;

    if (html.indexOf('请先登录') >= 0) {
      out.loggedOut = true;
      return out;
    }

    const blockRe = /space(?:&amp;|&)uid=(\d+)[\s\S]{0,1500}?<\/li>/g;
    let m: RegExpExecArray | null = blockRe.exec(html);
    while (m !== null) {
      const block = m[0];
      const pm = new PrivateMessage();
      pm.touid = m[1];

      const nameRe = /<strong[^>]*>([^<]+)<\/strong>/;
      const nm = nameRe.exec(block);
      if (nm) pm.username = nm[1].trim();

      const avRe = /<img[^>]+src=["']([^"']+)["']/;
      const av = avRe.exec(block);
      if (av) {
        let u = av[1];
        if (u.indexOf('//') === 0) u = 'https:' + u;
        pm.avatarUrl = u;
      }

      const timeRe = /<span[^>]*class="[^"]*xg1[^"]*"[^>]*>([^<]+)<\/span>/;
      const tm = timeRe.exec(block);
      if (tm) pm.timeText = tm[1].trim();

      const summaryRe = /<p[^>]*>([^<]+)<\/p>/;
      const sm = summaryRe.exec(block);
      if (sm) pm.summary = sm[1].trim();

      if (block.indexOf('未读') >= 0) pm.unread = true;

      out.messages.push(pm);
      m = blockRe.exec(html);
    }

    return out;
  }

  static parseChatConversation(html: string, touid: string): ChatConversation {
    const out = new ChatConversation();
    out.touid = touid;
    if (!html) return out;

    const fhRe = /name="formhash"\s+value="([a-zA-Z0-9]+)"/;
    const fhM = fhRe.exec(html);
    if (fhM) out.formhash = fhM[1];

    const nameRe = /<title>([^<]+)<\/title>/;
    const nm = nameRe.exec(html);
    if (nm) {
      let title = nm[1].trim();
      title = title.replace(/ - [^ ]+$/, '');
      out.targetName = title;
    }

    const msgRe = /<div[^>]*class="[^"]*message[^"]*"[^>]*>([\s\S]{0,2000}?)<\/div>/g;
    let mm: RegExpExecArray | null = msgRe.exec(html);
    let idx = 0;
    while (mm !== null) {
      const block = mm[0];
      const cm = new ChatMessage();
      cm.id = 'm' + idx;
      idx++;

      const txtRe = /<p[^>]*>([\s\S]*?)<\/p>/;
      const tm = txtRe.exec(block);
      if (tm) {
        cm.text = tm[1].replace(/<[^>]+>/g, '').trim();
      }

      const timeRe = /<span[^>]*class="[^"]*time[^"]*"[^>]*>([^<]+)<\/span>/;
      const tt = timeRe.exec(block);
      if (tt) cm.time = tt[1].trim();

      if (block.indexOf('class="self') >= 0) cm.isSelf = true;

      if (cm.text) out.messages.push(cm);
      mm = msgRe.exec(html);
    }

    return out;
  }

}
