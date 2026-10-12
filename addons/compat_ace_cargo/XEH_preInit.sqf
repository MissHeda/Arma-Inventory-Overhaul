#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// The one thing being unloaded from the window: [item, vehicle, start time, duration in seconds], or []
// (fnc_startUnload, fnc_unloadFrame), and the per-frame handler that runs it, -1 for none. Only one at a
// time, as ACE's own progress bar is only one.
GVAR(unloading) = [];
GVAR(unloadPFH) = -1;

ADDON = true;
