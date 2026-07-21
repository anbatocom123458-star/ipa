import React, { useEffect, useState } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Text } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { BatteryService } from './src/services/BatteryService';
import SetupScreen from './src/screens/SetupScreen';
import DashboardScreen from './src/screens/DashboardScreen';
import HistoryScreen from './src/screens/HistoryScreen';

const Tab = createBottomTabNavigator();
const batteryService = new BatteryService();

export default function App() {
  const [configured, setConfigured] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    checkConfig();
  }, []);

  const checkConfig = async () => {
    try {
      const data = await AsyncStorage.getItem('webhook_config');
      if (data) {
        setConfigured(true);
        await batteryService.init();
      }
    } catch (error) {
      console.error('Config check failed:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) return null;

  if (!configured) {
    return <SetupScreen onComplete={() => {
      setConfigured(true);
      batteryService.init();
    }} />;
  }

  return (
    <NavigationContainer>
      <Tab.Navigator
        screenOptions={{
          tabBarStyle: {
            backgroundColor: '#16213e',
            borderTopColor: '#1a1a4e',
            height: 60,
            paddingBottom: 10,
            paddingTop: 5,
          },
          tabBarActiveTintColor: '#e94560',
          tabBarInactiveTintColor: '#666',
          headerStyle: { backgroundColor: '#16213e' },
          headerTintColor: '#fff',
        }}
      >
        <Tab.Screen
          name="Dashboard"
          component={DashboardScreen}
          options={{
            tabBarLabel: 'Tổng quan',
            headerTitle: '🔋 BatteryWebhook',
            tabBarIcon: ({ color }) => <Text style={{ fontSize: 24 }}>📊</Text>,
          }}
        />
        <Tab.Screen
          name="History"
          component={HistoryScreen}
          options={{
            tabBarLabel: 'Lịch sử',
            headerTitle: '📅 Lịch sử sạc',
            tabBarIcon: ({ color }) => <Text style={{ fontSize: 24 }}>📅</Text>,
          }}
        />
      </Tab.Navigator>
    </NavigationContainer>
  );
}
