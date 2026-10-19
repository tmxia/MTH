import fs from '@ohos.file.fs';
import http from '@ohos.net.http';
import util from '@ohos.util';
import common from '@ohos.app.ability.common';
import { ThreadSnapshot } from '../models/Models';

export class ThreadArchiveStore {
  private filesDir: string = '';

  async init(context: common.UIAbilityContext): Promise<void> {
    this.filesDir = context.filesDir;
  }

  private archiveDir(tid: string): string {
    return this.filesDir + '/thread_archive/' + tid;
  }

  private snapshotPath(tid: string): string {
    return this.archiveDir(tid) + '/snapshot.json';
  }

  async exists(tid: string): Promise<boolean> {
    try {
      return await fs.access(this.snapshotPath(tid));
    } catch (e) {
      return false;
    }
  }

  async archive(tid: string, snapshot: ThreadSnapshot): Promise<void> {
    const dir = this.archiveDir(tid);
    try {
      await fs.mkdir(dir, true);
    } catch (e) {
      // 目录已存在
    }
    const json = JSON.stringify(snapshot);
    const file = await fs.open(this.snapshotPath(tid), fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
    try {
      await fs.write(file.fd, json);
    } finally {
      await fs.close(file);
    }
  }

  async read(tid: string): Promise<ThreadSnapshot | null> {
    try {
      const path = this.snapshotPath(tid);
      const ok = await fs.access(path);
      if (!ok) return null;
      const json = await fs.readText(path);
      return JSON.parse(json) as ThreadSnapshot;
    } catch (e) {
      return null;
    }
  }

  async delete(tid: string): Promise<void> {
    try {
      await fs.rmdir(this.archiveDir(tid));
    } catch (e) {
      // 忽略
    }
  }

  // ===== 图片本地化（base64 内嵌） =====

  async inlineImages(snapshot: ThreadSnapshot): Promise<ThreadSnapshot> {
    if (!snapshot || !snapshot.posts) return snapshot;
    const cache: Map<string, string> = new Map();
    for (let i = 0; i < snapshot.posts.length; i++) {
      const post = snapshot.posts[i];
      // 1) 头像
      if (post.avatarUrl && typeof post.avatarUrl === 'string' && post.avatarUrl.indexOf('http') === 0) {
        const av = await this.fetchAsDataUri(post.avatarUrl, cache);
        if (av) post.avatarUrl = av;
      }
      // 2) contentHtml 里的 img
      if (post.contentHtml) {
        const urls = this.extractImgUrls(post.contentHtml);
        for (let j = 0; j < urls.length; j++) {
          const u = urls[j];
          const dataUri = await this.fetchAsDataUri(u, cache);
          if (dataUri) {
            post.contentHtml = post.contentHtml.split('src="' + u + '"').join('src="' + dataUri + '"');
            post.contentHtml = post.contentHtml.split("src='" + u + "'").join("src='" + dataUri + "'");
          }
        }
      }
    }
    return snapshot;
  }

  private extractImgUrls(html: string): string[] {
    const urls: string[] = [];
    const re = /<img[^>]+src=["']([^"']+)["']/gi;
    let m: RegExpExecArray | null = re.exec(html);
    while (m !== null) {
      let u = m[1];
      if (u && u.indexOf('data:') !== 0) {
        if (u.indexOf('//') === 0) u = 'https:' + u;
        if (u.indexOf('http') === 0) urls.push(u);
      }
      m = re.exec(html);
    }
    return urls;
  }

  private async fetchAsDataUri(url: string, cache: Map<string, string>): Promise<string | null> {
    const cached = cache.get(url);
    if (cached) return cached;
    try {
      const req = http.createHttp();
      const opts: http.HttpRequestOptions = {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        readTimeout: 20000,
        connectTimeout: 20000
      };
      const resp = await req.request(url, opts);
      req.destroy();
      if (resp.responseCode !== 200) return null;
      const buffer = resp.result as ArrayBuffer;
      const bytes = new Uint8Array(buffer);
      const helper = new util.Base64Helper();
      const b64 = helper.encodeToStringSync(bytes);
      const dataUri = 'data:' + this.guessMime(url) + ';base64,' + b64;
      cache.set(url, dataUri);
      return dataUri;
    } catch (e) {
      return null;
    }
  }

  private guessMime(url: string): string {
    const lower = url.toLowerCase();
    if (lower.indexOf('.png') >= 0) return 'image/png';
    if (lower.indexOf('.gif') >= 0) return 'image/gif';
    if (lower.indexOf('.webp') >= 0) return 'image/webp';
    if (lower.indexOf('.svg') >= 0) return 'image/svg+xml';
    return 'image/jpeg';
  }

}

export const threadArchiveStore = new ThreadArchiveStore();
