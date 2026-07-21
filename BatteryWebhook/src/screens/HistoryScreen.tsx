import React, { useEffect, useState } from 'react';
import { View, Text, FlatList, StyleSheet, RefreshControl } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { StorageService } from '../services/StorageService';
import { ChargingSession } from '../types';

export default function HistoryScreen() {
  const [sessions, setSessions] = useState<ChargingSession[]>([]);
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => { loadData(); }, []);

  const loadData = async () => {
    const data = await StorageService.getSessions();
    setSessions(data.reverse());
  };

  const onRefresh = async () => {
    setRefreshing(true);
    await loadData();
    setRefreshing(false);
  };

  const fmt = (s?: number) => {
    if (!s) return 'Đang sạc...';
    const h = Math.floor(s / 3600);
    const m = Math.floor((s % 3600) / 60);
    return `${h}h ${m}m`;
  };

  return (
    <View style={styles.container}>
      <FlatList
        data={sessions}
        renderItem={({ item }) => (
          <View style={styles.card}>
            <View style={styles.header}>
              <View>
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
              <Ionicons name="battery" size={32} color={item.endLevel ? '#2ECC71' : '#F1C40F'} />
            </View>
            <View style={styles.details}>
              <View style={styles.row}>
                <Text style={styles.label}>Bắt đầu</Text>
                <Text style={styles.value}>{Math.round(item.startLevel * 100)}%</Text>
              </View>
              {item.endLevel !== undefined && (
                <View style={styles.row}>
                  <Text style={styles.label}>Kết thúc</Text>
                  <Text style={styles.value}>{Math.round(item.endLevel * 100)}%</Text>
                </View>
              )}
              <View style={styles.row}>
                <Text style={styles.label}>Thời gian</Text>
                <Text style={styles.value}>{fmt(item.duration)}</Text>
              </View>
              <View style={styles.row}>
                <Text style={styles.label}>Pin tăng</Text>
                <Text style={[styles.value, { color: '#2ECC71' }]}>
                  {item.endLevel ? `+${Math.round((item.endLevel - item.startLevel) * 100)}%` : 'N/A'}
                </Text>
              </View>
            </View>
          </View>
        )}
        keyExtractor={item => item.id}
        contentContainerStyle={styles.list}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor="#4A90E2" />}
        ListEmptyComponent={<Text style={styles.empty}>Chưa có lịch sử sạc</Text>}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#0f0f1a' },
  list: { padding: 15 },
  card: { backgroundColor: '#16213e', borderRadius: 15, padding: 15, marginBottom: 10 },
  header: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 10, borderBottomWidth: 1, borderBottomColor: '#1a1a4e', paddingBottom: 10 },
  date: { color: '#fff', fontSize: 16, fontWeight: 'bold' },
  time: { color: '#4A90E2', fontSize: 14 },
  details: { gap: 8 },
  row: { flexDirection: 'row', justifyContent: 'space-between' },
  label: { color: '#888', fontSize: 14 },
  value: { color: '#fff', fontSize: 14, fontWeight: '600' },
  empty: { color: '#666', fontSize: 16, textAlign: 'center', marginTop: 50 },
});
