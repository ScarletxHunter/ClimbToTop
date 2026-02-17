# MainMenuGui Visual Layout

## Desktop View (40% width, 60% height)

```
┌─────────────────────────────────────────────────────────────────────┐
│                      SEMI-TRANSPARENT BACKGROUND                    │
│  (Full Screen - Black with 0.4 transparency)                        │
│                                                                      │
│      ┌────────────────────────────────────────────────┐   ╔═╗      │
│      │  ╔════════════════════════════════════════╗    │   ║X║      │
│      │  ║        MAIN MENU (Title Image)         ║    │   ╚═╝      │
│      │  ╚════════════════════════════════════════╝    │  Close Btn  │
│      │                                                 │             │
│      │  ┌─────────────────────────────────────────┐   │             │
│      │  │      ▶ PLAY (Green - 50,150,50)        │   │             │
│      │  └─────────────────────────────────────────┘   │             │
│      │                                                 │             │
│      │  ┌─────────────────────────────────────────┐   │             │
│      │  │    ⚙ SETTINGS (Purple - 60,50,100)     │   │             │
│      │  └─────────────────────────────────────────┘   │             │
│      │                                                 │             │
│      │  ┌─────────────────────────────────────────┐   │             │
│      │  │    🛒 SHOP (Gold - 200,150,50)          │   │             │
│      │  └─────────────────────────────────────────┘   │             │
│      │                                                 │             │
│      │  ┌─────────────────────────────────────────┐   │             │
│      │  │  🏆 LEADERBOARD (Blue - 50,100,200)     │   │             │
│      │  └─────────────────────────────────────────┘   │             │
│      │                                                 │             │
│      └────────────────────────────────────────────────┘             │
│                   MAIN MENU FRAME                                   │
│              (Purple Theme - 28,25,45)                              │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Mobile View (85% width, 75% height - Auto-adjusted)

```
┌──────────────────────────────────────────────────────────────┐
│            SEMI-TRANSPARENT BACKGROUND (Full)                │
│                                                               │
│  ┌──────────────────────────────────────────────────┐  ╔═╗  │
│  │  ╔════════════════════════════════════════════╗  │  ║X║  │
│  │  ║         MAIN MENU (Smaller Text)           ║  │  ╚═╝  │
│  │  ╚════════════════════════════════════════════╝  │        │
│  │                                                   │        │
│  │  ┌────────────────────────────────────────────┐  │        │
│  │  │      ▶ PLAY (Larger Button)               │  │        │
│  │  └────────────────────────────────────────────┘  │        │
│  │                                                   │        │
│  │  ┌────────────────────────────────────────────┐  │        │
│  │  │      ⚙ SETTINGS                           │  │        │
│  │  └────────────────────────────────────────────┘  │        │
│  │                                                   │        │
│  │  ┌────────────────────────────────────────────┐  │        │
│  │  │      🛒 SHOP                               │  │        │
│  │  └────────────────────────────────────────────┘  │        │
│  │                                                   │        │
│  │  ┌────────────────────────────────────────────┐  │        │
│  │  │      🏆 LEADERBOARD                        │  │        │
│  │  └────────────────────────────────────────────┘  │        │
│  │                                                   │        │
│  └──────────────────────────────────────────────────┘        │
│                   MAIN MENU FRAME                             │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

## Button States

### Normal State
```
┌─────────────────────────────────────────┐
│       ▶ PLAY                            │  ← Background: RGB(50,150,50)
│                                         │  ← Stroke: RGB(150,100,255) - 2px
└─────────────────────────────────────────┘
```

### Hover State
```
┌═════════════════════════════════════════┐
║       ▶ PLAY (Brighter)                 ║  ← Background: RGB(80,70,130)
║                                         ║  ← Stroke: RGB(200,150,255) - 3px
└═════════════════════════════════════════┘
```

### Pressed State
```
┌───────────────────────────────────────┐
│     ▶ PLAY (Smaller)                  │  ← Size: 0.80 (from 0.85)
│                                       │  ← Height: 65px (from 70px)
└───────────────────────────────────────┘
```

## UI Components Applied

### To Every Button
- ✓ UICorner (16px radius)
- ✓ UIStroke (2-3px thickness, animated)
- ✓ UIAspectRatioConstraint (5:1 ratio for wide buttons)
- ✓ TextLabel overlay for button text

### To Main Frame
- ✓ UICorner (20px radius)
- ✓ UIStroke (3px thickness, purple accent)
- ✓ UIPadding (20-30px on all sides)

### To Button Container
- ✓ UIListLayout (15px spacing between buttons)
- ✓ Vertical center alignment

## Color Palette

```
┌─────────────────────────────────────────────────────────────┐
│ BACKGROUND                                                   │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓ RGB(0, 0, 0) - 0.4 transparency             │
├─────────────────────────────────────────────────────────────┤
│ MAIN FRAME                                                   │
│ ████████████████ RGB(28, 25, 45) - Dark Purple              │
├─────────────────────────────────────────────────────────────┤
│ ACCENT STROKE                                                │
│ ████████████████ RGB(100, 60, 200) - Purple                 │
├─────────────────────────────────────────────────────────────┤
│ PLAY BUTTON                                                  │
│ ████████████████ RGB(50, 150, 50) - Green                   │
├─────────────────────────────────────────────────────────────┤
│ SETTINGS BUTTON                                              │
│ ████████████████ RGB(60, 50, 100) - Purple                  │
├─────────────────────────────────────────────────────────────┤
│ SHOP BUTTON                                                  │
│ ████████████████ RGB(200, 150, 50) - Gold                   │
├─────────────────────────────────────────────────────────────┤
│ LEADERBOARD BUTTON                                           │
│ ████████████████ RGB(50, 100, 200) - Blue                   │
├─────────────────────────────────────────────────────────────┤
│ CLOSE BUTTON                                                 │
│ ████████████████ RGB(200, 50, 50) - Red                     │
└─────────────────────────────────────────────────────────────┘
```

## Interactions

### Opening Animation
```
Step 1: Menu is hidden
        MainMenuFrame.Visible = false
        
Step 2: _G.ToggleMainMenu() is called
        MainMenuFrame.Visible = true
        Size starts at: UDim2.new(0, 0, 0, 0)
        
Step 3: TweenService animates to full size
        Target: UDim2.new(0.4, 0, 0.6, 0)
        Duration: 0.3 seconds
        Style: Back (bouncy)
        Direction: Out
```

### Button Click Sequence
```
1. MouseButton1Down:
   - Button scales to 0.80 (from 0.85)
   - Height reduces to 65px (from 70px)
   - Duration: 0.1 seconds

2. MouseButton1Up:
   - Button returns to normal size
   - 0.85 width, 70px height
   - Duration: 0.1 seconds

3. Activated:
   - Execute button function
   - Print debug message
   - (User adds custom logic here)
```

## Keyboard Shortcuts

```
┌─────────────────────────────────────────┐
│  ESC Key  →  Toggle Main Menu           │
│                                          │
│  Press once: Show menu with animation   │
│  Press again: Hide menu                 │
└─────────────────────────────────────────┘
```

## Touch/Mobile Support

```
✓ Detects UserInputService.TouchEnabled
✓ Checks if keyboard is disabled (mobile indicator)
✓ Auto-scales to 85% width, 75% height
✓ Reduces text sizes for readability
✓ All buttons respond to Activated event (works on mobile)
```

## Z-Index Layering

```
Layer 3: Close Button (top-right, always visible)
Layer 2: Button Container & Buttons
Layer 1: Title Label
Layer 0: Background & Main Frame
```
