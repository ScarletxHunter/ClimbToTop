# GUI Generator Scripts

## Overview
This repository includes two GUI generator scripts that create complete, fully-functional GUI structures in StarterGui:

1. **`GenerateStarterGui.lua`** - Main Menu GUI with game controls
2. **`GenerateStarterPackGui.lua`** - Starter Pack/Welcome GUI matching the shop theme

These are one-time use scripts that generate professional-looking interfaces with all functionality built-in. Run once, then edit manually in Roblox Studio.

---

## GenerateStarterGui.lua - Main Menu GUI

### Overview
Creates a complete Main Menu GUI structure with all buttons, animations, and functionality built-in.

## Purpose
Instead of manually creating dozens of UI elements and setting hundreds of properties one by one, this script does it all programmatically in seconds. Once generated, the GUI appears in StarterGui where you can edit it like any other GUI.

## Features

### Generated GUI Structure
- **ScreenGui** (MainMenuGui) - Container for the entire menu
- **Background Frame** - Semi-transparent dark overlay
- **Main Menu Frame** - Centered container with rounded corners and purple theme
- **Title Section** - ImageLabel with text overlay for the menu title
- **5 ImageButtons**:
  - ▶ **Play Button** (Green) - For starting the game
  - ⚙ **Settings Button** (Purple) - For opening settings menu
  - 🛒 **Shop Button** (Gold) - For opening the shop/store
  - 🏆 **Leaderboard Button** (Blue) - For viewing leaderboards
  - ✕ **Close Button** (Red) - For closing the menu

### UI Enhancements
Each element includes professional touches:
- **UICorner** - Rounded edges for modern look
- **UIStroke** - Colored outlines for visual depth
- **UIAspectRatioConstraint** - Consistent sizing across devices
- **UIListLayout** - Automatic vertical button arrangement
- **UIPadding** - Proper spacing inside containers
- **Placeholder Images** - All ImageButtons use `rbxassetid://0` for easy replacement

### Design Features
- **Color-coded buttons** - Each button type has a distinct color
- **Mobile-friendly** - Responsive sizing with aspect ratio constraints
- **Theme consistency** - Matches the game's purple/dark color scheme
- **Professional appearance** - Rounded corners, outlines, proper spacing

## How to Use

### Step 1: Run the Script
There are two ways to run this script:

#### Method A: Using Command Bar (Recommended)
1. Open Roblox Studio
2. Open your game/place
3. Open the Command Bar (View → Command Bar)
4. Copy the ENTIRE contents of `GenerateStarterGui.lua`
5. Paste it into the Command Bar
6. Press Enter to execute

#### Method B: Using a Script Object
1. Open Roblox Studio
2. In the Explorer, go to ServerScriptService
3. Insert a new Script
4. Copy the ENTIRE contents of `GenerateStarterGui.lua`
5. Paste it into the Script
6. Press F5 to run the game (or click Play)
7. Wait a moment for the script to execute
8. Stop the game (Press F5 or click Stop)

### Step 2: Verify Creation
1. Look in the Output window - you should see success messages:
   ```
   Creating MainMenuGui in StarterGui...
     ✓ Background frame created
     ✓ Main menu frame created with rounded corners, stroke, and padding
     ✓ Title section created
     ✓ Button container with UIListLayout created
     ✓ Play button created (Green)
     ✓ Settings button created
     ✓ Shop button created (Gold)
     ✓ Leaderboard button created (Blue)
     ✓ Close button created (Red)
     ✓ Mobile-friendly sizing applied
   
   ✓ GUI GENERATION COMPLETE!
   ```

2. In the Explorer window, navigate to **StarterGui**
3. You should see **MainMenuGui** listed there
4. Expand it to see all the generated elements

### Step 3: Customize the GUI
Now you can edit the GUI manually in Studio:

#### Replace Placeholder Images
1. Find each ImageButton in the Explorer
2. Select it and look at the Properties window
3. Find the `Image` property (currently set to `rbxassetid://0`)
4. Replace with your own image asset ID (e.g., `rbxassetid://123456789`)

#### Customize Text
1. Expand any button to find the `ButtonText` TextLabel
2. Select it and edit the `Text` property
3. Change colors, fonts, sizes as desired

#### Adjust Colors
1. Select any Frame or ImageButton
2. Edit the `BackgroundColor3` property
3. Colors are already color-coded but feel free to customize

#### Modify Sizes and Positions
1. Select any element
2. Edit `Size`, `Position`, `AnchorPoint` properties
3. The layout uses relative sizing (UDim2) for responsive design

### Step 4: Add Functionality
The buttons currently have no behavior. You need to add scripts:

#### Adding Button Scripts
1. In the Explorer, navigate to your button (e.g., MainMenuGui → ButtonContainer → PlayButton)
2. Insert a **LocalScript** as a child of the button
3. Add your button logic:

```lua
-- Example PlayButton script
local button = script.Parent
local Players = game:GetService("Players")
local player = Players.LocalPlayer

button.Activated:Connect(function()
    print("Play button clicked!")
    -- Add your game start logic here
    -- Example: Hide menu and start game
    script.Parent.Parent.Parent.Parent.Enabled = false
end)
```

Similar scripts can be added to other buttons for their respective functions.

### Step 5: Clean Up
1. Delete the generator script from ServerScriptService (if you used Method B)
2. OR simply discard the Command Bar contents (if you used Method A)
3. The generated GUI will remain in StarterGui

## GUI Hierarchy

```
StarterGui
└── MainMenuGui (ScreenGui)
    ├── Background (Frame)
    ├── MainMenuFrame (Frame)
    │   ├── UICorner
    │   ├── UIStroke
    │   ├── UIPadding
    │   ├── TitleLabel (ImageLabel)
    │   │   ├── UICorner
    │   │   ├── UIStroke
    │   │   └── TitleText (TextLabel)
    │   ├── ButtonContainer (Frame)
    │   │   ├── UIListLayout
    │   │   ├── PlayButton (ImageButton)
    │   │   │   ├── UICorner
    │   │   │   ├── UIStroke
    │   │   │   ├── UIAspectRatioConstraint
    │   │   │   └── ButtonText (TextLabel)
    │   │   ├── SettingsButton (ImageButton)
    │   │   │   ├── UICorner
    │   │   │   ├── UIStroke
    │   │   │   ├── UIAspectRatioConstraint
    │   │   │   └── ButtonText (TextLabel)
    │   │   ├── ShopButton (ImageButton)
    │   │   │   ├── UICorner
    │   │   │   ├── UIStroke
    │   │   │   ├── UIAspectRatioConstraint
    │   │   │   └── ButtonText (TextLabel)
    │   │   └── LeaderboardButton (ImageButton)
    │   │       ├── UICorner
    │   │       ├── UIStroke
    │   │       ├── UIAspectRatioConstraint
    │   │       └── ButtonText (TextLabel)
    │   └── CloseButton (ImageButton)
    │       ├── UICorner
    │       ├── UIStroke
    │       ├── UIAspectRatioConstraint
    │       └── CloseText (TextLabel)
```

## Button Color Scheme

Following the repository's established theme:

- **Main Frame Background**: `RGB(28, 25, 45)` - Dark purple
- **Accent Stroke**: `RGB(100, 60, 200)` - Purple
- **Play Button**: `RGB(50, 150, 50)` - Green (action/start)
- **Settings Button**: `RGB(60, 50, 100)` - Purple (default)
- **Shop Button**: `RGB(200, 150, 50)` - Gold (store/premium)
- **Leaderboard Button**: `RGB(50, 100, 200)` - Blue (info/stats)
- **Close Button**: `RGB(200, 50, 50)` - Red (close/exit)

## Tips and Best Practices

### Mobile Optimization
- The GUI uses `UIAspectRatioConstraint` to maintain button proportions
- Relative sizing (UDim2 with scale) ensures responsiveness
- Consider adding mobile-specific scaling logic in your scripts

### Image Assets
- Upload your button icons to Roblox as Image assets
- Get the asset ID from the uploaded image
- Replace all `rbxassetid://0` placeholders with your asset IDs
- Use transparent PNG images for best results

### Button Functionality
- Add LocalScripts to buttons for click handling
- Use the `Activated` event (works for both mouse and touch)
- Consider adding sound effects for button clicks
- Implement hover effects for better UX (desktop)

### Animations
- Consider using TweenService for smooth transitions
- Animate the menu opening/closing
- Add scale animations on button hover/click
- See `MainMenuGui.lua` for animation examples

## Troubleshooting

### GUI Not Appearing
- Make sure you ran the script successfully (check Output window)
- Verify StarterGui contains MainMenuGui
- Check if the GUI's `Enabled` property is set to true
- In test mode, check PlayerGui (the GUI copies from StarterGui to PlayerGui)

### Buttons Not Visible
- Expand MainMenuFrame → ButtonContainer in Explorer
- Verify buttons are there (PlayButton, SettingsButton, etc.)
- Check button `Visible` property is set to true
- Verify MainMenuFrame is visible

### Images Not Showing
- This is expected! All images use placeholder `rbxassetid://0`
- You need to replace these with your own image asset IDs
- Upload images to Roblox and get their asset IDs
- Set the `Image` property of each ImageButton

### Layout Issues
- The UIListLayout automatically arranges buttons
- If buttons overlap, check the UIListLayout.Padding value
- Adjust MainMenuFrame.Size if content doesn't fit
- Use UIAspectRatioConstraint properties to maintain proportions

## Advanced Customization

### Adding More Buttons
1. Find the button creation section in the script
2. Copy one of the `createImageButton()` calls
3. Modify the parameters (name, order, text, color)
4. Re-run the script OR manually create the button in Studio

### Changing Layout
- Currently uses UIListLayout for vertical arrangement
- You can change to UIGridLayout for grid layout
- Or use manual positioning by removing UIListLayout
- Adjust Position and Size properties directly

### Multiple Menus
- Run the script multiple times with different names
- Change `screenGui.Name` to create different menus
- Example: "SettingsMenuGui", "ShopMenuGui", etc.

## Related Files

- **MainMenuGui.lua** - Runtime version with animations and logic
- **StarterPackGui.lua** - Example of similar GUI structure
- **SpecialActionsGui.lua** - Another GUI following the same theme

## Support

If you encounter issues:
1. Check the Output window for error messages
2. Verify you copied the entire script
3. Make sure you're running in Roblox Studio, not in-game
4. Review the hierarchy structure above
5. Check that StarterGui is not locked or has permissions issues

---

## GenerateStarterPackGui.lua - Starter Pack GUI

### Overview
Creates a Starter Pack/Welcome GUI that matches the design of the existing gamepass/shop GUIs. Features a clean, modern interface with reward items and claim functionality.

### Features

#### Generated GUI Structure
- **ScreenGui** (StarterPackGui)
- **Container Frame** - Centered modal with shop-style theme
- **Title Bar** - "🎁 STARTER PACK" with close button
- **Description** - Welcome message
- **Items Frame** - List of reward items (coins, trails, etc.)
- **Claim Button** - Large green button to claim rewards
- **Toggle Button** - Bottom-left corner button (🎁 icon)

#### Design Highlights
- **Matches Shop Theme** - Same colors, corners, and styling as gamepass/shop GUIs
- **Animated Transitions** - Smooth open/close with back easing
- **Hover Effects** - All buttons have hover animations
- **Auto-Display** - Automatically shows for new players (< 100 coins)
- **Server Integration** - Ready for RemoteEvent connection

#### Color Scheme
Following the repository's shop theme:
- **Container Background**: `RGB(28, 25, 45)` - Dark purple
- **Container Stroke**: `RGB(100, 60, 200)` - Purple accent
- **Title Bar**: `RGB(40, 32, 65)` - Darker purple
- **Items Background**: `RGB(35, 30, 55)` - Mid purple
- **Item Cards**: `RGB(45, 38, 70)` - Lighter purple
- **Claim Button**: `RGB(100, 200, 100)` - Green
- **Close Button**: `RGB(200, 50, 50)` - Red
- **Toggle Button**: `RGB(100, 60, 200)` - Purple

### How to Use

Same methods as GenerateStarterGui.lua:

#### Method A: Command Bar (Recommended)
1. Open the Command Bar (View → Command Bar)
2. Copy the ENTIRE contents of `GenerateStarterPackGui.lua`
3. Paste and press Enter

#### Method B: Script Object
1. Insert Script in ServerScriptService
2. Paste the contents
3. Press F5 to run, then F5 to stop

### Customization

#### Change Reward Items
Edit the items in the ItemsFrame:
1. Find Item1, Item2, Item3 in the Explorer
2. Edit the Text property to change rewards
3. Add more items by duplicating an existing item

#### Server-Side Integration
To make claims work, create a RemoteEvent:
1. In ReplicatedStorage, create a folder named "RemoteEvents"
2. Create a RemoteEvent named "ClaimStarterPack"
3. Write a server script to handle the event:

```lua
-- ServerScriptService script
local RS = game:GetService("ReplicatedStorage")
local claimEvent = RS:WaitForChild("RemoteEvents"):WaitForChild("ClaimStarterPack")

claimEvent.OnServerEvent:Connect(function(player)
    -- Check if player has already claimed
    -- Grant 500 coins, trails, etc.
    -- Mark as claimed in PlayerDataManager
    print(player.Name .. " claimed starter pack!")
end)
```

#### Keyboard Shortcut
- Press **P** to toggle the Starter Pack GUI
- Or call `_G.OpenStarterPack()` from other scripts

### GUI Hierarchy

```
StarterGui
└── StarterPackGui (ScreenGui)
    ├── Container (Frame)
    │   ├── UICorner
    │   ├── UIStroke
    │   ├── TitleBar (Frame)
    │   │   ├── UICorner
    │   │   ├── TitleLabel (TextLabel)
    │   │   └── CloseBtn (TextButton)
    │   │       └── UICorner
    │   └── Body (Frame)
    │       ├── UIListLayout
    │       ├── Description (TextLabel)
    │       ├── ItemsFrame (Frame)
    │       │   ├── UICorner
    │       │   ├── UIListLayout
    │       │   ├── UIPadding
    │       │   ├── Item1 (TextLabel)
    │       │   │   ├── UICorner
    │       │   │   └── UIPadding
    │       │   ├── Item2 (TextLabel)
    │       │   │   ├── UICorner
    │       │   │   └── UIPadding
    │       │   └── Item3 (TextLabel)
    │       │       ├── UICorner
    │       │       └── UIPadding
    │       └── ClaimBtn (TextButton)
    │           └── UICorner
    ├── StarterPackToggle (TextButton)
    │   ├── UICorner
    │   └── UIStroke
    └── StarterPackScript (LocalScript)
```

---

## Comparison: Main Menu vs Starter Pack

| Feature | GenerateStarterGui.lua | GenerateStarterPackGui.lua |
|---------|------------------------|---------------------------|
| **Style** | Custom main menu | Shop/gamepass theme |
| **Purpose** | Game navigation | Welcome/rewards |
| **Buttons** | Play, Settings, Shop, Leaderboard | Claim, Toggle |
| **Position** | Center overlay | Center modal |
| **Toggle** | ESC key | P key |
| **Auto-show** | No | Yes (new players) |
| **Size** | 40% x 60% | 50% x 55% |
| **Corner Button** | No | Yes (bottom-left) |

---

## Tips for Both GUIs

### Integration
Both GUIs can coexist in your game:
- Main Menu for navigation
- Starter Pack for new player onboarding

### Global Functions
- `_G.ToggleMainMenu()` - Toggle main menu
- `_G.OpenStarterPack()` - Open starter pack

### Notifications
Both GUIs use `_G.Notify()` if available. Ensure your notification system is loaded first.

### Mobile Support
Both GUIs are mobile-friendly with:
- Relative sizing (UDim2 scale values)
- Touch-enabled buttons
- UIAspectRatioConstraints (Main Menu)
- Responsive layouts

---

**Created**: 2026-02-17  
**Version**: 2.0  
**Scripts**: GenerateStarterGui.lua, GenerateStarterPackGui.lua  
**Purpose**: One-time GUI generation with full functionality  
**License**: Use freely within this project
