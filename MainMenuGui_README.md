# MainMenuGui - Starter GUI Structure

## Overview
A modern, mobile-friendly main menu GUI for Roblox games featuring ImageButtons and clean UI design.

## Structure

```
MainMenuGui (ScreenGui)
├── Background (Frame) - Semi-transparent overlay
└── MainMenuFrame (Frame) - Main menu container
    ├── TitleLabel (ImageLabel) - Title section with text overlay
    ├── ButtonContainer (Frame) - Container for menu buttons
    │   ├── PlayButton (ImageButton) - Green themed
    │   ├── SettingsButton (ImageButton) - Purple themed
    │   ├── ShopButton (ImageButton) - Gold themed
    │   └── LeaderboardButton (ImageButton) - Blue themed
    └── CloseButton (ImageButton) - Red themed (top-right)
```

## Components

### Main Elements

| Element | Description | Properties |
|---------|-------------|------------|
| **Background** | Full-screen semi-transparent overlay | Black with 0.4 transparency |
| **MainMenuFrame** | Main container for all menu elements | Purple/dark theme (28, 25, 45) |
| **TitleLabel** | ImageLabel for title graphics | Placeholder image with text overlay |
| **ButtonContainer** | Organized button layout container | Uses UIListLayout for vertical arrangement |

### ImageButtons

All buttons use the same structure with customizable colors:

| Button | Color Theme | Icon | Purpose |
|--------|-------------|------|---------|
| **PlayButton** | Green (50, 150, 50) | ▶ | Start/join game |
| **SettingsButton** | Purple (60, 50, 100) | ⚙ | Open settings menu |
| **ShopButton** | Gold (200, 150, 50) | 🛒 | Open in-game shop |
| **LeaderboardButton** | Blue (50, 100, 200) | 🏆 | Display leaderboard |
| **CloseButton** | Red (200, 50, 50) | ✕ | Close the menu |

## UI Components Used

### For Every Element
- **UICorner** - Rounded edges (12-20 pixel radius)
- **UIStroke** - Colored outlines (2-3 pixel thickness)
- **UIAspectRatioConstraint** - Consistent sizing across devices

### Additional Components
- **UIPadding** - Proper spacing (20-30 pixels)
- **UIListLayout** - Organized vertical button arrangement

## Features

### 1. Interactive Animations
- **Hover Effects**: Color changes and stroke thickness adjustments
- **Click Animations**: Button size changes on press/release
- **Opening Animation**: Smooth scale-in effect using TweenService

### 2. Mobile-Friendly Design
- Automatic screen size detection
- Dynamic sizing for small screens (< 800px width)
- Touch-enabled controls
- Responsive text scaling

### 3. Placeholder Images
All ImageButtons and the title use `rbxassetid://0` as placeholders:
- Easy to replace with actual asset IDs
- Fallback text labels for visibility without images

### 4. Color-Coded Buttons
Each button has a distinct color theme for easy visual identification:
- **Green** = Action (Play)
- **Purple** = Configuration (Settings)
- **Gold** = Commerce (Shop)
- **Blue** = Information (Leaderboard)
- **Red** = Dismiss (Close)

## Integration Points

### Global Function
```lua
_G.ToggleMainMenu()
```
Call this from any script to show/hide the menu with animation.

### Button Click Handlers
Each button has a placeholder `Activated` event:

```lua
playButton.Activated:Connect(function()
    -- Add your game logic here
end)
```

### Keyboard Shortcut
- **ESC key** - Toggle menu visibility

## Customization Guide

### 1. Replace Images
Update image IDs in the script:
```lua
-- Title image
titleLabel.Image = "rbxassetid://YOUR_ID_HERE"

-- Button images
local playButton = createImageButton("PlayButton", 1, "▶ PLAY", "rbxassetid://YOUR_ID_HERE")
```

### 2. Adjust Colors
Modify `BackgroundColor3` values:
```lua
mainMenuFrame.BackgroundColor3 = Color3.fromRGB(28, 25, 45)  -- Main frame color
playButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)    -- Play button
```

### 3. Change Button Layout
Adjust `UIListLayout` properties:
```lua
buttonLayout.Padding = UDim.new(0, 15)              -- Spacing between buttons
buttonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
```

### 4. Modify Sizing
Update `UDim2` values:
```lua
mainMenuFrame.Size = UDim2.new(0.4, 0, 0.6, 0)      -- Menu size (40% width, 60% height)
playButton.Size = UDim2.new(0.85, 0, 0, 70)         -- Button size
```

## Mobile Responsiveness

The script automatically adjusts for mobile:
- Detects touch-enabled devices without keyboard
- Scales menu to 85% width, 75% height on mobile
- Reduces text sizes for better readability
- Adjusts button and close button sizes

## Code Organization

### Sections
1. **Service Imports** - Lines 6-8
2. **ScreenGui Creation** - Lines 16-20
3. **Background Frame** - Lines 25-33
4. **Main Menu Container** - Lines 38-62
5. **Title Section** - Lines 67-95
6. **Button Container** - Lines 100-115
7. **Button Creation Function** - Lines 120-214
8. **Menu Buttons** - Lines 219-246
9. **Close Button** - Lines 251-290
10. **Button Functionality** - Lines 295-310
11. **Global Toggle Function** - Lines 315-326
12. **Mobile Adjustments** - Lines 331-365
13. **Keyboard Shortcut** - Lines 370-375

## Best Practices

### When Adding Scripts
1. Use descriptive names for all elements
2. Keep button handlers organized and commented
3. Use the global `_G.ToggleMainMenu()` for consistency
4. Test on both desktop and mobile devices

### When Customizing
1. Maintain the dark purple theme for consistency
2. Keep UICorner radius consistent (12-20 pixels)
3. Use UIStroke for all button outlines
4. Test hover effects after color changes

### Performance Tips
1. Reuse the global toggle function instead of recreating logic
2. Use TweenService for smooth animations
3. Keep transparency values reasonable (0.3-0.7)
4. Test with multiple screen sizes

## Dependencies

### Required Services
- `Players` - Player and PlayerGui access
- `TweenService` - Smooth animations
- `UserInputService` - Input detection and mobile detection

### No External Dependencies
The script is self-contained and creates all UI elements programmatically.

## Compatibility

- ✅ Desktop (Windows, Mac)
- ✅ Mobile (iOS, Android)
- ✅ Tablet devices
- ✅ All screen sizes (automatic scaling)
- ✅ Touch and mouse input

## Next Steps

1. **Add Button Logic** - Connect buttons to your game systems
2. **Upload Images** - Replace placeholder images with actual assets
3. **Customize Colors** - Match your game's branding
4. **Test Mobile** - Verify scaling on different devices
5. **Add Sounds** - Include button click sounds for better UX

## Support

For questions or issues:
1. Check the SETUP_INSTRUCTIONS.md file
2. Review button handler comments in MainMenuGui.lua
3. Test the global toggle function: `_G.ToggleMainMenu()`

---

**Created:** 2026-02-17  
**Version:** 1.0  
**Location:** StarterPlayerScripts or StarterGui
