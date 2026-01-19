# Status Rules
| Name   | Stacks? | When it ticks         | Effect per tick                 |
|--------|---------|------------------------|---------------------------------|
| Poison | yes     | end-of-turn (target)   | target takes X dmg; X-- (min 0)|
| Burn   | yes     | on-hit (when target hit)| +X bonus dmg on next hit only  |
| Chill  | yes     | start-of-turn (target) | target energy -1 (min 0)       |
| Shock  | yes     | on-cast (attacker)     | next attack deals +X% dmg       |
*Agents must implement these in `StatusHandler.gd` and cover with tests.*
