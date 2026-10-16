// What an item is
PREP(getFacts);
PREP(getInfo);
PREP(footprintAs);
PREP(turnMask);

// Kits of Enhanced First Aid Kits, by that mod's registry in config
PREP(kitTypes);
PREP(kitOf);

// The rules: reading and writing their text
PREP(parseRules);
PREP(writeRules);
PREP(parseGrid);
PREP(formatGrid);
PREP(parseMask);
PREP(formatMask);
PREP(parseIcon);
PREP(formatIcon);
PREP(encodeName);
PREP(decodeName);
PREP(sanitizeText);

// The rules: compiling and applying them
PREP(compileCond);
PREP(compileRules);
PREP(matches);
PREP(resolve);
PREP(explain);
PREP(setBy);

// The rules in effect
PREP(rulesInputs);
PREP(currentRules);
PREP(loadRules);
PREP(checkServerRules);

// Sizes, stacks and container grids by class, from the older table settings
PREP(parseTable);

// An item's own config keys (einv_size, einv_grid, ...): reading them, and writing or reading a snippet of them
PREP(readConfigKeys);
PREP(configEntry);
PREP(parseConfigEntry);

// What a vest, uniform or helmet protects: armor per body zone, as ACE's damage counts it
PREP(getArmor);
PREP(getProtection);
