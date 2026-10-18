import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';

export class CookieManager {
  private static pref: preferences.Preferences | null = null;
  private static readonly STORE_NAME = 'mtf_cookie_store';
  private static readonly KEY_COOKIE = 'mtf_session_cookie';
  private static cookieCache: string = '';

  static async init(context: common.UIAbilityContext): Promise<void> {
    if (!this.pref) {
      this.pref = await preferences.getPreferences(context, this.STORE_NAME);
      this.cookieCache = await this.pref.get(this.KEY_COOKIE, '') as string;
    }
  }

  static async save(cookie: string): Promise<void> {
    if (!cookie || cookie === this.cookieCache) return;
    this.cookieCache = cookie;
    if (this.pref) {
      await this.pref.put(this.KEY_COOKIE, cookie);
      await this.pref.flush();
    }
  }

  static get(): string {
    return this.cookieCache;
  }

  static async clear(): Promise<void> {
    this.cookieCache = '';
    if (this.pref) {
      await this.pref.delete(this.KEY_COOKIE);
      await this.pref.flush();
    }
  }
}
