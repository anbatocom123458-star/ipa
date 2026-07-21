import React, { useState } from 'react';
import { View, Text, StyleSheet, Switch, TouchableOpacity } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import * as Battery from 'expo-battery';

export default function SettingsScreen() {
  const [notifications, setNotifications] = useState(true);
  const [backgroundRefresh, setBackgroundRefresh] = useState(true);

  const handleExportData = () => {
    // TODO: Export data
  };

  const handleClearData = () => {
    // TODO: Clear data
  };

  return (
    <View style={styles.container}>
      <View style={styles.card}>
        <Text style={styles.sectionTitle}>🔔 Thông báo</Text>
        <View style={styles.settingItem}>
          <Text style={styles.settingLabel}>Thông báo trong app</Text>
          <Switch value={notifications} onValueChange={setNotifications} trackColor={{ false: '#333', true: '#4A90E2' }} />
        </View>
        <View style={styles.settingItem}>
          <Text style={styles.settingLabel}>Làm mới nền</Text>
          <Switch value={backgroundRefresh} onValueChange={setBackgroundRefresh} trackColor={{ false: '#333', true: '#4A90E2' }} />
        </View>
      </View>

      <View style={styles.card}>
        <Text style={styles.sectionTitle}>📊 Dữ liệu</Text>
        <TouchableOpacity style={styles.menuItem} onPress={handleExportData}>
          <Ionicons name="download-outline" size={24} color="#4A90E2" />
          <Text style={styles.menuText}>Xuất dữ liệu</Text>
          <Ionicons name="chevron-forward" size={20} color="#666" style={styles.menuArrow} />
        </TouchableOpacity>
        <TouchableOpacity style={styles.menuItem} onPress={handleClearData}>
          <Ionicons name="trash-outline" size={24} color="#E74C3C" />
          <Text style={[styles.menuText, { color: '#E74C3C' }]}>Xóa dữ liệu</Text>
          <Ionicons name="chevron-forward" size={20} color="#666" style={styles.menuArrow} />
        </TouchableOpacity>
      </View>

      <View style={styles.card}>
        <Text style={styles.sectionTitle}>ℹ️ Thông tin</Text>
        <View style={styles.settingItem}>
          <Text style={styles.settingLabel}>Phiên bản</Text>
          <Text style={styles.settingValue}>1.0.0</Text>
        </View>
        <View style={styles.settingItem}>
          <Text style={styles.settingLabel}>Thiết bị</Text>
          <Text style={styles.settingValue}>{Battery.isAvailableAsync() ? 'Hỗ trợ' : 'Không hỗ trợ'}</Text>
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#0f0f1a', padding: 15 },
  card: { backgroundColor: '#16213e', borderRadius: 15, padding: 15, marginBottom: 15 },
  sectionTitle: { color: '#fff', fontSize: 18, fontWeight: 'bold', marginBottom: 15 },
  settingItem: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingVertical: 12, borderBottomWidth: 1, borderBottomColor: '#1a1a4e' },
  settingLabel: { color: '#fff', fontSize: 16 },
  settingValue: { color: '#888', fontSize: 16 },
  menuItem: { flexDirection: 'row', alignItems: 'center', paddingVertical: 12, borderBottomWidth: 1, borderBottomColor: '#1a1a4e' },
  menuText: { color: '#fff', fontSize: 16, marginLeft: 15, flex: 1 },
  menuArrow: { marginLeft: 'auto' },
});
