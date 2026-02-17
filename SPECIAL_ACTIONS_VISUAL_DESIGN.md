# Special Actions Visual Design Specification

## 📐 Layout Overview

The special action buttons appear on the **right side of the screen** during gameplay ("Playing" state):

```
                                                                    ┌─────────┐
                                                                    │         │
                                                                    │  💀     │  ← Kill All Button
                                                                    │ KILL    │     (Red, 70x70)
                                                                    │  ALL    │     Position: Right side, middle-ish
                                                                    └─────────┘
                                                                        
                                                                     10px gap
                                                                        
                                                                    ┌─────────┐
                                                                    │         │
                                                                    │  🏁     │  ← Skip Button  
                                                                    │  SKIP   │     (Green, 70x70)
                                                                    │         │     Position: Below Kill All
                                                                    └─────────┘
```

## 🎨 Kill All Button (💀) Specifications

### Visual Properties
```lua
Size: 70x70 pixels
Position: UDim2.new(1, -90, 0.5, -100)
  - 1 = Right edge of screen
  - -90 = 90 pixels from right edge (20px margin)
  - 0.5 = Vertical center
  - -100 = 100 pixels above center

Background Color: Color3.fromRGB(200, 50, 50)  -- Red
Border: White stroke, 3px thickness
Corners: Rounded with 16px radius
```

### Content Layout
- **Icon (💀)**: 60% of height, centered horizontally, top 10%
  - Font: Gotham Bold
  - Size: 32px
  - Color: White
  
- **Text ("KILL ALL")**: 30% of height, centered horizontally, bottom 35%
  - Font: Gotham Black
  - Size: 9px
  - Color: White
  - Wrapped text

### Color Scheme
```
Background:  #C83232 (200, 50, 50)   - Dark Red
Border:      #FFFFFF (255, 255, 255) - White
Text/Icon:   #FFFFFF (255, 255, 255) - White
```

## 🏁 Skip to Finish Button Specifications

### Visual Properties
```lua
Size: 70x70 pixels
Position: UDim2.new(1, -90, 0.5, -20)
  - 1 = Right edge of screen
  - -90 = 90 pixels from right edge (20px margin)
  - 0.5 = Vertical center
  - -20 = 20 pixels above center (10px gap from Kill button)

Background Color: Color3.fromRGB(50, 200, 50)  -- Green
Border: White stroke, 3px thickness
Corners: Rounded with 16px radius
```

### Content Layout
- **Icon (🏁)**: 60% of height, centered horizontally, top 10%
  - Font: Gotham Bold
  - Size: 32px
  - Color: White
  
- **Text ("SKIP")**: 30% of height, centered horizontally, bottom 35%
  - Font: Gotham Black
  - Size: 11px
  - Color: White
  - Wrapped text

### Color Scheme
```
Background:  #32C832 (50, 200, 50)   - Green
Border:      #FFFFFF (255, 255, 255) - White
Text/Icon:   #FFFFFF (255, 255, 255) - White
```

## 🎯 Positioning Details

### Screen Coordinates
```
Screen Width: 100%
Screen Height: 100%

Kill All Button:
  X: 100% - 90px = Right edge with 20px visible margin
  Y: 50% - 100px = Above center

Skip Button:
  X: 100% - 90px = Same X as Kill All
  Y: 50% - 20px = Below center (10px gap from Kill All)

Gap Between Buttons:
  Kill All bottom: 50% - 100px + 70px = 50% - 30px
  Skip top: 50% - 20px
  Gap: (50% - 20px) - (50% - 30px) = 10px ✓
```

## 📱 Responsive Design

The buttons are positioned using:
- **Scale coordinates** (0-1 range) for percentage-based positioning
- **Offset coordinates** (pixel values) for precise spacing
- This ensures the buttons:
  - Stay on the right side regardless of screen size
  - Maintain consistent spacing
  - Remain touch-friendly on mobile (70x70 is large enough)

## 🎮 Visibility Rules

### Show Buttons When:
- GameState.Value == "Playing"
- Player is in an active round

### Hide Buttons When:
- GameState.Value == "Intermission"
- GameState.Value == "Waiting"
- GameState.Value == "Voting"
- Any other non-playing state

### Implementation
```lua
local function updateButtonVisibility()
    local gameState = RS.GameValues.GameState
    local isPlaying = (gameState.Value == "Playing")
    killAllBtn.Visible = isPlaying
    skipBtn.Visible = isPlaying
end
```

## 🔘 Button States

### Default State
- Full opacity
- Normal colors (Red/Green)
- White border visible

### Hover State (Not Implemented)
- Could add transparency change
- Could add size animation

### Pressed State (Not Implemented)
- Could add pressed animation
- Currently just triggers purchase prompt

### Disabled State
- If Product ID = 0
- Shows "Not Available" notification
- No visual change to button itself

## 🎨 Theme Consistency

The buttons match the existing UI theme:
- **Rounded corners** (16px) like other game UIs
- **Stroke borders** (3px white) matching button bar style
- **Bold fonts** (Gotham Black/Bold) consistent with menus
- **High contrast** for visibility during gameplay

However, they use **bright colors** (Red/Green) to stand out:
- Red = Danger/Aggressive action (Kill All)
- Green = Progress/Advancement (Skip to Finish)

This contrasts with the **dark purple theme** of menus (RGB 28, 25, 45) to ensure these action buttons are immediately noticeable during gameplay.

## 📏 Exact Measurements

```
Kill All Button:
  Top:    50% - 100px
  Bottom: 50% - 30px
  Left:   100% - 90px
  Right:  100% - 20px
  Width:  70px
  Height: 70px

Skip Button:
  Top:    50% - 20px
  Bottom: 50% + 50px
  Left:   100% - 90px
  Right:  100% - 20px
  Width:  70px
  Height: 70px

Total Height (both buttons + gap):
  170px (70 + 10 + 70 + 20 margins)
```

## 🖼️ ASCII Art Preview

```
┌──────────────────────────────────────────────┐
│                                          ┌──┐│
│                                          │💀││ Kill All
│                                          │KI││ (Red)
│                                          │LL││
│                                          │AL││
│                                          │L ││
│                                          └──┘│
│                                           10px
│                                          ┌──┐│
│                                          │🏁││ Skip
│                                          │SK││ (Green)
│                                          │IP││
│                                          │  ││
│                                          └──┘│
│                                              │
└──────────────────────────────────────────────┘
```

## ✅ Design Checklist

- [x] Uses ImageButton (not TextButton)
- [x] Correct size: 70x70 pixels
- [x] Correct position: Right side of screen
- [x] Correct colors: Red (Kill All), Green (Skip)
- [x] Correct icons: 💀 and 🏁 emojis
- [x] Correct text: "KILL ALL" and "SKIP"
- [x] Rounded corners (UICorner)
- [x] White stroke borders (UIStroke)
- [x] Only visible during "Playing" state
- [x] Mobile-friendly size
- [x] Proper spacing between buttons
- [x] Matches existing UI theme patterns
