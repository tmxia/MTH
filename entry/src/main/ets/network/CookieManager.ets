import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';

export class CookieManager {
  private pref: preferences.Preferences | null = null;
  private readonly STORE_NAME = 'mtf_cookie_store';
  private readonly KEY_COOKIE = 'mtf_session_cookie';
  private cookieCache: string = '';

  async init(context: common.UIAbilityContext): Promise<void> {
    if (!this.pref) {
      this.pref = await preferences.getPreferences(context, this.STORE_NAME);
      this.cookieCache = await this.pref.get(this.KEY_COOKIE, '') as string;
    }
  }

  async save(cookie: string): Promise<void> {
    if (!cookie || cookie === this.cookieCache) return;
    this.cookieCache = cookie;
    if (this.pref) {
      await this.pref.put(this.KEY_COOKIE, cookie);
      await this.pref.flush();
    }
  }

  get(): string {
    return this.cookieCache;
  }

  async clear(): Promise<void> {
    this.cookieCache = '';
    if (this.pref) {
      await this.pref.delete(this.KEY_COOKIE);
      await this.pref.flush();
    }
  }
}

// 导出单例
export const cookieManager = new CookieManager();
