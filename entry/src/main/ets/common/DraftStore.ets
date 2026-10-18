import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';

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
      console.error(e);
    }
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
}
