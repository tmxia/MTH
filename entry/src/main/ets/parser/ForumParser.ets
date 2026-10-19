import { Thread, ThreadPage, Post, RichTextNode, ActionState, ForumGroup, ForumPage } from '../models/Models';

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

}
