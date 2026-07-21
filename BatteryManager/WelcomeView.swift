import SwiftUI

struct WelcomeView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0

    let pages = [
        WelcomePageData(
            icon: "bolt.fill",
            color: Color(hex: "#4ade80"),
            title: "Chào mừng đến\nBattery Manager",
            description: "Ứng dụng giúp bạn theo dõi và quản lý sức khỏe pin iPhone một cách chi tiết nhất."
        ),
        WelcomePageData(
            icon: "chart.bar.fill",
            color: Color(hex: "#60a5fa"),
            title: "Thống kê chuyên sâu",
            description: "Xem số chu kỳ sạc, thời gian sử dụng, lịch sử sạc và tình trạng pin hiện tại."
        ),
        WelcomePageData(
            icon: "bell.badge.fill",
            color: Color(hex: "#fb923c"),
            title: "Thông báo thông minh",
            description: "Nhận cảnh báo khi sử dụng thiết bị quá nhiều hoặc pin đạt ngưỡng nguy hiểm."
        ),
        WelcomePageData(
            icon: "checkmark.shield.fill",
            color: Color(hex: "#c084fc"),
            title: "Bảo vệ pin lâu dài",
            description: "Gợi ý tối ưu dựa trên thói quen sạc của bạn để kéo dài tuổi thọ pin."
        )
    ]

    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            VStack(spacing: 0) {
                Spacer()

                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        WelcomePageView(page: pages[index], isActive: currentPage == index)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 420)

                Spacer()

                HStack(spacing: 10) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                            .frame(width: currentPage == index ? 28 : 8, height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.bottom, 36)

                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()

                    if currentPage < pages.count - 1 {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            currentPage += 1
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            onComplete()
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        Text(currentPage < pages.count - 1 ? "Tiếp theo" : "Bắt đầu sử dụng")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                        Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "checkmark.circle.fill")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(colors: [Color(hex: "#4ade80"), Color(hex: "#22c55e")],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(20)
                    .shadow(color: Color(hex: "#4ade80").opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 48)
            }
        }
    }
}

struct WelcomePageData {
    let icon: String
    let color: Color
    let title: String
    let description: String
}

struct WelcomePageView: View {
    let page: WelcomePageData
    let isActive: Bool

    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.15))
                    .frame(width: 180, height: 180)
                    .blur(radius: 20)

                Circle()
                    .stroke(page.color.opacity(0.3), lineWidth: 1)
                    .frame(width: 160, height: 160)

                Circle()
                    .fill(
                        LinearGradient(colors: [page.color.opacity(0.2), page.color.opacity(0.05)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 140, height: 140)
                    .overlay(
                        Circle()
                            .stroke(page.color.opacity(0.4), lineWidth: 1.5)
                    )

                Image(systemName: page.icon)
                    .font(.system(size: 56, weight: .medium))
                    .foregroundStyle(page.color)
                    .symbolRenderingMode(.multicolor)
            }
            .scaleEffect(isActive ? 1.0 : 0.85)
            .opacity(isActive ? 1.0 : 0.5)
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: isActive)

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .lineSpacing(4)

                Text(page.description)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.white.opacity(0.7))
                    .lineSpacing(6)
                    .padding(.horizontal, 36)
            }
            .offset(y: isActive ? 0 : 20)
            .opacity(isActive ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.5).delay(0.1), value: isActive)
        }
    }
}

struct AnimatedGradientBackground: View {
    @State private var start = UnitPoint(x: 0, y: 0)
    @State private var end = UnitPoint(x: 1, y: 1)

    let colors = [
        Color(hex: "#0f172a"),
        Color(hex: "#1e293b"),
        Color(hex: "#0f172a"),
        Color(hex: "#14532d").opacity(0.3)
    ]

    var body: some View {
        LinearGradient(colors: colors, startPoint: start, endPoint: end)
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                    start = UnitPoint(x: 1, y: 1)
                    end = UnitPoint(x: 0, y: 0)
                }
            }
    }
}
