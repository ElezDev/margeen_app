# Margeen — Guía de diseño Flutter

Auth ya funciona con Material 3 por defecto. Esto define cómo subir el nivel visual **sin cambiar de framework**.

---

## Identidad

| Elemento | Valor |
|----------|-------|
| Nombre | Margeen |
| Personalidad | Rápido, confiable, de campo (vendedor con celular) |
| Público | Dueños y vendedores de distribución (Colombia) |

---

## Paleta (más allá del azul Material default)

```dart
// lib/core/theme/app_colors.dart
class AppColors {
  static const primary = Color(0xFF1E3A5F);      // Azul noche — confianza
  static const primaryLight = Color(0xFF2D5A8E);
  static const accent = Color(0xFFF59E0B);       // Ámbar — acción / CTA
  static const profit = Color(0xFF16A34A);       // Verde — ganancia
  static const danger = Color(0xFFDC2626);
  static const surface = Color(0xFFF8FAFC);
  static const card = Colors.white;
  static const textPrimary = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
}
```

- **No** uses `ColorScheme.fromSeed` solo — define colores fijos de marca.
- Ganancia siempre en **verde** (`profit`), nunca en rojo/azul genérico.

---

## Tipografía

Agregar en `pubspec.yaml`:

```yaml
dependencies:
  google_fonts: ^6.2.1
```

```dart
import 'package:google_fonts/google_fonts.dart';

ThemeData buildTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
  return base.copyWith(
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme),
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
    ),
  );
}
```

**Plus Jakarta Sans** — moderna, legible en móvil, no es la Roboto default.

---

## Componentes custom (no Material puro)

### 1. Profit Banner (estrella de la app)

Banner fijo al crear factura — lo más importante para el cliente:

```
┌─────────────────────────────────────┐
│  💰 Ganancia en esta factura        │
│     $ 60.000          (25%)         │
└─────────────────────────────────────┘
```

- Fondo: gradiente `profit` → verde más oscuro
- Texto blanco, número grande (`headlineMedium`, bold)
- Actualizar en vivo al cambiar líneas

### 2. Cards con sombra suave

```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  ),
)
```

Radio **16** en cards, **12** en inputs — más redondeado que Material default (8).

### 3. Bottom Navigation (no drawer)

Para vendedor en campo, el pulgar importa:

| Tab | Icono | Pantalla |
|-----|-------|----------|
| Inicio | home | Dashboard / resumen día |
| Facturas | receipt_long | Lista + FAB nueva |
| Clientes | people | Lista clientes |
| Más | menu | Productos, perfil, logout |

FAB central o en tab Facturas: **+ Nueva factura** color `accent`.

### 4. Inputs de factura

- Cantidad con botones **+ / −** grandes (campo, dedos sucios)
- Precio editable pero precargado del catálogo
- Unidad visible (`arroba`, `galón`)

### 5. Lista de facturas

Cada item:
```
FAC-0042          $240.000
Edwin Pérez       +$60.000 verde
Hoy 3:45pm
```

---

## Pantallas — wireframe rápido

### Login ✅ (mejorar)
- Logo/icono factura arriba
- Fondo `surface`, card blanca centrada con sombra
- Botón CTA color `accent` (no primary azul)

### Home / Dashboard
- Saludo: "Hola, Carlos"
- 2 stat cards: **Ventas hoy** | **Ganancia hoy**
- Botón grande: "Nueva factura"
- Últimas 3 facturas

### Nueva factura
1. Selector cliente (buscador)
2. Lista líneas
3. **Profit banner** sticky abajo
4. Botón "Emitir factura"

### Detalle factura
- Resumen + líneas
- Botones: **PDF** | **WhatsApp** (verde WA no es obligatorio, pero icono reconocible)

---

## Paquetes UI recomendados

```yaml
google_fonts: ^6.2.1        # Tipografía
flutter_animate: ^4.5.2     # Entradas suaves (opcional)
share_plus: ^10.1.4         # WhatsApp / PDF
url_launcher: ^6.3.1        # wa.me
```

**No** uses paquetes de UI completos (GetX themes, etc.) — custom ligero sobre Material 3.

---

## Animaciones (sutiles)

- Login → Home: fade + slide up 200ms
- Agregar línea factura: `AnimatedList`
- Profit banner: `AnimatedSwitcher` al cambiar monto
- Nada exagerado — app de trabajo, no consumo

---

## Iconografía

Material Icons Rounded (más amigable que outlined):

```dart
Icon(Icons.receipt_long_rounded)
Icon(Icons.add_rounded)
Icon(Icons.trending_up_rounded)  // ganancia
```

---

## Próximo paso implementación

1. Crear `lib/core/theme/app_theme.dart` + `app_colors.dart`
2. Refactor `main.dart` → `theme: buildTheme()`
3. Rediseñar `login_screen` con card + accent
4. `MainShell` con `NavigationBar` + 4 tabs
5. Fase 2: `CreateInvoiceScreen` con profit banner
