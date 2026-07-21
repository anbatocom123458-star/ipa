import React, { useState } from 'react';
import {
  View, Text, TextInput, TouchableOpacity, StyleSheet,
  Alert, ScrollView, KeyboardAvoidingView, Platform
} from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';

interface Props {
  onComplete: () => void;
}

export default function SetupScreen({ onComplete }: Props) {
  const [webhookUrl, setWebhookUrl] = useState('');
  const [avatarUrl, setAvatarUrl] = useState('');
  const [username, setUsername] = useState('');
  const [saving, setSaving] = useState(false);

  const handleSave = async () => {
    if (!webhookUrl.trim()) {
      Alert.alert('Lỗi', 'Vui lòng nhập Webhook URL');
      return;
    }
    if (!username.trim()) {
      Alert.alert('Lỗi', 'Vui lòng nhập tên hiển thị');
      return;
    }

    setSaving(true);
    try {
      const config = {
        webhookUrl: webhookUrl.trim(),
        avatarUrl: avatarUrl.trim() || 'https://i.imgur.com/fHPLi51.png',
        username: username.trim(),
      };
      await AsyncStorage.setItem('webhook_config', JSON.stringify(config));
      Alert.alert('Thành công', 'Đã lưu cấu hình!', [{ text: 'OK', onPress: onComplete }]);
    } catch (error) {
      Alert.alert('Lỗi', 'Không thể lưu cấu hình');
    } finally {
      setSaving(false);
    }
  };

  return (
    <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : 'height'} style={styles.container}>
      <ScrollView contentContainerStyle={styles.content}>
        <View style={styles.header}>
          <Text style={styles.icon}>🔋</Text>
          <Text style={styles.title}>BatteryWebhook</Text>
          <Text style={styles.subtitle}>Cấu hình thông báo pin</Text>
        </View>

        <View style={styles.form}>
          <Text style={styles.label}>Webhook URL *</Text>
          <TextInput
            style={styles.input}
            value={webhookUrl}
            onChangeText={setWebhookUrl}
            placeholder="https://discord.com/api/webhooks/..."
            placeholderTextColor="#666"
            autoCapitalize="none"
          />

          <Text style={styles.label}>Avatar URL</Text>
          <TextInput
            style={styles.input}
            value={avatarUrl}
            onChangeText={setAvatarUrl}
            placeholder="https://example.com/avatar.png"
            placeholderTextColor="#666"
            autoCapitalize="none"
          />

          <Text style={styles.label}>Tên hiển thị *</Text>
          <TextInput
            style={styles.input}
            value={username}
            onChangeText={setUsername}
            placeholder="My iPhone"
            placeholderTextColor="#666"
            maxLength={32}
          />

          <TouchableOpacity style={[styles.button, saving && styles.buttonDisabled]} onPress={handleSave} disabled={saving}>
            <Text style={styles.buttonText}>{saving ? 'Đang lưu...' : '💾 Lưu cấu hình'}</Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#1a1a2e' },
  content: { padding: 20 },
  header: { alignItems: 'center', marginVertical: 30 },
  icon: { fontSize: 60 },
  title: { fontSize: 32, fontWeight: 'bold', color: '#fff', marginTop: 10 },
  subtitle: { fontSize: 16, color: '#888', marginTop: 5 },
  form: { backgroundColor: '#16213e', borderRadius: 15, padding: 20 },
  label: { fontSize: 16, fontWeight: '600', color: '#fff', marginBottom: 8, marginTop: 15 },
  input: {
    backgroundColor: '#0f3460', borderRadius: 10, padding: 15,
    fontSize: 16, color: '#fff', borderWidth: 1, borderColor: '#1a1a4e'
  },
  button: { backgroundColor: '#e94560', borderRadius: 10, padding: 15, alignItems: 'center', marginTop: 20 },
  buttonDisabled: { opacity: 0.5 },
  buttonText: { color: '#fff', fontSize: 18, fontWeight: 'bold' },
});
