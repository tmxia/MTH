import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { HistoryItem } from '../models/Models';

export class HistoryStore {
  private pref: preferences.Preferences | null = null;
  private readonly STORE_NAME: string = 'mtf_history';
  private readonly KEY: string = 'items_json';
  private readonly MAX_ITEMS: number = 200;
  private cache: HistoryItem[] = [];

  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.pref) return;
    try {
      this.pref = await preferences.getPreferences(context, this.STORE_NAME);
      const raw = await this.pref.get(this.KEY, '[]') as string;
      this.cache = this.parse(raw);
    } catch (e) {
      console.error('Init History Error: ' + JSON.stringify(e));
    }
  }

  getItems(): HistoryItem[] {
    return this.cache.slice();
  }

  async add(item: HistoryItem): Promise<void> {
    const kept: HistoryItem[] = [];
    for (let i = 0; i < this.cache.length; i++) {
      if (this.cache[i].tid !== item.tid) kept.push(this.cache[i]);
    }
    kept.unshift(item);
    this.cache = kept.slice(0, this.MAX_ITEMS);
    await this.persist();
  }

  async remove(tid: string, type: string = 'thread'): Promise<void> {
    const kept: HistoryItem[] = [];
    for (let i = 0; i < this.cache.length; i++) {
      const x = this.cache[i];
      if (!(x.tid === tid && x.type === type)) kept.push(x);
    }
    this.cache = kept;
    await this.persist();
  }

  async clear(): Promise<void> {
    this.cache = [];
    await this.persist();
  }

  private async persist(): Promise<void> {
    if (!this.pref) return;
    try {
      await this.pref.put(this.KEY, this.serialize(this.cache));
      await this.pref.flush();
    } catch (e) {
      console.error('History persist error: ' + JSON.stringify(e));
    }
  }

  private parse(json: string): HistoryItem[] {
    const result: HistoryItem[] = [];
    try {
      const arr = JSON.parse(json) as Object[];
      if (!Array.isArray(arr)) return result;
      for (let i = 0; i < arr.length; i++) {
        const o = arr[i] as Record<string, string | number>;
        const h = new HistoryItem();
        h.tid = (o['tid'] as string) || '';
        h.title = (o['title'] as string) || '';
        h.author = (o['author'] as string) || '';
        h.avatarUrl = (o['avatarUrl'] as string) || '';
        h.forumName = (o['forumName'] as string) || '';
        h.viewedAt = (o['viewedAt'] as number) || 0;
        h.type = (o['type'] as string) || 'thread';
        result.push(h);
      }
    } catch (e) {
      return result;
    }
    return result;
  }

  private serialize(items: HistoryItem[]): string {
    return JSON.stringify(items);
  }
}

export const historyStore = new HistoryStore();
