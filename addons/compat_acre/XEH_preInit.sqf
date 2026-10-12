#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// ACRE2 keeps a dummy radio in the radio slot for the game's text chat. The slot stays as it is wherever
// a transaction runs, whatever a window or a script asked for (einv_storage_guards). The storage loaded
// before this addon (required addon). Wrapped, so a recompiled function is the one that runs.
EGVAR(storage,guards) pushBack {_this call FUNC(guard)};

ADDON = true;
