import React, { useEffect, useState } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Ionicons } from '@expo/vector-icons';
import { StatusBar } from 'expo-status-bar';
import { BatteryService } from './src/services/BatteryService';
import { StorageService } from './src/services/StorageService';
import SetupScreen from './src/screens/SetupScreen';
import DashboardScreen from './src/screens/DashboardScreen';
import HistoryScreen from './src/screens/HistoryScreen';
import NotificationsScreen from './src/screens/NotificationsScreen';
import SettingsScreen from './src/screens/SettingsScreen';

const Tab = createBottomTabNavigator();
const batteryService = new BatteryService();

export default function App() {
  const [configured, setConfigured] = useState(true);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    checkConfig();
  }, []);

  const checkConfig = async () => {
    // Bỏ qua setup vì đã bỏ webhook
    setConfigured(true);
    await batteryService.init();
    setLoading(false);
  };

  if (loading) return null;

  return (
    <>
      <StatusBar style="light" />
      <NavigationContainer>
        <Tab.Navigator
          screenOptions={({ route }) => ({
            tabBarIcon: ({ focused, color, size }) => {
              let iconName: keyof typeof Ionicons.glyphMap = 'home';
              if (route.name === 'Tổng quan') iconName = 'battery-charging';
              else if (route.name === 'Lịch sử') iconName = 'time';
              else if (route.name === 'Thông báo') iconName = 'notifications';
              else if (route.name === 'Cài đặt') iconName = 'settings';
              return <Ionicons name={iconName} size={size} color={color} />;
            },
            tabBarStyle: {
              backgroundColor: '#0f0f1a',
              borderTopColor: '#1a1a2e',
              height: 60,
              paddingBottom: 10,
              paddingTop: 5,
            },
            tabBarActiveTintColor: '#4A90E2',
            tabBarInactiveTintColor: '#666',
            headerStyle: { backgroundColor: '#0f0f1a' },
            headerTintColor: '#fff',
          })}
        >
          <Tab.Screen name="Tổng quan" component={DashboardScreen} />
          <Tab.Screen name="Lịch sử" component={HistoryScreen} />
          <Tab.Screen name="Thông báo" component={NotificationsScreen} />
          <Tab.Screen name="Cài đặt" component={SettingsScreen} />
        </Tab.Navigator>
      </NavigationContainer>
    </>
  );
}
