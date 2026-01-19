# Turn Loop (combat)
Order each round:
1) Player start-of-turn
   - energy := max_energy
   - draw N cards (default 5)
   - start-of-turn statuses tick (on player & enemies)
2) Player phase
   - player may play cards while energy > 0
   - end turn button ends player phase
3) Enemy phase
   - each enemy resolves its current intent
4) Cleanup
   - discard hand, draw pile reshuffle if empty
   - end-of-turn statuses tick
Definition of Done for any change touching turns:
- Must keep this order, prove via unit tests.
