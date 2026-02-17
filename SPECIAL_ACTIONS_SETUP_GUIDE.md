# Special Actions Setup Guide

This guide explains how to use the command bar generator script to add Kill All Players and Skip to Finish buttons, and fix the StarterPack gamepass system.

## 📋 What This Script Does

The `GenerateSpecialActions_CommandBar.lua` script automatically creates:

1. **Kill All Players Button (💀)** - A red ImageButton that prompts a Robux purchase and kills all other players
2. **Skip to Finish Button (🏁)** - A green ImageButton that prompts a Robux purchase and teleports the player to the finish line
3. **StarterPack Gamepass Fix** - Updates the StarterPack reward handler to require gamepass ownership (ID: 1708836892)
4. **Server Integration** - Updates the ProcessReceipt handler to handle the new dev product purchases

## 🚀 Quick Start

### Step 1: Run the Generator Script

1. Open your game in Roblox Studio
2. Open the Command Bar (View → Command Bar)
3. Copy the entire contents of `GenerateSpecialActions_CommandBar.lua`
4. Paste it into the Command Bar and press Enter
5. Watch the output for confirmation messages

### Step 2: Create Dev Products

1. Go to the [Create page](https://create.roblox.com/) on Roblox
2. Navigate to your game → Monetization → Dev Products
3. Create two new dev products:
   - **Kill All Players** (suggested price: 25-50 Robux)
   - **Skip to Finish** (suggested price: 10-25 Robux)
4. Note the Product IDs for each

### Step 3: Configure Product IDs

#### In StarterGui (Client-Side):
1. Navigate to: `StarterGui → SpecialActionsGui → SpecialActionsScript`
2. Edit the configuration at the top:
```lua
-- ⚙️ CONFIGURATION - Set your Dev Product IDs here
local KILL_ALL_PRODUCT_ID = 123456789  -- Replace with your actual ID
local SKIP_PRODUCT_ID = 987654321      -- Replace with your actual ID
```

#### In ServerScriptService (Server-Side):
1. Navigate to: `ServerScriptService → SpecialActionsHandler`
2. Edit the configuration at the top (must match client-side):
```lua
-- ⚙️ CONFIGURATION - Set your Dev Product IDs here
local KILL_ALL_PRODUCT_ID = 123456789  -- Must match client-side
local SKIP_PRODUCT_ID = 987654321      -- Must match client-side
```

### Step 4: Test In-Game

1. Start a test server with 2+ players
2. Start a round (buttons only appear during "Playing" state)
3. Click the Kill All or Skip buttons
4. Verify the purchase prompts appear
5. Test with actual Robux purchases (in published game)

### Step 5: Clean Up

1. Delete `GenerateSpecialActions_CommandBar.lua` from your game
2. You can now edit the generated GUIs manually in StarterGui if needed

## 🎨 GUI Specifications

### Kill All Players Button (💀)
- **Size**: 70x70 pixels
- **Position**: Right side of screen, middle-ish
- **Color**: Red `Color3.fromRGB(200, 50, 50)`
- **Icon**: 💀 emoji
- **Text**: "KILL ALL"
- **Visibility**: Only during "Playing" game state

### Skip to Finish Button (🏁)
- **Size**: 70x70 pixels
- **Position**: Right side, below Kill All button
- **Color**: Green `Color3.fromRGB(50, 200, 50)`
- **Icon**: 🏁 flag emoji
- **Text**: "SKIP"
- **Visibility**: Only during "Playing" game state

## 🔧 How It Works

### Kill All Players
1. Player clicks the Kill All button
2. Client prompts dev product purchase
3. Player confirms and pays Robux
4. Server receives ProcessReceipt callback
5. Server validates the purchase
6. Server kills all other players in the game
7. Player receives success notification

### Skip to Finish
1. Player clicks the Skip button
2. Client prompts dev product purchase
3. Player confirms and pays Robux
4. Server receives ProcessReceipt callback
5. Server validates the purchase
6. Server finds the "End" or "GamepassEnd" part
7. Server teleports player to the finish line
8. Player receives success notification

### StarterPack Gamepass Check
The generator script updates `StarterPackRewardHandler` to:
1. Check if player owns gamepass ID 1708836892 BEFORE granting rewards
2. Show error message if they don't own it: "You need the Starter Pack gamepass!"
3. Show warning if already claimed: "Already claimed!"
4. Only grant rewards if both conditions are met

## 🔐 Security Features

- All purchases are validated server-side via ProcessReceipt
- Product IDs are checked before granting actions
- Game state is verified (must be "Playing")
- Direct remote event calls are blocked (only ProcessReceipt can grant actions)
- Gamepass ownership is verified before granting StarterPack rewards

## 📁 Files Created

After running the generator, you'll have:

1. **StarterGui/SpecialActionsGui**
   - Contains both ImageButtons
   - Includes LocalScript for client-side logic
   - Handles button clicks and purchase prompts

2. **ServerScriptService/SpecialActionsHandler**
   - Server-side purchase validation
   - Kill All and Skip to Finish functions
   - Integration with ProcessReceipt

3. **Updated: ServerScriptService/CoinRemotes**
   - ProcessReceipt now checks for special action purchases
   - Integrates with existing coin purchase system

4. **Updated: ServerScriptService/StarterPackRewardHandler**
   - Now requires gamepass ownership (ID: 1708836892)
   - Shows appropriate error messages

## 🐛 Troubleshooting

### Buttons don't appear
- Check that GameState value exists in ReplicatedStorage/GameValues
- Verify the game is in "Playing" state
- Check the Output window for errors

### Purchase prompts don't show
- Verify you've set the Product IDs in BOTH client and server scripts
- Check that the Product IDs are correct and exist in your game
- Ensure the game is published (dev products only work in published games)

### Purchases don't work
- Check the Output window for ProcessReceipt errors
- Verify Product IDs match on client and server
- Ensure CoinRemotes.lua was updated correctly
- Check that _G.ProcessSpecialActionPurchase is being called

### StarterPack still gives free rewards
- Verify StarterPackRewardHandler was updated
- Check that the gamepass ID (1708836892) is correct
- Look for error messages in the Output window
- Ensure the player doesn't actually own the gamepass

## 💡 Customization

### Change Button Positions
Edit the Position property in SpecialActionsGui:
```lua
killAllBtn.Position = UDim2.new(1, -90, 0.5, -100)  -- Right side, upper-middle
skipBtn.Position = UDim2.new(1, -90, 0.5, 0)        -- Right side, lower-middle
```

### Change Button Colors
Edit the BackgroundColor3 properties:
```lua
killAllBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)   -- Red
skipBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)      -- Green
```

### Change Button Text
Edit the Text properties in the TextLabels:
```lua
killText.Text = "KILL ALL"
skipText.Text = "SKIP"
```

### Add Custom Notifications
The scripts use the existing `_G.Notify` system. You can customize messages:
```lua
notifyPlayer(player, "💀 Kill All Activated!", 
    "Message here", 
    3,          -- duration in seconds
    "success")  -- type: "success", "warning", "error"
```

## 📝 Notes

- The buttons are **ImageButtons** (not TextButtons) as specified
- They use emojis for icons (💀 and 🏁)
- They match the existing purple/dark theme from other GUIs
- They only appear during "Playing" state
- All actions are server-validated for security
- The system integrates with existing notification and game state systems

## ✅ Checklist

After setup, verify:

- [ ] Generator script ran without errors
- [ ] SpecialActionsGui exists in StarterGui
- [ ] SpecialActionsHandler exists in ServerScriptService
- [ ] Dev Products created on Roblox website
- [ ] Product IDs set in client script
- [ ] Product IDs set in server script
- [ ] CoinRemotes.lua ProcessReceipt updated
- [ ] StarterPackRewardHandler gamepass check added
- [ ] Buttons appear during "Playing" state
- [ ] Buttons hide during other states
- [ ] Purchase prompts work
- [ ] Kill All function works (tested)
- [ ] Skip to Finish function works (tested)
- [ ] StarterPack requires gamepass
- [ ] Generator script deleted

## 🎯 Support

If you encounter issues:
1. Check the Output window in Roblox Studio for errors
2. Verify all configuration steps were completed
3. Ensure Product IDs are correct
4. Test in a published game with Robux
5. Check that all generated files exist in the correct locations
