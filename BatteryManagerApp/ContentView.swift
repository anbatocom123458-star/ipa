import SwiftUI

struct ContentView: View {
    @StateObject private var monitor = BatteryMonitor.shared
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Tổng quan", systemImage: "gauge.with.dots.needle.67percent")
                }
                .tag(0)

            HistoryView()
                .tabItem {
                    Label("Lịch sử", systemImage: "clock.arrow.circlepath")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Cài đặt", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .accentColor(.green)
        .environmentObject(monitor)
    }
}

// MARK: - Dashboard
struct DashboardView: View {
    @EnvironmentObject var monitor: BatteryMonitor

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Battery Ring
                    BatteryRingView()
                        .frame(height: 220)
                        .padding(.top, 10)

                    // Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(
                            icon: "bolt.fill",
                            color: .yellow,
                            title: "Số lần sạc",
                            value: "\(monitor.chargeCount)",
                            unit: "lần"
                        )
                        StatCard(
                            icon: "clock.fill",
                            color: .blue,
                            title: "Thời gian sử dụng",
                            value: String(format: "%.1f", monitor.totalUsageHours),
                            unit: "giờ"
                        )
                        StatCard(
                            icon: "arrow.2.circlepath",
                            color: .purple,
                            title: "Chu kỳ sạc",
                            value: "\(monitor.cycleCount)",
                            unit: "chu kỳ"
                        )
                        StatCard(
                            icon: "heart.fill",
                            color: .red,
                            title: "Sức khỏe pin",
                            value: String(format: "%.0f", monitor.healthPercentage),
                            unit: "%"
                        )
                    }
                    .padding(.horizontal)

                    // Detailed Info Card
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Thông số chi tiết")
                            .font(.headline.bold())
                            .foregroundColor(.white)

                        DetailRow(icon: "thermometer", color: .orange, label: "Nhiệt độ pin", value: "\(String(format: "%.1f", monitor.temperature))°C")
                        DetailRow(icon: "bolt.fill", color: .yellow, label: "Điện áp", value: "\(String(format: "%.2f", monitor.voltage))V")
                        DetailRow(icon: "waveform", color: .cyan, label: "Dòng điện", value: "\(monitor.amperage) mA")
                        DetailRow(icon: "cube.box", color: .gray, label: "Dung lượng thiết kế", value: "\(monitor.designCapacity) mAh")
                        DetailRow(icon: "cube.box.fill", color: .green, label: "Dung lượng tối đa", value: "\(monitor.maxCapacity) mAh")

                        if monitor.lastChargeDuration > 0 {
                            let mins = Int(monitor.lastChargeDuration) / 60
                            DetailRow(icon: "timer", color: .pink, label: "Lần sạc gần nhất", value: "\(mins) phút")
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .padding(.horizontal)

                    // Status Banner
                    HStack {
                        Image(systemName: monitor.isCharging ? "bolt.fill" : "iphone")
                        Text(monitor.batteryStatusText)
                            .fontWeight(.semibold)
                        if monitor.isCharging {
                            Spacer()
                            Text(monitor.isFullyCharged ? "Đã đầy" : "\(monitor.batteryLevel)%")
                        }
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(monitor.isCharging ? Color.green.opacity(0.8) : Color.blue.opacity(0.8))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Battery Manager")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    BatteryIndicator()
                }
            }
        }
    }
}

struct BatteryRingView: View {
    @EnvironmentObject var monitor: BatteryMonitor

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 20)

            Circle()
                .trim(from: 0, to: CGFloat(monitor.batteryLevel) / 100.0)
                .stroke(
                    monitor.batteryColor,
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1), value: monitor.batteryLevel)

            VStack(spacing: 6) {
                Text("\(monitor.batteryLevel)%")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                HStack(spacing: 4) {
                    Image(systemName: monitor.isCharging ? "bolt.fill" : "minus")
                        .font(.caption)
                    Text(monitor.batteryStatusText)
                        .font(.caption.bold())
                }
                .foregroundColor(monitor.batteryColor)
            }
        }
        .padding(30)
    }
}

struct StatCard: View {
    let icon: String
    let color: Color
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title.bold())
                    .foregroundColor(.white)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(20)
    }
}

struct DetailRow: View {
    let icon: String
    let color: Color
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .font(.subheadline)
    }
}

struct BatteryIndicator: View {
    @EnvironmentObject var monitor: BatteryMonitor

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: monitor.isCharging ? "bolt.batteryblock.fill" : "battery.100")
                .foregroundColor(monitor.batteryColor)
            Text("\(monitor.batteryLevel)%")
                .font(.caption.bold())
                .foregroundColor(monitor.batteryColor)
        }
    }
}
