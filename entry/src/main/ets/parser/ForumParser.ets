import { ForumGroup, Forum, Thread, HomeData, ForumPage, ThreadPage, Post, PostQuote } from '../models/Models';

// 提取 ID 的正则
const RE_FID = /forum-(\d+)-/;
const RE_TID = /thread-(\d+)-/;
const RE_CDATA = /<!\[CDATA\[([\s\S]*?)\]\]>/;

export class ForumParser {
  
  // 1. 解析版块列表
  static parseForumList(html: string): Array<ForumGroup> {
    const groups: Array<ForumGroup> = [];
    const todayByFid: Map<string, number> = new Map();

    // 粗略提取所有 sub_forum 的块来统计今日贴数
    const blockRegex = /<div class="comiis_forumlist"[\s\S]*?(?=<div class="comiis_forumlist"|$)/g;
    const blocks = html.match(blockRegex) || [];

    // 先提取今日帖子数
    for (const block of blocks) {
      const subForumRegex = /<div id="sub_forum_\d+">([\s\S]*?)<\/div>/g;
      let subMatch: RegExpExecArray | null;
      while ((subMatch = subForumRegex.exec(block)) !== null) {
        const content = subMatch[1];
        const liRegex = /<li>\s*<a href="([^"]+)"[^>]*>([\s\S]*?)<\/a>\s*<\/li>/g;
        let liMatch: RegExpExecArray | null;
        while ((liMatch = liRegex.exec(content)) !== null) {
          const href = liMatch[1];
          const inner = liMatch[2];
          const fidMatch = RE_FID.exec(href);
          const fid = fidMatch ? fidMatch[1] : null;
          if (!fid) continue;

          // 匹配 <em><span>123</span></em>
          const emMatch = /<em><span>(\d+)<\/span><\/em>/.exec(inner);
          if (emMatch) {
            const n = parseInt(emMatch[1]);
            if (n > 0) todayByFid.set(fid, n);
          }
        }
      }
    }

    // 再提取版块信息
    for (const block of blocks) {
      // 获取版块分组名称
      let groupName = "";
      const h2Regex = /<div class="comiis_bbs_show">\s*<h2[^>]*>\s*(?:<a[^>]*>)?([^<]+)(?:<\/a>)?\s*<\/h2>/;
      const h2Match = h2Regex.exec(block);
      if (h2Match) {
        groupName = h2Match[1].trim();
      } else {
        continue; // 找不到分类名就跳过
      }

      const forums: Array<Forum> = [];
      const subForumRegex = /<div id="sub_forum_\d+">([\s\S]*?)<\/div>/g;
      let subMatch: RegExpExecArray | null;
      
      while ((subMatch = subForumRegex.exec(block)) !== null) {
        const content = subMatch[1];
        const liRegex = /<li>\s*<a href="([^"]+)"[^>]*>([\s\S]*?)<\/a>\s*<\/li>/g;
        let liMatch: RegExpExecArray | null;
        
        while ((liMatch = liRegex.exec(content)) !== null) {
          const href = liMatch[1];
          const inner = liMatch[2];
          const fidMatch = RE_FID.exec(href);
          const fid = fidMatch ? fidMatch[1] : null;
          if (!fid) continue;

          // 获取版块名 (优先从 img 的 alt 属性，其次从 p 标签，最后取纯文本)
          let forumName = "";
          const altMatch = /<img[^>]*alt="([^"]+)"/.exec(inner);
          const pMatch = /<p>([^<]+)<\/p>/.exec(inner);
          
          if (altMatch && altMatch[1].trim()) {
            forumName = altMatch[1].trim();
          } else if (pMatch && pMatch[1].trim()) {
            forumName = pMatch[1].trim();
          } else {
            // 去掉所有 HTML 标签
            forumName = inner.replace(/<[^>]+>/g, '').trim();
          }

          if (!forumName) continue;

          // 获取图标
          let icon: string | null = null;
          const iconMatch = /<em><img[^>]*src="([^"]+)"/.exec(inner);
          if (iconMatch) icon = iconMatch[1];

          const forum = new Forum();
          forum.fid = fid;
          forum.name = forumName;
          forum.icon = icon;
          forum.todayPosts = todayByFid.get(fid) || 0;
          forums.push(forum);
        }
      }
      
      if (forums.length > 0) {
        const group = new ForumGroup();
        group.name = groupName;
        group.forums = forums;
        groups.push(group);
      }
    }

    return groups;
  }

  // 2. 解析首页
  static parseHome(html: string): HomeData {
    const home = new HomeData();

    // 热门版块
    const hotForums: Array<Forum> = [];
    const hotBkRegex = /<div class="comiis_mh_hotbk">([\s\S]*?)<\/ul>/;
    const hotBkMatch = hotBkRegex.exec(html);
    if (hotBkMatch) {
      const content = hotBkMatch[1];
      const liRegex = /<li>\s*<a href="([^"]+)"[^>]*>([\s\S]*?)<\/a>\s*<\/li>/g;
      let liMatch: RegExpExecArray | null;
      while ((liMatch = liRegex.exec(content)) !== null) {
        const href = liMatch[1];
        const inner = liMatch[2];
        const fidMatch = RE_FID.exec(href);
        if (!fidMatch) continue;
        
        const fid = fidMatch[1];
        const pMatch = /<p>([^<]+)<\/p>/.exec(inner);
        const name = pMatch ? pMatch[1].trim() : "";
        if (!name) continue;

        let icon: string | null = null;
        const iconMatch = /<img[^>]*src="([^"]+)"/.exec(inner);
        if (iconMatch) icon = iconMatch[1];

        const forum = new Forum();
        forum.fid = fid;
        forum.name = name;
        forum.icon = icon;
        hotForums.push(forum);
      }
    }

    // 热帖
    const hotThreads: Array<Thread> = [];
    const seenTids: Set<string> = new Set();
    
    // 找包含线程的 div
    let targetHtml = html;
    const txtListRegex = /<div class="[^"]*comiis_mh_txtlist[^"]*">([\s\S]*?)<\/div>/g;
    const txtBlocks: string[] = [];
    let blockMatch: RegExpExecArray | null;
    while ((blockMatch = txtListRegex.exec(html)) !== null) {
      txtBlocks.push(blockMatch[1]);
    }
    
    if (txtBlocks.length > 0) {
      targetHtml = txtBlocks.join('');
    }

    const threadRegex = /<a href="([^"]*thread-[^"]+)"[^>]*>([^<]+)<\/a>/g;
    let tMatch: RegExpExecArray | null;
    
    while ((tMatch = threadRegex.exec(targetHtml)) !== null) {
      const href = tMatch[1];
      let subject = tMatch[2].trim();
      
      const tidMatch = RE_TID.exec(href);
      if (!tidMatch) continue;
      const tid = tidMatch[1];

      if (subject.length < 4) continue;
      
      // 移除开头的数字 (Kotlin 里的 replace(Regex("^\\d+\\s*"), ""))
      subject = subject.replace(/^\d+\s*/, '');

      if (!seenTids.has(tid)) {
        seenTids.add(tid);
        const thread = new Thread();
        thread.tid = tid;
        thread.subject = subject;
        hotThreads.push(thread);
      }
      
      if (hotThreads.length >= 15) break;
    }

    home.hotForums = hotForums;
    home.hotThreads = hotThreads;
    return home;
  }

  // 3. 解析门户流
  static parsePortalFeed(xml: string): Array<Thread> {
    const cdataMatch = RE_CDATA.exec(xml);
    if (!cdataMatch) return [];
    const html = cdataMatch[1];
    // 因为 parseForumPage 还没实现，暂时返回空，下一步搞定它
    return this.parseForumPage(html, 1).threads;
  }
  // ==========================================
  // 高级解析方法 (对应 Kotlin 的辅助函数)
  // ==========================================
  private static stripInvisibleChars(text: string): string {
    // 移除零宽字符、控制字符并 Trim
    return text.replace(/[\u200B-\u200D\uFEFF]/g, '').trim();
  }

  private static readCardStats(li: string): [string | null, string | null, string | null] {
    let reply: string | null = null;
    let view: string | null = null;
    let like: string | null = null;

    // 尝试找 class包含 znalist_bottom 的 div
    const bottomMatch = /<div[^>]*class="[^"]*znalist_bottom[^"]*"[^>]*>([\s\S]*?)<\/div>/i.exec(li);
    if (!bottomMatch) return [null, null, null];
    
    const box = bottomMatch[1];
    
    // 尝试找 span class="comiis_tm"
    const spans: string[] = [];
    const spanRegex = /<span[^>]*class="[^"]*comiis_tm[^"]*"[^>]*>([\s\S]*?)<\/span>/gi;
    let m: RegExpExecArray | null;
    while ((m = spanRegex.exec(box)) !== null) {
      spans.push(m[1].trim());
    }
    
    if (spans.length > 0) {
      // 第一个通常是回复数，最后一个是浏览量，中间的是点赞 (或者根据实际业务逻辑反推)
      reply = spans.length > 0 ? spans[0] : null;
      view = spans.length > 1 ? spans[spans.length - 1] : null;
      like = spans.length > 2 ? spans[1] : null;
      return [reply, view, like];
    }
    
    // 如果没有 comiis_tm，找 li 包含的文字
    const extractStat = (label: string): string | null => {
      const reg = new RegExp(`<li[^>]*>[^<]*${label}[^<]*<\/li>`, 'gi');
      const match = reg.exec(box);
      if (match) {
        const numMatch = /(\d+)/.exec(match[0]);
        return numMatch ? numMatch[1] : null;
      }
      return null;
    };
    
    return [extractStat("评论"), extractStat("阅读"), extractStat("赞")];
  }

  private static isCardImage(url: string): boolean {
    const lower = url.toLowerCase();
    // 排除头像、表情、非图片后缀等
    if (lower.includes("avatar") || lower.includes("smiley") || lower.includes("static/image")) return false;
    if (lower.endsWith(".gif") && lower.includes("smiley")) return false;
    return /(jpg|jpeg|png|webp|gif)/i.test(lower);
  }

  private static collectThreadImages(li: string): Array<string> {
    const urls: Set<string> = new Set();
    const MAX_CARD_IMAGES = 3;

    const imgRegex = /<img[^>]*>/gi;
    let match: RegExpExecArray | null;
    
    while ((match = imgRegex.exec(li)) !== null) {
      if (urls.size >= MAX_CARD_IMAGES) break;
      const imgTag = match[0];
      
      // 提取属性
      const attrRegex = /(comiis_loadimages|data-original|data-src|file|src)="([^"]+)"/gi;
      let attrMatch: RegExpExecArray | null;
      let url = "";
      while ((attrMatch = attrRegex.exec(imgTag)) !== null) {
        if (attrMatch[2] && attrMatch[2].trim() !== '') {
          url = attrMatch[2].trim();
          break; 
        }
      }
      
      if (url && this.isCardImage(url)) {
        urls.add(url);
      }
    }
    return Array.from(urls);
  }

  private static hasNextPage(html: string): boolean {
    return html.includes("下一页") || html.includes("class=\"nxt\"");
  }

  // ==========================================
  // 4. 解析帖子列表页
  // ==========================================
  static parseForumPage(html: string, page: number): ForumPage {
    const fp = new ForumPage();
    fp.page = page;
    fp.hasNext = this.hasNextPage(html);

    // 1. 提取版块名
    const headerMatch = /<div[^>]*class="[^"]*comiis_view_header1[^"]*"[^>]*>[\s\S]*?<h1[^>]*>([\s\S]*?)<\/h1>/i.exec(html);
    fp.forumName = headerMatch ? this.stripInvisibleChars(headerMatch[1]) : null;

    // 2. 提取公告 (不含 forumlist_li)
    const announcements: Array<Thread> = [];
    const seenAnn: Set<string> = new Set();
    const b_t_Regex = /<li[^>]*class="[^"]*b_t[^"]*"[^>]*>([\s\S]*?)<\/li>/gi;
    let aMatch: RegExpExecArray | null;
    while ((aMatch = b_t_Regex.exec(html)) !== null) {
      const liContent = aMatch[0]; // 用全标签防止匹配出错
      if (liContent.includes("forumlist_li")) continue;
      
      const aTagMatch = /<a[^>]*href="[^"]*thread-([^"]+)"[^>]*>([\s\S]*?)<\/a>/i.exec(aMatch[1]);
      if (aTagMatch) {
        const tid = aTagMatch[1].replace(/\D/g, '');
        let subject = this.stripInvisibleChars(aTagMatch[2]).replace(/^置顶/, '').trim();
        if (!seenAnn.has(tid)) {
          seenAnn.add(tid);
          const t = new Thread();
          t.tid = tid;
          t.subject = subject;
          t.isAnnouncement = true;
          announcements.push(t);
        }
      }
    }
    fp.announcements = announcements;

    // 3. 提取普通帖子
    const threads: Array<Thread> = [];
    const seenTid: Set<string> = new Set();
    const liRegex = /<li[^>]*class="[^"]*forumlist_li[^"]*"[^>]*>([\s\S]*?)<\/li>/gi;
    let liMatch: RegExpExecArray | null;

    while ((liMatch = liRegex.exec(html)) !== null) {
      const liContent = liMatch[1];
      
      // 提取标题链接
      let titleHref = "";
      let subject = "";
      let isTitleA = false;
      
      const titleAMatch = /<div[^>]*class="[^"]*mmlist_li_box[^"]*"[^>]*>[\s\S]*?<h2[^>]*>[\s\S]*?<a[^>]*href="([^"]*thread-[^"]+)"[^>]*>([\s\S]*?)<\/a>/i.exec(liContent);
      if (titleAMatch) {
        titleHref = titleAMatch[1];
        subject = titleAMatch[2];
        isTitleA = true;
      } else {
        const threadAMatch = /<div[^>]*class="[^"]*list_body[^"]*"[^>]*>[\s\S]*?<a[^>]*href="([^"]*thread-[^"]+)"[^>]*>([\s\S]*?)<\/a>/i.exec(liContent);
        if (threadAMatch) {
          titleHref = threadAMatch[1];
          subject = threadAMatch[2];
        }
      }
      
      if (!titleHref) continue;

      const tidMatch = /thread-(\d+)/.exec(titleHref);
      if (!tidMatch) continue;
      const tid = tidMatch[1];
      
      if (seenTid.has(tid)) continue;
      seenTid.add(tid);

      // 作者
      const authorAMatch = /<a[^>]*class="[^"]*top_user[^"]*"[^>]*href="([^"]*)"[^>]*>([\s\S]*?)<\/a>/i.exec(liContent);
      let authorName: string | null = null;
      let authorUid: string | null = null;
      if (authorAMatch) {
        authorName = this.stripInvisibleChars(authorAMatch[2]);
        const uidMatch = /uid=(\d+)/.exec(authorAMatch[1]);
        if (uidMatch) authorUid = uidMatch[1];
      }

      // 头像、等级、时间
      const avatarMatch = /<img[^>]*class="[^"]*top_tximg[^"]*"[^>]*src="([^"]+)"/i.exec(liContent);
      const levelMatch = /<span[^>]*class="[^"]*top_lev[^"]*"[^>]*>([\s\S]*?)<\/span>/i.exec(liContent);
      const timeMatch = /<div[^>]*class="[^"]*forumlist_li_time[^"]*"[^>]*>[\s\S]*?<span[^>]*>([\s\S]*?)<\/span>/i.exec(liContent);

      // 摘要
      let excerpt: string | null = null;
      if (isTitleA) {
        const exMatch = /<div[^>]*class="[^"]*list_body[^"]*"[^>]*>[\s\S]*?<a[^>]*>([\s\S]*?)<\/a>/i.exec(liContent);
        if (exMatch) excerpt = this.stripInvisibleChars(exMatch[1]);
      }

      // 版块名
      let forumName: string | null = null;
      const fNameMatch = /<div[^>]*class="[^"]*comiis_xznalist_bk[^"]*"[^>]*>[\s\S]*?<a[^>]*href="[^"]*forum-[^"]*"[^>]*>([\s\S]*?)<\/a>/i.exec(liContent);
      if (fNameMatch) {
        forumName = this.stripInvisibleChars(fNameMatch[1]);
      } else {
        const fNameTimeMatch = /<div[^>]*class="[^"]*forumlist_li_time[^"]*"[^>]*>[\s\S]*?<a[^>]*href="[^"]*forum-[^"]*"[^>]*>([\s\S]*?)<\/a>/i.exec(liContent);
        if (fNameTimeMatch) {
          const text = this.stripInvisibleChars(fNameTimeMatch[1]);
          const parts = text.split("来自");
          if (parts.length > 1 && parts[1].trim() !== '') {
             forumName = parts[1].trim();
          }
        }
      }

      // 统计和图片
      const [replyCount, viewCount, likeCount] = this.readCardStats(liContent);
      const imageUrls = this.collectThreadImages(liContent);

      const thread = new Thread();
      thread.tid = tid;
      thread.subject = this.stripInvisibleChars(subject);
      thread.authorName = authorName;
      thread.authorUid = authorUid;
      thread.avatarUrl = avatarMatch ? avatarMatch[1] : null;
      thread.level = levelMatch ? this.stripInvisibleChars(levelMatch[1]) : null;
      thread.timeText = timeMatch ? this.stripInvisibleChars(timeMatch[1]) : null;
      thread.replyCount = replyCount;
      thread.viewCount = viewCount;
      thread.excerpt = excerpt;
      thread.forumName = forumName;
      thread.imageUrls = imageUrls;
      thread.likeCount = likeCount;
      
      threads.push(thread);
    }

    fp.threads = threads;
    return fp;
  }

  // ==========================================
  // 5. 解析帖子详情页
  // ==========================================
  static parseThreadPage(html: string, page: number): ThreadPage {
    const tp = new ThreadPage();
    tp.page = page;

    // 提取标题 (通常包含在 <title> 中)
    const titleMatch = /<title>([\s\S]*?)<\/title>/i.exec(html);
    if (titleMatch) {
      tp.subject = this.stripInvisibleChars(titleMatch[1]).replace("- MT论坛", "").trim();
    }

    // 提取版块名
    const forumMatch = /<a[^>]*class="[^"]*kmtit[^"]*"[^>]*>([\s\S]*?)<\/a>/i.exec(html);
    if (forumMatch) {
      tp.forumName = this.stripInvisibleChars(forumMatch[1]);
    }

    // 提取回复数 (位于 div.comiis_pltit h2 span)
    const replyMatch = /<div[^>]*class="[^"]*comiis_pltit[^"]*"[^>]*>[\s\S]*?<h2[^>]*>[\s\S]*?<span[^>]*>([\s\S]*?)<\/span>/i.exec(html);
    if (replyMatch) {
      tp.totalReplies = parseInt(this.stripInvisibleChars(replyMatch[1])) || 0;
    }

    // 提取点赞数
    const likeMatch = /<em[^>]*class="[^"]*comiis_recommend_num[^"]*"[^>]*>([\s\S]*?)<\/em>/i.exec(html);
    if (likeMatch) {
      const numMatch = /(\d+)/.exec(likeMatch[1]);
      tp.likeCount = numMatch ? parseInt(numMatch[1]) : 0;
    }

    // 提取收藏数
    const favMatch = /<span[^>]*class="[^"]*comiis_favorite_a_num[^"]*"[^>]*>([\s\S]*?)<\/span>/i.exec(html);
    if (favMatch) {
      const numMatch = /(\d+)/.exec(favMatch[1]);
      tp.favoriteCount = numMatch ? parseInt(numMatch[1]) : 0;
    }

    // 提取 formhash
    const fhMatch = /name="formhash" value="([^"]+)"/i.exec(html);
    if (fhMatch) tp.formhash = fhMatch[1];

    // 提取帖子列表
    const posts: Array<Post> = [];
    const postBlockRegex = /<div[^>]*id="pid(\d+)"[^>]*class="[^"]*comiis_postli[^"]*"[^>]*>([\s\S]*?)<div[^>]*class="[^"]*comiis_postli_bottom[^"]*"/gi;
    let pMatch: RegExpExecArray | null;
    
    while ((pMatch = postBlockRegex.exec(html)) !== null) {
      const pid = pMatch[1];
      const content = pMatch[2];
      const post = new Post();
      post.pid = pid;

      // 是否楼主
      if (content.includes("楼主") || content.includes("顶楼")) {
        post.isOp = true;
      }

      // 作者信息
      const authorMatch = /<a[^>]*class="[^"]*top_user[^"]*"[^>]*href="[^"]*uid=(\d+)[^"]*"[^>]*>([\s\S]*?)<\/a>/i.exec(content);
      if (authorMatch) {
        post.authorUid = authorMatch[1];
        post.authorName = this.stripInvisibleChars(authorMatch[2]);
      }

      // 时间
      const timeMatch = /<span[^>]*class="[^"]*kmtime[^"]*"[^>]*>([\s\S]*?)<\/span>/i.exec(content);
      if (timeMatch) {
        post.timeText = this.stripInvisibleChars(timeMatch[1]);
      }

      // 楼层号
      const floorMatch = /<span[^>]*class="[^"]*f_d[^"]*y[^"]*"[^>]*>([\s\S]*?)<\/span>/i.exec(content);
      if (floorMatch) {
        post.floorLabel = this.stripInvisibleChars(floorMatch[1]);
        const fNum = /(\d+)/.exec(post.floorLabel);
        if (fNum) post.floor = parseInt(fNum[1]);
      }

      // 正文 HTML (去除所有 img 标签或者替换为文本，这里简单粗暴提取整个 div)
      // 注：由于鸿蒙没有 RichText 原生支持，我们暂存 HTML，UI 层做简单剥离显示
      const htmlMatch = /<div[^>]*class="[^"]*comiis_a[^"]*"[^>]*>([\s\S]*?)<\/div>/i.exec(content);
      if (htmlMatch) {
        // 去除引用块
        let rawHtml = htmlMatch[1];
        rawHtml = rawHtml.replace(/<div[^>]*class="[^"]*(?:comiis_quote|quote)[^"]*"[^>]*>[\s\S]*?<\/div>/gi, '');
        
        // 将 <br> 和 <p> 替换为换行符，方便纯文本显示
        rawHtml = rawHtml.replace(/<br\s*\/?>/gi, '\n');
        rawHtml = rawHtml.replace(/<\/p>/gi, '\n');
        // 剥离所有其他标签
        rawHtml = rawHtml.replace(/<[^>]+>/g, '');
        post.contentHtml = this.stripInvisibleChars(rawHtml);
      }

      posts.push(post);
    }
    
    tp.posts = posts;
    return tp;
  }
}

