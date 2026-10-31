#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// An update is waiting for the next frame (fnc_queueVirtualLoad). What the player's unit has been
// given so far is kept on the unit itself (aio_weight_appliedLoad), so it goes along with the unit.
GVAR(queued) = false;

// The limits worked out per unit and settings (fnc_getLimits), keyed by everything they depend on - so a
// changed setting makes a new entry and nothing has to be told. What the tier check saw the last time
// round (XEH_postInit): the load, the limits' key and the effects switch.
GVAR(limitsCache) = createHashMap;
GVAR(lastState) = [];

// Strict mode's hidden holder of the player's unit as the look saw it last (XEH_postInit): a tile moved into
// or out of it from a crate changes the load without a loadout event.
GVAR(lastHidden) = [];

#include "initSettings.inc.sqf"

ADDON = true;
