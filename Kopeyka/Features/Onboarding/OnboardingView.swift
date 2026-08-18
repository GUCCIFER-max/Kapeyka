import SwiftUI

private struct OnboardingSlide {
    let title: String
    let message: String
    let systemImage: String
}

private let onboardingSlides: [OnboardingSlide] = [
    OnboardingSlide(
        title: "Записывай трату за секунды",
        message: "Один тап на «+» — и трата уже сохранена. Никаких лишних экранов.",
        systemImage: "bolt.fill"
    ),
    OnboardingSlide(
        title: "Категории и шаблоны",
        message: "Свои категории и быстрые шаблоны для повторяющихся трат — кофе, проезд, сигареты.",
        systemImage: "square.grid.2x2.fill"
    ),
    OnboardingSlide(
        title: "Бюджет под контролем",
        message: "Месячный бюджет и статистика по категориям — всегда на главном экране.",
        systemImage: "chart.pie.fill"
    ),
]

struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var pageIndex = 0

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button("Пропустить") { onFinish() }
                    .foregroundStyle(.secondary)
            }
            .padding()

            TabView(selection: $pageIndex) {
                ForEach(Array(onboardingSlides.enumerated()), id: \.offset) { index, slide in
                    OnboardingSlideView(slide: slide)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button(pageIndex == onboardingSlides.count - 1 ? "Начать" : "Далее") {
                if pageIndex == onboardingSlides.count - 1 {
                    onFinish()
                } else {
                    pageIndex += 1
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .padding()
        }
    }
}

private struct OnboardingSlideView: View {
    let slide: OnboardingSlide

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: slide.systemImage)
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.accent)

            Text(slide.title)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)

            Text(slide.message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    OnboardingView(onFinish: {})
        .preferredColorScheme(.dark)
}
