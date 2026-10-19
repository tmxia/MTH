import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';

export enum LogLevel {
  INFO = 0,
  WARN = 1,
  ERROR = 2
}

export class LogEntry {
  id: number = 0;
  time: number = 0;
  level: LogLevel = LogLevel.INFO;
  tag: string = '';
  message: string = '';
  detail: string = '';
}

export function levelLabel(l: LogLevel): string {
  if (l === LogLevel.WARN) return 'Warn';
  if (l === LogLevel.ERROR) return 'Error';
  return 'Info';
}

export function levelColor(l: LogLevel): string {
  if (l === LogLevel.WARN) return '#F5A623';
  if (l === LogLevel.ERROR) return '#E53935';
  return '#4D6BFE';
}

export class LogStore {
  private static MAX: number = 500;
  private static entries: LogEntry[] = [];
  private static nextId: number = 1;
  private static level: LogLevel = LogLevel.INFO;
  private static pref: preferences.Preferences | null = null;
  private static readonly STORE_NAME = 'mtf_log';
  private static readonly KEY_LEVEL = 'level';

  static async init(context: common.UIAbilityContext): Promise<void> {
    if (LogStore.pref) return;
    try {
      LogStore.pref = await preferences.getPreferences(context, LogStore.STORE_NAME);
      const raw = await LogStore.pref.get(LogStore.KEY_LEVEL, 'INFO') as string;
      if (raw === 'WARN') LogStore.level = LogLevel.WARN;
      else if (raw === 'ERROR') LogStore.level = LogLevel.ERROR;
      else LogStore.level = LogLevel.INFO;
    } catch (e) {
      console.error('Init LogStore error: ' + JSON.stringify(e));
    }
  }

  static getLevel(): LogLevel {
    return LogStore.level;
  }

  static async setLevel(l: LogLevel): Promise<void> {
    LogStore.level = l;
    if (!LogStore.pref) return;
    try {
      let name = 'INFO';
      if (l === LogLevel.WARN) name = 'WARN';
      else if (l === LogLevel.ERROR) name = 'ERROR';
      await LogStore.pref.put(LogStore.KEY_LEVEL, name);
      await LogStore.pref.flush();
    } catch (e) {}
  }

  static add(level: LogLevel, tag: string, message: string, detail?: string): void {
    if (level < LogStore.level) return;
    const e = new LogEntry();
    e.id = LogStore.nextId++;
    e.time = Date.now();
    e.level = level;
    e.tag = tag;
    e.message = message;
    e.detail = detail || '';
    LogStore.entries.push(e);
    while (LogStore.entries.length > LogStore.MAX) {
      LogStore.entries.shift();
    }
  }

  static getEntries(): LogEntry[] {
    const out: LogEntry[] = [];
    for (let i = 0; i < LogStore.entries.length; i++) {
      out.push(LogStore.entries[i]);
    }
    out.reverse();
    return out;
  }

  static getById(id: number): LogEntry | null {
    for (let i = 0; i < LogStore.entries.length; i++) {
      if (LogStore.entries[i].id === id) return LogStore.entries[i];
    }
    return null;
  }

  static clear(): void {
    LogStore.entries = [];
  }

  static remove(id: number): void {
    const kept: LogEntry[] = [];
    for (let i = 0; i < LogStore.entries.length; i++) {
      if (LogStore.entries[i].id !== id) kept.push(LogStore.entries[i]);
    }
    LogStore.entries = kept;
  }
}

export const logger = LogStore;
