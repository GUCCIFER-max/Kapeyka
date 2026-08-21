import SwiftUI
import CoreData

/// Hosts the four tabs plus the floating "+" that opens Quick Add over
/// whichever tab is currently active (ТЗ 4.1: works "с любой вкладки").
struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var isQuickAddPresented = false

    var body: some View {
        if hasCompletedOnboarding {
            mainContent
        } else {
            OnboardingView {
                withAnimation {
                    hasCompletedOnboarding = true
                }
            }
        }
    }

    private var mainContent: some View {
        ZStack(alignment: .bottom) {
            TabView {
                DashboardView()
                    .tabItem { Label("Дашборд", systemImage: "house.fill") }

                AnalyticsView()
                    .tabItem { Label("Аналитика", systemImage: "chart.bar.fill") }

                CategoriesView()
                    .tabItem { Label("Категории", systemImage: "square.grid.2x2.fill") }

                ProfileView()
                    .tabItem { Label("Профиль", systemImage: "person.fill") }
            }
            // ТЗ 4.1: "Стеклянный tab-bar с блюром внизу экрана".
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)

            QuickAddButton {
                Haptics.tap()
                isQuickAddPresented = true
            }
            .padding(.bottom, 56)
        }
        .tint(AppTheme.accent)
        .sheet(isPresented: $isQuickAddPresented) {
            QuickAddView()
        }
    }
}

private struct QuickAddButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Circle().fill(AppTheme.accent))
                .shadow(radius: 8, y: 4)
        }
        .pressScale(0.9)
        .accessibilityLabel("Добавить трату")
    }
}

#Preview {
    RootView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
