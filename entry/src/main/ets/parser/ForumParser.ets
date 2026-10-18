import { ForumGroup, Forum, Thread, HomeData, ForumPage } from '../models/Models';

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

  // 4. 解析帖子列表页 (临时占位，马上重写)
  static parseForumPage(html: string, page: number): ForumPage {
    const fp = new ForumPage();
    fp.page = page;
    return fp;
  }
}
