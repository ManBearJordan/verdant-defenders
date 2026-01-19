# Effect Verbs -> Engine Calls
deal_damage(amount)        -> CardRules.deal_damage(target, amount)
gain_block(amount)         -> CardRules.gain_block(target, amount)
draw_cards(n)              -> CardRules.draw_cards(player, n)
apply_status(status, amt)  -> StatusHandler.apply_status(target, status, amt)
heal(amount)               -> CardRules.heal(target, amount)
*Unknown verbs: add a stub in CardRules + a passing test.*
