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
        .accentColor(Color(hex: "#4ade80"))
        .environmentObject(monitor)
    }
}

// MARK: - Dashboard
struct DashboardView: View {
    @EnvironmentObject var monitor: BatteryMonitor
    @State private var appear = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#0a0f0a").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        BatteryRingView()
                            .frame(height: 260)
                            .padding(.top, 10)
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : 30)
                            .animation(.easeOut(duration: 0.6).delay(0.1), value: appear)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            StatCard(
                                icon: "bolt.fill",
                                gradient: [Color(hex: "#fbbf24"), Color(hex: "#f59e0b")],
                                title: "Số lần sạc",
                                value: "\(monitor.chargeCount)",
                                unit: "lần",
                                delay: 0.2
                            )
                            StatCard(
                                icon: "clock.fill",
                                gradient: [Color(hex: "#60a5fa"), Color(hex: "#3b82f6")],
                                title: "Thời gian sử dụng",
                                value: String(format: "%.1f", monitor.totalUsageHours),
                                unit: "giờ",
                                delay: 0.3
                            )
                            StatCard(
                                icon: "arrow.2.circlepath",
                                gradient: [Color(hex: "#c084fc"), Color(hex: "#a855f7")],
                                title: "Chu kỳ sạc",
                                value: "\(monitor.cycleCount)",
                                unit: "chu kỳ",
                                delay: 0.4
                            )
                            StatCard(
                                icon: "heart.fill",
                                gradient: [Color(hex: "#f87171"), Color(hex: "#ef4444")],
                                title: "Sức khỏe pin",
                                value: String(format: "%.0f", monitor.healthPercentage),
                                unit: "%",
                                delay: 0.5
                            )
                        }
                        .padding(.horizontal, 16)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "doc.text.magnifyingglass")
                                        .foregroundColor(Color(hex: "#4ade80"))
                                    Text("Thông số chi tiết")
                                        .font(.system(size: 17, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Spacer()
                                }

                                VStack(spacing: 14) {
                                    DetailRow(icon: "thermometer", color: Color(hex: "#fb923c"), label: "Nhiệt độ pin", value: "\(String(format: "%.1f", monitor.temperature))°C")
                                    DetailRow(icon: "bolt.fill", color: Color(hex: "#fbbf24"), label: "Điện áp", value: "\(String(format: "%.2f", monitor.voltage))V")
                                    DetailRow(icon: "waveform", color: Color(hex: "#22d3ee"), label: "Dòng điện", value: "\(monitor.amperage) mA")
                                    DetailRow(icon: "cube.box", color: Color(hex: "#94a3b8"), label: "Dung lượng thiết kế", value: "\(monitor.designCapacity) mAh")
                                    DetailRow(icon: "cube.box.fill", color: Color(hex: "#4ade80"), label: "Dung lượng tối đa", value: "\(monitor.maxCapacity) mAh")

                                    if monitor.lastChargeDuration > 0 {
                                        let mins = Int(monitor.lastChargeDuration) / 60
                                        DetailRow(icon: "timer", color: Color(hex: "#f472b6"), label: "Lần sạc gần nhất", value: "\(mins) phút")
                                    }
                                }
                            }
                            .padding()
                        }
                        .padding(.horizontal, 16)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.6), value: appear)

                        StatusBanner()
                            .padding(.horizontal, 16)
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : 20)
                            .animation(.easeOut(duration: 0.5).delay(0.7), value: appear)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Battery Manager")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    BatteryIndicator()
                }
            }
            .onAppear {
                appear = true
            }
        }
    }
}

struct BatteryRingView: View {
    @EnvironmentObject var monitor: BatteryMonitor
    @State private var animatedLevel: CGFloat = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(monitor.batteryColor.opacity(0.08))
                .frame(width: 260, height: 260)
                .blur(radius: 30)

            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 24)
                .frame(width: 220, height: 220)

            Circle()
                .trim(from: 0, to: animatedLevel / 100.0)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            monitor.batteryColor.opacity(0.3),
                            monitor.batteryColor,
                            monitor.batteryColor.opacity(0.8)
                        ]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 24, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 220, height: 220)
                .shadow(color: monitor.batteryColor.opacity(0.5), radius: 15, x: 0, y: 0)

            VStack(spacing: 8) {
                Text("\(monitor.batteryLevel)%")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                HStack(spacing: 6) {
                    Image(systemName: monitor.isCharging ? "bolt.fill" : "minus")
                        .font(.system(size: 13, weight: .bold))
                    Text(monitor.batteryStatusText)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundColor(monitor.batteryColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(monitor.batteryColor.opacity(0.15))
                .cornerRadius(20)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animatedLevel = CGFloat(monitor.batteryLevel)
            }
        }
        .onChange(of: monitor.batteryLevel) { newLevel in
            withAnimation(.easeOut(duration: 0.8)) {
                animatedLevel = CGFloat(newLevel)
            }
        }
    }
}

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.05))
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
    }
}

struct StatCard: View {
    let icon: String
    let gradient: [Color]
    let title: String
    let value: String
    let unit: String
    let delay: Double
    @State private var appear = false

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                                .opacity(0.2)
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(colors: gradient, startPoint: .top, endPoint: .bottom)
                        )
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(unit)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.white.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(delay)) {
                appear = true
            }
        }
    }
}

struct DetailRow: View {
    let icon: String
    let color: Color
    let label: String
    let value: String

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

            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.white.opacity(0.6))

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

struct StatusBanner: View {
    @EnvironmentObject var monitor: BatteryMonitor

    var bannerColor: Color {
        if monitor.isFullyCharged { return Color(hex: "#4ade80") }
        if monitor.isCharging { return Color(hex: "#22c55e") }
        if monitor.batteryLevel <= 20 { return Color(hex: "#ef4444") }
        return Color(hex: "#3b82f6")
    }

    var iconName: String {
        if monitor.isFullyCharged { return "checkmark.shield.fill" }
        if monitor.isCharging { return "bolt.fill" }
        if monitor.batteryLevel <= 20 { return "exclamationmark.triangle.fill" }
        return "iphone"
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(bannerColor.opacity(0.2))
                    .frame(width: 36, height: 36)
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(bannerColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(monitor.batteryStatusText)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                if monitor.isCharging {
                    Text(monitor.isFullyCharged ? "Đã đầy - ngắt sạc để bảo vệ pin" : "Đang sạc \(monitor.batteryLevel)%")
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.6))
                } else if monitor.batteryLevel <= 20 {
                    Text("Pin yếu - hãy cắm sạc sớm")
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.6))
                }
            }

            Spacer()

            if monitor.isCharging && !monitor.isFullyCharged {
                ChargingAnimation()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(bannerColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(bannerColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct ChargingAnimation: View {
    @State private var offset: CGFloat = -20

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color(hex: "#4ade80"))
                    .frame(width: 6, height: 6)
                    .opacity(offset > CGFloat(i) * 8 ? 1 : 0.3)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(Double(i) * 0.15), value: offset)
            }
        }
        .onAppear {
            offset = 30
        }
    }
}

struct BatteryIndicator: View {
    @EnvironmentObject var monitor: BatteryMonitor

    var body: some View {
        HStack(spacing: 6) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(monitor.batteryColor.opacity(0.5), lineWidth: 1.5)
                    .frame(width: 24, height: 12)

                RoundedRectangle(cornerRadius: 2)
                    .fill(monitor.batteryColor)
                    .frame(width: max(2, CGFloat(monitor.batteryLevel) / 100.0 * 20), height: 8)
                    .padding(.leading, 2)
            }

            Text("\(monitor.batteryLevel)%")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(monitor.batteryColor)
        }
    }
}
