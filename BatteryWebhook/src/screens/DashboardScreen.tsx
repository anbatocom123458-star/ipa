import React, { useEffect, useState } from 'react';
import { View, Text, ScrollView, StyleSheet, Dimensions, RefreshControl } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import * as Battery from 'expo-battery';
import { LineChart } from 'react-native-chart-kit';
import { StorageService } from '../services/StorageService';
import { BatterySnapshot, WeeklyReport } from '../types';

export default function DashboardScreen() {
  const [level, setLevel] = useState(0);
  const [state, setState] = useState('Không xác định');
  const [snaps, setSnaps] = useState<BatterySnapshot[]>([]);
  const [weekly, setWeekly] = useState<WeeklyReport | null>(null);
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => {
    loadData();
    const levelSub = Battery.addBatteryLevelListener(({ batteryLevel }) => setLevel(batteryLevel));
    const stateSub = Battery.addBatteryStateListener(async ({ batteryState }) => {
      const states: Record<number, string> = {
        [Battery.BatteryState.CHARGING]: 'Đang sạc ⚡',
        [Battery.BatteryState.FULL]: 'Đã đầy 🔋',
        [Battery.BatteryState.UNPLUGGED]: 'Đang dùng',
        [Battery.BatteryState.UNKNOWN]: 'Không xác định',
      };
      setState(states[batteryState] || 'Không xác định');
      setLevel(await Battery.getBatteryLevelAsync());
    });
    const interval = setInterval(loadData, 30000);
    return () => { levelSub.remove(); stateSub.remove(); clearInterval(interval); };
  }, []);

  const loadData = async () => {
    setLevel(await Battery.getBatteryLevelAsync());
    const data = await StorageService.getSnapshots();
    const dayAgo = Date.now() - 24 * 60 * 60 * 1000;
    setSnaps(data.filter(s => s.timestamp > dayAgo));
    const w = await StorageService.getWeekData();
    if (w) setWeekly(w);
  };

  const onRefresh = async () => {
    setRefreshing(true);
    await loadData();
    setRefreshing(false);
  };

  const chartData = {
    labels: snaps.map(s => {
      const d = new Date(s.timestamp);
      return `${d.getHours()}:${String(d.getMinutes()).padStart(2, '0')}`;
    }),
    datasets: [{
      data: snaps.length > 0 ? snaps.map(s => s.level * 100) : [0],
    }],
  };

  const fmt = (s: number) => {
    const h = Math.floor(s / 3600);
    const m = Math.floor((s % 3600) / 60);
    return `${h}h ${m}m`;
  };

  return (
    <ScrollView 
      style={styles.container} 
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor="#4A90E2" />}
    >
      <LinearGradient colors={['#1a1a2e', '#16213e']} style={styles.header}>
        <Text style={styles.headerTitle}>🔋 Battery Monitor</Text>
        <Text style={styles.headerSub}>Theo dõi pin thông minh</Text>
      </LinearGradient>

      <View style={styles.circleContainer}>
        <LinearGradient
          colors={['#4A90E2', '#2ECC71']}
          style={styles.circleGradient}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
        >
          <View style={styles.circle}>
            <Text style={styles.percentage}>{Math.round(level * 100)}%</Text>
            <Text style={styles.state}>{state}</Text>
          </View>
        </LinearGradient>
      </View>

      {snaps.length > 2 && (
        <View style={styles.card}>
          <Text style={styles.cardTitle}>📈 Biểu đồ pin (24h)</Text>
          <LineChart
            data={chartData}
            width={Dimensions.get('window').width - 40}
            height={200}
            chartConfig={{
              backgroundColor: '#16213e',
              backgroundGradientFrom: '#16213e',
              backgroundGradientTo: '#16213e',
              decimalCount: 0,
              color: (opacity = 1) => `rgba(74, 144, 226, ${opacity})`,
              labelColor: () => '#fff',
              style: { borderRadius: 16 },
            }}
            bezier
            style={{ marginVertical: 8, borderRadius: 16 }}
          />
        </View>
      )}

      {weekly && (
        <View style={styles.card}>
          <Text style={styles.cardTitle}>📊 Tổng quan tuần</Text>
          <View style={styles.statsRow}>
            <View style={styles.stat}>
              <Text style={styles.statValue}>{weekly.totalCharges}</Text>
              <Text style={styles.statLabel}>Lần sạc</Text>
            </View>
            <View style={styles.stat}>
              <Text style={styles.statValue}>{fmt(weekly.totalChargingTime)}</Text>
              <Text style={styles.statLabel}>Thời gian</Text>
            </View>
            <View style={styles.stat}>
              <Text style={styles.statValue}>{Math.round(weekly.totalBatteryDrain * 100)}%</Text>
              <Text style={styles.statLabel}>Pin dùng</Text>
            </View>
          </View>
        </View>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#0f0f1a' },
  header: { padding: 20, paddingTop: 40, paddingBottom: 30 },
  headerTitle: { fontSize: 28, fontWeight: 'bold', color: '#fff' },
  headerSub: { fontSize: 14, color: '#888', marginTop: 4 },
  circleContainer: { alignItems: 'center', marginVertical: 20 },
  circleGradient: { borderRadius: 110, padding: 3 },
  circle: {
    width: 200, height: 200, borderRadius: 100,
    backgroundColor: '#0f0f1a',
    justifyContent: 'center', alignItems: 'center',
  },
  percentage: { fontSize: 48, fontWeight: 'bold', color: '#4A90E2' },
  state: { fontSize: 14, color: '#888', marginTop: 5 },
  card: { backgroundColor: '#16213e', marginHorizontal: 20, padding: 20, borderRadius: 15, marginBottom: 15 },
  cardTitle: { color: '#fff', fontSize: 18, fontWeight: 'bold', marginBottom: 15 },
  statsRow: { flexDirection: 'row', justifyContent: 'space-around' },
  stat: { alignItems: 'center' },
  statValue: { color: '#4A90E2', fontSize: 24, fontWeight: 'bold' },
  statLabel: { color: '#888', fontSize: 12, marginTop: 5 },
});
