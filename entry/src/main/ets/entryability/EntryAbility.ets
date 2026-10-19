import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';

import { cookieManager } from '../network/CookieManager';
import { DraftStore } from '../common/DraftStore';
import { historyStore } from '../common/HistoryStore';
import { downloadStore } from '../common/DownloadStore';
export default class EntryAbility extends UIAbility {
  onCreate(): void {
    this.initStores().catch((e: Error) => {
      console.error('Init stores error: ' + (e.message ? e.message : String(e)));
    });
  }

  private async initStores(): Promise<void> {
    try { await cookieManager.init(this.context); } catch (e) {}
    try { await DraftStore.init(this.context); } catch (e) {}
    try { await historyStore.init(this.context); } catch (e) {}
    try { await downloadStore.init(this.context); } catch (e) {}
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        console.error('Failed to load the content. Cause: ' + JSON.stringify(err) ?? '');
        return;
      }
    });
  }
}