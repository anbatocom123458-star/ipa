import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var monitor: BatteryMonitor
    @State private var appear = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#0a0f0a").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        VStack(spacing: 14) {
                            HStack(spacing: 14) {
                                SummaryMiniCard(
                                    icon: "arrow.2.circlepath",
                                    color: Color(hex: "#c084fc"),
                                    label: "Tổng chu kỳ",
                                    value: "\(monitor.cycleCount)",
                                    delay: 0.1
                                )
                                SummaryMiniCard(
                                    icon: "bolt.fill",
                                    color: Color(hex: "#fbbf24"),
                                    label: "Tổng lần sạc",
                                    value: "\(monitor.chargeCount)",
                                    delay: 0.2
                                )
                            }
                            HStack(spacing: 14) {
                                SummaryMiniCard(
                                    icon: "clock.fill",
                                    color: Color(hex: "#60a5fa"),
                                    label: "Tổng giờ dùng",
                                    value: String(format: "%.1f h", monitor.totalUsageHours),
                                    delay: 0.3
                                )
                                SummaryMiniCard(
                                    icon: "heart.fill",
                                    color: Color(hex: "#f87171"),
                                    label: "Sức khỏe pin",
                                    value: String(format: "%.0f%%", monitor.healthPercentage),
                                    delay: 0.4
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 10)

                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "list.bullet.rectangle.fill")
                                    .foregroundColor(Color(hex: "#4ade80"))
                                Text("Lịch sử sạc gần đây")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(monitor.chargeHistory.count) lần")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.06))
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal, 16)

                            if monitor.chargeHistory.isEmpty {
                                EmptyHistoryView()
                                    .padding(.horizontal, 16)
                            } else {
                                VStack(spacing: 10) {
                                    ForEach(Array(monitor.chargeHistory.prefix(15).enumerated()), id: \.element.id) { index, session in
                                        ChargeRow(session: session, index: index)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.5), value: appear)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "chart.pie.fill")
                                        .foregroundColor(Color(hex: "#fb923c"))
                                    Text("Thống kê sử dụng")
                                        .font(.system(size: 17, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Spacer()
                                }

                                StatRow(label: "Thời gian sử dụng TB / lần sạc", value: avgUsagePerCharge)
                                DividerLine()
                                StatRow(label: "Thời gian sạc TB", value: avgChargeTime)
                                DividerLine()
                                StatRow(label: "Tốc độ sạc TB", value: avgChargeSpeed)
                            }
                            .padding()
                        }
                        .padding(.horizontal, 16)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.6), value: appear)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Lịch sử")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                appear = true
            }
        }
    }

    var avgUsagePerCharge: String {
        guard monitor.chargeCount > 0 else { return "--" }
        let avg = monitor.totalUsageHours / Double(monitor.chargeCount)
        return String(format: "%.1f giờ", avg)
    }

    var avgChargeTime: String {
        guard !monitor.chargeHistory.isEmpty else { return "--" }
        let total = monitor.chargeHistory.reduce(0) { $0 + $1.duration }
        let avg = total / Double(monitor.chargeHistory.count)
        let mins = Int(avg) / 60
        return "\(mins) phút"
    }

    var avgChargeSpeed: String {
        guard !monitor.chargeHistory.isEmpty else { return "--" }
        let totalPercent = monitor.chargeHistory.reduce(0) { $0 + ($1.endLevel - $1.startLevel) }
        let totalTime = monitor.chargeHistory.reduce(0) { $0 + $1.duration }
        guard totalTime > 0 else { return "--" }
        let speed = Double(totalPercent) / (totalTime / 60.0)
        return String(format: "%.1f %%/phút", speed)
    }
}

struct SummaryMiniCard: View {
    let icon: String
    let color: Color
    let label: String
    let value: String
    let delay: Double
    @State private var appear = false

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(color.opacity(0.15), lineWidth: 1)
                )
        )
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 15)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(delay)) {
                appear = true
            }
        }
    }
}

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#4ade80").opacity(0.08))
                    .frame(width: 100, height: 100)
                Image(systemName: "clock.badge.questionmark.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: "#4ade80").opacity(0.6))
            }

            Text("Chưa có dữ liệu sạc")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)

            Text("Dữ liệu sẽ được ghi lại tự động sau mỗi lần sạc")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

struct ChargeRow: View {
    let session: BatteryMonitor.ChargeSession
    let index: Int
    @State private var appear = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#4ade80").opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: "bolt.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "#4ade80"))
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(session.startTime, style: .date)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                HStack(spacing: 6) {
                    Text(session.formattedDuration)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "#4ade80"))

                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 4, height: 4)

                    Text("\(session.startLevel)% → \(session.endLevel)%")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            Text(session.startTime, style: .time)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
        .opacity(appear ? 1 : 0)
        .offset(x: appear ? 0 : 20)
        .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.05), value: appear)
        .onAppear {
            appear = true
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "#4ade80"))
        }
    }
}

struct DividerLine: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 1)
            .padding(.leading, 44)
    }
}
