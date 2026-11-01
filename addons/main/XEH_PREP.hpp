// The settings that are the same for everyone: registering one (a CBA setting and a control of the setup wizard),
// the wizard's own text of them, and the one-time move out of the settings box of the test builds
PREP(addSetting);
PREP(parseValue);
PREP(parseSettings);
PREP(writeSettings);
PREP(migrateSettings);
PREP(sanitizeSettings);
PREP(encodeText);
PREP(decodeText);

// A message to the player, ACE's way when ACE is loaded
PREP(showText);

// ACE's answers where ACE is loaded, the engine's where it is not
PREP(isAwake);
PREP(canInteract);
PREP(unitName);
