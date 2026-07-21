import * as Battery from 'expo-battery';
import { StorageService } from './StorageService';
import { WebhookService } from './WebhookService';
import { ChargingSession, WeeklyReport, DailyBreakdown, BatterySnapshot } from '../types';

export class BatteryService {
  private webhook: WebhookService | null = null;
  private session: ChargingSession | null = null;

  async init() {
    const config = await StorageService.getConfig();
    if (config) {
      this.webhook = new WebhookService(config);
    }

    Battery.addBatteryStateListener(async (state) => {
      const level = await Battery.getBatteryLevelAsync();
      
      if (state === Battery.BatteryState.CHARGING) {
        await this.onChargeStart(level);
      } else if (state === Battery.BatteryState.UNPLUGGED) {
        await this.onChargeStop(level);
      }

      await this.saveSnapshot(level, state === Battery.BatteryState.CHARGING);
      
      if (level <= 0.2 && state !== Battery.BatteryState.CHARGING) {
        if (this.webhook) await this.webhook.notifyLowBattery(level);
      }
    });
  }

  private async onChargeStart(level: number) {
    this.session = {
      id: Date.now().toString(),
      startTime: Date.now(),
      startLevel: level,
    };
    await StorageService.saveSession(this.session);
    if (this.webhook) await this.webhook.notifyChargeStart(level);
  }

  private async onChargeStop(level: number) {
    if (!this.session) return;
    const end = Date.now();
    const dur = (end - this.session.startTime) / 1000;

    await StorageService.updateSession(this.session.id, {
      endTime: end,
      endLevel: level,
      duration: dur,
    });

    if (this.webhook) await this.webhook.notifyChargeStop(level, dur);
    this.session = null;
  }

  private async saveSnapshot(level: number, charging: boolean) {
    await StorageService.saveSnapshot({
      timestamp: Date.now(),
      level,
      isCharging: charging,
    });
  }

  async sendDailyReport() {
    const today = new Date().toISOString().split('T')[0];
    const last = await StorageService.getLastDaily();
    if (last === today) return;

    const hour = new Date().getHours();
    if (hour < 22 || hour > 23) return;

    const sessions = await StorageService.getTodaySessions();
    const snaps = await StorageService.getSnapshots();
    const todaySnaps = snaps.filter((s: BatterySnapshot) => {
      return new Date(s.timestamp).toISOString().split('T')[0] === today;
    });

    let drain = 0;
    if (todaySnaps.length >= 2) {
      drain = todaySnaps[0].level - todaySnaps[todaySnaps.length - 1].level;
    }

    const report = {
      date: today,
      chargeCount: sessions.length,
      totalUsageTime: sessions.reduce((sum: number, s: ChargingSession) => sum + (s.duration || 0), 0),
      batteryDrain: Math.max(0, drain),
      sessions,
    };

    if (this.webhook) await this.webhook.sendDailyReport(report);
    await StorageService.setLastDaily(today);
  }

  async sendWeeklyReport() {
    const now = new Date();
    if (now.getDay() !== 0 || now.getHours() !== 23) return;

    const wn = this.getWeekNum(now);
    const last = await StorageService.getLastWeekly();
    if (last === wn.toString()) return;

    const data = await this.calcWeeklyData();
    if (this.webhook) await this.webhook.sendWeeklyReport(data);
    await StorageService.setLastWeekly(wn.toString());
    await StorageService.saveWeekData(data);
  }

  private async calcWeeklyData(): Promise<WeeklyReport> {
    const now = new Date();
    const ws = this.getWeekStart(now);
    const we = new Date(ws.getTime() + 7 * 86400000 - 1);

    const sessions = await StorageService.getSessions();
    const wsSessions = sessions.filter((s: ChargingSession) => 
      s.startTime >= ws.getTime() && s.startTime <= we.getTime()
    );

    const snaps = await StorageService.getSnapshots();
    const wsSnaps = snaps.filter((s: BatterySnapshot) => 
      s.timestamp >= ws.getTime() && s.timestamp <= we.getTime()
    );

    const tc = wsSessions.length;
    const tt = wsSessions.reduce((sum: number, s: ChargingSession) => sum + (s.duration || 0), 0);
    const td = this.calcDrain(wsSnaps);
    const days = 7;

    const db = this.buildDailyBreakdown(wsSessions, wsSnaps, ws);
    const most = db.reduce((a: DailyBreakdown, b: DailyBreakdown) => a.charges > b.charges ? a : b);
    const best = db.reduce((a: DailyBreakdown, b: DailyBreakdown) => a.batteryDrain < b.batteryDrain ? a : b);

    return {
      weekStart: ws.getTime(),
      weekEnd: we.getTime(),
      totalCharges: tc,
      totalChargingTime: tt,
      totalBatteryDrain: td,
      avgDailyCharges: tc / days,
      avgDailyChargingTime: tt / days,
      avgChargeDuration: tc > 0 ? tt / tc : 0,
      avgDailyBatteryDrain: td / days,
      mostChargesDay: { date: most.date, count: most.charges },
      longestCharge: { date: 'N/A', duration: 0 },
      bestBatteryDay: { date: best.date, drain: best.batteryDrain },
      overnightCharges: 0,
      dailyBreakdown: db,
    };
  }

  private buildDailyBreakdown(sessions: ChargingSession[], snaps: BatterySnapshot[], ws: Date): DailyBreakdown[] {
    const days: DailyBreakdown[] = [];
    for (let i = 0; i < 7; i++) {
      const ds = new Date(ws.getTime() + i * 86400000);
      const de = new Date(ds.getTime() + 86400000 - 1);

      const daySessions = sessions.filter((s: ChargingSession) => 
        s.startTime >= ds.getTime() && s.startTime <= de.getTime()
      );
      const daySnaps = snaps.filter((s: BatterySnapshot) => 
        s.timestamp >= ds.getTime() && s.timestamp <= de.getTime()
      );

      days.push({
        date: ds.toISOString(),
        charges: daySessions.length,
        chargingTime: daySessions.reduce((sum: number, s: ChargingSession) => sum + (s.duration || 0), 0),
        batteryDrain: this.calcDrain(daySnaps),
      });
    }
    return days;
  }

  private calcDrain(snaps: BatterySnapshot[]): number {
    if (snaps.length < 2) return 0;
    return Math.max(0, snaps[0].level - snaps[snaps.length - 1].level);
  }

  private getWeekNum(d: Date): number {
    const start = new Date(d.getFullYear(), 0, 1);
    const diff = d.getTime() - start.getTime();
    return Math.ceil((diff / 86400000 + start.getDay() + 1) / 7);
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
