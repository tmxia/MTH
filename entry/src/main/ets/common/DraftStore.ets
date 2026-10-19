import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';

import { PostDraft } from '../models/Models';
// 明确定义草稿数据接口
export interface DraftData {
  title: string;
  content: string;
  time: number;
}

export class DraftStore {
  private static pref: preferences.Preferences | null = null;
  private static readonly STORE_NAME = 'mtf_drafts';

  static async init(context: common.UIAbilityContext) {
    if (!DraftStore.pref) {
      DraftStore.pref = await preferences.getPreferences(context, DraftStore.STORE_NAME);
      await DraftStore.ensureListLoaded();
    } else {
      await DraftStore.ensureListLoaded();
    }
  }

  static async saveDraft(fid: string, title: string, content: string) {
    if (!DraftStore.pref || (!title && !content)) return;
    try {
      const draftKey = `draft_${fid}`;
      const data = JSON.stringify({ title, content, time: Date.now() });
      await DraftStore.pref.put(draftKey, data);
      await DraftStore.pref.flush();
    } catch (e) {
      console.error(JSON.stringify(e));
    }
    // 同步到列表模式，让 Drafts 页面能读到
    const cur = DraftStore.getItems();
    const kept: PostDraft[] = [];
    let found: PostDraft | null = null;
    for (let i = 0; i < cur.length; i++) {
      if (cur[i].fid === fid) { found = cur[i]; } else { kept.push(cur[i]); }
    }
    const d: PostDraft = found || new PostDraft();
    d.fid = fid;
    d.subject = title || '';
    d.message = content || '';
    d.savedAt = Date.now();
    if (!d.forumName) d.forumName = '';
    if (!d.typeId) d.typeId = '';
    kept.push(d);
    DraftStore._listCache = kept;
    try {
      await DraftStore.pref.put(DraftStore.LIST_KEY, JSON.stringify(kept));
      await DraftStore.pref.flush();
    } catch (e) {}
  }

  static async getDraft(fid: string): Promise<DraftData | null> {
    if (!DraftStore.pref) return null;
    try {
      const draftKey = `draft_${fid}`;
      const data = await DraftStore.pref.get(draftKey, '') as string;
      if (data) {
        return JSON.parse(data) as DraftData;
      }
    } catch (e) {}
    return null;
  }

  static async clearDraft(fid: string) {
    if (!DraftStore.pref) return;
    try {
      const draftKey = `draft_${fid}`;
      await DraftStore.pref.delete(draftKey);
      await DraftStore.pref.flush();
    } catch (e) {}
  }

  // ===== 列表模式（与安卓 DraftStore 对齐，给 DraftsScreen 用）=====
  private static readonly LIST_KEY = 'drafts_list_v1';

  static getItems(): PostDraft[] {
    if (!DraftStore._listCache) return [];
    const out: PostDraft[] = [];
    for (let i = 0; i < DraftStore._listCache.length; i++) {
      out.push(DraftStore._listCache[i]);
    }
    out.sort(function(a: PostDraft, b: PostDraft): number {
      return (b.savedAt || 0) - (a.savedAt || 0);
    });
    return out;
  }

  static async save(draft: PostDraft): Promise<void> {
    if (!DraftStore.pref) return;
    const cur = DraftStore.getItems();
    const kept: PostDraft[] = [];
    for (let i = 0; i < cur.length; i++) {
      if (cur[i].fid !== draft.fid) kept.push(cur[i]);
    }
    kept.push(draft);
    DraftStore._listCache = kept;
    try {
      await DraftStore.pref.put(DraftStore.LIST_KEY, JSON.stringify(kept));
      await DraftStore.pref.flush();
    } catch (e) {}
  }

  static async remove(fids: string[]): Promise<void> {
    if (!DraftStore.pref || !fids || fids.length === 0) return;
    const cur = DraftStore.getItems();
    const kept: PostDraft[] = [];
    for (let i = 0; i < cur.length; i++) {
      let del = false;
      for (let j = 0; j < fids.length; j++) {
        if (cur[i].fid === fids[j]) { del = true; break; }
      }
      if (!del) kept.push(cur[i]);
    }
    DraftStore._listCache = kept;
    try {
      await DraftStore.pref.put(DraftStore.LIST_KEY, JSON.stringify(kept));
      await DraftStore.pref.flush();
    } catch (e) {}
  }

  static async clear(): Promise<void> {
    if (!DraftStore.pref) return;
    DraftStore._listCache = [];
    try {
      await DraftStore.pref.put(DraftStore.LIST_KEY, '[]');
      await DraftStore.pref.flush();
    } catch (e) {}
  }

  static sizeBytes(): number {
    if (!DraftStore._listCache) return 0;
    try {
      return JSON.stringify(DraftStore._listCache).length;
    } catch (e) {
      return 0;
    }
  }

  private static _listCache: PostDraft[] | null = null;

  private static async ensureListLoaded(): Promise<void> {
    if (!DraftStore.pref || DraftStore._listCache) return;
    try {
      const raw = await DraftStore.pref.get(DraftStore.LIST_KEY, '[]') as string;
      const arr = JSON.parse(raw) as Object[];
      const list: PostDraft[] = [];
      if (Array.isArray(arr)) {
        for (let i = 0; i < arr.length; i++) {
          const o = arr[i] as Record<string, string | number>;
          const d = new PostDraft();
          d.fid = (o['fid'] as string) || '';
          d.forumName = (o['forumName'] as string) || '';
          d.subject = (o['subject'] as string) || '';
          d.message = (o['message'] as string) || '';
          d.typeId = (o['typeId'] as string) || '';
          d.savedAt = (o['savedAt'] as number) || 0;
          list.push(d);
        }
      }
      DraftStore._listCache = list;
    } catch (e) {
      DraftStore._listCache = [];
    }
  }

}