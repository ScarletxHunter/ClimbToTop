# Setup Instructions for New Features

## Overview
This document explains the new features added and how to configure them.

## Features Added

### 1. 🎮 Main Menu GUI (StarterGui)
- **New File:** `MainMenuGui.lua`
- **Description:** Complete main menu system with modern UI design and ImageButtons
- **Features:**
  - Semi-transparent dark background overlay
  - Main menu frame with purple/dark theme matching existing GUIs
  - All buttons are ImageButtons (not TextButtons) with placeholder images
  - **Buttons included:**
    - ▶ **Play Button** - Green themed, ready for game start logic
    - ⚙ **Settings Button** - Purple themed, ready for settings toggle
    - 🛒 **Shop Button** - Gold themed, ready for shop integration
    - 🏆 **Leaderboard Button** - Blue themed, ready for leaderboard display
    - ✕ **Close Button** - Red themed, positioned in top-right corner
  - Modern UI elements:
    - UICorner for all rounded edges
    - UIStroke for button outlines with hover effects
    - UIAspectRatioConstraints for consistent sizing across devices
    - UIPadding for proper spacing
    - UIListLayout for organized button placement
  - **Mobile-friendly:**
    - Automatic scaling based on screen size
    - Touch-enabled with proper button sizing
    - Responsive layout adjustments for small screens
  - **Interactive effects:**
    - Hover animations (color changes, stroke thickness)
    - Press/click animations (button size changes)
    - Smooth opening/closing animations
  - **Keyboard shortcut:** Press ESC to toggle menu
  - **Global function:** `_G.ToggleMainMenu()` available for scripts
- **Placeholder Images:** All ImageButtons use `rbxassetid://0` - replace with actual asset IDs
- **Ready for Scripting:** All buttons have descriptive names and placeholder click handlers

### 2. ✅ Skill Bomber Timer Fix
- **Fixed:** Removed "??" question marks from the bomber skill countdown
- **Changed:** Now displays "💣 3", "💣 2", "💣 1" instead of "?? 3", etc.
- **File:** `SkillHandler.lua` (lines 765, 774)

### 2. ✅ Teleport Skill Distance Doubled
- **Changed:** Teleport distance doubled from 16→32 studs (default) and max from 24→48 studs
- **File:** `SkillHandler.lua` (line 455)

### 3. 🎁 StarterPack GUI
- **New File:** `StarterPackGui.lua`
- **Description:** New player welcome GUI matching the TrailShop/GamepassShop theme
- **Features:**
  - Purple/dark theme matching existing shops
  - Shows starter pack items (500 coins, speed boost, rainbow trail)
  - Toggle button in bottom left corner (gift icon 🎁)
  - Claim button to receive starter pack
- **TODO:** Connect to server-side rewards system to actually grant items

### 4. 💀 Kill All Players Button
- **New Files:** `SpecialActionsGui.lua`, `SpecialActionsHandler.lua`
- **Description:** ImageButton that allows players to eliminate all other players in the match
- **Location:** Right side of screen, only visible during "Playing" state
- **Features:**
  - Red button with skull emoji (💀)
  - Prompts for Robux purchase via dev product
  - Confirmation dialog before purchase
  - Only works during active rounds

### 5. 🏁 Skip to Finish Line Button
- **New Files:** `SpecialActionsGui.lua`, `SpecialActionsHandler.lua`
- **Description:** ImageButton that teleports player to the End/GamepassEnd part
- **Location:** Right side of screen below Kill All button, only visible during "Playing" state
- **Features:**
  - Yellow/gold button with flag emoji (🏁)
  - Prompts for Robux purchase via dev product
  - Confirmation dialog before purchase
  - Teleports to End or GamepassEnd part
  - Only works during active rounds

## Setup Instructions

### For Main Menu GUI:

The MainMenuGui is ready to use with minimal setup:

#### Step 1: Place the Script
1. In Roblox Studio, place `MainMenuGui.lua` in **StarterPlayer → StarterPlayerScripts** or **StarterGui**
2. The script will automatically create the GUI when a player joins

#### Step 2: Replace Placeholder Images (Optional)
All ImageButtons use placeholder image IDs (`rbxassetid://0`). To add custom images:

1. Upload your images to Roblox (Create → Development Items → Decals)
2. Get the asset IDs for each image
3. Update the image IDs in `MainMenuGui.lua`:
   - **Title Image:** Line ~73 - `titleLabel.Image = "rbxassetid://YOUR_ID_HERE"`
   - **Play Button:** Line ~133 - Pass image ID to `createImageButton`
   - **Settings Button:** Line ~136 - Pass image ID to `createImageButton`
   - **Shop Button:** Line ~139 - Pass image ID to `createImageButton`
   - **Leaderboard Button:** Line ~142 - Pass image ID to `createImageButton`
   - **Close Button:** Line ~151 - `closeButton.Image = "rbxassetid://YOUR_ID_HERE"`

Example:
```lua
local playButton = createImageButton("PlayButton", 1, "▶ PLAY", "rbxassetid://123456789")
```

#### Step 3: Connect Button Functionality
The buttons have placeholder click handlers. Connect them to your game logic:

**Play Button** (Line ~267):
```lua
playButton.Activated:Connect(function()
    -- Add your game start logic
    -- Example: Fire a RemoteEvent to start the game
    local re = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteEvents")
    if re and re:FindFirstChild("StartGame") then
        re.StartGame:FireServer()
    end
    _G.ToggleMainMenu()  -- Close menu after clicking
end)
```

**Settings Button** (Line ~272):
```lua
settingsButton.Activated:Connect(function()
    -- Toggle existing settings GUI
    if _G.OpenSettings then
        _G.OpenSettings()
    end
    _G.ToggleMainMenu()  -- Close main menu
end)
```

**Shop Button** (Line ~278):
```lua
shopButton.Activated:Connect(function()
    -- Toggle existing shop GUI
    local shopGui = plr.PlayerGui:FindFirstChild("NewShopGui")
    if shopGui then
        local content = shopGui:FindFirstChild("Content")
        if content then
            content.Visible = not content.Visible
        end
    end
    _G.ToggleMainMenu()  -- Close main menu
end)
```

**Leaderboard Button** (Line ~284):
```lua
leaderboardButton.Activated:Connect(function()
    -- Toggle leaderboard
    local lbGui = plr.PlayerGui:FindFirstChild("NewLeaderboardGui")
    if lbGui then
        local panel = lbGui:FindFirstChild("Panel")
        if panel then
            panel.Visible = not panel.Visible
        end
    end
    _G.ToggleMainMenu()  -- Close main menu
end)
```

#### Step 4: Control Menu Visibility
Use the global function to show/hide the menu from other scripts:

```lua
-- From any script:
_G.ToggleMainMenu()  -- Toggle visibility

-- Or directly:
local mainMenu = plr.PlayerGui:FindFirstChild("MainMenuGui")
if mainMenu then
    local frame = mainMenu:FindFirstChild("MainMenuFrame")
    local bg = mainMenu:FindFirstChild("Background")
    frame.Visible = true  -- or false
    bg.Visible = true     -- or false
end
```

#### Step 5: Keyboard Shortcut
Players can press **ESC** to toggle the menu (already configured in the script).

#### Step 6: Mobile Testing
The GUI automatically adjusts for mobile devices. Test on different screen sizes to ensure proper scaling.

### For StarterPack GUI:
1. The GUI is ready to use as-is
2. To grant actual rewards, you need to:
   - Create a RemoteEvent in `ReplicatedStorage/RemoteEvents` called `ClaimStarterPack`
   - Create server-side handler to give coins, trails, etc.
   - Update the claim button in `StarterPackGui.lua` to fire the event

### For Special Action Buttons:

#### Step 1: Create Dev Products in Roblox
1. Go to Roblox Creator Dashboard
2. Navigate to your game → Monetization → Dev Products
3. Create two dev products:
   - **Kill All Players** (suggested price: 100-500 Robux)
   - **Skip to Finish** (suggested price: 50-200 Robux)
4. Note the Product IDs for each

#### Step 2: Configure Product IDs
1. Open `SpecialActionsGui.lua`
2. Update lines with KILL_ALL_PRODUCT_ID and SKIP_PRODUCT_ID:
   ```lua
   local KILL_ALL_PRODUCT_ID = 1234567890  -- Example: Replace with your actual product ID
   local SKIP_PRODUCT_ID = 9876543210      -- Example: Replace with your actual product ID
   ```

3. Open `SpecialActionsHandler.lua`
4. Update the same product ID constants with matching values:
   ```lua
   local KILL_ALL_PRODUCT_ID = 1234567890  -- Must match client-side value
   local SKIP_PRODUCT_ID = 9876543210      -- Must match client-side value
   ```

#### Step 3: Integrate Purchase Handler
The file `CoinRemotes.lua` already has a `ProcessReceipt` function. You need to merge the special actions handler:

1. Open `CoinRemotes.lua`
2. Search for the `MarketplaceService.ProcessReceipt` function
3. Add cases for the new product IDs before the existing coin product handling
4. Reference the logic in `SpecialActionsHandler.lua` (search for the processReceipt function)

#### Step 4: Security Note
**⚠️ IMPORTANT:** The special action buttons are now secured and will only work when:
1. Valid product IDs are configured (not 0)
2. Purchase is completed through MarketplaceService
3. ProcessReceipt validates the purchase

If product IDs are not configured, players will see a "Not Available" message instead of being able to exploit the system.

#### Step 5: Create End Part
If you don't have an "End" or "GamepassEnd" part in your maps:
1. Add a part named "End" or "GamepassEnd" at the finish line of each map
2. The Skip to Finish button will teleport players to this part

## File Locations
All new files are in the root directory:
- `MainMenuGui.lua` (new - should be in StarterPlayerScripts or StarterGui)
- `SkillHandler.lua` (modified)
- `StarterPackGui.lua` (new - should be in StarterGui or PlayerGui)
- `SpecialActionsGui.lua` (new - should be in StarterGui or PlayerGui)
- `SpecialActionsHandler.lua` (new - should be in ServerScriptService)

## Questions Answered

### "Can I make it so if u dont win u can win coins?"
Yes! You can modify the `GameManager.lua` to award coins to all players based on placement or participation. Look for the win handling code and add coin rewards for non-winners.

### "How do I change game sounds again for maps etc?"
Check `SoundManager.lua` - this handles all game sounds. You can modify the sound IDs there to change music and sound effects for different maps and game states.

## Notes
- All GUIs match the existing purple/dark theme used in TrailShop and GamepassShop
- MainMenuGui uses modern UI design with ImageButtons, UICorner, UIStroke, and mobile-friendly scaling
- All ImageButtons in MainMenuGui use placeholder images (rbxassetid://0) that should be replaced with actual assets
- Special action buttons only appear during active rounds (Playing state)
- Backpack tool UI is already disabled in LoadingScreenScript.lua and TransitionScript.lua
