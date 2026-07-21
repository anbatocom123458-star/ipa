import React, { useEffect, useState } from 'react';
import { View, Text, FlatList, StyleSheet } from 'react-native';
import { StorageService } from '../services/StorageService';
import { ChargingSession } from '../types';

export default function HistoryScreen() {
  const [sessions, setSessions] = useState<ChargingSession[]>([]);

  useEffect(() => { loadData(); }, []);

  const loadData = async () => {
    const data = await StorageService.getSessions();
    setSessions(data.reverse());
  };

  const fmt = (s?: number) => {
    if (!s) return 'Đang sạc...';
    const h = Math.floor(s / 3600);
    const m = Math.floor((s % 3600) / 60);
    return `${h}h ${m}m`;
  };

  const renderItem = ({ item }: { item: ChargingSession }) => (
    <View style={styles.card}>
      <View style={styles.header}>
        <Text style={styles.date}>
          {new Date(item.startTime).toLocaleDateString('vi-VN', {
            weekday: 'short', month: 'short', day: 'numeric',
          })}
        </Text>
        <Text style={styles.time}>
          {new Date(item.startTime).toLocaleTimeString('vi-VN', {
            hour: '2-digit', minute: '2-digit',
          })}
        </Text>
      </View>
      <View style={styles.details}>
        <View style={styles.row}>
          <Text style={styles.label}>Bắt đầu:</Text>
          <Text style={styles.value}>{Math.round(item.startLevel * 100)}%</Text>
        </View>
        {item.endLevel !== undefined && (
          <View style={styles.row}>
            <Text style={styles.label}>Kết thúc:</Text>
            <Text style={styles.value}>{Math.round(item.endLevel * 100)}%</Text>
          </View>
        )}
        <View style={styles.row}>
          <Text style={styles.label}>Thời gian:</Text>
          <Text style={styles.value}>{fmt(item.duration)}</Text>
        </View>
        <View style={styles.row}>
          <Text style={styles.label}>Pin tăng:</Text>
          <Text style={[styles.value, { color: '#27ae60' }]}>
            {item.endLevel ? `+${Math.round((item.endLevel - item.startLevel) * 100)}%` : 'N/A'}
          </Text>
        </View>
      </View>
    </View>
  );

  return (
    <View style={styles.container}>
      <FlatList
        data={sessions}
        renderItem={renderItem}
        keyExtractor={item => item.id}
        contentContainerStyle={styles.list}
        ListEmptyComponent={<Text style={styles.empty}>Chưa có lịch sử sạc</Text>}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#1a1a2e' },
  list: { padding: 15 },
  card: { backgroundColor: '#16213e', borderRadius: 15, padding: 15, marginBottom: 10 },
  header: {
    flexDirection: 'row', justifyContent: 'space-between',
    marginBottom: 10, borderBottomWidth: 1, borderBottomColor: '#1a1a4e', paddingBottom: 10,
  },
  date: { color: '#fff', fontSize: 16, fontWeight: 'bold' },
  time: { color: '#e94560', fontSize: 14 },
  details: { gap: 8 },
  row: { flexDirection: 'row', justifyContent: 'space-between' },
  label: { color: '#888', fontSize: 14 },
  value: { color: '#fff', fontSize: 14, fontWeight: '600' },
  empty: { color: '#666', fontSize: 16, textAlign: 'center', marginTop: 50 },
});
