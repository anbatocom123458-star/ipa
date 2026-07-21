import axios from 'axios';
import { WebhookConfig, DailyReport, WeeklyReport } from '../types';

export class WebhookService {
  private config: WebhookConfig;

  constructor(config: WebhookConfig) {
    this.config = config;
  }

  private async sendEmbed(title: string, description: string, fields: any[], color: number = 0x00ff00) {
    try {
      const payload = {
        username: this.config.username,
        avatar_url: this.config.avatarUrl || 'https://i.imgur.com/fHPLi51.png',
        embeds: [{
          title,
          description,
          fields,
          color,
          timestamp: new Date().toISOString(),
          footer: { text: 'BatteryWebhook Monitor' }
        }]
      };

      await axios.post(this.config.webhookUrl, payload, {
        headers: { 'Content-Type': 'application/json' }
      });
    } catch (error) {
      console.error('Webhook failed:', error);
    }
  }

  async notifyChargeStart(level: number) {
    await this.sendEmbed(
      '🔌 Đã cắm sạc',
      'Thiết bị đang được sạc pin',
      [
        { name: '🔋 Mức pin', value: `${Math.round(level * 100)}%`, inline: true },
        { name: '⚡ Trạng thái', value: 'Đang sạc', inline: true },
        { name: '🕐 Thời gian', value: new Date().toLocaleTimeString('vi-VN'), inline: true }
      ],
      0x3498db
    );
  }

  async notifyChargeStop(level: number, duration: number) {
    const h = Math.floor(duration / 3600);
    const m = Math.floor((duration % 3600) / 60);
    
    await this.sendEmbed(
      '🔋 Đã rút sạc',
      'Thiết bị đã ngừng sạc',
      [
        { name: '🔋 Mức pin', value: `${Math.round(level * 100)}%`, inline: true },
        { name: '⚡ Trạng thái', value: 'Đã rút sạc', inline: true },
        { name: '⏱️ Thời gian sạc', value: `${h}h ${m}m`, inline: true }
      ],
      0xe74c3c
    );
  }

  async sendDailyReport(report: DailyReport) {
    const today = new Date().toLocaleDateString('vi-VN', {
      weekday: 'long', year: 'numeric', month: 'long', day: 'numeric'
    });

    const totalTime = report.sessions.reduce((sum, s) => sum + (s.duration || 0), 0);
    const h = Math.floor(totalTime / 3600);
    const m = Math.floor((totalTime % 3600) / 60);

    await this.sendEmbed(
      `📊 Báo cáo pin ngày ${today}`,
      'Tổng kết hoạt động pin trong ngày',
      [
        { name: '📊 Số lần sạc', value: `${report.chargeCount} lần`, inline: true },
        { name: '⏱️ Tổng thời gian', value: `${h}h ${m}m`, inline: true },
        { name: '🔋 Pin đã dùng', value: `${Math.round(report.batteryDrain * 100)}%`, inline: true }
      ],
      0x9b59b6
    );
  }

  async sendWeeklyReport(data: WeeklyReport) {
    const start = new Date(data.weekStart).toLocaleDateString('vi-VN', { month: 'numeric', day: 'numeric' });
    const end = new Date(data.weekEnd).toLocaleDateString('vi-VN', { month: 'numeric', day: 'numeric' });

    const fmt = (s: number) => {
      const h = Math.floor(s / 3600);
      const m = Math.floor((s % 3600) / 60);
      return `${h}h ${m}m`;
    };

    await this.sendEmbed(
      `📊 Báo cáo tuần ${start} - ${end}`,
      'Tổng kết hoạt động pin trong tuần',
      [
        { name: '📊 Tổng lần sạc', value: `${data.totalCharges} lần`, inline: true },
        { name: '⏱️ Tổng thời gian', value: fmt(data.totalChargingTime), inline: true },
        { name: '🔋 Pin đã dùng', value: `${Math.round(data.totalBatteryDrain * 100)}%`, inline: true },
        { name: '📈 TB/ngày', value: `${data.avgDailyCharges.toFixed(1)} lần`, inline: true }
      ],
      0x9b59b6
    );
  }

  async notifyLowBattery(level: number) {
    await this.sendEmbed(
      '⚠️ Pin yếu',
      `Pin chỉ còn ${Math.round(level * 100)}%! Hãy sạc ngay.`,
      [
        { name: '⚠️ Mức pin', value: `${Math.round(level * 100)}%`, inline: true },
        { name: '🕐 Thời gian', value: new Date().toLocaleTimeString('vi-VN'), inline: true }
      ],
      0xe67e22
    );
  }
}
