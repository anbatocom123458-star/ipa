import React, { useEffect, useState } from 'react';
import { View, Text, ScrollView, StyleSheet, Dimensions } from 'react-native';
import * as Battery from 'expo-battery';
import { LineChart } from 'react-native-chart-kit';
import { StorageService } from '../services/StorageService';
import { BatterySnapshot, WeeklyReport } from '../types';

export default function DashboardScreen() {
  const [level, setLevel] = useState(0);
  const [state, setState] = useState('Không xác định');
  const [snaps, setSnaps] = useState<BatterySnapshot[]>([]);
  const [weekly, setWeekly] = useState<WeeklyReport | null>(null);

  useEffect(() => {
    loadData();
    const sub = Battery.addBatteryStateListener(({ batteryState }) => {
      const states: Record<number, string> = {
        [Battery.BatteryState.CHARGING]: 'Đang sạc ⚡',
        [Battery.BatteryState.FULL]: 'Đã đầy 🔋',
        [Battery.BatteryState.UNPLUGGED]: 'Đang dùng',
        [Battery.BatteryState.UNKNOWN]: 'Không xác định',
      };
      setState(states[batteryState] || 'Không xác định');
    });

    const interval = setInterval(loadData, 30000);
    return () => { sub.remove(); clearInterval(interval); };
  }, []);

  const loadData = async () => {
    const lvl = await Battery.getBatteryLevelAsync();
    setLevel(lvl);
    const data = await StorageService.getSnapshots();
    setSnaps(data.slice(-24));
    const w = await StorageService.getWeekData();
    if (w) setWeekly(w);
  };

  const chartData = {
    labels: snaps.map(s => {
      const d = new Date(s.timestamp);
      return `${d.getHours()}:${String(d.getMinutes()).padStart(2, '0')}`;
    }),
    datasets: [{
      data: snaps.length > 0 ? snaps.map(s => s.level * 100) : [0],
      color: (opacity = 1) => `rgba(233, 69, 96, ${opacity})`,
      strokeWidth: 2,
    }],
  };

  const fmt = (s: number) => {
    const h = Math.floor(s / 3600);
    const m = Math.floor((s % 3600) / 60);
    return `${h}h ${m}m`;
  };

  return (
    <ScrollView style={styles.container}>
      <View style={styles.circleContainer}>
        <View style={styles.circle}>
          <Text style={styles.percentage}>{Math.round(level * 100)}%</Text>
          <Text style={styles.state}>{state}</Text>
        </View>
      </View>

      {snaps.length > 2 && (
        <View style={styles.card}>
          <Text style={styles.cardTitle}>📈 Biểu đồ pin (24h)</Text>
          <LineChart
            data={chartData}
            width={Dimensions.get('window').width - 60}
            height={220}
            chartConfig={{
              backgroundColor: '#16213e',
              backgroundGradientFrom: '#16213e',
              backgroundGradientTo: '#16213e',
              decimalCount: 0,
              color: (opacity = 1) => `rgba(233, 69, 96, ${opacity})`,
              labelColor: () => '#fff',
              style: { borderRadius: 16 },
              propsForDots: { r: '4', strokeWidth: '2', stroke: '#e94560' },
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
  container: { flex: 1, backgroundColor: '#1a1a2e', padding: 20 },
  circleContainer: { alignItems: 'center', marginVertical: 20 },
  circle: {
    width: 200, height: 200, borderRadius: 100, backgroundColor: '#16213e',
    justifyContent: 'center', alignItems: 'center', borderWidth: 3, borderColor: '#4A90E2',
  },
  percentage: { fontSize: 48, fontWeight: 'bold', color: '#4A90E2' },
  state: { fontSize: 14, color: '#888', marginTop: 5 },
  card: { backgroundColor: '#16213e', padding: 20, borderRadius: 15, marginBottom: 15 },
  cardTitle: { color: '#fff', fontSize: 18, fontWeight: 'bold', marginBottom: 15 },
  statsRow: { flexDirection: 'row', justifyContent: 'space-around' },
  stat: { alignItems: 'center' },
  statValue: { color: '#e94560', fontSize: 24, fontWeight: 'bold' },
  statLabel: { color: '#888', fontSize: 12, marginTop: 5 },
});
