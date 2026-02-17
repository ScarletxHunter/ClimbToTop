# Setup Instructions for New Features

## Overview
This document explains the new features added and how to configure them.

## Features Added

### 1. ✅ Skill Bomber Timer Fix
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
- Special action buttons only appear during active rounds (Playing state)
- Backpack tool UI is already disabled in LoadingScreenScript.lua and TransitionScript.lua
