# Butake Design

Paquete Swift compartido por Butake Git y Butake Stack: temas (`Theme`, `ThemeStore`) y tamaño de
texto (`TextScale`, `Font.ui…`).

- Trabajar en develop; main es release. Cada release es un tag semántico (`1.0.0`) que las apps
  fijan con `.package(url:…, from:)`.
- API pública estable: cambios incompatibles suben la versión mayor.
- Swift 6 estricto; `ThemeStore` y `TextScale` son `@MainActor`; `ThemeStore.snapshot` es la única
  lectura válida fuera del hilo principal.
- Validar con `swift test` y compilando Butake Git y Butake Stack.
- No publicar ni crear tags salvo instrucción del usuario.
