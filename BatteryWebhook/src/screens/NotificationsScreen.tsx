import React, { useEffect, useState } from 'react';
import { View, Text, FlatList, StyleSheet, TouchableOpacity, RefreshControl } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { NotificationService } from '../services/NotificationService';
import { Notification } from '../types';

export default function NotificationsScreen() {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => { loadData(); }, []);

  const loadData = async () => {
    const data = await NotificationService.get();
    setNotifications(data);
  };

  const onRefresh = async () => {
    setRefreshing(true);
    await loadData();
    setRefreshing(false);
  };

  const getIcon = (type: Notification['type']) => {
    switch (type) {
      case 'charge_start': return 'flash';
      case 'charge_stop': return 'battery';
      case 'low_battery': return 'warning';
      case 'daily_report': return 'calendar';
      case 'weekly_report': return 'calendar-outline';
      default: return 'notifications';
    }
  };

  const getColor = (type: Notification['type']) => {
    switch (type) {
      case 'charge_start': return '#2ECC71';
      case 'charge_stop': return '#4A90E2';
      case 'low_battery': return '#E74C3C';
      case 'daily_report': return '#F39C12';
      case 'weekly_report': return '#9B59B6';
      default: return '#888';
    }
  };

  const formatTime = (ts: number) => {
    const d = new Date(ts);
    return d.toLocaleDateString('vi-VN') + ' ' + d.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
  };

  return (
    <View style={styles.container}>
      {notifications.length > 0 && (
        <TouchableOpacity style={styles.clearBtn} onPress={async () => {
          await NotificationService.clear();
          await loadData();
        }}>
          <Text style={styles.clearText}>Xóa tất cả</Text>
        </TouchableOpacity>
      )}
      <FlatList
        data={notifications}
        renderItem={({ item }) => (
          <View style={styles.card}>
            <View style={styles.iconContainer}>
              <Ionicons name={getIcon(item.type)} size={28} color={getColor(item.type)} />
            </View>
            <View style={styles.content}>
              <Text style={styles.title}>{item.title}</Text>
              <Text style={styles.message}>{item.message}</Text>
              <Text style={styles.time}>{formatTime(item.timestamp)}</Text>
            </View>
          </View>
        )}
        keyExtractor={item => item.id}
        contentContainerStyle={styles.list}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor="#4A90E2" />}
        ListEmptyComponent={<Text style={styles.empty}>Chưa có thông báo nào</Text>}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#0f0f1a' },
  list: { padding: 15 },
  clearBtn: { alignSelf: 'flex-end', margin: 15, padding: 8, paddingHorizontal: 16, backgroundColor: '#E74C3C', borderRadius: 8 },
  clearText: { color: '#fff', fontWeight: 'bold' },
  card: { flexDirection: 'row', backgroundColor: '#16213e', borderRadius: 15, padding: 15, marginBottom: 10 },
  iconContainer: { justifyContent: 'center', marginRight: 15 },
  content: { flex: 1 },
  title: { color: '#fff', fontSize: 16, fontWeight: 'bold' },
  message: { color: '#ccc', fontSize: 14, marginTop: 4 },
  time: { color: '#666', fontSize: 12, marginTop: 6 },
  empty: { color: '#666', fontSize: 16, textAlign: 'center', marginTop: 50 },
});
