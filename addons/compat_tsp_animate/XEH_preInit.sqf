#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// What the current weapon wore when last looked at: [weapon, primary items, launcher items, handgun items], or []
// while the window is closed (fnc_tick).
GVAR(last) = [];

ADDON = true;
