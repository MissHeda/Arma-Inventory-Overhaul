#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// What an item is under the rules in effect, per lowercase class, see fnc_getInfo. Emptied every time
// the rules change (fnc_loadRules); what an item is in config stays - fnc_getFacts keeps that in
// uiNamespace, where it is not saved with the game and lasts as long as the game's config does.
GVAR(info) = createHashMap;

// The rules in effect: GVAR(ruleset) is the compiled form (fnc_compileRules), GVAR(rulesInputs) the
// settings it was compiled from (fnc_rulesInputs). Both are nil until the first item is asked for or
// the settings are read, whichever comes first (fnc_currentRules, fnc_loadRules). The revision counts
// every change, for anyone keeping something worked out from the rules. GVAR(rulesOverride), nil
// unless set, is a rules text given to fnc_loadRules for testing - read in the setting's place.
GVAR(rulesRevision) = 0;

// A client warns once that it reads the same rules differently from the server - another version of
// the mod or of a preset (fnc_checkServerRules).
GVAR(hashWarned) = false;
GVAR(versionWarned) = false;

// The server publishes what it compiled; a client compares it with its own once both are there, in
// whichever order they arrive. One joining later finds it already set when it reads its own rules.
if (!isServer) then {
    [QGVAR(rulesPublished), {
        params ["_server"];
        [_server] call FUNC(checkServerRules);
    }] call CBA_fnc_addEventHandler;
};

#include "initSettings.inc.sqf"

ADDON = true;
