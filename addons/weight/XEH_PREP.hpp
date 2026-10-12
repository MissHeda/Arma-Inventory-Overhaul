// What the weight overrides of the rules add to what a unit carries
PREP(getExtraLoad);

// Handing that to ACE as virtual load, once per burst of changes
PREP(updateVirtualLoad);
PREP(queueVirtualLoad);

// How heavy the load is on the soldier: the numbers, the tier, and what the tier does to him
PREP(getLoad);
PREP(getLimits);
PREP(heavyFromAce);
PREP(getTier);
PREP(tierText);
PREP(updateTier);
PREP(applyEffects);
PREP(notifyTier);
