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

export interface Notification {
  id: string;
  type: 'charge_start' | 'charge_stop' | 'low_battery' | 'daily_report' | 'weekly_report';
  title: string;
  message: string;
  timestamp: number;
  data?: any;
}

export interface DailyBreakdown {
  date: string;
  charges: number;
  chargingTime: number;
  batteryDrain: number;
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
  bestBatteryDay: { date: string; drain: number };
  dailyBreakdown: DailyBreakdown[];
}
