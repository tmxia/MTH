import { ForumGroup, Forum, Thread, ForumPage, ThreadPage, Post, PostQuote, RichTextNode } from '../models/Models';

export class ActionState {
  liked: boolean = false;
  likedKnown: boolean = false;
  favorited: boolean = false;
  favoritedKnown: boolean = false;
}

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
    let match = text.match(/(\\d+)/);
    return match ? parseInt(match[1]) : null;
  }

  static parseForumList(html: string): ForumGroup[] { return []; }
  
  static parseForumPage(html: string, page: number): ForumPage {
    return new ForumPage();
  }

  static parseThreadPage(html: string, page: number): ThreadPage {
    let threadPage = new ThreadPage();
    threadPage.page = page;
    threadPage.posts = [];

    let titleMatch = this.extractFirstMatch(html, /<title>(.*?)<\\/title>/i);
    if (titleMatch) {
      threadPage.subject = titleMatch.replace('- MT论坛', '').trim();
    }
    
    let tidMatch = this.extractFirstMatch(html, /thread-(\\d+)/);
    if (tidMatch) {
      threadPage.tid = tidMatch;
    }

    threadPage.formhash = this.extractFirstMatch(html, /formhash["']?\\s+value=["']([0-9a-fA-F]+)/i);

    let authorIdMatch = this.extractFirstMatch(html, /authorid\\s*=\\s*['"](\\d+)['"]/i);
    if (authorIdMatch) {
      threadPage.opUid = authorIdMatch;
    }

    let totalRepliesMatch = this.extractFirstMatch(html, /<div class="comiis_pltit">[\\s\\S]*?<h2>.*?<span>(\\d+)<\\/span>/i);
    if (totalRepliesMatch) threadPage.totalReplies = parseInt(totalRepliesMatch);

    let likeMatch = this.extractFirstMatch(html, /<em class="comiis_recommend_num">(.*?)<\\/em>/i);
    if (likeMatch) threadPage.likeCount = this.numberFromText(likeMatch);

    let favMatch = this.extractFirstMatch(html, /<span class="comiis_favorite_a_num">(\\d+)<\\/span>/i);
    if (favMatch) threadPage.favoriteCount = parseInt(favMatch);

    threadPage.replyUrl = this.extractFirstMatch(html, /<form[^>]*id="fastpostform"[^>]*action="([^"]+)"/i);

    let action = this.parseActionState(html);
    threadPage.isLiked = action.liked;
    threadPage.likedStateKnown = action.likedKnown;
    threadPage.isFavorited = action.favorited;
    threadPage.favoritedStateKnown = action.favoritedKnown;

    let follow = this.parseFollowState(html);
    threadPage.isFollowingOp = follow[0];
    threadPage.followingStateKnown = follow[1];

    const parts = html.split('<div class="comiis_postli"');
    for (let i = 1; i < parts.length; i++) {
      let liHtml = parts[i];
      let nextDivIndex = liHtml.indexOf('<div class="comiis_postli"');
      if (nextDivIndex !== -1) {
        liHtml = liHtml.substring(0, nextDivIndex);
      }

      let post = this.parsePost(liHtml, threadPage.opUid);
      if (post) {
        threadPage.posts.push(post);
      }
    }

    return threadPage;
  }

  static parsePost(liHtml: string, opUid: string | null): Post | null {
    let post = new Post();
    
    let pidMatch = this.extractFirstMatch(liHtml, /id="pid(\\d+)"/i);
    if (!pidMatch) return null;
    post.pid = pidMatch;

    let authorMatch = this.extractFirstMatch(liHtml, /<a[^>]*class="[^"]*xw1[^"]*"[^>]*>(.*?)<\\/a>/i) || this.extractFirstMatch(liHtml, /<div class="comiis_postli_topv1">[\\s\\S]*?<a[^>]*>(.*?)<\\/a>/i);
    if (authorMatch) post.authorName = this.stripHtmlTags(authorMatch);

    let uidMatch = this.extractFirstMatch(liHtml, /href="[^"]*uid=(\\d+)[^"]*"/i);
    if (uidMatch) post.authorUid = uidMatch;

    let avatarMatch = this.extractFirstMatch(liHtml, /<img[^>]*src="([^"]+)"[^>]*class="[^"]*avatar[^"]*"/i) || this.extractFirstMatch(liHtml, /<div class="avatar">[\\s\\S]*?<img[^>]*src="([^"]+)"/i);
    if (avatarMatch) post.avatarUrl = avatarMatch;

    let timeMatch = this.extractFirstMatch(liHtml, /<span[^>]*title="([^"]+)"[^>]*>.*?发表于/i);
    if (timeMatch) post.timeText = timeMatch;

    let floorTextMatch = this.extractFirstMatch(liHtml, /<span class="f_d y">(.*?)<\\/span>/i);
    if (floorTextMatch) {
      post.floorLabel = this.stripHtmlTags(floorTextMatch);
      let numMatch = post.floorLabel.match(/^(\\d+)/);
      if (numMatch) {
        post.floor = parseInt(numMatch[1]);
      }
    }

    if (opUid && post.authorUid === opUid) {
      post.isOp = true;
    }

    let contentMatch = this.extractFirstMatch(liHtml, /<td[^>]*class="[^"]*t_f[^"]*"[^>]*>([\\s\\S]*?)<\\/td>/i) || this.extractFirstMatch(liHtml, /<div class="comiis_postmessage">([\\s\\S]*?)<\\/div>/i);
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

  static parseActionState(html: string): ActionState {
    let res = new ActionState();
    let recommendMatch = this.extractFirstMatch(html, /<a[^>]*class="([^"]*comiis_recommend[^"]*)"[^>]*>/i);
    if (recommendMatch) {
      res.likedKnown = true;
      res.liked = recommendMatch.includes('f_a');
    }
    let favMatch = this.extractFirstMatch(html, /<i[^>]*class="([^"]*comiis_favorite_a_color[^"]*)"[^>]*>/i);
    if (favMatch) {
      res.favoritedKnown = true;
      res.favorited = favMatch.includes('f_a');
    }
    return res;
  }

  static parseFollowState(html: string): [boolean, boolean] {
    let match = html.match(/<a[^>]*href="([^"]*ac=follow[^"]*)"[^>]*>(.*?)<\\/a>/i);
    if (match) {
      let href = match[1];
      let text = this.stripHtmlTags(match[2]);
      if (href.includes('op=del') || text.includes('取消关注')) return [true, true];
      if (href.includes('op=add')) return [false, true];
      if (text.includes('已关注')) return [true, true];
      return [false, true];
    }
    return [false, false];
  }

  static parseRichText(html: string): Array<RichTextNode> {
    let nodes: Array<RichTextNode> = [];
    if (!html) return nodes;
    let node = new RichTextNode();
    node.type = 'text';
    node.content = this.stripHtmlTags(html).replace(/<br\\s*\\/?>/gi, '\\n');
    nodes.push(node);
    return nodes;
  }
}
