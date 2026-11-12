# Butake Design

Diseño compartido de las apps macOS de Butake (Butake Git y Butake Stack):

- `Theme`, `HexColor` y `ThemeStore`: familias Butake, Drácula y personalizada, modo claro/oscuro/sistema.
- `TextScale` y `Font.ui…`: tamaño de texto con ⌘+ / ⌘− / ⌘0.

Cada app fija su nombre al iniciar (`ThemeStore.shared.brandName`, `customName`) y guarda sus
preferencias en su propio dominio. Se usa como dependencia de Swift Package Manager:

```swift
.package(url: "https://github.com/Jose-Currinir/Butake-Design.git", from: "1.0.0")
```

Validar con `swift test` y compilando las dos apps.
