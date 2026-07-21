import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var monitor: BatteryMonitor

    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            StatSummaryItem(icon: "arrow.2.circlepath", color: .purple, label: "Tổng chu kỳ", value: "\(monitor.cycleCount)")
                            Divider()
                            StatSummaryItem(icon: "bolt.fill", color: .yellow, label: "Tổng lần sạc", value: "\(monitor.chargeCount)")
                        }
                        Divider()
                        HStack {
                            StatSummaryItem(icon: "clock.fill", color: .blue, label: "Tổng giờ dùng", value: String(format: "%.1f h", monitor.totalUsageHours))
                            Divider()
                            StatSummaryItem(icon: "heart.fill", color: .red, label: "Sức khỏe pin", value: String(format: "%.0f%%", monitor.healthPercentage))
                        }
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color(.systemGray6))

                Section(header: Text("Lịch sử sạc gần đây").font(.caption)) {
                    if monitor.chargeHistory.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "clock.badge.questionmark.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("Chưa có dữ liệu sạc")
                                    .foregroundColor(.gray)
                                Text("Dữ liệu sẽ được ghi lại sau mỗi lần sạc")
                                    .font(.caption)
                                    .foregroundColor(.gray.opacity(0.7))
                            }
                            .padding()
                            Spacer()
                        }
                    } else {
                        ForEach(monitor.chargeHistory.prefix(20)) { session in
                            ChargeRow(session: session)
                        }
                    }
                }

                Section(header: Text("Thống kê sử dụng").font(.caption)) {
                    HStack {
                        Text("Thời gian sử dụng trung bình/lần sạc")
                            .font(.subheadline)
                        Spacer()
                        if monitor.chargeCount > 0 {
                            let avg = monitor.totalUsageHours / Double(monitor.chargeCount)
                            Text(String(format: "%.1f giờ", avg))
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        } else {
                            Text("--")
                                .foregroundColor(.gray)
                        }
                    }

                    HStack {
                        Text("Thời gian sạc trung bình")
                            .font(.subheadline)
                        Spacer()
                        if !monitor.chargeHistory.isEmpty {
                            let total = monitor.chargeHistory.reduce(0) { $0 + $1.duration }
                            let avg = total / Double(monitor.chargeHistory.count)
                            let mins = Int(avg) / 60
                            Text("\(mins) phút")
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        } else {
                            Text("--")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Lịch sử")
        }
    }
}

struct StatSummaryItem: View {
    let icon: String
    let color: Color
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline.bold())
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ChargeRow: View {
    let session: BatteryMonitor.ChargeSession

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: "bolt.fill")
                    .foregroundColor(.green)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(session.startTime, style: .date)
                    .font(.subheadline.bold())
                Text("\(session.formattedDuration) • \(session.startLevel)% → \(session.endLevel)%")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Text(session.startTime, style: .time)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}
