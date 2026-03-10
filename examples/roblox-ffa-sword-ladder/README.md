# Roblox FFA Sword Ladder (Implementation Package)

This folder contains a full server/client Lua implementation for the FFA sword ladder mode:

- 8-minute rounds with 15-second intermission
- 1 kill = +1 sword tier
- death = -1 sword tier (minimum 0)
- `Darkheart` final tier
- round win on kill while holding `Darkheart`
- main menu with `Play` and `Servers`
- public server browser + teleport by JobId

## Install Into Roblox Studio

1. Create these folders/services in your place if missing:
   - `ReplicatedStorage/Config`
   - `ReplicatedStorage/Shared`
   - `ServerScriptService/Services`
   - `StarterPlayer/StarterPlayerScripts`
   - `ServerStorage/Swords`
2. Copy files from this package into matching locations.
3. In `ServerStorage/Swords`, insert classic sword tools with exact names:
   - `Linked Sword`
   - `Venomshank`
   - `Firebrand`
   - `Ice Dagger`
   - `Ghostwalker`
   - `Illumina`
   - `Darkheart`
4. Enable **Allow HTTP Requests** in Game Settings (required for server browser).
5. Press Play.

## Required Script Locations

- `src/ReplicatedStorage/Config/GameConfig.lua` -> `ReplicatedStorage/Config/GameConfig`
- `src/ReplicatedStorage/Config/SwordLadder.lua` -> `ReplicatedStorage/Config/SwordLadder`
- `src/ReplicatedStorage/Shared/RemoteRegistry.lua` -> `ReplicatedStorage/Shared/RemoteRegistry`
- `src/ServerScriptService/Services/*.lua` -> `ServerScriptService/Services/*`
- `src/ServerScriptService/Bootstrap.server.lua` -> `ServerScriptService/Bootstrap`
- `src/StarterPlayer/StarterPlayerScripts/GameClient.client.lua` -> `StarterPlayer/StarterPlayerScripts/GameClient`

## Notes

- Tie-break at timer end:
  1. highest tier
  2. highest kills
  3. lowest deaths
  4. earliest timestamp reaching current tier
- The game is server-authoritative for progression updates.
- Client updates are display-only.