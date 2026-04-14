# Quick Start Guide - Revox App

## What Was Created

A Flutter app shell configured for **tablet landscape mode** with:
- ✅ Landscape orientation locked
- ✅ Fullscreen immersive UI mode
- ✅ Tablet-optimized layout (sidebar navigation + content area)
- ✅ Navigation between 3 basic screens (Home, Settings, About)
- ✅ Material Design 3 with light/dark theme support
- ✅ Clean, minimal code structure ready to build upon

## Project Structure

```
revox_app/
├── lib/
│   └── main.dart           # Complete app shell (all components in one file for now)
├── test/
│   └── widget_test.dart    # Basic widget tests
├── pubspec.yaml            # Flutter dependencies
└── APP_STRUCTURE.md        # Detailed architecture docs
```

## Running the App

### Prerequisites
- Flutter SDK installed
- Xcode installed (for iOS) / Android Studio (for Android)

### Commands

**Get dependencies:**
```bash
cd revox_app
flutter pub get
```

**Run on iPad:**
```bash
flutter run -d ipad
```

**Run on Android tablet:**
```bash
flutter run
# Then select your device when prompted
```

**Run in debug mode:**
```bash
flutter run
```

**Build for release:**
```bash
# iOS
flutter build ios --release

# Android
flutter build apk --release
flutter build appbundle --release
```

## Architecture

### Main Components

**RevoxApp** - Root widget that sets up:
- Material/Material 3 theme
- Light and dark themes
- Navigation to HomeScreen

**HomeScreen** - Main screen controller with:
- AppBar (top header)
- NavigationRail (sidebar with Home, Settings, About)
- Dynamic content area based on selected tab

**Content Sections** (built conditionally):
- `_buildHomeContent()` - Main home view
- `_buildSettingsContent()` - Settings panel
- `_buildAboutContent()` - About information

### Key Configuration

**Landscape Orientation Lock** (in `main()`):
```dart
await SystemChrome.setPreferredOrientations(
  [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
);
```

**Fullscreen Mode** (in `main()`):
```dart
await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
```

## Customization Tips

### Add a New Navigation Screen
1. Add new case to `_buildContent()` switch statement
2. Add `NavigationRailDestination` with icon and label
3. Create new `Widget _buildYourScreenName()` method

### Change Colors
Edit `colorScheme` in both theme and darkTheme:
```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: Colors.blue,  // Change this color
  brightness: Brightness.light,
),
```

### Modify Layout
The layout is in the `build()` method of `_HomeScreenState`:
- `NavigationRail` on the left
- `Expanded` widget containing content on the right
- Adjust `groupAlignment`, `destinations`, or spacing as needed

### Fix System UI
To re-enable system UI (status bar, navigation bar):
```dart
await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
```

## Testing

**Run tests:**
```bash
flutter test
```

**Run specific test:**
```bash
flutter test test/widget_test.dart
```

## Common Issues

**App won't rotate:**
- Check `AndroidManifest.xml` has portrait orientation removed
- Check `Info.plist` on iOS has landscape orientations enabled

**System UI showing/hiding glitchy:**
- Make sure `setEnabledSystemUIMode` is called in `main()` before `runApp()`

**Text not displaying on tablet:**
- Check theme Text styles are set correctly
- Use `Theme.of(context).textTheme.headlineLarge` etc.

## Next Steps

1. **Organize Code**: Split into multiple files as the app grows
2. **Add State Management**: Consider Provider, Riverpod, or GetX
3. **Create More Screens**: Build out actual functionality
4. **Add Assets**: Images, icons, fonts in `assets/` folder
5. **Configure Platform-Specific Code**: Android/iOS specific settings

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Material Design 3](https://m3.material.io/)
- [Flutter for Large Screens](https://docs.flutter.dev/perf/best_practices/large_screens)

---

**Ready to build!** The shell is ready for your app logic.
