import { Thread, ThreadPage, Post, RichTextNode, ActionState, ForumGroup, ForumPage } from '../models/Models';

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
}
