import * as Battery from 'expo-battery';
import { StorageService } from './StorageService';
import { NotificationService } from './NotificationService';
import { ChargingSession, BatterySnapshot, WeeklyReport, DailyBreakdown } from '../types';

export class BatteryService {
  private session: ChargingSession | null = null;

  async init() {
    const level = await Battery.getBatteryLevelAsync();
    const state = await Battery.getBatteryStateAsync();
    await this.handleUpdate(level, state);

    Battery.addBatteryStateListener(async ({ batteryState }) => {
      const level = await Battery.getBatteryLevelAsync();
      await this.handleUpdate(level, batteryState);
    });

    Battery.addBatteryLevelListener(async ({ batteryLevel }) => {
      const state = await Battery.getBatteryStateAsync();
      await this.handleUpdate(batteryLevel, state);
    });

    // Báo cáo hàng ngày lúc 22h
    this.scheduleDailyReport();
    // Báo cáo tuần vào Chủ nhật 23h
    this.scheduleWeeklyReport();
  }

  private async handleUpdate(level: number, state: Battery.BatteryState) {
    const isCharging = state === Battery.BatteryState.CHARGING || state === Battery.BatteryState.FULL;

    if (state === Battery.BatteryState.CHARGING && !this.session) {
      await this.onChargeStart(level);
    } else if (state === Battery.BatteryState.UNPLUGGED && this.session) {
      await this.onChargeStop(level);
    }

    await this.saveSnapshot(level, isCharging);

    if (level <= 0.2 && !isCharging) {
      await NotificationService.add(
        'low_battery',
        '⚠️ Pin yếu',
        `Pin chỉ còn ${Math.round(level * 100)}%, hãy sạc ngay!`,
        { level }
      );
    }
  }

  private async onChargeStart(level: number) {
    this.session = {
      id: Date.now().toString(),
      startTime: Date.now(),
      startLevel: level,
    };
    await StorageService.saveSession(this.session);
    await NotificationService.add(
      'charge_start',
      '🔌 Đã cắm sạc',
      `Pin đang ở mức ${Math.round(level * 100)}%`,
      { level }
    );
  }

  private async onChargeStop(level: number) {
    if (!this.session) return;
    const duration = (Date.now() - this.session.startTime) / 1000;
    await StorageService.updateSession(this.session.id, {
      endTime: Date.now(),
      endLevel: level,
      duration,
    });
    const h = Math.floor(duration / 3600);
    const m = Math.floor((duration % 3600) / 60);
    await NotificationService.add(
      'charge_stop',
      '🔋 Đã rút sạc',
      `Sạc trong ${h}h ${m}m, pin đạt ${Math.round(level * 100)}%`,
      { level, duration }
    );
    this.session = null;
  }

  private async saveSnapshot(level: number, charging: boolean) {
    await StorageService.saveSnapshot({
      timestamp: Date.now(),
      level,
      isCharging: charging,
    });
  }

  private scheduleDailyReport() {
    const now = new Date();
    const target = new Date(now);
    target.setHours(22, 0, 0, 0);
    if (now > target) target.setDate(target.getDate() + 1);
    const delay = target.getTime() - now.getTime();
    setTimeout(async () => {
      await this.sendDailyReport();
      setInterval(() => this.sendDailyReport(), 24 * 60 * 60 * 1000);
    }, delay);
  }

  private scheduleWeeklyReport() {
    const now = new Date();
    const target = new Date(now);
    const daysUntilSunday = 7 - target.getDay();
    target.setDate(target.getDate() + daysUntilSunday);
    target.setHours(23, 0, 0, 0);
    const delay = target.getTime() - now.getTime();
    setTimeout(async () => {
      await this.sendWeeklyReport();
      setInterval(() => this.sendWeeklyReport(), 7 * 24 * 60 * 60 * 1000);
    }, delay);
  }

  private async sendDailyReport() {
    const today = new Date().toISOString().split('T')[0];
    const sessions = await StorageService.getSessions();
    const daySessions = sessions.filter(s => 
      new Date(s.startTime).toISOString().split('T')[0] === today
    );
    const snaps = await StorageService.getSnapshots();
    const daySnaps = snaps.filter(s => 
      new Date(s.timestamp).toISOString().split('T')[0] === today
    );
    const drain = daySnaps.length >= 2 ? Math.max(0, daySnaps[0].level - daySnaps[daySnaps.length - 1].level) : 0;
    const totalTime = daySessions.reduce((sum, s) => sum + (s.duration || 0), 0);
    const h = Math.floor(totalTime / 3600);
    const m = Math.floor((totalTime % 3600) / 60);

    await NotificationService.add(
      'daily_report',
      '📊 Báo cáo ngày',
      `${daySessions.length} lần sạc, ${h}h ${m}m, dùng ${Math.round(drain * 100)}% pin`,
      { sessions: daySessions, drain, totalTime }
    );
  }

  private async sendWeeklyReport() {
    const data = await this.calcWeeklyData();
    await StorageService.saveWeekData(data);
    const fmt = (s: number) => {
      const h = Math.floor(s / 3600);
      const m = Math.floor((s % 3600) / 60);
      return `${h}h ${m}m`;
    };
    await NotificationService.add(
      'weekly_report',
      '📊 Báo cáo tuần',
      `${data.totalCharges} lần sạc, ${fmt(data.totalChargingTime)}, dùng ${Math.round(data.totalBatteryDrain * 100)}% pin`,
      data
    );
  }

  private async calcWeeklyData(): Promise<WeeklyReport> {
    const now = new Date();
    const ws = this.getWeekStart(now);
    const we = new Date(ws.getTime() + 7 * 86400000 - 1);
    const sessions = await StorageService.getSessions();
    const weekSessions = sessions.filter(s => s.startTime >= ws.getTime() && s.startTime <= we.getTime());
    const snaps = await StorageService.getSnapshots();
    const weekSnaps = snaps.filter(s => s.timestamp >= ws.getTime() && s.timestamp <= we.getTime());
    const totalCharges = weekSessions.length;
    const totalChargingTime = weekSessions.reduce((sum, s) => sum + (s.duration || 0), 0);
    const totalBatteryDrain = weekSnaps.length >= 2 ? Math.max(0, weekSnaps[0].level - weekSnaps[weekSnaps.length - 1].level) : 0;

    const dailyBreakdown: DailyBreakdown[] = [];
    for (let i = 0; i < 7; i++) {
      const ds = new Date(ws.getTime() + i * 86400000);
      const de = new Date(ds.getTime() + 86400000 - 1);
      const daySessions = weekSessions.filter(s => s.startTime >= ds.getTime() && s.startTime <= de.getTime());
      const daySnaps = weekSnaps.filter(s => s.timestamp >= ds.getTime() && s.timestamp <= de.getTime());
      const drain = daySnaps.length >= 2 ? Math.max(0, daySnaps[0].level - daySnaps[daySnaps.length - 1].level) : 0;
      dailyBreakdown.push({
        date: ds.toISOString().split('T')[0],
        charges: daySessions.length,
        chargingTime: daySessions.reduce((sum, s) => sum + (s.duration || 0), 0),
        batteryDrain: drain,
      });
    }

    const mostChargesDay = dailyBreakdown.reduce((a, b) => a.charges > b.charges ? a : b);
    const bestBatteryDay = dailyBreakdown.reduce((a, b) => a.batteryDrain < b.batteryDrain ? a : b);

    return {
      weekStart: ws.getTime(),
      weekEnd: we.getTime(),
      totalCharges,
      totalChargingTime,
      totalBatteryDrain,
      avgDailyCharges: totalCharges / 7,
      avgDailyChargingTime: totalChargingTime / 7,
      avgChargeDuration: totalCharges > 0 ? totalChargingTime / totalCharges : 0,
      avgDailyBatteryDrain: totalBatteryDrain / 7,
      mostChargesDay: { date: mostChargesDay.date, count: mostChargesDay.charges },
      bestBatteryDay: { date: bestBatteryDay.date, drain: bestBatteryDay.batteryDrain },
      dailyBreakdown,
    };
  }

  private getWeekStart(d: Date): Date {
    const date = new Date(d);
    const day = date.getDay();
    const diff = date.getDate() - day + (day === 0 ? -6 : 1);
    date.setDate(diff);
    date.setHours(0, 0, 0, 0);
    return date;
  }
}
