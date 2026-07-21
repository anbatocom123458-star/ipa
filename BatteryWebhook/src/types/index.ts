export interface WebhookConfig {
  webhookUrl: string;
  avatarUrl: string;
  username: string;
}

export interface BatterySnapshot {
  timestamp: number;
  level: number;
  isCharging: boolean;
}

export interface ChargingSession {
  id: string;
  startTime: number;
  endTime?: number;
  startLevel: number;
  endLevel?: number;
  duration?: number;
}

export interface DailyReport {
  date: string;
  chargeCount: number;
  totalUsageTime: number;
  batteryDrain: number;
  sessions: ChargingSession[];
}

export interface DailyBreakdown {
  date: string;
  charges: number;
  chargingTime: number;
  batteryDrain: number;
  note?: string;
}

export interface WeeklyReport {
  weekStart: number;
  weekEnd: number;
  totalCharges: number;
  totalChargingTime: number;
  totalBatteryDrain: number;
  avgDailyCharges: number;
  avgDailyChargingTime: number;
  avgChargeDuration: number;
  avgDailyBatteryDrain: number;
  mostChargesDay: { date: string; count: number };
  longestCharge: { date: string; duration: number };
  bestBatteryDay: { date: string; drain: number };
  overnightCharges: number;
  dailyBreakdown: DailyBreakdown[];
  comparisonWithLastWeek?: {
    chargeTrend: number;
    timeTrend: number;
    drainTrend: number;
  };
}
