#include "script_component.hpp"
#include "defines.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// The repack running in the window, an empty HashMap while none does (fnc_begin, fnc_stop). Plain data:
// the controls that show it live in uiNamespace (einv_magazines_fx).
GVAR(job) = createHashMap;

#include "initSettings.inc.sqf"

ADDON = true;
