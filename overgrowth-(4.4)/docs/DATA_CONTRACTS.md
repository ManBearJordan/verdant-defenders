# Data Contracts

## Card (example)
```json
{
  "id": "growth_sap_shot",
  "name": "Sap Shot",
  "type": "attack",
  "cost": 1,
  "pool": "growth",
  "rarity": "common",
  "effects": [
    { "type": "deal_damage", "amount": 7 },
    { "type": "apply_status", "status": "wither", "amount": 1 }
  ],
  "tags": ["starter"]
}
type: one of "attack" | "skill" | "power" | "ritual" | "strike"

pool: "growth" | "decay" | "elemental"

rarity: "common" | "uncommon" | "rare"