import { ForumGroup, Forum, Thread, HomeData, ForumPage, ThreadPage, Post, LoginResult, UserProfile, CheckInStatus, CheckInResult, Notice, NoticePage, ReplyResult, SearchResult, MyThreadPage, FavoritePage, FavoriteItem, FriendUserPage, FriendUserItem } from '../models/Models';

const RE_FID = /forum-(\d+)-/;
const RE_TID = /thread-(\d+)-/;
const RE_CDATA = /<!\[CDATA\[([\s\S]*?)\]\]>/;

export class ForumParser {
  
  static stripInvisible(text: string): string {
    return text.replace(/[\u200B-\u200D\uFEFF]/g, '').trim();
  }

  private static readCardStats(li: string): [string | null, string | null, string | null] {
    let reply: string | null = null;
    let view: string | null = null;
    let like: string | null = null;

    const bottomMatch = /<div[^>]*class="[^"]*znalist_bottom[^"]*"[^>]*>([\s\S]*?)<\/div>/i.exec(li);
    if (!bottomMatch) return [null, null, null];
    
    const box = bottomMatch[1];
    const spans: string[] = [];
    const spanRegex = /<span[^>]*class="[^"]*comiis_tm[^"]*"[^>]*>([\s\S]*?)<\/span>/gi;
    let m: RegExpExecArray | null;
    while ((m = spanRegex.exec(box)) !== null) {
      spans.push(m[1].trim());
    }
    
    if (spans.length > 0) {
      reply = spans.length > 0 ? spans[0] : null;
      view = spans.length > 1 ? spans[spans.length - 1] : null;
      like = spans.length > 2 ? spans[1] : null;
      return [reply, view, like];
    }
    
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
      const attrRegex = /(comiis_loadimages|data-original|data-src|file|src)="([^"]+)"/gi;
      let attrMatch: RegExpExecArray | null;
      let url = "";
      while ((attrMatch = attrRegex.exec(imgTag)) !== null) {
        if (attrMatch[2] && attrMatch[2].trim() !== '') {
          url = attrMatch[2].trim();
          break; 
        }
      }
      if (url && ForumParser.isCardImage(url)) {
        urls.add(url);
      }
    }
    return Array.from(urls);
  }

  static parseForumList(html: string): Array<ForumGroup> {
    const groups: Array<ForumGroup> = [];
    const todayByFid: Map<string, number> = new Map();
    const blockRegex = /<div class="comiis_forumlist"[\s\S]*?(?=<div class="comiis_forumlist"|$)/g;
    const blocks = html.match(blockRegex) || [];

    for (const block of blocks) {
      const subForumRegex = /<div id="sub_forum_\d+">([\s\S]*?)<\/div>/g;
      let subMatch: RegExpExecArray | null;
      while ((subMatch = subForumRegex.exec(block)) !== null) {
        const content = subMatch[1];
        const liRegex = /<li>\s*<a href="([^"]+)"[^>]*>([\s\S]*?)<\/a>\s*<\/li>/g;
        let liMatch: RegExpExecArray | null;
        while ((liMatch = liRegex.exec(content)) !== null) {
          const fidMatch = RE_FID.exec(liMatch[1]);
          const fid = fidMatch ? fidMatch[1] : null;
          if (!fid) continue;
          const emMatch = /<em><span>(\d+)<\/span><\/em>/.exec(liMatch[2]);
          if (emMatch) {
            const n = parseInt(emMatch[1]);
            if (n > 0) todayByFid.set(fid, n);
          }
        }
      }
    }

    for (const block of blocks) {
      let groupName = "";
      const h2Regex = /<div class="comiis_bbs_show">\s*<h2[^>]*>\s*(?:<a[^>]*>)?([^<]+)(?:<\/a>)?\s*<\/h2>/;
      const h2Match = h2Regex.exec(block);
      if (h2Match) groupName = h2Match[1].trim(); else continue;

      const forums: Array<Forum> = [];
      const subForumRegex = /<div id="sub_forum_\d+">([\s\S]*?)<\/div>/g;
      let subMatch: RegExpExecArray | null;
      
      while ((subMatch = subForumRegex.exec(block)) !== null) {
        const content = subMatch[1];
        const liRegex = /<li>\s*<a href="([^"]+)"[^>]*>([\s\S]*?)<\/a>\s*<\/li>/g;
        let liMatch: RegExpExecArray | null;
        
        while ((liMatch = liRegex.exec(content)) !== null) {
          const fidMatch = RE_FID.exec(liMatch[1]);
          const fid = fidMatch ? fidMatch[1] : null;
          if (!fid) continue;
          const inner = liMatch[2];
          let forumName = "";
          const altMatch = /<img[^>]*alt="([^"]+)"/.exec(inner);
          const pMatch = /<p>([^<]+)<\/p>/.exec(inner);
          if (altMatch && altMatch[1].trim()) forumName = altMatch[1].trim();
          else if (pMatch && pMatch[1].trim()) forumName = pMatch[1].trim();
          else forumName = inner.replace(/<[^>]+>/g, '').trim();
          if (!forumName) continue;
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

  static parseHome(html: string): HomeData {
    const home = new HomeData();
    const hotForums: Array<Forum> = [];
    const hotBkMatch = /<div class="comiis_mh_hotbk">([\s\S]*?)<\/ul>/.exec(html);
    if (hotBkMatch) {
      const liRegex = /<li>\s*<a href="([^"]+)"[^>]*>([\s\S]*?)<\/a>\s*<\/li>/g;
      let liMatch: RegExpExecArray | null;
      while ((liMatch = liRegex.exec(hotBkMatch[1])) !== null) {
        const fidMatch = RE_FID.exec(liMatch[1]);
        if (!fidMatch) continue;
        const pMatch = /<p>([^<]+)<\/p>/.exec(liMatch[2]);
        const name = pMatch ? pMatch[1].trim() : "";
        if (!name) continue;
        const iconMatch = /<img[^>]*src="([^"]+)"/.exec(liMatch[2]);
        const forum = new Forum();
        forum.fid = fidMatch[1];
        forum.name = name;
        forum.icon = iconMatch ? iconMatch[1] : null;
        hotForums.push(forum);
      }
    }
    const hotThreads: Array<Thread> = [];
    const seenTids: Set<string> = new Set();
    let targetHtml = html;
    const txtListRegex = /<div class="[^"]*comiis_mh_txtlist[^"]*">([\s\S]*?)<\/div>/g;
    const txtBlocks: string[] = [];
    let blockMatch: RegExpExecArray | null;
    while ((blockMatch = txtListRegex.exec(html)) !== null) txtBlocks.push(blockMatch[1]);
    if (txtBlocks.length > 0) targetHtml = txtBlocks.join('');
    const threadRegex = /<a href="([^"]*thread-[^"]+)"[^>]*>([^<]+)<\/a>/g;
    let tMatch: RegExpExecArray | null;
    while ((tMatch = threadRegex.exec(targetHtml)) !== null) {
      const tidMatch = RE_TID.exec(tMatch[1]);
      if (!tidMatch) continue;
      const tid = tidMatch[1];
      let subject = ForumParser.stripInvisible(tMatch[2]).replace(/^\d+\s*/, '');
      if (subject.length < 4) continue;
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

  static parsePortalFeed(xml: string): Array<Thread> {
    const cdataMatch = RE_CDATA.exec(xml);
    if (!cdataMatch) return [];
    return ForumParser.parseForumPage(cdataMatch[1], 1).threads;
  }

  static parseForumPage(html: string, page: number): ForumPage {
    const fp = new ForumPage();
    fp.page = page;
    fp.hasNext = html.includes("下一页") || html.includes("class=\"nxt\"");
    
    const headerMatch = /<div[^>]*class="[^"]*comiis_view_header1[^"]*"[^>]*>[\s\S]*?<h1[^>]*>([\s\S]*?)<\/h1>/i.exec(html);
    fp.forumName = headerMatch ? ForumParser.stripInvisible(headerMatch[1]) : null;

    const announcements: Array<Thread> = [];
    const seenAnn: Set<string> = new Set();
    const b_t_Regex = /<li[^>]*class="[^"]*b_t[^"]*"[^>]*>([\s\S]*?)<\/li>/gi;
    let aMatch: RegExpExecArray | null;
    while ((aMatch = b_t_Regex.exec(html)) !== null) {
      if (aMatch[0].includes("forumlist_li")) continue;
      const aTagMatch = /<a[^>]*href="[^"]*thread-([^"]+)"[^>]*>([\s\S]*?)<\/a>/i.exec(aMatch[1]);
      if (aTagMatch) {
        const tid = aTagMatch[1].replace(/\D/g, '');
        let subject = ForumParser.stripInvisible(aTagMatch[2]).replace(/^置顶/, '').trim();
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

    const threads: Array<Thread> = [];
    const seenTid: Set<string> = new Set();
    const liRegex = /<li[^>]*class="[^"]*forumlist_li[^"]*"[^>]*>([\s\S]*?)<\/li>/gi;
    let liMatch: RegExpExecArray | null;

    while ((liMatch = liRegex.exec(html)) !== null) {
      const liContent = liMatch[1];
      let titleHref = "", subject = "", isTitleA = false;
      
      const titleAMatch = /<div[^>]*class="[^"]*mmlist_li_box[^"]*"[^>]*>[\s\S]*?<h2[^>]*>[\s\S]*?<a[^>]*href="([^"]*thread-[^"]+)"[^>]*>([\s\S]*?)<\/a>/i.exec(liContent);
      if (titleAMatch) { titleHref = titleAMatch[1]; subject = titleAMatch[2]; isTitleA = true; }
      else {
        const threadAMatch = /<div[^>]*class="[^"]*list_body[^"]*"[^>]*>[\s\S]*?<a[^>]*href="([^"]*thread-[^"]+)"[^>]*>([\s\S]*?)<\/a>/i.exec(liContent);
        if (threadAMatch) { titleHref = threadAMatch[1]; subject = threadAMatch[2]; }
      }
      if (!titleHref) continue;

      const tidMatch = /thread-(\d+)/.exec(titleHref);
      if (!tidMatch || seenTid.has(tidMatch[1])) continue;
      const tid = tidMatch[1];
      seenTid.add(tid);

      const authorAMatch = /<a[^>]*class="[^"]*top_user[^"]*"[^>]*href="([^"]*)"[^>]*>([\s\S]*?)<\/a>/i.exec(liContent);
      let authorName: string | null = null, authorUid: string | null = null;
      if (authorAMatch) {
        authorName = ForumParser.stripInvisible(authorAMatch[2]);
        const uidMatch = /uid=(\d+)/.exec(authorAMatch[1]);
        if (uidMatch) authorUid = uidMatch[1];
      }

      const avatarMatch = /<img[^>]*class="[^"]*top_tximg[^"]*"[^>]*src="([^"]+)"/i.exec(liContent);
      const levelMatch = /<span[^>]*class="[^"]*top_lev[^"]*"[^>]*>([\s\S]*?)<\/span>/i.exec(liContent);
      const timeMatch = /<div[^>]*class="[^"]*forumlist_li_time[^"]*"[^>]*>[\s\S]*?<span[^>]*>([\s\S]*?)<\/span>/i.exec(liContent);

      let excerpt: string | null = null;
      if (isTitleA) {
        const exMatch = /<div[^>]*class="[^"]*list_body[^"]*"[^>]*>[\s\S]*?<a[^>]*>([\s\S]*?)<\/a>/i.exec(liContent);
        if (exMatch) excerpt = ForumParser.stripInvisible(exMatch[1]);
      }

      let forumName: string | null = null;
      const fNameMatch = /<div[^>]*class="[^"]*comiis_xznalist_bk[^"]*"[^>]*>[\s\S]*?<a[^>]*href="[^"]*forum-[^"]*"[^>]*>([\s\S]*?)<\/a>/i.exec(liContent);
      if (fNameMatch) forumName = ForumParser.stripInvisible(fNameMatch[1]);

      const stats = ForumParser.readCardStats(liContent);
      const thread = new Thread();
      thread.tid = tid;
      thread.subject = ForumParser.stripInvisible(subject);
      thread.authorName = authorName;
      thread.authorUid = authorUid;
      thread.avatarUrl = avatarMatch ? avatarMatch[1] : null;
      thread.level = levelMatch ? ForumParser.stripInvisible(levelMatch[1]) : null;
      thread.timeText = timeMatch ? ForumParser.stripInvisible(timeMatch[1]) : null;
      thread.replyCount = stats[0];
      thread.viewCount = stats[1];
      thread.likeCount = stats[2];
      thread.excerpt = excerpt;
      thread.forumName = forumName;
      thread.imageUrls = ForumParser.collectThreadImages(liContent);
      threads.push(thread);
    }
    fp.threads = threads;
    return fp;
  }

  static parseThreadPage(html: string, page: number): ThreadPage {
    const tp = new ThreadPage();
    tp.page = page;

    const titleMatch = /<title>([\s\S]*?)<\/title>/i.exec(html);
    if (titleMatch) tp.subject = ForumParser.stripInvisible(titleMatch[1]).replace("- MT论坛", "").trim();

    const forumMatch = /<a[^>]*class="[^"]*kmtit[^"]*"[^>]*>([\s\S]*?)<\/a>/i.exec(html);
    if (forumMatch) tp.forumName = ForumParser.stripInvisible(forumMatch[1]);

    const replyMatch = /<div[^>]*class="[^"]*comiis_pltit[^"]*"[^>]*>[\s\S]*?<h2[^>]*>[\s\S]*?<span[^>]*>([\s\S]*?)<\/span>/i.exec(html);
    if (replyMatch) tp.totalReplies = parseInt(ForumParser.stripInvisible(replyMatch[1])) || 0;

    const likeMatch = /<em[^>]*class="[^"]*comiis_recommend_num[^"]*"[^>]*>([\s\S]*?)<\/em>/i.exec(html);
    if (likeMatch) {
      const numMatch = /(\d+)/.exec(likeMatch[1]);
      tp.likeCount = numMatch ? parseInt(numMatch[1]) : 0;
    }

    const favMatch = /<span[^>]*class="[^"]*comiis_favorite_a_num[^"]*"[^>]*>([\s\S]*?)<\/span>/i.exec(html);
    if (favMatch) {
      const numMatch = /(\d+)/.exec(favMatch[1]);
      tp.favoriteCount = numMatch ? parseInt(numMatch[1]) : 0;
    }

    const fhMatch = /name="formhash" value="([^"]+)"/i.exec(html);
    if (fhMatch) tp.formhash = fhMatch[1];

    const fidMatch = /fid=(\d+)/.exec(html);
    if (fidMatch) tp.fid = fidMatch[1];

    const posts: Array<Post> = [];
    const postBlockRegex = /<div[^>]*id="pid(\d+)"[^>]*class="[^"]*comiis_postli[^"]*"[^>]*>([\s\S]*?)<div[^>]*class="[^"]*comiis_postli_bottom[^"]*"/gi;
    let pMatch: RegExpExecArray | null;
    
    while ((pMatch = postBlockRegex.exec(html)) !== null) {
      const content = pMatch[2];
      const post = new Post();
      post.pid = pMatch[1];
      post.isOp = content.includes("楼主") || content.includes("顶楼");

      const authorMatch = /<a[^>]*class="[^"]*top_user[^"]*"[^>]*href="[^"]*uid=(\d+)[^"]*"[^>]*>([\s\S]*?)<\/a>/i.exec(content);
      if (authorMatch) {
        post.authorUid = authorMatch[1];
        post.authorName = ForumParser.stripInvisible(authorMatch[2]);
      }

      const timeMatch = /<span[^>]*class="[^"]*kmtime[^"]*"[^>]*>([\s\S]*?)<\/span>/i.exec(content);
      if (timeMatch) post.timeText = ForumParser.stripInvisible(timeMatch[1]);

      const floorMatch = /<span[^>]*class="[^"]*f_d[^"]*y[^"]*"[^>]*>([\s\S]*?)<\/span>/i.exec(content);
      if (floorMatch) {
        post.floorLabel = ForumParser.stripInvisible(floorMatch[1]);
        const fNum = /(\d+)/.exec(post.floorLabel);
        if (fNum) post.floor = parseInt(fNum[1]);
      }

      const htmlMatch = /<div[^>]*class="[^"]*comiis_a[^"]*"[^>]*>([\s\S]*?)<\/div>/i.exec(content);
      if (htmlMatch) {
        let rawHtml = htmlMatch[1];
        rawHtml = rawHtml.replace(/<div[^>]*class="[^"]*(?:comiis_quote|quote)[^"]*"[^>]*>[\s\S]*?<\/div>/gi, '');
        post.imageUrls = ForumParser.extractImagesFromHtml(rawHtml);
        rawHtml = rawHtml.replace(/<br\s*\/?>/gi, '\n').replace(/<\/p>/gi, '\n').replace(/<[^>]+>/g, '');
        post.contentHtml = ForumParser.stripInvisible(rawHtml);
      }
      posts.push(post);
    }
    tp.posts = posts;
    return tp;
  }

  static extractLoginHash(html: string): string | null {
    const match = /loginhash=([a-zA-Z0-9]+)/.exec(html);
    return match ? match[1] : null;
  }

  static extractLoginFormhash(html: string): string | null {
    const match = /name="formhash" value="([^"]+)"/.exec(html);
    return match ? match[1] : null;
  }

  static parseLoginResult(html: string): LoginResult {
    const result = new LoginResult();
    if (html.includes("欢迎您回来") || html.includes("现在将转入登录前页面") || html.includes("successhandle")) {
      result.success = true;
      result.message = "登录成功";
      return result;
    }
    if (html.includes("需要验证码") || html.includes("seccode")) {
      result.success = false;
      result.needsCaptcha = true;
      result.message = "需要验证码";
      return result;
    }
    let errMsg = "登录失败";
    const dtMatch = /id=["']messagetext["'][^>]*>([\s\S]*?)<\/dt>/i.exec(html);
    if (dtMatch) {
      errMsg = ForumParser.stripInvisible(dtMatch[1].replace(/<[^>]+>/g, ''));
    } else {
      const pMatch = /<p>([\s\S]*?)(?:<script|<\/p>)/i.exec(html);
      if (pMatch && !pMatch[1].includes("<img") && pMatch[1].trim().length > 0) {
        errMsg = ForumParser.stripInvisible(pMatch[1].replace(/<[^>]+>/g, ''));
      }
    }
    result.success = false;
    result.message = errMsg;
    return result;
  }

  static parseUserProfile(html: string, fallbackUid: string | null = null): UserProfile {
    const profile = new UserProfile();
    let uid = fallbackUid;
    if (!uid || uid.trim() === '') {
      const uidMatch = /discuz_uid\s*=\s*'(\d+)'/.exec(html) || /uid=(\d+)/.exec(html);
      if (uidMatch) uid = uidMatch[1];
    }
    profile.uid = uid;
    if (!uid || uid === '0') return profile;

    const nameMatch = /<div[^>]*class="[^"]*comiis_space_tx[^"]*"[^>]*>[\s\S]*?<h2[^>]*>([\s\S]*?)<\/h2>/i.exec(html);
    if (nameMatch) {
      profile.name = ForumParser.stripInvisible(nameMatch[1].replace(/<[^>]+>/g, ''));
    } else {
      const sideNameMatch = /<a[^>]*class="[^"]*sidenv_user[^"]*"[^>]*>([\s\S]*?)<\/a>/i.exec(html);
      if (sideNameMatch) profile.name = ForumParser.stripInvisible(sideNameMatch[1]);
    }

    const levelMatch = /<span[^>]*class="[^"]*(?:kmlevs|user_lev)[^"]*"[^>]*>([\s\S]*?)<\/span>/i.exec(html);
    if (levelMatch) {
      profile.level = ForumParser.stripInvisible(levelMatch[1]);
      profile.groupName = profile.level;
    }

    const avatarMatch = /<div[^>]*class="[^"]*comiis_space_tx[^"]*"[^>]*>[\s\S]*?<img[^>]*src="([^"]+)"/i.exec(html);
    if (avatarMatch) {
      profile.avatarUrl = avatarMatch[1];
    } else {
      const sideAvatarMatch = /<img[^>]*class="[^"]*sidenv_tximg[^"]*"[^>]*src="([^"]+)"/i.exec(html);
      if (sideAvatarMatch) profile.avatarUrl = sideAvatarMatch[1];
    }

    const extractNumber = (label: string): number => {
      const reg = new RegExp(`<li[^>]*>[^<]*${label}[^<]*<[^>]*>\s*(\\d+)`, 'i');
      const match = reg.exec(html);
      return match ? parseInt(match[1]) : 0;
    };

    profile.posts = extractNumber("帖子");
    profile.threads = extractNumber("主题");
    profile.credits = extractNumber("积分");
    profile.gold = extractNumber("金币");
    profile.friends = extractNumber("好友");
    profile.followers = extractNumber("粉丝");
    return profile;
  }

  static parseCheckInStatus(html: string): CheckInStatus {
    const status = new CheckInStatus();
    const fhMatch = /name="formhash" value="([^"]+)"/i.exec(html);
    if (fhMatch) status.formhash = fhMatch[1];
    if (html.includes("已签到") || html.includes("今日已签到") || html.includes("已经签到")) {
      status.hasSigned = true;
    } else {
      status.hasSigned = false;
    }
    return status;
  }

  static parseCheckInResponse(response: string): CheckInResult {
    const result = new CheckInResult();
    if (response.includes("签到成功") || response.includes("恭喜") || response.includes("已签到")) {
      result.success = true;
      result.message = "签到成功";
    } else {
      result.success = false;
      result.message = ForumParser.stripInvisible(response.replace(/<[^>]+>/g, '')).substring(0, 50);
    }
    return result;
  }

  static parseNoticePage(html: string): NoticePage {
    const page = new NoticePage();
    if (html.includes("您需要先登录") || html.includes("立即登录")) {
      page.loggedOut = true;
      return page;
    }
    const liRegex = /<li[^>]*>([\s\S]*?)<\/li>/gi;
    let match: RegExpExecArray | null;
    while ((match = liRegex.exec(html)) !== null) {
      const li = match[1];
      const textMatch = /<p[^>]*>([\s\S]*?)<\/p>/i.exec(li);
      const timeMatch = /<span[^>]*>([\s\S]*?)<\/span>/i.exec(li);
      if (textMatch) {
        const notice = new Notice();
        notice.id = Math.random().toString(36).substr(2, 9);
        notice.text = ForumParser.stripInvisible(textMatch[1].replace(/<[^>]+>/g, ''));
        notice.timeText = timeMatch ? ForumParser.stripInvisible(timeMatch[1]) : null;
        const tidMatch = /thread-(\d+)/.exec(li);
        if (tidMatch) notice.tid = tidMatch[1];
        if (notice.text.length > 0) page.notices.push(notice);
      }
    }
    return page;
  }

  static parseReplyResponse(html: string): ReplyResult {
    const result = new ReplyResult();
    if (html.includes("回复成功") || html.includes("感谢您的回复") || html.includes("succeedhandle")) {
      result.success = true;
      result.message = "回复成功";
    } else {
      result.success = false;
      const errMatch = /id=["']messagetext["'][^>]*>([\s\S]*?)<\/dt>/i.exec(html);
      if (errMatch) {
        result.message = ForumParser.stripInvisible(errMatch[1].replace(/<[^>]+>/g, ''));
      } else {
        result.message = "回复失败，可能包含敏感词或被限制";
      }
    }
    return result;
  }

  static parseSearchResult(html: string): SearchResult {
    const result = new SearchResult();
    const threads = ForumParser.parseForumPage(html, 1).threads;
    result.threads = threads;
    return result;
  }

  static parseMyThreads(html: string, page: number): MyThreadPage {
    const pageData = new MyThreadPage();
    const fp = ForumParser.parseForumPage(html, page);
    pageData.threads = fp.threads;
    pageData.page = page;
    pageData.hasNext = fp.hasNext;
    return pageData;
  }

  static parseFavorites(html: string, page: number): FavoritePage {
    const fp = new FavoritePage();
    fp.page = page;
    fp.hasNext = html.includes("下一页");
    const liRegex = /<li[^>]*>([\s\S]*?)<\/li>/gi;
    let match: RegExpExecArray | null;
    while ((match = liRegex.exec(html)) !== null) {
      const content = match[1];
      const tidMatch = /thread-(\d+)/.exec(content);
      if (tidMatch) {
        const item = new FavoriteItem();
        item.id = tidMatch[1];
        item.favid = tidMatch[1];
        const titleMatch = /<a[^>]*>([\s\S]*?)<\/a>/i.exec(content);
        if (titleMatch) {
          item.title = ForumParser.stripInvisible(titleMatch[1].replace(/<[^>]+>/g, ''));
          if (item.title.length > 0) fp.items.push(item);
        }
      }
    }
    return fp;
  }

  static parseFriends(html: string, page: number): FriendUserPage {
    const fp = new FriendUserPage();
    fp.page = page;
    fp.hasNext = html.includes("下一页");
    const liRegex = /<li[^>]*>([\s\S]*?)<\/li>/gi;
    let match: RegExpExecArray | null;
    while ((match = liRegex.exec(html)) !== null) {
      const content = match[1];
      const uidMatch = /uid=(\d+)/.exec(content);
      if (uidMatch) {
        const user = new FriendUserItem();
        user.uid = uidMatch[1];
        const nameMatch = /<h4[^>]*>([\s\S]*?)<\/h4>|<a[^>]*class="[^"]*kmname[^"]*"[^>]*>([\s\S]*?)<\/a>/i.exec(content);
        if (nameMatch) {
          user.username = ForumParser.stripInvisible((nameMatch[1] || nameMatch[2] || '').replace(/<[^>]+>/g, ''));
          if (user.username) fp.users.push(user);
        }
      }
    }
    return fp;
  }

  static extractImagesFromHtml(html: string): Array<string> {
    const images: Array<string> = [];
    const imgRegex = /<img[^>]*src="([^"]+)"/gi;
    let match: RegExpExecArray | null;
    while ((match = imgRegex.exec(html)) !== null) {
      const url = match[1];
      if (url.includes("smiley") || url.includes("static/image")) continue;
      if (!images.includes(url)) {
        images.push(url);
      }
    }
    return images;
  }
}
