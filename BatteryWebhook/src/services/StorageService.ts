import AsyncStorage from '@react-native-async-storage/async-storage';
import { BatterySnapshot, ChargingSession, WeeklyReport, Notification } from '../types';

const KEYS = {
  SNAPSHOTS: '@battery_snapshots',
  SESSIONS: '@battery_sessions',
  WEEK_DATA: '@week_data',
  NOTIFICATIONS: '@battery_notifications',
};

export class StorageService {
  // Snapshots
  static async saveSnapshot(snapshot: BatterySnapshot): Promise<void> {
    const snaps = await this.getSnapshots();
    snaps.push(snapshot);
    const weekAgo = Date.now() - 7 * 24 * 60 * 60 * 1000;
    await AsyncStorage.setItem(KEYS.SNAPSHOTS, JSON.stringify(snaps.filter(s => s.timestamp > weekAgo)));
  }

  static async getSnapshots(): Promise<BatterySnapshot[]> {
    const data = await AsyncStorage.getItem(KEYS.SNAPSHOTS);
    return data ? JSON.parse(data) : [];
  }

  // Sessions
  static async saveSession(session: ChargingSession): Promise<void> {
    const sessions = await this.getSessions();
    sessions.push(session);
    await AsyncStorage.setItem(KEYS.SESSIONS, JSON.stringify(sessions));
  }

  static async updateSession(id: string, updates: Partial<ChargingSession>): Promise<void> {
    const sessions = await this.getSessions();
    const index = sessions.findIndex(s => s.id === id);
    if (index !== -1) {
      sessions[index] = { ...sessions[index], ...updates };
      await AsyncStorage.setItem(KEYS.SESSIONS, JSON.stringify(sessions));
    }
  }

  static async getSessions(): Promise<ChargingSession[]> {
    const data = await AsyncStorage.getItem(KEYS.SESSIONS);
    return data ? JSON.parse(data) : [];
  }

  // Notifications
  static async saveNotification(notification: Notification): Promise<void> {
    const notifs = await this.getNotifications();
    notifs.unshift(notification);
    if (notifs.length > 100) notifs.pop();
    await AsyncStorage.setItem(KEYS.NOTIFICATIONS, JSON.stringify(notifs));
  }

  static async getNotifications(): Promise<Notification[]> {
    const data = await AsyncStorage.getItem(KEYS.NOTIFICATIONS);
    return data ? JSON.parse(data) : [];
  }

  static async clearNotifications(): Promise<void> {
    await AsyncStorage.removeItem(KEYS.NOTIFICATIONS);
  }

  // Week data
  static async saveWeekData(data: WeeklyReport): Promise<void> {
    await AsyncStorage.setItem(KEYS.WEEK_DATA, JSON.stringify(data));
  }

  static async getWeekData(): Promise<WeeklyReport | null> {
    const data = await AsyncStorage.getItem(KEYS.WEEK_DATA);
    return data ? JSON.parse(data) : null;
  }
}
