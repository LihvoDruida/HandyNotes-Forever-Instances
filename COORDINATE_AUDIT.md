# Coordinate audit — Forever Instances

Audit date: 2026-09-23.

## Coordinate contract

- Top-level `x` / `y` are the primary map point for the dungeon or raid.
- Every record has `entrance = { x, y }`.
- `entrance = { x = 0.0, y = 0.0 }` means the separate entrance is unknown or would duplicate the primary point.
- A green flag is rendered only for a non-zero entrance that differs from the primary point.
- If an entrance is on another map, the entrance block may contain its own `zone`.

## Audited records

| Instance | Primary point | Separate entrance | Result |
| --- | --- | --- | --- |
| Ragefire Chasm | Orgrimmar 53.0, 48.9 | 0.0, 0.0 | no extra flag |
| The Deadmines | Westfall 38.2, 77.5 | 0.0, 0.0 | no extra flag |
| Wailing Caverns | The Barrens 46.0, 36.3 | 0.0, 0.0 | no extra flag |
| Shadowfang Keep | Silverpine Forest 44.7, 67.8 | 0.0, 0.0 | no extra flag |
| Blackfathom Deeps | Ashenvale 14.5, 14.6 | Darkshore 33.5, 93.5 | green flag — Main location retained in Ashenvale/Zoram Strand; current Forever map resource also exposes a distinct Darkshore access point. |
| The Stockade | Stormwind City 50.4, 66.2 | 0.0, 0.0 | no extra flag |
| Gnomeregan | Dun Morogh 24.0, 40.0 | Dun Morogh 17.7, 39.1 | green flag — Primary complex marker remains around the Gnomeregan exterior complex; current Forever resource gives the portal at 17.7, 39.1. |
| Razorfen Kraul | The Barrens 42.3, 89.9 | 0.0, 0.0 | no extra flag |
| The Scarlet Monastery | Tirisfal Glades 85.1, 31.4 | 0.0, 0.0 | no extra flag |
| Uldaman | Badlands 44.2, 12.2 | Badlands 65.0, 43.0 | green flag — Primary entrance remains the main marker; the second flag is the documented Uldaman back entrance in Dustwind Gulch. |
| Razorfen Downs | The Barrens 50.9, 92.9 | 0.0, 0.0 | no extra flag — Only the verified 50.9,92.9 point is retained; the old approximate approach coordinate was removed. |
| Zul'Farrak | Tanaris 38.7, 19.9 | 0.0, 0.0 | no extra flag |
| Maraudon | Desolace 29.3, 62.5 | Desolace 38.0, 58.0 | green flag — Primary marker remains the published dungeon point; the green flag marks the Stone Door exterior access at 38,58. |
| The Temple of Atal'Hakkar | Swamp of Sorrows 69.0, 54.0 | Swamp of Sorrows 77.3, 35.9 | green flag — Primary marker represents the temple exterior; the green flag marks the current Forever entrance/portal coordinate. |
| Blackrock Depths | Searing Gorge 27.1, 72.5 | 0.0, 0.0 | no extra flag |
| Blackrock Spire | Burning Steppes 33.0, 25.2 | 0.0, 0.0 | no extra flag |
| Dire Maul | Feralas 62.0, 33.3 | 0.0, 0.0 | no extra flag |
| Stratholme | Eastern Plaguelands 26.1, 10.4 | Eastern Plaguelands 43.5, 17.8 | green flag — Primary marker is the main/northern gate; the green flag marks the separately documented Service Gate. |
| Scholomance | Western Plaguelands 69.7, 73.4 | 0.0, 0.0 | no extra flag |
| Hall of Thanes | Ironforge 43.0, 51.0 | Ironforge 43.5, 52.0 | green flag — Primary marker represents the dungeon location under Ironforge; the green flag marks the newly published portal at 43.5,52.0. |
| Ruins of Lordaeron | Tirisfal Glades 61.3, 58.8 | 0.0, 0.0 | no extra flag |
| Excavation Site: Wetlands | Wetlands 36.8, 48.2 | 0.0, 0.0 | no extra flag |
| City of Dalaran | Alterac Mountains 32.4, 66.7 | 0.0, 0.0 | no extra flag |
| The Drowned City | Stranglethorn Vale 19.8, 22.4 | 0.0, 0.0 | no extra flag |
| Krol'Dok Stronghold | The Riverglades 74.2, 33.5 | 0.0, 0.0 | no extra flag |
| Alcaz Prison | Dustwallow Marsh 78.4, 18.2 | 0.0, 0.0 | no extra flag |
| Blackmaw Hold | Azshara 23.4, 28.5 | 0.0, 0.0 | no extra flag |
| Shaper's Terrace | Un'Goro Crater 41.6, 11.2 | 0.0, 0.0 | no extra flag |
| Molten Core | Burning Steppes 26.3, 24.6 | 0.0, 0.0 | no extra flag |
| Onyxia's Lair | Dustwallow Marsh 52.3, 76.1 | 0.0, 0.0 | no extra flag |
| Blackwing Lair | Burning Steppes 32.5, 32.4 | 0.0, 0.0 | no extra flag |
| Zul'Gurub | Stranglethorn Vale 54.0, 17.6 | 0.0, 0.0 | no extra flag |
| Ruins of Ahn'Qiraj | Silithus 29.0, 92.8 | 0.0, 0.0 | no extra flag |
| Temple of Ahn'Qiraj | Silithus 29.0, 92.7 | 0.0, 0.0 | no extra flag |
| Naxxramas | Eastern Plaguelands 39.0, 26.0 | 0.0, 0.0 | no extra flag |
| Barrow Deeps | unknown | 0.0, 0.0 | no extra flag — Exact map point and exact entrance are not published; no marker is invented. |
| Hyjal Summit | unknown | 0.0, 0.0 | no extra flag — Mount Hyjal location is known, but no exact map/entrance coordinate is published; no marker is invented. |

## Distinct green entrance flags

- **Blackfathom Deeps** — Darkshore 33.5, 93.5
- **Gnomeregan** — Dun Morogh 17.7, 39.1
- **Uldaman** — Badlands 65.0, 43.0
- **Maraudon** — Desolace 38.0, 58.0
- **The Temple of Atal'Hakkar** — Swamp of Sorrows 77.3, 35.9
- **Stratholme** — Eastern Plaguelands 43.5, 17.8
- **Hall of Thanes** — Ironforge 43.5, 52.0

All other records deliberately use `0.0, 0.0` in the entrance block and therefore do not render a green entrance flag.
