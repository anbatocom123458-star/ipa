import Foundation
import UIKit
import IOKit

class BatteryMonitor: ObservableObject {
    static let shared = BatteryMonitor()

    @Published var batteryLevel: Int = 0
    @Published var batteryState: UIDevice.BatteryState = .unknown
    @Published var cycleCount: Int = 0
    @Published var designCapacity: Int = 0
    @Published var maxCapacity: Int = 0
    @Published var temperature: Double = 0.0
    @Published var voltage: Double = 0.0
    @Published var amperage: Int = 0
    @Published var healthPercentage: Double = 100.0
    @Published var isCharging: Bool = false
    @Published var isFullyCharged: Bool = false
    @Published var totalUsageHours: Double = 0.0
    @Published var chargeCount: Int = 0
    @Published var lastChargeDuration: TimeInterval = 0
    @Published var chargeHistory: [ChargeSession] = []

    private var timer: Timer?
    private var chargeStartTime: Date?
    private var wasCharging = false
    private var lastLevel = -1

    struct ChargeSession: Identifiable, Codable {
        let id = UUID()
        let startTime: Date
        let endTime: Date
        let startLevel: Int
        let endLevel: Int
        let duration: TimeInterval

        var formattedDuration: String {
            let hours = Int(duration) / 3600
            let minutes = (Int(duration) % 3600) / 60
            if hours > 0 {
                return "\(hours)g \(minutes)p"
            }
            return "\(minutes) phút"
        }
    }

    private init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        loadHistory()
        updateBatteryInfo()
    }

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.updateBatteryInfo()
            self.checkThresholds()
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryStateDidChange),
            name: UIDevice.batteryStateDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryLevelDidChange),
            name: UIDevice.batteryLevelDidChangeNotification,
            object: nil
        )
    }

    @objc private func batteryStateDidChange() {
        updateBatteryInfo()
        handleChargeStateChange()
    }

    @objc private func batteryLevelDidChange() {
        let newLevel = Int(UIDevice.current.batteryLevel * 100)
        if newLevel != lastLevel && lastLevel != -1 {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
        lastLevel = newLevel
        updateBatteryInfo()
    }

    private func handleChargeStateChange() {
        let currentState = UIDevice.current.batteryState
        isCharging = (currentState == .charging || currentState == .full)
        isFullyCharged = (currentState == .full)

        if isCharging && !wasCharging {
            chargeStartTime = Date()
            wasCharging = true
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
        } else if !isCharging && wasCharging {
            if let start = chargeStartTime {
                let session = ChargeSession(
                    startTime: start,
                    endTime: Date(),
                    startLevel: batteryLevel,
                    endLevel: batteryLevel,
                    duration: Date().timeIntervalSince(start)
                )
                chargeHistory.insert(session, at: 0)
                lastChargeDuration = session.duration
                saveHistory()
            }
            chargeCount += 1
            UserDefaults.standard.set(chargeCount, forKey: "totalChargeCount")
            wasCharging = false
            chargeStartTime = nil
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
        }
    }

    private func updateBatteryInfo() {
        DispatchQueue.global(qos: .utility).async {
            let info = self.getIOKitBatteryInfo()
            DispatchQueue.main.async {
                self.batteryLevel = Int(UIDevice.current.batteryLevel * 100)
                self.batteryState = UIDevice.current.batteryState
                self.cycleCount = info["CycleCount"] as? Int ?? UserDefaults.standard.integer(forKey: "cycleCount")
                self.designCapacity = info["DesignCapacity"] as? Int ?? 0
                self.maxCapacity = info["MaxCapacity"] as? Int ?? 0
                self.temperature = info["Temperature"] as? Double ?? 0.0
                self.voltage = info["Voltage"] as? Double ?? 0.0
                self.amperage = info["Amperage"] as? Int ?? 0
                self.totalUsageHours = UserDefaults.standard.double(forKey: "totalUsageHours")
                self.chargeCount = UserDefaults.standard.integer(forKey: "totalChargeCount")

                if self.designCapacity > 0 {
                    self.healthPercentage = Double(self.maxCapacity) / Double(self.designCapacity) * 100.0
                }

                self.accumulateUsageTime()
            }
        }
    }

    private func accumulateUsageTime() {
        let now = Date()
        let lastCheck = UserDefaults.standard.object(forKey: "lastCheckTime") as? Date ?? now
        let interval = now.timeIntervalSince(lastCheck)
        if interval > 0 && interval < 300 {
            totalUsageHours += interval / 3600.0
            UserDefaults.standard.set(totalUsageHours, forKey: "totalUsageHours")
        }
        UserDefaults.standard.set(now, forKey: "lastCheckTime")
    }

    private func checkThresholds() {
        if totalUsageHours - (UserDefaults.standard.double(forKey: "lastNotifiedUsage")) > 8.0 {
            NotificationManager.shared.sendNotification(
                title: "⚠️ Cảnh báo sử dụng",
                body: "Bạn đã sử dụng thiết bị hơn 8 tiếng. Hãy nghỉ ngơi để bảo vệ pin và mắt!"
            )
            UserDefaults.standard.set(totalUsageHours, forKey: "lastNotifiedUsage")
        }

        if batteryLevel <= 20 && batteryLevel > 0 && !isCharging {
            NotificationManager.shared.sendNotification(
                title: "🔋 Pin yếu",
                body: "Pin còn \(batteryLevel)%. Hãy cắm sạc để tránh tắt nguồn đột ngột."
            )
        }

        if let start = chargeStartTime, Date().timeIntervalSince(start) > 14400 {
            NotificationManager.shared.sendNotification(
                title: "🔌 Sạc quá lâu",
                body: "Thiết bị đã cắm sạc hơn 4 tiếng. Ngắt sạc để bảo vệ pin!"
            )
        }
    }

    private func getIOKitBatteryInfo() -> [String: Any] {
        var result: [String: Any] = [:]

        let service = IOServiceGetMatchingService(kIOMainPortDefault,
            IOServiceMatching("AppleSmartBattery"))

        guard service != 0 else { return result }
        defer { IOObjectRelease(service) }

        if let props = IORegistryEntryCreateCFProperties(service, nil, kCFAllocatorDefault, 0)
            .takeRetainedValue() as? [String: Any] {

            if let cycle = props["CycleCount"] as? Int {
                result["CycleCount"] = cycle
                UserDefaults.standard.set(cycle, forKey: "cycleCount")
            }
            if let design = props["DesignCapacity"] as? Int {
                result["DesignCapacity"] = design
            }
            if let max = props["MaxCapacity"] as? Int {
                result["MaxCapacity"] = max
            }
            if let temp = props["Temperature"] as? Int {
                result["Temperature"] = Double(temp) / 100.0
            }
            if let volt = props["Voltage"] as? Int {
                result["Voltage"] = Double(volt) / 1000.0
            }
            if let amp = props["Amperage"] as? Int {
                result["Amperage"] = amp
            }
        }

        return result
    }

    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(chargeHistory) {
            UserDefaults.standard.set(encoded, forKey: "chargeHistory")
        }
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "chargeHistory"),
           let decoded = try? JSONDecoder().decode([ChargeSession].self, from: data) {
            chargeHistory = decoded
        }
    }

    var batteryStatusText: String {
        switch batteryState {
        case .charging: return "Đang sạc"
        case .full: return "Đã đầy"
        case .unplugged: return "Đang dùng pin"
        default: return "Không xác định"
        }
    }

    var batteryColor: Color {
        if batteryLevel <= 20 { return Color(hex: "#ef4444") }
        if batteryLevel <= 50 { return Color(hex: "#fbbf24") }
        return Color(hex: "#4ade80")
    }
}
