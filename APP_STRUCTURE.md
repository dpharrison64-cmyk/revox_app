# Revox App - Structure

## Overview
A tablet-optimized Flutter application configured for landscape orientation.

## Features

### Orientation
- **Locked to Landscape Mode**: The app runs exclusively in landscape orientation (both left and right rotations supported)
- **Fullscreen UI**: System UI is hidden for immersive experience

### Navigation
- **Sidebar Navigation**: Left-side navigation rail for easy tablet access
- **Three Primary Sections**:
  1. **Home** - Main application view
  2. **Settings** - App configuration and preferences
  3. **About** - Application information

### Layout
- **AppBar**: Top header with app title
- **NavigationRail**: Left sidebar with icon and label navigation
- **Content Area**: Main expanding content section that fills remaining space
- **Responsive Design**: Uses `Expanded` widgets for tablet-responsive layout

## File Structure
```
lib/
└── main.dart        # Main application - contains all shell components
```

## Running the App

```bash
cd revox_app
flutter run
```

For specific devices:
```bash
# iPad
flutter run -d ipad

# Android tablet
flutter run -d <device-id>
```

## Configuration

### System Orientation
The app is configured in `main()` to:
- Lock to landscape orientations (left and right)
- Enable immersive fullscreen mode

### Theme
- Material Design 3 enabled
- Light and dark theme support
- Blue color scheme (can be customized in `colorScheme`)

## Building for Production

### iOS
```bash
flutter build ios --release
```

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

## Customization

### Adding New Screens
1. Create new widget in `_buildContent()` switch statement
2. Add new `NavigationRailDestination` to the NavigationRail
3. Update `_selectedNavIndex` handling

### Changing Colors
Edit the `colorScheme` in both `theme` and `darkTheme` sections of `RevoxApp`

### Adjusting Layout
The `Row` widget in the `body` controls the sidebar + content layout. Modify spacing, padding, and sizing as needed.

## Dependencies
- **flutter**: Core framework
- **flutter/services**: For system orientation and UI mode control
- **flutter/material**: Material Design widgets

---
Built with Flutter for tablet devices in landscape orientation.
