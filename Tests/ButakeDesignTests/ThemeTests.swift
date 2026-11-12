import Testing
@testable import ButakeDesign

@MainActor @Test func themeNamesFollowTheAppAndHexRoundTrips() {
    let store = ThemeStore.shared
    store.brandName = "Butake Git"
    store.family = .butake
    #expect(store.theme.name.hasPrefix("Butake Git "))
    #expect(ThemeStore.snapshot == store.theme)
    #expect(HexColor(HexColor(0x19D79F).color).value == 0x19D79F)
    #expect(ThemeStore.palette(.dracula, dark: true).surface != nil)
}

@MainActor @Test func textScaleStaysWithinItsSteps() {
    let scale = TextScale.shared
    scale.reset()
    #expect(scale.factor == 1)
    for _ in 0..<20 { scale.increase() }
    #expect(scale.factor == TextScale.steps.last)
    scale.reset()
}
