# Special Actions Testing Checklist

This document provides a comprehensive testing checklist for the Special Actions system (Kill All Players, Skip to Finish, and StarterPack Gamepass Fix).

## 🧪 Pre-Testing Setup

Before testing, ensure:
- [ ] Generator script has been run successfully
- [ ] SpecialActionsGui exists in StarterGui
- [ ] SpecialActionsHandler exists in ServerScriptService
- [ ] Dev Product IDs are set in both client and server scripts
- [ ] CoinRemotes.lua has been updated with ProcessReceipt integration
- [ ] StarterPackRewardHandler has been updated with gamepass check
- [ ] Game is published to Roblox

## 📋 Test Categories

### 1. GUI Generation Tests

#### 1.1 Generator Script Execution
- [ ] Script runs without errors
- [ ] Prints all completion messages
- [ ] Creates SpecialActionsGui in StarterGui
- [ ] Creates SpecialActionsHandler in ServerScriptService
- [ ] Updates CoinRemotes.lua ProcessReceipt
- [ ] Updates StarterPackRewardHandler
- [ ] Old GUI/handlers are removed before creating new ones

#### 1.2 GUI Structure Verification
Navigate to `StarterGui → SpecialActionsGui`:
- [ ] ScreenGui exists with correct name
- [ ] ResetOnSpawn = false
- [ ] Contains KillAllButton ImageButton
- [ ] Contains SkipToFinishButton ImageButton
- [ ] Contains LocalScript named "SpecialActionsScript"

#### 1.3 Kill All Button Verification
Check `KillAllButton` properties:
- [ ] Size = 70x70 pixels
- [ ] Position = Right side, middle-ish (1, -90, 0.5, -100)
- [ ] BackgroundColor3 = Red (200, 50, 50)
- [ ] Has UICorner with 16px radius
- [ ] Has UIStroke with white color, 3px thickness
- [ ] Contains emoji icon "💀"
- [ ] Contains text label "KILL ALL"
- [ ] Initially Visible = false

#### 1.4 Skip Button Verification
Check `SkipToFinishButton` properties:
- [ ] Size = 70x70 pixels
- [ ] Position = Below Kill All (1, -90, 0.5, -20)
- [ ] BackgroundColor3 = Green (50, 200, 50)
- [ ] Has UICorner with 16px radius
- [ ] Has UIStroke with white color, 3px thickness
- [ ] Contains emoji icon "🏁"
- [ ] Contains text label "SKIP"
- [ ] Initially Visible = false

### 2. Configuration Tests

#### 2.1 Product ID Configuration
In `StarterGui → SpecialActionsGui → SpecialActionsScript`:
- [ ] KILL_ALL_PRODUCT_ID variable exists at top
- [ ] SKIP_PRODUCT_ID variable exists at top
- [ ] Default values are 0
- [ ] Configuration comment is clear

In `ServerScriptService → SpecialActionsHandler`:
- [ ] KILL_ALL_PRODUCT_ID variable exists at top
- [ ] SKIP_PRODUCT_ID variable exists at top
- [ ] Default values are 0
- [ ] Configuration comment is clear

#### 2.2 StarterPack Gamepass Configuration
In `ServerScriptService → StarterPackRewardHandler`:
- [ ] STARTERPACK_GAMEPASS_ID = 1708836892
- [ ] Gamepass check added before rewards
- [ ] Error notification for missing gamepass
- [ ] Already claimed check still works

### 3. Visibility Tests

#### 3.1 Game State Integration
Start a test server:
- [ ] Buttons are hidden during "Waiting" state
- [ ] Buttons are hidden during "Intermission" state
- [ ] Buttons are hidden during "Voting" state
- [ ] Buttons appear during "Playing" state
- [ ] Buttons hide again after round ends
- [ ] Visibility updates automatically with state changes

#### 3.2 Multi-Round Testing
- [ ] Buttons hide/show correctly across multiple rounds
- [ ] No memory leaks or duplicate buttons
- [ ] State listener continues working after multiple rounds

### 4. Purchase Flow Tests

#### 4.1 Kill All Button - Unconfigured
Set KILL_ALL_PRODUCT_ID = 0:
- [ ] Click button shows "Not Available" notification
- [ ] No purchase prompt appears
- [ ] No errors in output

#### 4.2 Kill All Button - Configured
Set KILL_ALL_PRODUCT_ID to valid product ID:
- [ ] Click button prompts purchase dialog
- [ ] Purchase dialog shows correct product info
- [ ] Cancel works without errors
- [ ] Confirm proceeds to payment

#### 4.3 Skip Button - Unconfigured
Set SKIP_PRODUCT_ID = 0:
- [ ] Click button shows "Not Available" notification
- [ ] No purchase prompt appears
- [ ] No errors in output

#### 4.4 Skip Button - Configured
Set SKIP_PRODUCT_ID to valid product ID:
- [ ] Click button prompts purchase dialog
- [ ] Purchase dialog shows correct product info
- [ ] Cancel works without errors
- [ ] Confirm proceeds to payment

### 5. Server-Side Function Tests

#### 5.1 Kill All Players Function
During "Playing" state with 3+ players:
- [ ] Purchaser clicks Kill All and completes purchase
- [ ] All other players' characters die (Health = 0)
- [ ] Purchaser's character survives
- [ ] Success notification sent to purchaser
- [ ] Correct count shown in notification
- [ ] Server prints kill count to output

Edge cases:
- [ ] Works with only 2 players (kills 1)
- [ ] Works if some players already dead
- [ ] Doesn't crash if purchaser has no character
- [ ] Shows warning if not in "Playing" state

#### 5.2 Skip to Finish Function
During "Playing" state with "End" part in workspace:
- [ ] Purchaser clicks Skip and completes purchase
- [ ] Player teleports to End part location
- [ ] Player teleports 5 studs above End part
- [ ] Success notification sent to purchaser
- [ ] Server prints skip message to output

Edge cases:
- [ ] Works with "GamepassEnd" part instead of "End"
- [ ] Searches descendants if not in workspace root
- [ ] Shows error if no End part found
- [ ] Shows error if player has no character
- [ ] Shows warning if not in "Playing" state

### 6. ProcessReceipt Integration Tests

#### 6.1 CoinRemotes Integration
Check `ServerScriptService → CoinRemotes`:
- [ ] ProcessReceipt function exists
- [ ] Calls _G.ProcessSpecialActionPurchase first
- [ ] Returns result if special action handled
- [ ] Falls through to coin products if not special action
- [ ] Coin purchases still work correctly

#### 6.2 Purchase Receipt Handling
With valid product IDs:
- [ ] Kill All purchase grants action immediately
- [ ] Skip purchase grants action immediately
- [ ] Returns PurchaseGranted for successful actions
- [ ] Returns NotProcessedYet for unknown products
- [ ] No duplicate purchases processed
- [ ] Works with player reconnect scenarios

### 7. StarterPack Gamepass Tests

#### 7.1 Gamepass Ownership Check
Test with player WITHOUT gamepass (ID 1708836892):
- [ ] Claim button shows gamepass required error
- [ ] Error notification: "You need the Starter Pack gamepass!"
- [ ] No rewards are granted
- [ ] Claim status remains unclaimed

Test with player WITH gamepass (ID 1708836892):
- [ ] First claim grants all rewards successfully
- [ ] Rewards include: Coins, Trail, Wins
- [ ] Success notification shows reward details
- [ ] Claim status is saved

#### 7.2 Already Claimed Check
With gamepass owned and already claimed:
- [ ] Second claim attempt shows "Already claimed!" warning
- [ ] No duplicate rewards granted
- [ ] Claim status persists across sessions

### 8. Security Tests

#### 8.1 Server Validation
- [ ] Direct RemoteEvent calls are blocked
- [ ] Only ProcessReceipt can grant actions
- [ ] Product IDs are validated before granting
- [ ] Game state is checked before actions
- [ ] Player existence is verified
- [ ] Character existence is verified

#### 8.2 Exploit Prevention
- [ ] Cannot trigger actions without purchase
- [ ] Cannot bypass gamepass check
- [ ] Cannot claim StarterPack without ownership
- [ ] Cannot claim StarterPack multiple times
- [ ] Product ID = 0 prevents all purchases
- [ ] Invalid product IDs handled gracefully

### 9. Notification Tests

#### 9.1 Client Notifications
- [ ] "Not Available" shows for unconfigured products
- [ ] Notifications use existing _G.Notify system
- [ ] Proper notification types: success, warning, error
- [ ] Proper durations (3 seconds default)

#### 9.2 Server Notifications
- [ ] Kill All success notification sent to purchaser
- [ ] Skip success notification sent to purchaser
- [ ] Error notifications sent for failures
- [ ] StarterPack notifications work correctly
- [ ] Notifications show correct dynamic content

### 10. Mobile Compatibility Tests

Test on mobile device or emulator:
- [ ] Buttons are easily tappable (70x70 is good size)
- [ ] Buttons don't overlap with other UI
- [ ] Position is comfortable for thumb reach
- [ ] Text is readable on small screens
- [ ] Emojis render correctly
- [ ] Purchase prompts work on mobile

### 11. Performance Tests

#### 11.1 Memory Usage
- [ ] No memory leaks after multiple rounds
- [ ] GUI doesn't duplicate in PlayerGui
- [ ] Event connections are properly managed
- [ ] No orphaned scripts or objects

#### 11.2 Network Performance
- [ ] Button clicks are responsive
- [ ] Purchase prompts appear quickly
- [ ] Server actions execute within 1 second
- [ ] Notifications appear promptly
- [ ] No excessive RemoteEvent traffic

### 12. Edge Case Tests

#### 12.1 Player Scenarios
- [ ] Late joiners see buttons correctly
- [ ] Player leaving during purchase
- [ ] Player dying during purchase
- [ ] Player resetting during action
- [ ] Multiple simultaneous purchases

#### 12.2 Map Scenarios
- [ ] Works with different map layouts
- [ ] Handles missing End part gracefully
- [ ] Works with End part in folders
- [ ] Works with multiple End parts
- [ ] Handles map changes during round

#### 12.3 Timing Scenarios
- [ ] Purchase at exact round start
- [ ] Purchase at exact round end
- [ ] Purchase during state transition
- [ ] Multiple purchases in quick succession
- [ ] Purchase with high server lag

## 🐛 Common Issues & Solutions

### Buttons Not Appearing
**Check:**
- GameState exists in ReplicatedStorage/GameValues
- Game is in "Playing" state
- LocalScript is running (check Output)
- No errors in script

**Solution:**
- Verify GameState path is correct
- Check that ReplicatedStorage has GameValues folder
- Ensure LocalScript is enabled

### Purchase Prompts Not Showing
**Check:**
- Product IDs are set and valid
- Product IDs match between client and server
- Products exist in game monetization settings
- Game is published

**Solution:**
- Create products on Roblox Create page
- Copy exact product IDs
- Set IDs in both scripts
- Publish game to Roblox

### Actions Not Working After Purchase
**Check:**
- ProcessReceipt integration in CoinRemotes
- _G.ProcessSpecialActionPurchase exists
- No errors in server output
- Product IDs match

**Solution:**
- Re-run generator script to update CoinRemotes
- Verify ProcessReceipt code is correct
- Check server output for errors
- Test with test purchases (free in Studio)

### StarterPack Giving Free Rewards
**Check:**
- StarterPackRewardHandler has gamepass check
- Gamepass ID is correct (1708836892)
- MarketplaceService is imported
- Check is before reward granting

**Solution:**
- Re-run generator script to add gamepass check
- Verify gamepass ID is correct
- Ensure check runs before giveRewards()
- Test with non-owner account

## ✅ Final Acceptance Checklist

Before marking the feature as complete:
- [ ] All visual specifications met
- [ ] All functionality tests pass
- [ ] No console errors or warnings
- [ ] Works on desktop and mobile
- [ ] Works across multiple rounds
- [ ] StarterPack requires gamepass
- [ ] Security measures in place
- [ ] Performance is acceptable
- [ ] Documentation is complete
- [ ] Code is clean and commented

## 📝 Test Results Template

```
Test Date: _______________
Tester: _______________
Game Version: _______________

GUI Generation: ✅ Pass / ❌ Fail
Configuration: ✅ Pass / ❌ Fail
Visibility: ✅ Pass / ❌ Fail
Purchase Flow: ✅ Pass / ❌ Fail
Kill All Function: ✅ Pass / ❌ Fail
Skip Function: ✅ Pass / ❌ Fail
ProcessReceipt: ✅ Pass / ❌ Fail
StarterPack Gamepass: ✅ Pass / ❌ Fail
Security: ✅ Pass / ❌ Fail
Notifications: ✅ Pass / ❌ Fail
Mobile: ✅ Pass / ❌ Fail
Performance: ✅ Pass / ❌ Fail

Notes:
_______________________________________
_______________________________________
_______________________________________

Overall Result: ✅ PASS / ❌ FAIL
```
