# 🔋 Battery Manager iOS

Ứng dụng quản lý pin iOS với thông số chuyên sâu từ IOKit, màn hình welcome, thông báo thông minh và lịch sử sạc chi tiết.

## ✨ Tính năng

- **Màn hình Welcome**: Giới thiệu 4 trang về ứng dụng
- **Dashboard tổng quan**: Vòng tròn pin trực quan, thống kê grid
- **Thông số chuyên sâu**: Số chu kỳ sạc, nhiệt độ, điện áp, dòng điện, dung lượng thiết kế/tối đa
- **Thông báo thông minh**: Cảnh báo khi dùng > 8 tiếng, pin < 20%, sạc > 4 tiếng
- **Lịch sử sạc**: Ghi nhận thời gian sạc, % pin đầu/cuối, thống kê trung bình
- **Tổng giờ sử dụng**: Tích lũy thời gian dùng thiết bị

## 🏗 Cấu trúc project

```
BatteryManagerApp/
├── .github/workflows/build.yml    # GitHub Actions CI/CD
├── BatteryManager/
│   ├── BatteryManagerApp.swift    # App entry point + Welcome logic
│   ├── WelcomeView.swift          # Onboarding 4 trang
│   ├── ContentView.swift          # TabView + Dashboard
│   ├── BatteryMonitor.swift       # IOKit + logic pin
│   ├── NotificationManager.swift  # Local notifications
│   ├── HistoryView.swift          # Lịch sử sạc & thống kê
│   ├── SettingsView.swift         # Cài đặt & xóa dữ liệu
│   ├── Info.plist                 # Cấu hình app
│   └── ExportOptions.plist        # Cấu hình export IPA
├── project.yml                    # XcodeGen project spec
└── setup.sh                       # Script setup local
```

## 🚀 Cách chạy local

```bash
cd BatteryManagerApp
./setup.sh
```

Sau đó mở `BatteryManager.xcodeproj` trong Xcode, chọn team signing và build.

## 🔐 Setup GitHub Actions (Build IPA tự động)

### Bước 1: Tạo Apple Certificate & Provisioning Profile
- Vào [Apple Developer](https://developer.apple.com/account/resources/certificates/list)
- Tạo **iOS Distribution** certificate (hoặc Development nếu cài trực tiếp)
- Tạo Provisioning Profile cho bundle ID của bạn
- Download cả 2 file

### Bước 2: Chuẩn bị secrets

```bash
# Encode certificate
base64 -i Certificates.p12 | pbcopy

# Encode provisioning profile
base64 -i profile.mobileprovision | pbcopy
```

### Bước 3: Thêm GitHub Secrets
Vào **Settings → Secrets and variables → Actions**, thêm:

| Secret | Giá trị |
|--------|---------|
| `BUILD_CERTIFICATE_BASE64` | Base64 của `.p12` |
| `P12_PASSWORD` | Mật khẩu export p12 |
| `BUILD_PROVISION_PROFILE_BASE64` | Base64 của `.mobileprovision` |
| `KEYCHAIN_PASSWORD` | Mật khẩu tùy ý cho keychain tạm |
| `TEAM_ID` | Apple Team ID (10 ký tự) |
| `PROVISIONING_PROFILE_SPECIFIER` | Tên provisioning profile |

### Bước 4: Cập nhật project
Sửa các file sau với thông tin của bạn:
- `project.yml`: `PRODUCT_BUNDLE_IDENTIFIER`, `DEVELOPMENT_TEAM`
- `BatteryManager/ExportOptions.plist`: `teamID`

### Bước 5: Push & Build
```bash
git add .
git commit -m "Initial commit"
git push origin main
```

GitHub Actions sẽ tự động build và upload IPA trong mục **Actions → Artifacts**.

## ⚠️ Lưu ý quan trọng

1. **IOKit**: App sử dụng IOKit để đọc thông số phần cứng. Điều này **không được Apple chấp thuận trên App Store**, nhưng hoàn toàn OK khi sideload IPA.

2. **macOS Runner**: GitHub Actions dùng `macos-latest`. Thời gian build ~5-10 phút. Nhớ kiểm tra quota (macOS tính ×10 phút).

3. **Self-hosted runner**: Nếu bạn có Mac riêng, có thể dùng self-hosted runner để tiết kiệm quota và build nhanh hơn.

4. **Notification**: Trên iOS simulator không test được notification thật. Cần test trên device thật.

## 📱 Cài IPA lên iPhone

Sau khi có file IPA, cài qua:
- **AltStore** (miễn phí, cần refresh 7 ngày/lần)
- **Sideloadly** (miễn phí)
- **Apple Configurator 2** (Mac)
- **TestFlight** (nếu có Apple Developer $99/năm)

## 🛠 Stack

- Swift 5.9
- SwiftUI
- IOKit (private framework)
- UserNotifications
- XcodeGen
- GitHub Actions

---

*Lưu ý: Số chu kỳ sạc và một số thông số phần cứng chỉ đọc được qua IOKit. Nếu Apple thay đổi API trong tương lai, có thể cần cập nhật code.*
