import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';

export class DraftStore {
  private static pref: preferences.Preferences | null = null;
  private static readonly STORE_NAME = 'mtf_drafts';

  static async init(context: common.UIAbilityContext) {
    if (!this.pref) {
      this.pref = await preferences.getPreferences(context, this.STORE_NAME);
    }
  }

  static async saveDraft(fid: string, title: string, content: string) {
    if (!this.pref || (!title && !content)) return;
    try {
      const draftKey = `draft_${fid}`;
      const data = JSON.stringify({ title, content, time: Date.now() });
      await this.pref.put(draftKey, data);
      await this.pref.flush();
    } catch (e) {
      console.error(e);
    }
  }

  static async getDraft(fid: string): Promise<{title: string, content: string} | null> {
    if (!this.pref) return null;
    try {
      const draftKey = `draft_${fid}`;
      const data = await this.pref.get(draftKey, '') as string;
      if (data) return JSON.parse(data);
    } catch (e) {}
    return null;
  }

  static async clearDraft(fid: string) {
    if (!this.pref) return;
    try {
      const draftKey = `draft_${fid}`;
      await this.pref.delete(draftKey);
      await this.pref.flush();
    } catch (e) {}
  }
}
