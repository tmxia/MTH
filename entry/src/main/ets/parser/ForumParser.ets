import { 
  ForumGroup, Forum, Thread, ForumPage, ThreadPage, Post, PostQuote 
} from '../models/Models';

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

  // 辅助：从文本提取数字
  static numberFromText(text: string): number | null {
    let match = text.match(/(\d+)/);
    return match ? parseInt(match[1]) : null;
  }

  // 解析板块列表 (之前已实现，保持不变)
  static parseForumList(html: string): ForumGroup[] { return []; }

  // 解析帖子列表 (之前已实现，保持不变)
  static parseForumPage(html: string, page: number): ForumPage {
    return new ForumPage();
  }

  // ------------------ 核心：解析帖子详情页 ------------------

  static parseRichText(html: string): Array<RichTextNode> { return []; }

  static parseThreadPage(html: string, page: number): ThreadPage {
    let threadPage = new ThreadPage();
    threadPage.page = page;
    threadPage.posts = [];

    // 1. 提取标题与 TID
    let titleMatch = ForumParser.extractFirstMatch(html, /<title>(.*?)<\/title>/i);
    threadPage.subject = titleMatch ? titleMatch.replace('- MT论坛', '').trim() : "";
    
    let tidMatch = ForumParser.extractFirstMatch(html, /thread-(\d+)/);
    threadPage.tid = tidMatch || "";

    // 2. 提取 formhash
    threadPage.formhash = ForumParser.extractFirstMatch(html, /formhash["']?\s+value=["']([0-9a-fA-F]+)/i);

    // 3. 提取作者 ID、总回复、点赞、收藏
    threadPage.opUid = ForumParser.extractFirstMatch(html, /authorid\s*=\s*['"](\d+)['"]/i);
    
    let totalRepliesMatch = ForumParser.extractFirstMatch(html, /<div class="comiis_pltit">[\s\S]*?<h2>.*?<span>(\d+)<\/span>/i);
    threadPage.totalReplies = totalRepliesMatch ? parseInt(totalRepliesMatch) : null;

    let likeMatch = ForumParser.extractFirstMatch(html, /<em class="comiis_recommend_num">(.*?)<\/em>/i);
    threadPage.likeCount = likeMatch ? ForumParser.numberFromText(likeMatch) : null;

    let favMatch = ForumParser.extractFirstMatch(html, /<span class="comiis_favorite_a_num">(\d+)<\/span>/i);
    threadPage.favoriteCount = favMatch ? parseInt(favMatch) : null;

    // 4. 提取回复表单 Action
    threadPage.replyUrl = ForumParser.extractFirstMatch(html, /<form[^>]*id="fastpostform"[^>]*action="([^"]+)"/i);

    // 5. 状态检测
    let actionState = ForumParser.parseActionState(html);
    threadPage.isLiked = actionState.liked;
    threadPage.likedStateKnown = actionState.likedKnown;
    threadPage.isFavorited = actionState.favorited;
    threadPage.favoritedStateKnown = actionState.favoritedKnown;

    let followState = ForumParser.parseFollowState(html);
    threadPage.isFollowingOp = followState[0];
    threadPage.followingStateKnown = followState[1];

    // 6. 解析每一层楼
    // 使用 split 切割出所有的 div.comiis_postli
    const parts = html.split('<div class="comiis_postli"');
    for (let i = 1; i < parts.length; i++) {
      let liHtml = parts[i];
      // 只取到当前 div 结束，简化处理，截取到下一个楼层前
      let nextDivIndex = liHtml.indexOf('<div class="comiis_postli"');
      if (nextDivIndex !== -1) {
        liHtml = liHtml.substring(0, nextDivIndex);
      }

      let post = ForumParser.parsePost(liHtml, threadPage.opUid);
      if (post) {
        threadPage.posts.push(post);
      }
    }

    return threadPage;
  }

  static parsePost(liHtml: string, opUid: string | null): Post | null {
    let post = new Post();
    
    // 提取 pid
    let pidMatch = ForumParser.extractFirstMatch(liHtml, /id="pid(\d+)"/i);
    if (!pidMatch) return null;
    post.pid = pidMatch;

    // 提取作者信息
    let authorMatch = ForumParser.extractFirstMatch(liHtml, /<a[^>]*class="[^"]*xw1[^"]*"[^>]*>(.*?)<\/a>/i) || ForumParser.extractFirstMatch(liHtml, /<div class="comiis_postli_topv1">[\s\S]*?<a[^>]*>(.*?)<\/a>/i);
    post.authorName = authorMatch ? ForumParser.stripHtmlTags(authorMatch) : "匿名";

    let uidMatch = ForumParser.extractFirstMatch(liHtml, /href="[^"]*uid=(\d+)[^"]*"/i);
    post.authorUid = uidMatch;

    let avatarMatch = ForumParser.extractFirstMatch(liHtml, /<img[^>]*src="([^"]+)"[^>]*class="[^"]*avatar[^"]*"/i) || ForumParser.extractFirstMatch(liHtml, /<div class="avatar">[\s\S]*?<img[^>]*src="([^"]+)"/i);
    post.avatarUrl = avatarMatch;

    // 提取时间
    let timeMatch = ForumParser.extractFirstMatch(liHtml, /<span[^>]*title="([^"]+)"[^>]*>.*?发表于/i);
    post.timeText = timeMatch;

    // 提取楼层文本
    let floorTextMatch = ForumParser.extractFirstMatch(liHtml, /<span class="f_d y">(.*?)<\/span>/i);
    if (floorTextMatch) {
      post.floorLabel = ForumParser.stripHtmlTags(floorTextMatch);
      let numMatch = post.floorLabel.match(/^(\d+)/);
      post.floor = numMatch ? parseInt(numMatch[1]) : null;
    }

    // 判断楼主
    if (opUid && post.authorUid === opUid) {
      post.isOp = true;
    }

    // 提取正文内容
    let contentMatch = ForumParser.extractFirstMatch(liHtml, /<td[^>]*class="[^"]*t_f[^"]*"[^>]*>([\s\S]*?)<\/td>/i) || ForumParser.extractFirstMatch(liHtml, /<div class="comiis_postmessage">([\s\S]*?)<\/div>/i);
    if (contentMatch) {
      post.contentHtml = contentMatch.trim();
      // 检查是否包含隐藏内容提示
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
    // 检查推荐/点赞状态
    let recommendMatch = ForumParser.extractFirstMatch(html, /<a[^>]*class="([^"]*comiis_recommend[^"]*)"[^>]*>/i);
    if (recommendMatch) {
      res.likedKnown = true;
      res.liked = recommendMatch.includes('f_a');
    }
    // 检查收藏状态
    let favMatch = ForumParser.extractFirstMatch(html, /<i[^>]*class="([^"]*comiis_favorite_a_color[^"]*)"[^>]*>/i);
    if (favMatch) {
      res.favoritedKnown = true;
      res.favorited = favMatch.includes('f_a');
    }
    return res;
  }

  static parseFollowState(html: string): [boolean, boolean] {
    let linkMatch = ForumParser.extractFirstMatch(html, /<a[^>]*href="([^"]*ac=follow[^"]*)"[^>]*>(.*?)<\/a>/i);
    if (!linkMatch) return [false, false];
    // 因为 extractFirstMatch 只抓取第一个括号，这里重新处理一下
    let match = html.match(/<a[^>]*href="([^"]*ac=follow[^"]*)"[^>]*>(.*?)<\/a>/i);
    if (match) {
      let href = match[1];
      let text = ForumParser.stripHtmlTags(match[2]);
      if (href.includes('op=del') || text.includes('取消关注')) return [true, true];
      if (href.includes('op=add')) return [false, true];
      if (text.includes('已关注')) return [true, true];
      return [false, true];
    }
    return [false, false];
  }
}
