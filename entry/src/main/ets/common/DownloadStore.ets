import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import fileIo from '@ohos.file.fs';
import { DownloadedThread } from '../models/Models';

export class DownloadStore {
  private pref: preferences.Preferences | null = null;
  private readonly STORE_NAME: string = 'mtf_downloads';
  private readonly KEY: string = 'threads';
  private cache: DownloadedThread[] = [];

  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.pref) return;
    try {
      this.pref = await preferences.getPreferences(context, this.STORE_NAME);
      const raw = await this.pref.get(this.KEY, '[]') as string;
      this.cache = this.parse(raw);
    } catch (e) {
      console.error('Init Download Error: ' + JSON.stringify(e));
    }
  }

  getItems(): DownloadedThread[] {
    const sorted = this.cache.slice();
    sorted.sort(function(a: DownloadedThread, b: DownloadedThread): number {
      return (b.savedAt || 0) - (a.savedAt || 0);
    });
    return sorted;
  }

  async upsert(entry: DownloadedThread): Promise<void> {
    // 先删旧文件（同 tid 替换时）
    for (let i = 0; i < this.cache.length; i++) {
      if (this.cache[i].tid === entry.tid && this.cache[i].uri) {
        await this.deleteDocumentFile(this.cache[i].uri);
        break;
      }
    }
    const kept: DownloadedThread[] = [];
    for (let i = 0; i < this.cache.length; i++) {
      if (this.cache[i].tid !== entry.tid) kept.push(this.cache[i]);
    }
    kept.push(entry);
    this.cache = kept;
    await this.persist();
  }

  async remove(tid: string): Promise<void> {
    let targetUri: string = '';
    const kept: DownloadedThread[] = [];
    for (let i = 0; i < this.cache.length; i++) {
      const x = this.cache[i];
      if (x.tid === tid) {
        targetUri = x.uri || '';
      } else {
        kept.push(x);
      }
    }
    if (targetUri) await this.deleteDocumentFile(targetUri);
    this.cache = kept;
    await this.persist();
  }

  private async deleteDocumentFile(uriString: string): Promise<void> {
    // 鸿蒙无法删除 SAF content:// URI，跳过
    if (!uriString || uriString.indexOf('content://') === 0) {
      return;
    }
    try {
      await fileIo.unlink(uriString);
    } catch (e) {
      console.error('Delete file failed: ' + JSON.stringify(e));
    }
  }

  private async persist(): Promise<void> {
    if (!this.pref) return;
    try {
      await this.pref.put(this.KEY, JSON.stringify(this.cache));
      await this.pref.flush();
    } catch (e) {
      console.error('Download persist error: ' + JSON.stringify(e));
    }
  }

  private parse(json: string): DownloadedThread[] {
    const result: DownloadedThread[] = [];
    try {
      const arr = JSON.parse(json) as Object[];
      if (!Array.isArray(arr)) return result;
      for (let i = 0; i < arr.length; i++) {
        const o = arr[i] as Record<string, string | number>;
        const d = new DownloadedThread();
        d.tid = (o['tid'] as string) || '';
        d.subject = (o['subject'] as string) || '';
        d.forumName = (o['forumName'] as string) || '';
        d.fileName = (o['fileName'] as string) || '';
        d.uri = (o['uri'] as string) || '';
        d.savedAt = (o['savedAt'] as number) || 0;
        d.replyCount = (o['replyCount'] as number) || 0;
        d.sizeBytes = (o['sizeBytes'] as number) || 0;
        result.push(d);
      }
    } catch (e) {
      return result;
    }
    return result;
  }
}

export const downloadStore = new DownloadStore();
