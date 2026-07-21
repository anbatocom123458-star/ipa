import AsyncStorage from '@react-native-async-storage/async-storage';
import { WebhookConfig, BatterySnapshot, ChargingSession, WeeklyReport } from '../types';

const KEYS = {
  CONFIG: '@battery_config',
  SNAPSHOTS: '@battery_snapshots',
  SESSIONS: '@battery_sessions',
  LAST_DAILY: '@last_daily',
  LAST_WEEKLY: '@last_weekly',
  WEEK_DATA: '@week_data',
};

export class StorageService {
  static async saveConfig(config: WebhookConfig): Promise<void> {
    await AsyncStorage.setItem(KEYS.CONFIG, JSON.stringify(config));
  }

  static async getConfig(): Promise<WebhookConfig | null> {
    const data = await AsyncStorage.getItem(KEYS.CONFIG);
    return data ? JSON.parse(data) : null;
  }

  static async saveSnapshot(snapshot: BatterySnapshot): Promise<void> {
    const snaps = await this.getSnapshots();
    snaps.push(snapshot);
    const weekAgo = Date.now() - 7 * 24 * 60 * 60 * 1000;
    const filtered = snaps.filter((s: BatterySnapshot) => s.timestamp > weekAgo);
    await AsyncStorage.setItem(KEYS.SNAPSHOTS, JSON.stringify(filtered));
  }

  static async getSnapshots(): Promise<BatterySnapshot[]> {
    const data = await AsyncStorage.getItem(KEYS.SNAPSHOTS);
    return data ? JSON.parse(data) : [];
  }

  static async saveSession(session: ChargingSession): Promise<void> {
    const sessions = await this.getSessions();
    sessions.push(session);
    await AsyncStorage.setItem(KEYS.SESSIONS, JSON.stringify(sessions));
  }

  static async updateSession(id: string, updates: Partial<ChargingSession>): Promise<void> {
    const sessions = await this.getSessions();
    const index = sessions.findIndex((s: ChargingSession) => s.id === id);
    if (index !== -1) {
      sessions[index] = { ...sessions[index], ...updates };
      await AsyncStorage.setItem(KEYS.SESSIONS, JSON.stringify(sessions));
    }
  }

  static async getSessions(): Promise<ChargingSession[]> {
    const data = await AsyncStorage.getItem(KEYS.SESSIONS);
    return data ? JSON.parse(data) : [];
  }

  static async getTodaySessions(): Promise<ChargingSession[]> {
    const sessions = await this.getSessions();
    const today = new Date().setHours(0, 0, 0, 0);
    return sessions.filter((s: ChargingSession) => s.startTime >= today);
  }

  static async getLastDaily(): Promise<string | null> {
    return AsyncStorage.getItem(KEYS.LAST_DAILY);
  }

  static async setLastDaily(date: string): Promise<void> {
    await AsyncStorage.setItem(KEYS.LAST_DAILY, date);
  }

  static async getLastWeekly(): Promise<string | null> {
    return AsyncStorage.getItem(KEYS.LAST_WEEKLY);
  }

  static async setLastWeekly(date: string): Promise<void> {
    await AsyncStorage.setItem(KEYS.LAST_WEEKLY, date);
  }

  static async saveWeekData(data: WeeklyReport): Promise<void> {
    await AsyncStorage.setItem(KEYS.WEEK_DATA, JSON.stringify(data));
  }

  static async getWeekData(): Promise<WeeklyReport | null> {
    const data = await AsyncStorage.getItem(KEYS.WEEK_DATA);
    return data ? JSON.parse(data) : null;
  }
}
