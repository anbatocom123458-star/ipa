import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var monitor: BatteryMonitor
    @State private var showResetAlert = false

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Thông báo")) {
                    Toggle("Cảnh báo dùng quá 8 tiếng", isOn: .constant(true))
                    Toggle("Cảnh báo pin < 20%", isOn: .constant(true))
                    Toggle("Cảnh báo sạc quá 4 tiếng", isOn: .constant(true))
                }

                Section(header: Text("Dữ liệu")) {
                    HStack {
                        Text("Tổng thời gian đã ghi nhận")
                        Spacer()
                        Text(String(format: "%.1f giờ", monitor.totalUsageHours))
                            .foregroundColor(.gray)
                    }

                    HStack {
                        Text("Số lần sạc đã ghi nhận")
                        Spacer()
                        Text("\(monitor.chargeCount)")
                            .foregroundColor(.gray)
                    }

                    HStack {
                        Text("Số lần sạc ghi lại chi tiết")
                        Spacer()
                        Text("\(monitor.chargeHistory.count)")
                            .foregroundColor(.gray)
                    }

                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Label("Xóa toàn bộ lịch sử", systemImage: "trash")
                    }
                }

                Section(header: Text("Thông tin")) {
                    HStack {
                        Text("Phiên bản")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }

                    HStack {
                        Text("Nguồn dữ liệu pin")
                        Spacer()
                        Text("IOKit / AppleSmartBattery")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Text("Ứng dụng sử dụng IOKit framework để đọc trực tiếp thông số phần cứng pin từ hệ thống iOS. Dữ liệu được lưu trữ cục bộ trên thiết bị.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Cài đặt")
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
        }
    }
}
