import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var monitor: BatteryMonitor
    @State private var showResetAlert = false
    @State private var appear = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#0a0f0a").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "#4ade80").opacity(0.15))
                                    .frame(width: 90, height: 90)
                                    .blur(radius: 10)

                                Image(systemName: "bolt.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(Color(hex: "#4ade80"))
                                    .symbolRenderingMode(.multicolor)
                            }

                            Text("Battery Manager")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text("Phiên bản 1.0.0")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 20)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)
                        .animation(.easeOut(duration: 0.5), value: appear)

                        SettingsSection(title: "Thông báo", icon: "bell.badge.fill", color: Color(hex: "#fb923c")) {
                            VStack(spacing: 0) {
                                ToggleRow(icon: "hourglass", color: Color(hex: "#60a5fa"), title: "Cảnh báo dùng > 8 tiếng")
                                DividerLine()
                                ToggleRow(icon: "battery.25", color: Color(hex: "#ef4444"), title: "Cảnh báo pin < 20%")
                                DividerLine()
                                ToggleRow(icon: "bolt.batteryblock.fill", color: Color(hex: "#fbbf24"), title: "Cảnh báo sạc > 4 tiếng")
                            }
                        }
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.1), value: appear)

                        SettingsSection(title: "Dữ liệu", icon: "externaldrive.fill", color: Color(hex: "#60a5fa")) {
                            VStack(spacing: 0) {
                                DataRow(label: "Tổng thời gian đã ghi nhận", value: String(format: "%.1f giờ", monitor.totalUsageHours))
                                DividerLine()
                                DataRow(label: "Số lần sạc đã ghi nhận", value: "\(monitor.chargeCount)")
                                DividerLine()
                                DataRow(label: "Số lần sạc chi tiết", value: "\(monitor.chargeHistory.count)")
                                DividerLine()

                                Button(role: .destructive) {
                                    let impact = UIImpactFeedbackGenerator(style: .heavy)
                                    impact.impactOccurred()
                                    showResetAlert = true
                                } label: {
                                    HStack {
                                        Image(systemName: "trash")
                                            .font(.system(size: 16))
                                        Text("Xóa toàn bộ lịch sử")
                                            .font(.system(size: 15, weight: .semibold))
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.gray)
                                    }
                                    .foregroundColor(Color(hex: "#ef4444"))
                                    .padding(.vertical, 14)
                                }
                            }
                        }
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.2), value: appear)

                        SettingsSection(title: "Thông tin", icon: "info.circle.fill", color: Color(hex: "#c084fc")) {
                            VStack(spacing: 0) {
                                DataRow(label: "Phiên bản", value: "1.0.0")
                                DividerLine()
                                DataRow(label: "Nguồn dữ liệu pin", value: "IOKit / AppleSmartBattery")
                                DividerLine()
                                DataRow(label: "Framework", value: "SwiftUI + IOKit")
                            }
                        }
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.3), value: appear)

                        Text("Ứng dụng sử dụng IOKit framework để đọc trực tiếp thông số phần cứng pin từ hệ thống iOS. Dữ liệu được lưu trữ cục bộ trên thiết bị.")
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.3))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.top, 8)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Cài đặt")
            .navigationBarTitleDisplayMode(.large)
            .alert("Xác nhận xóa", isPresented: $showResetAlert) {
                Button("Hủy", role: .cancel) {}
                Button("Xóa", role: .destructive) {
                    UserDefaults.standard.removeObject(forKey: "chargeHistory")
                    UserDefaults.standard.removeObject(forKey: "totalChargeCount")
                    UserDefaults.standard.removeObject(forKey: "totalUsageHours")
                    UserDefaults.standard.removeObject(forKey: "cycleCount")
                    monitor.chargeHistory.removeAll()
                    monitor.chargeCount = 0
                    monitor.totalUsageHours = 0
                }
            } message: {
                Text("Thao tác này không thể hoàn tác. Toàn bộ lịch sử sạc và thống kê sẽ bị xóa.")
            }
            .onAppear {
                appear = true
            }
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.7))
                    .textCase(.uppercase)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content
            }
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 16)
    }
}

struct ToggleRow: View {
    let icon: String
    let color: Color
    let title: String
    @State private var isOn = true

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
            }

            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#4ade80")))
                .scaleEffect(0.85)
        }
        .padding(.vertical, 12)
    }
}

struct DataRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 14)
    }
}
