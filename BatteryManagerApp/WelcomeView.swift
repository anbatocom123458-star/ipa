import SwiftUI

struct WelcomeView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0

    let pages = [
        WelcomePage(
            icon: "bolt.fill",
            color: .green,
            title: "Chào mừng đến Battery Manager",
            description: "Ứng dụng giúp bạn theo dõi và quản lý sức khỏe pin iPhone một cách chi tiết nhất."
        ),
        WelcomePage(
            icon: "chart.bar.fill",
            color: .blue,
            title: "Thống kê chuyên sâu",
            description: "Xem số chu kỳ sạc, thời gian sử dụng, lịch sử sạc và tình trạng pin hiện tại."
        ),
        WelcomePage(
            icon: "bell.badge.fill",
            color: .orange,
            title: "Thông báo thông minh",
            description: "Nhận cảnh báo khi sử dụng thiết bị quá nhiều hoặc pin đạt ngưỡng nguy hiểm."
        ),
        WelcomePage(
            icon: "checkmark.shield.fill",
            color: .purple,
            title: "Bảo vệ pin lâu dài",
            description: "Gợi ý tối ưu dựa trên thói quen sạc của bạn để kéo dài tuổi thọ pin."
        )
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        VStack(spacing: 24) {
                            Image(systemName: pages[index].icon)
                                .font(.system(size: 80))
                                .foregroundColor(pages[index].color)
                                .symbolRenderingMode(.multicolor)
                                .padding(.bottom, 20)

                            Text(pages[index].title)
                                .font(.title.bold())
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)

                            Text(pages[index].description)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 32)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 400)

                Spacer()

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? Color.green : Color.gray.opacity(0.4))
                            .frame(width: currentPage == index ? 20 : 8, height: 8)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        onComplete()
                    }
                }) {
                    HStack {
                        Text(currentPage < pages.count - 1 ? "Tiếp theo" : "Bắt đầu sử dụng")
                            .font(.headline.bold())
                        Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "checkmark")
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

struct WelcomePage {
    let icon: String
    let color: Color
    let title: String
    let description: String
}
