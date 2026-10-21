# Operation: Iron Grid

**Operation: Iron Grid** is a dieselpunk isometric turn-based tactical strategy game built in **Godot 4**. Inspired by the heavy mechanical atmosphere of *Ring of Red*, *Steel Battalion*, and *MechWarrior*, the grid-based tactical maneuvering of *Advance Wars* and *Fire Emblem*, and the directional card-flipping showdowns of *Final Fantasy VIII*'s *Triple Triad*.

---

## Core Gameplay & Turn Loop

Players command the **8th Iron Division** against the **Kriegs-Syndikat Red** across an extruded 2.5D isometric battlefield divided into square tactical nodes with varying terrain types and elevations (`0m` to `400m`).

Each turn cycles through three phases:

1. **Player Command Phase**:
   - Select any friendly Armored Fighting Walker (AFW) to compute reachable movement nodes within its current **Diesel Fuel** budget (using Dijkstra pathfinding across terrain and elevation climbs).
   - Hover over reachable enemy nodes to inspect a real-time **Skirmish Engagement Forecast** detailing approach vectors, terrain/elevation modifiers, projected card control, and estimated hull damage.
   - Move to secure strategic **Objective Cities**, press **`R`** (`WAIT / REFUEL`) to entrench (`+15% DEF` and `+5 Fuel`), or move directly onto an enemy-occupied node to trigger a collision engagement.
2. **Skirmish Resolution Phase (Automated Showdown)**:
   - When two opposing walkers occupy the same node, the game launches the **Automated Skirmish Resolver**.
   - Combines a **Stats-vs-Stats** exchange (`Firepower` vs `Armor Rating`, scaled by approach terrain and high-ground elevation) with a **3-Bout Equipment Deck Clash** on a **3x3 Triple Triad Matrix**.
   - Each walker deploys its 3 equipped weapon/armor/tactical cards onto the 3x3 board. Directional power ranks (`N, E, S, W` from `1–9` and `A`) are compared against adjacent opposing cards:
     - **Overmatch Capture**: Higher directional ranks flip adjacent enemy cards to the attacker's faction.
     - **Tactical Plus Overload**: Matching edge sums across two or more adjacent sides trigger a combo flip.
   - Controlled cards add their `Damage` and `Shield` ratings to the final hull exchange. If both units survive, the loser of the clash is dislodged and pushed back to an adjacent retreat tile.
3. **Syndicate AI Phase**:
   - Enemy walkers evaluate reachable tiles, approach vectors, high-ground advantages, fuel reserves, and objective priorities tailored to the map's strategic profile (`Pitched Battle`, `Fortified Defense`, or `Blitzkrieg Offense`).

---

## Terrain & Elevation Matrix

| Terrain Type | Code | Base Fuel | Attack Mod | Defense Mod | Card Edge Bonus | Tactical Notes |
| :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **Transit Road** | `ROD` | `1` | `+5%` | `0%` | `+0` | Fastest transit artery for heavy dreadnoughts |
| **Open Plain** | `PLN` | `2` | `0%` | `+5%` | `+0` | Standard open maneuvering ground |
| **Fortified City** | `CTY` | `2` | `+10%` | `+25%` | `+1` | Repairs **+12 Armor** & restores **+4 Fuel** at turn start |
| **Trench Timber** | `TRN` | `3` | `+5%` | `+15%` | `+0` | Prepared defensive cover and ambush concealment |
| **River Ford** | `RIV` | `4` | `-15%` | `-15%` | `-1` | Bogged down & exposed (`Falke` amphibious gear reduces cost) |
| **Mountain Crag** | `MTN` | `5` | `+15%` | `+30%` | `+1` | Commanding rock bastion (`Donner` quad legs reduce climb cost) |

### Elevation (`0m` – `400m`)
- **Climbing Fuel Surcharge**: Moving uphill costs `+1 Fuel` per `100m` elevation level gained.
- **High Ground Plunging Fire**: Attacking from higher elevation down onto a defender grants **+12% Firepower**, **+10% Armor deflection**, and **+1 to all Card Directional Ranks** per elevation level differential.
- **Uphill Assault Penalty**: Attacking uphill suffers **-10% Firepower** and **-1 to Card Directional Ranks** per level.

---

## Armored Fighting Walkers (6 Chassis Types)

1. **KPZ-09 "Sturmjäger" (`VANGUARD` — Medium Assault Walker)**
   - **Stats**: `110 Hull` | `30 Armor Rating` | `34 Firepower` | `13 Fuel` (`+5/turn`)
   - **Deck**: *88mm KwK AP-Shell*, *Sloped Krupp Plate*, *Twin MG-42 Salvo*
2. **VK-100 "Siegebreaker" (`GOLIATH` — Super-Heavy Dreadnought)**
   - **Stats**: `155 Hull` | `44 Armor Rating` | `46 Firepower` | `10 Fuel` (`+4/turn`, `+1` off-road fuel surcharge)
   - **Deck**: *210mm Siege Howitzer*, *Ferro-Bunker Bulkhead*, *Quad Flak-38 Battery*
3. **Sd.Kfz-22 "Spähfalke" (`FALKE` — Light Recon Strider)**
   - **Stats**: `85 Hull` | `21 Armor Rating` | `28 Firepower` | `17 Fuel` (`+6/turn`, Amphibious Seals & `-1` off-road fuel reduction)
   - **Deck**: *50mm Rapid Autocannon*, *Gyro-Flank Thrusters*, *Optical Rangefinder*
4. **SPG-88 "Spinne" (`DONNER` — Quadruped Mountain Walker)**
   - **Stats**: `98 Hull` | `26 Armor Rating` | `43 Firepower` | `12 Fuel` (`+5/turn`, Mountain Climbing Gear)
   - **Deck**: *Nebelwerfer Rocket Pod*, *Elevation Ballistics*, *Quad Anchor Struts*
5. **Befehls-IV "Kaiserstuhl" (`KOMMANDANT` — Tactical Command Walker)**
   - **Stats**: `120 Hull` | `34 Armor Rating` | `36 Firepower` | `14 Fuel` (`+5/turn`)
   - **Deck**: *Enigma ECM Scrambler*, *Command Uplink*, *105mm StuH Howitzer*
6. **Sturm-V "Brenner" (`MOLOCH` — Heavy Urban Brawler)**
   - **Stats**: `135 Hull` | `38 Armor Rating` | `41 Firepower` | `12 Fuel` (`+5/turn`)
   - **Deck**: *Thermite Flame Lance*, *Hydraulic Pile-Bunker*, *Reactive Shield Wall*

---

## Battle Arenas (3 Maps)

1. **Operation: Iron Bridge (`PITCHED BATTLE`)**
   - Symmetrical meeting engagement across the Rhine-Fulda river valley (`0m`) spanned by two transit road bridges (`100m`), four bridgehead cities (`200m`), and flanking mountain ridges (`300m`).
2. **Bastion Redoubt (`FORTIFIED DEFENSE`)**
   - Asymmetric defense of Citadel Höhenburg (`300m–400m`) against a numerically superior 5-walker Syndicate assault column advancing up the western valley roads.
3. **Breakthrough at Kessel-9 (`BLITZKRIEG OFFENSE`)**
   - Asymmetric offensive leading a 5-walker mobile spearhead to breach entrenched Syndicate gate guards and capture the Eastern HQ Bunker within 10 turns.

---

## Controls

| Input | Action |
| :--- | :--- |
| **Left Mouse Click** | Select walker / Move to highlighted tile / Engage enemy node |
| **Right / Middle Mouse Drag** | Pan tactical camera |
| **WASD / Arrow Keys** | Pan tactical camera |
| **Mouse Wheel Up / Down** | Zoom camera in / out |
| **`R`** | Wait, Entrench (`+15% DEF`), & Refuel (`+5 Fuel`) selected walker |
| **`E`** | End Player Command Phase |
| **`C`** | Reset & center camera on battlefield |
| **`H`** | Toggle Tactical Field Manual & Terrain Chart |
| **`Space` / `Enter`** | Skip / Confirm Skirmish Resolution outcome |
| **`Esc`** | Deselect unit / Close modal |

---

## Architecture & Project Structure

```text
iron-grid/
├── project.godot                   # Godot 4.7 project configuration & autoloads
├── icon.svg                        # Custom vector project icon
├── autoload/
│   ├── GlobalState.gd              # Global turn/phase state, card/mech/map catalogs, combat log
│   └── SoundManager.gd             # Procedural retro/dieselpunk WAV audio synthesizer
├── scenes/
│   ├── MainMenu.tscn               # Command HQ briefing console, 3-map selector & Mech Hangar Codex
│   └── Battlefield.tscn            # Root battle scene (GridMap, UnitContainer, Camera2D, UIOverlay)
└── scripts/
    ├── data/
    │   ├── EquipmentCard.gd        # Triple Triad directional ranks & damage/shield card struct
    │   ├── GridTileData.gd         # Terrain type, elevation, fuel cost & combat modifier struct
    │   ├── MapDefinition.gd        # Arena layout, strategy mode, objectives & unit spawns
    │   └── MechData.gd             # Core walker struct (armor, firepower, fuel, mobility, deck)
    ├── battle/
    │   ├── Battlefield.gd          # Turn flow controller (Player -> Skirmish Resolution -> AI)
    │   ├── IsoGridMap.gd           # 2.5D isometric terrain renderer & Dijkstra fuel pathfinder
    │   ├── UnitContainer.gd        # Y-sorted mech manager, collision checks & knockback logic
    │   ├── MechUnit.gd             # Procedural multi-part isometric mech renderer & animator
    │   ├── SkirmishEngine.gd       # Stats-vs-Stats + 3x3 Triple Triad card clash resolver
    │   └── AIController.gd         # Utility-based tactical AI decision engine
    └── ui/
        ├── MainMenu.gd             # War-room menu & interactive Mech Hangar Codex
        ├── UIOverlay.gd            # In-game CRT telemetry HUD, terrain inspector & forecast
        └── SkirmishModal.gd        # Animated Resolution Phase showdown screen
```

---

## Running the Game

1. Open **Godot Engine 4.x** (tested with Godot `4.7-stable`).
2. Import `project.godot` and press **F5** (or run from the command line):

```powershell
godot --path .
```
