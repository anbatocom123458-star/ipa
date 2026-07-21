import { StorageService } from './StorageService';
import { Notification } from '../types';

export class NotificationService {
  static async add(
    type: Notification['type'],
    title: string,
    message: string,
    data?: any
  ): Promise<void> {
    const notification: Notification = {
      id: Date.now().toString(),
      type,
      title,
      message,
      timestamp: Date.now(),
      data,
    };
    await StorageService.saveNotification(notification);
  }

  static async get(): Promise<Notification[]> {
    return StorageService.getNotifications();
  }

  static async clear(): Promise<void> {
    await StorageService.clearNotifications();
  }
}
