#include "script_component.hpp"
#include "defines.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// The classes on the keys, one string per slot, "" for an empty one. Read from the profile when the
// game starts (fnc_loadSlots) - until then every slot is empty.
GVAR(slots) = [];

for "_i" from 1 to SLOT_COUNT do {
    GVAR(slots) pushBack "";
};

// What a class does from the bar, lowercase class -> [kind, data] (fnc_useOf). The treatments ACE and its
// mods offer (fnc_treatmentIndex) and the throwables (fnc_useOf) are worked out when first needed and
// kept in GVAR(treatments) and GVAR(throwables).
GVAR(useCache) = createHashMap;

// The time before which a key press is ignored (fnc_onKey), and the slot and time of the last press that
// readied a throwable without ACE's advanced throwing (fnc_useThrowable).
GVAR(lockUntil) = 0;
GVAR(lastPress) = [];

// [slot, time it started] while ACE's progress bar runs for a treatment or a meal from the bar, else [].
GVAR(busy) = [];

// The bar on the screen: the handler that keeps it (fnc_hudFrame), the time until which "while in use"
// shows it (fnc_hudPing), the time the counts are read next, what was drawn at the last read (so a
// change shows), and the kinds of the slots.
GVAR(hudPFH) = -1;
GVAR(hudUntil) = 0;
GVAR(nextCount) = 0;
GVAR(hudSignature) = "";
GVAR(hudKinds) = [];

// Whether the bar is faded in, and when it has faded out.
GVAR(hudVisible) = false;
GVAR(hudHideAt) = 0;

// A refused press, [slot, colour name, time it ends], and the line over the boxes, [text, colour name,
// time it ends] (fnc_flash).
GVAR(flash) = [];
GVAR(message) = [];

// The player's interface colours, read when the bar is made (fnc_hudCreate): bcg, text, warning, error.
// The controls themselves are kept in uiNamespace, never here - the mission namespace is saved with the
// game and cannot hold controls.
GVAR(hudColors) = createHashMap;

#include "initSettings.inc.sqf"

ADDON = true;
