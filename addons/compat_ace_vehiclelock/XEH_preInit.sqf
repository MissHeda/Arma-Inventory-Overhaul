#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// ACE only closes the vanilla inventory display (602) of a locked vehicle, which this window never
// opens - so the same rule is one more lock of ours, asked on every machine: by the window, the
// engine's inventory gate and the guard on every op (aio_locks_fnc_canReach). The locks addon loaded
// before this one (required addon).
[{_this call FUNC(check)}] call EFUNC(locks,addProvider);

ADDON = true;
