# 🔄 COMPLETE HANDOFF: Hood Omni Hub Mega Edition

## PRIORITY: Continue generating the mega Lua script

### What's Done ✅
1. **GitHub repo exists**: `princeaamir0913-droid/hood-omni-hub` on `main` branch
2. **`underground-war-2.lua`** — pushed and live (710 lines, Underground War 2.0 specific script)
3. **`later-version.lua`** — PARTIALLY generated (660 lines). Has the framework/header/services/UI library but MISSING all game modules
4. **Agent Collab Hub app** — built and working (instant app for coordinating agents)
5. **Research complete** — all 55 games cataloged with features below

### What Needs To Be Done 🔧
1. **GENERATE the full mega hub Lua script** — `later-version.lua` needs to be completed with ALL 55 game modules + universal features. Target: 4000-8000 lines
2. **PUSH to GitHub** — once complete, push `later-version.lua` to `princeaamir0913-droid/hood-omni-hub` on `main`

### Estimated Credits Needed
- **Script generation** (genius level): ~400-600 credits
- **GitHub push**: ~50 credits  
- **Total**: ~500-700 credits

---

## HOW TO GENERATE THE SCRIPT

The best approach is to use Python to generate the Lua file. Write a Python script and run it with:
```
uv run python3 /tmp/generate_mega_hub.py
```

The Python script should output to `/agent/home/later-version.lua`

### Script Structure (Lua output):
```
1. Header banner comment
2. Services & Variables (Players, RunService, etc.)
3. UI Library (tab-based dark theme GUI with toggles/sliders/buttons/dropdowns, toggle with Right Shift)
4. Game Detection System (PlaceId table + game name fallback)
5. Utility Functions (ESP drawer, aimbot core, kill aura, fly, etc.)
6. Universal Features Tab (works in ALL games)
7. Game-Specific Tabs (only shown when detected in that game)
8. Main initialization + notification
```

---

## COMPLETE GAME DATABASE (55 Games)

### HOOD GAMES

**1. Tha Bronx 3** (PlaceId: 16472538603)
- Infinite Money (remote exploit), Auto Dupe Items, Gun Dupe
- Teleport Bypass, Toggle Stamina/Sleep/Hunger
- Silent Aim with FOV circle, ESP (names + distance + health)
- Kill Aura, Gun Mods (no recoil, no spread, rapid fire, infinite ammo)
- Auto Rob, ChatSpy, Fullbright

**2. Gang Wars** (PlaceId: 3689064593)
- Auto Farm Cash, Auto Rob Store
- ESP (players + items), Silent Aim, Kill Aura
- Gun Mods (no recoil, rapid fire, inf ammo)
- Teleport to locations, Speed Boost, Anti-ragdoll

**3. Central Streets** (detect by name "Central Streets")
- Infinite Money, Tool Spawner, Server Crash (optional)
- Silent Aim, ESP, Kill Aura, Gun Mods, Teleport

**4. Philly Streetz 2** (PlaceId: 130700367963690)
- Money Generator (1M per 30 min), Dirty Money Dupe
- Godmode, Repz Stealer, Robbery Autofarm
- Silent Aim, ESP, Aimlock, Instant Interaction, Gun Mods

**5. Da Hood** (PlaceId: 2788229376)
- Aimbot (lock on head/torso), Silent Aim
- ESP (names, health, distance), Kill Aura, Gun Mods
- Fly, Speed Hack, Stomp Aura, Anti-ragdoll, Macro (autostomp)

**6. Street Life Remastered** (detect by name)
- Auto Farm Jobs, Silent Aim, Fist Godmode
- ESP, Gun Mods, Teleport, Speed Boost

**7. South London Remastered** (detect by name)
- Auto Farm, ESP, Aimbot, Gun Mods, Teleport, Speed

**8. Cali Shootout** (detect by name)
- Silent Aim with FOV + team check, WallBang
- ESP, Kill All, Arrest All, Auto Farm Jobs
- Gun Mods, Aimbot, Teleport, Hit Chance slider

**9. Streetz War 2** (detect by name)
- Kill Aura, Kill All, Godmode
- Auto Farm, Auto Deposit/Withdraw
- ESP, Silent Aim, Gun Mods

**10. Outwest Chicago 2** (detect by name)
- Infinite Money, FE Admin Commands
- Silent Aim, ESP, Gun Mods, Teleport

**11. QZ Shootout** (detect by name)
- Silent Aim, ESP, Kill Aura, Gun Mods, Auto Farm

**12. South Bronx** (detect by name)
- Auto Farm, ESP, Aimbot, Gun Mods, Teleport

**13. No Mercy** (detect by name)
- Kill Aura, Aimbot, ESP, Combat Mods, Speed Boost

### BASKETBALL GAMES

**14. Playground Basketball** (detect by name)
- Auto Green, Celebration Unlocker, Dribble Macros
- Speed Boost, Ball Magnet

**15. Basketball Legends** (detect by name)
- Auto Green, Ball Magnet, Speed Changer, Aimbot (ball)
- Ball Reach, Auto Play, Auto Guard, Auto Score, Teleport

### FIGHTING GAMES

**16. Boxing Beta** (detect by name)
- Unlock All Gloves, Glove Changer, Punch Aura
- Kill Aura, Infinite Dodge Stamina, Auto Block, TP Kill, ESP

**17. The Strongest Battlegrounds** (detect by name)
- Kill Aura, Infinite Combo, Auto Block, ESP, Aimbot, Speed

**18. Fantasma PvP** (detect by name)
- Silent Aim, ESP, Kill Aura, Gun Mods, Auto Farm

### FPS GAMES

**19. Rivals** (PlaceId: 17625359962)
- Aimbot (smooth + FOV), Silent Aim
- ESP (box + name + health + distance), Wallhack
- No Recoil, No Spread, Rapid Fire, Fly, Speed

**20. Phantom Forces** (PlaceId: 292439477)
- Aimbot, ESP (box + name), No Recoil, No Spread, Wallhack, Rapid Fire

**21. Frontlines** (detect by name)
- Aimbot, ESP, No Recoil, Silent Aim

**22. Arsenal** (PlaceId: 286090429)
- Aimbot, ESP, Silent Aim, Kill All, Gun Mods

**23. Counter Blox** (PlaceId: 301549746)
- Aimbot, ESP, Wallhack, No Recoil, Bhop

**24. Bad Business** (PlaceId: 3233893879)
- Aimbot, ESP, No Recoil, Silent Aim

### POPULAR GAMES

**25. Blox Fruits** (PlaceId: 2753915549)
- Auto Farm (selected fruit), Auto Quest, Teleport to islands
- ESP (fruits + players), Mastery Farm, Raid Auto-complete
- Fruit Sniper, Sea Event farm

**26. Murder Mystery 2** (PlaceId: 142823291)
- ESP (murderer/sheriff/innocent), Aimbot (sheriff)
- Grab Gun, Coin Farm, Speed

**27. Jailbreak** (PlaceId: 606849621)
- Auto Rob (all locations), ESP (players + items)
- Teleport to locations, Infinite Nitro, Speed, Fly

**28. BedWars** (PlaceId: 6872274481)
- Kill Aura, ESP, Reach, Auto Bridge, Fly, Speed

**29. Blade Ball** (PlaceId: 13772394625)
- Auto Parry (perfect timing), ESP, Speed, Reach

**30. Doors** (PlaceId: 6516141723)
- ESP (entities + items), Speed, Infinite Stamina, Entity Alert

**31. Shindo Life** (PlaceId: 4616652839)
- Auto Farm, Auto Spin, ESP, Infinite Spins

**32. Pet Simulator 99** (PlaceId: 8737602449)
- Auto Farm, Auto Hatch, Teleport, Auto Sell

**33. King Legacy** (PlaceId: 4520749081)
- Auto Farm, Auto Quest, Teleport, Fruit Sniper

**34. Tower Defense Simulator** (PlaceId: 3260590327)
- Auto Place Towers, Auto Upgrade, ESP, Infinite Cash

**35. Bee Swarm Simulator** (PlaceId: 1537690962)
- Auto Farm (pollen), Auto Quest, Teleport, Auto Collect

**36. Grand Piece Online** (PlaceId: 4451193957)
- Auto Farm, Auto Quest, Fruit Finder, ESP, Teleport

**37. Dead Rails** (detect by name)
- Auto Farm, ESP, Kill Aura, Teleport

**38. Pressure** (detect by name)
- ESP, Aimbot, Speed, Teleport

**39. Fisch** (PlaceId: 16732694052)
- Auto Fish, Auto Sell, Teleport, ESP (rare fish)

**40. Deepwoken** (PlaceId: 4111023553)
- ESP, Auto Parry, Kill Aura, Speed

**41. Anime Defenders** (detect by name)
- Auto Place Units, Auto Upgrade, Auto Farm, ESP

**42. Grow A Garden** (detect by name)
- Auto Plant, Auto Water, Auto Harvest, Teleport

**43. Sol's RNG** (detect by name)
- Auto Roll, Auto Collect, Teleport, ESP

**44. Peroxide** (detect by name)
- Auto Farm, Kill Aura, ESP, Teleport

**45. Jujutsu Shenanigans** (detect by name)
- Kill Aura, Infinite Combo, Auto Block, ESP

**46. Knockout** (detect by name)
- Kill Aura, Inf Push Power, ESP, Speed

**47. Blue Lock Rivals** (detect by name)
- Aimbot (ball), Speed, Auto Score, ESP

**48. Iron Man Reimagined** (detect by name)
- Infinite Fly, Combat Mods, ESP, Speed

**49. MVS Duels** (detect by name)
- Kill Aura, Auto Block, Infinite Combo, ESP

**50. Westbound** (detect by name)
- Auto Farm, ESP, Aimbot, Teleport

**51. Dark Divers** (detect by name)
- ESP (items + entities), Auto Collect, Speed, Teleport

**52. Project Viltrumites** (detect by name)
- Kill Aura, Speed, Fly, ESP

**53. Adopt Me** (PlaceId: 920587237)
- ESP (pets), Speed, Teleport, Auto Age Pets

**54. Bubblegum Simulator** (detect by name)
- Auto Blow, Auto Sell, Auto Hatch, Teleport, ESP

**55. Underground War 2.0** (PlaceId: 9791603388)
- Auto Dig, Kill Aura, ESP, Aimbot, Sword Reach, Auto Upgrade, Silent Aim

---

## UNIVERSAL FEATURES (work in ALL games — always visible tab)

### Combat
- Aimbot (Smooth) with FOV slider (1-500, default 250)
- Silent Aim with FOV circle (toggleable visibility)
- Kill Aura with range slider (1-50, default 15)
- Reach (extend melee range, slider 1-100)
- Hitbox Expander (slider 1-50, default 5)
- Spinbot

### Movement
- Fly (PC + Mobile with button) + Fly Speed Slider
- Noclip, Infinite Jump, Walk Speed Slider (16-500)
- Jump Power Slider (50-500), Gravity Slider
- Click TP, Swim Mode, Wall Walk, Float, Anti Void

### Player
- God Mode, Infinite Stamina, Invisible (local)
- Anti Fling, Anti KillPart, Refill Health, Auto Click

### Visual
- ESP (Player names + health + distance + box)
- X-Ray (see through walls), Full Bright
- No Shadows, Remove Fog, Freecam

### Utility
- Server Hop, Rejoin, Anti AFK
- Fling Player, Walk Fling
- IP Spoofer (display only), Copy Game ID / Job ID, Game Info

---

## GITHUB INFO

- **Owner**: princeaamir0913-droid
- **Repo**: hood-omni-hub
- **Branch**: main
- **File to update**: `later-version.lua`
- **Loadstring**: `loadstring(game:HttpGet("https://raw.githubusercontent.com/princeaamir0913-droid/hood-omni-hub/main/later-version.lua"))()`

To push, use the GitHub connection's push_to_branch tool with:
- owner: princeaamir0913-droid
- repo: hood-omni-hub
- branch: main
- file: later-version.lua (use localPath: /agent/home/later-version.lua)

---

## CURRENT PARTIAL SCRIPT

The file at `/agent/home/later-version.lua` has 660 lines containing:
- Header banner
- All Roblox services
- UI Library (OmniLib) with dark theme, tab creation, toggles, sliders, buttons, dropdowns
- Notification system

What's MISSING and needs to be added:
- Game Detection System (PlaceId lookup + name matching)
- Utility function modules (ESP, Aimbot, Kill Aura, Fly, etc.)
- Universal Features tab with all working toggles
- All 55 game-specific tabs with conditional loading
- Main initialization

## RECOMMENDED APPROACH

Use Python to generate the remaining Lua and APPEND or OVERWRITE later-version.lua:

```bash
uv run python3 /tmp/generate_mega_hub.py
```

The Python script should:
1. Write the COMPLETE Lua file (don't try to append — regenerate the whole thing)
2. Use helper functions to avoid repetition (make_toggle, make_esp, make_aimbot, etc.)
3. Target 4000-8000 lines
4. Save to /agent/home/later-version.lua
5. Then push to GitHub

## IMPORTANT NOTES
- Every feature MUST have real working Lua code, not placeholder comments
- Use pcall() around risky operations
- The UI toggle key is Right Shift
- The script auto-detects game by PlaceId first, then falls back to game name matching
- Only show game-specific tab when player is actually in that game
