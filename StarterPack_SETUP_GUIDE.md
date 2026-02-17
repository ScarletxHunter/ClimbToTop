# StarterPack Setup Guide

This guide explains how to set up and customize the StarterPack reward system for your game.

## 🚀 Quick Setup

### Step 1: Run the Setup Script

1. Open your game in Roblox Studio
2. Find the `SetupStarterPack.lua` script in the file explorer
3. Move it to `ServerScriptService` or `Workspace`
4. Run the game in Studio (F5)
5. Check the output console for confirmation messages

The script will automatically:
- ✅ Create the `ClaimStarterPack` RemoteEvent
- ✅ Create the `CheckStarterPackClaim` RemoteFunction
- ✅ Create the `StarterPackRewardHandler` script

### Step 2: Verify the Setup

After running the setup script, you should see in the Explorer:

```
ReplicatedStorage
└── RemoteEvents
    ├── ClaimStarterPack (RemoteEvent)
    └── CheckStarterPackClaim (RemoteFunction)

ServerScriptService
└── StarterPackRewardHandler (Script)
```

### Step 3: Delete the Setup Script

Once you've confirmed the setup worked, you can safely delete `SetupStarterPack.lua` from ServerScriptService or Workspace.

## ⚙️ Customizing Rewards

To customize the rewards, edit the `STARTER_PACK_REWARDS` table in `StarterPackRewardHandler`:

```lua
local STARTER_PACK_REWARDS = {
    Coins = 5000,      -- Amount of coins to give
    Trail = "Blue",    -- Trail name (must match trail names in your game)
    Wins = 1,          -- Number of wins to give
}
```

### Available Trail Names

Make sure the trail name matches exactly with the trails in your game. Common trail names include:
- "Blue"
- "Red"
- "Green"
- "Rainbow"
- etc.

## 🎮 How It Works

### For Players

1. **New Players**: When a new player joins the game, they will see the StarterPack GUI automatically pop up after 2.5 seconds
2. **Claiming**: Players click the "CLAIM STARTER PACK" button to receive their rewards
3. **One-Time Only**: Each player can only claim the starter pack once per account
4. **Returning Players**: Players who have already claimed will not see the auto-prompt

### For Developers

The system uses three main components:

1. **StarterPackGui.lua** (Client-side)
   - Shows the StarterPack GUI
   - Auto-opens for new players
   - Handles claim button clicks

2. **StarterPackRewardHandler.lua** (Server-side)
   - Validates claim requests
   - Gives rewards (coins, trails, wins)
   - Tracks who has claimed using DataStore
   - Sends notifications to players

3. **RemoteEvents**
   - `ClaimStarterPack`: Client fires this to claim rewards
   - `CheckStarterPackClaim`: Client uses this to check if already claimed

## 🎁 Reward Details

### Coins
- Added to player's `leaderstats.Coins`
- Also synced with `PlayerDataManager`

### Trail
- Added to player's `OwnedTrails` in PlayerDataManager
- Players can equip it from the trail shop

### Wins
- Added to player's `leaderstats.Wins`
- Also synced with `PlayerDataManager`

## 🔧 Troubleshooting

### "Already claimed today" message for new players

This shouldn't happen, but if it does:
- Check that the DataStore name is unique (`StarterPack_V1`)
- In Studio, player IDs are negative and don't save to DataStore

### Rewards not being given

1. Check that `PlayerDataManager` exists in `ServerScriptService` or `ServerScriptService.GameScripts`
2. Verify that the player has `leaderstats` created
3. Check the output console for error messages

### Auto-prompt not showing

1. Verify `CheckStarterPackClaim` RemoteFunction exists in `ReplicatedStorage.RemoteEvents`
2. Check that `StarterPackRewardHandler` is running (should print "✅ StarterPackRewardHandler loaded successfully!")
3. Try manually opening the GUI by clicking the 🎁 button in the bottom-left corner

### Trail not appearing in player's inventory

1. Verify the trail name matches exactly (case-sensitive)
2. Check that `PlayerDataManager.AddTrail()` function exists
3. The trail will be added to `OwnedTrails`, not `PermanentTrails`

## 📝 Integration Notes

### Notification System
The reward handler uses the existing notification system:
- Looks for `RemoteEvents.NotifyClient` RemoteEvent
- Sends notifications for successful claims and errors

### Data Persistence
- Uses DataStore name: `StarterPack_V1`
- Stores claim status as: `Claimed_[UserId]`
- Claim status is permanent (one-time claim per account)

### Player Data Integration
The system automatically integrates with:
- `leaderstats.Coins`
- `leaderstats.Wins`
- `PlayerDataManager` (if available)

## 🎨 GUI Design

The StarterPack GUI matches the existing game theme:
- Purple/dark theme matching shop GUIs
- Animated open/close transitions
- Responsive design for mobile/desktop
- Toggle button in bottom-left corner (🎁)

## 📊 Testing in Studio

When testing in Studio:
- Player UserIds are negative in Studio
- DataStore won't persist between sessions in Studio
- Each time you restart Studio, players can claim again
- This is normal Studio behavior

## 🚨 Important Notes

1. **One-Time Setup**: The `SetupStarterPack.lua` script only needs to be run once
2. **Don't Delete**: Keep `StarterPackRewardHandler.lua` - it's needed for the system to work
3. **DataStore**: The system uses DataStore to track claims, so it works across servers
4. **Backwards Compatible**: The system gracefully handles missing components (will print warnings instead of breaking)

## 📞 Support

If you encounter issues:
1. Check the Output console for error messages
2. Verify all components are in the correct locations
3. Make sure DataStore is enabled in Studio (Game Settings > Security)
4. Check that the reward values in the configuration are valid
