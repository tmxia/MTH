import fs from '@ohos.file.fs';
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
}

export const threadArchiveStore = new ThreadArchiveStore();
