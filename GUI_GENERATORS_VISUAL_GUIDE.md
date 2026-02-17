# GUI Generator Scripts - Visual Guide

## GenerateStarterGui.lua - Main Menu

### Visual Layout
```
┌────────────────────────────────────────────────────────────┐
│                     FULL SCREEN OVERLAY                    │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  ┌────────────────────────────────────────────────┐  │  │
│  │  │            MAIN MENU                        ✕  │  │  │
│  │  │  (Title - can use image or text)               │  │  │
│  │  ├────────────────────────────────────────────────┤  │  │
│  │  │                                                 │  │  │
│  │  │        ┌─────────────────────────┐             │  │  │
│  │  │        │    ▶ PLAY (Green)       │             │  │  │
│  │  │        └─────────────────────────┘             │  │  │
│  │  │                                                 │  │  │
│  │  │        ┌─────────────────────────┐             │  │  │
│  │  │        │  ⚙ SETTINGS (Purple)    │             │  │  │
│  │  │        └─────────────────────────┘             │  │  │
│  │  │                                                 │  │  │
│  │  │        ┌─────────────────────────┐             │  │  │
│  │  │        │   🛒 SHOP (Gold)        │             │  │  │
│  │  │        └─────────────────────────┘             │  │  │
│  │  │                                                 │  │  │
│  │  │        ┌─────────────────────────┐             │  │  │
│  │  │        │ 🏆 LEADERBOARD (Blue)   │             │  │  │
│  │  │        └─────────────────────────┘             │  │  │
│  │  │                                                 │  │  │
│  │  └────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────┘  │
│         Semi-transparent dark background                   │
└────────────────────────────────────────────────────────────┘
```

### Features
- **Background**: Semi-transparent black overlay (40% transparency)
- **Main Frame**: 40% width x 60% height, centered
- **Rounded Corners**: All elements have rounded corners
- **Purple Theme**: Main color RGB(28, 25, 45) with RGB(100, 60, 200) accents
- **Color-Coded Buttons**:
  - Play: Green RGB(50, 150, 50)
  - Settings: Purple RGB(60, 50, 100)
  - Shop: Gold RGB(200, 150, 50)
  - Leaderboard: Blue RGB(50, 100, 200)
  - Close: Red RGB(200, 50, 50)

### Interactions
- **ESC Key**: Toggle menu visibility
- **Hover**: Buttons brighten on hover
- **Click**: Buttons shrink slightly when pressed
- **Global Function**: `_G.ToggleMainMenu()`

---

## GenerateStarterPackGui.lua - Starter Pack

### Visual Layout
```
┌────────────────────────────────────────────────────────────┐
│                                                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  ┌────────────────────────────────────────────────┐  │  │
│  │  │  🎁 STARTER PACK                            ✕  │  │  │
│  │  ├────────────────────────────────────────────────┤  │  │
│  │  │                                                 │  │  │
│  │  │  Welcome to Climb To Top! Here's your          │  │  │
│  │  │  starter pack to help you begin your journey!  │  │  │
│  │  │                                                 │  │  │
│  │  │  ┌───────────────────────────────────────────┐ │  │  │
│  │  │  │                                           │ │  │  │
│  │  │  │   💰  500 Bonus Coins                     │ │  │  │
│  │  │  │                                           │ │  │  │
│  │  │  │   ⚡  Speed Boost Trail                   │ │  │  │
│  │  │  │                                           │ │  │  │
│  │  │  │   🎨  Free Rainbow Trail                  │ │  │  │
│  │  │  │                                           │ │  │  │
│  │  │  └───────────────────────────────────────────┘ │  │  │
│  │  │                                                 │  │  │
│  │  │       ┌─────────────────────────────┐          │  │  │
│  │  │       │  ✓ CLAIM STARTER PACK       │          │  │  │
│  │  │       └─────────────────────────────┘          │  │  │
│  │  │                                                 │  │  │
│  │  └────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                            │
│  ┌────┐                                                    │
│  │ 🎁 │  ← Toggle Button (Bottom Left)                    │
│  └────┘                                                    │
└────────────────────────────────────────────────────────────┘
```

### Features
- **Shop-Style Design**: Matches gamepass/shop GUI theme
- **Main Frame**: 50% width x 55% height, centered
- **Title Bar**: Dark purple RGB(40, 32, 65) with white text
- **Items Frame**: Mid-purple RGB(35, 30, 55) with item cards
- **Rounded Corners**: Consistent 16px on main, 12px on buttons
- **Toggle Button**: Bottom-left corner, purple with white stroke

### Interactions
- **P Key**: Toggle starter pack visibility
- **Toggle Button**: Click 🎁 button to open/close
- **Claim Button**: Click to claim rewards (connects to server)
- **Auto-Open**: Automatically shows for new players (< 100 coins)
- **Hover**: All buttons brighten on hover
- **Global Function**: `_G.OpenStarterPack()`

---

## Color Reference

### Main Menu Colors
| Element | Color | RGB |
|---------|-------|-----|
| Main Frame | Dark Purple | `(28, 25, 45)` |
| Accent Stroke | Purple | `(100, 60, 200)` |
| Play Button | Green | `(50, 150, 50)` |
| Settings Button | Purple | `(60, 50, 100)` |
| Shop Button | Gold | `(200, 150, 50)` |
| Leaderboard Button | Blue | `(50, 100, 200)` |
| Close Button | Red | `(200, 50, 50)` |

### Starter Pack Colors
| Element | Color | RGB |
|---------|-------|-----|
| Container | Dark Purple | `(28, 25, 45)` |
| Stroke | Purple | `(100, 60, 200)` |
| Title Bar | Darker Purple | `(40, 32, 65)` |
| Items Frame | Mid Purple | `(35, 30, 55)` |
| Item Cards | Lighter Purple | `(45, 38, 70)` |
| Claim Button | Green | `(100, 200, 100)` |
| Toggle Button | Purple | `(100, 60, 200)` |

---

## Animation Details

### Main Menu
- **Open Animation**: Back ease out, 0.3 seconds
- **Hover**: 0.2 second smooth color transition
- **Press**: 0.1 second size reduction

### Starter Pack
- **Open Animation**: Back ease out, 0.3 seconds
- **Close Animation**: Quad ease in, 0.2 seconds
- **Hover**: 0.2 second smooth color transition
- **Auto-Close**: 1.5 seconds after claiming

---

## Usage Examples

### Opening from Another Script
```lua
-- Open Main Menu
_G.ToggleMainMenu()

-- Open Starter Pack
_G.OpenStarterPack()
```

### Checking if GUI Exists
```lua
local player = game.Players.LocalPlayer
local gui = player.PlayerGui:FindFirstChild("MainMenuGui")
if gui then
    print("Main Menu exists!")
end
```

### Customizing Button Actions
Edit the LocalScript inside the ScreenGui after generation:
```lua
-- Find the button script section
playButton.Activated:Connect(function()
    print("Play button clicked!")
    -- Add your custom logic here
    -- Example: FireRemoteEvent to start game
end)
```

---

## Mobile Responsiveness

Both GUIs are mobile-friendly:

### Main Menu
- Uses UIAspectRatioConstraints on buttons
- Adjusts to 85% width on small screens
- Reduces text sizes on mobile
- Works with touch input

### Starter Pack
- Uses relative sizing (UDim2 scale)
- UIListLayout for automatic stacking
- Large touch-friendly buttons
- Adapts to any screen size

---

## Troubleshooting

### GUI Not Showing
1. Check StarterGui contains the GUI
2. Verify LocalScript is present
3. Check Output for errors
4. Try toggling with global function

### Buttons Not Working
1. LocalScript should be enabled
2. Check Output for script errors
3. Verify button connections in script

### Wrong Colors
1. Find the element in Explorer
2. Adjust BackgroundColor3 property
3. Or edit the generator script and re-run

---

**Visual Guide Version**: 1.0  
**Last Updated**: 2026-02-17  
**Supported Platforms**: PC, Mobile, Tablet
