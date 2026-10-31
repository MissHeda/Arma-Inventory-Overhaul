#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a kit may be changed in ACE Arsenal, and if not why - asked for everything the panel does to a kit there:
 * an item packed into it out of ACE's list or the kits tab's list (fnc_canPackNew, fnc_packNew), a tile taken out of
 * it and away (fnc_discard), a move into or out of it (fnc_canDrop, fnc_drop). The same rules as Enhanced First Aid
 * Kits' own kits tab:
 *   its contents have not reached this machine yet (fnc_notReady)
 *   the kit type's Arsenal setting (efak_core_fnc_getArsenalEditing): nothing may change, or only taking out -
 *   "Remove only" lets things out of the kit, never in (Eden always allows everything)
 *   the kit is ticked to follow the default contents ("Use CBA default" in that tab, efak_core_followDefaults): it
 *   holds the mission's defaults and comes back with them out of every loadout, so that tab locks it - and the panel
 *   too, or what was packed would be gone at the next loadout
 * The reasons are that mod's own words where it has them.
 *
 * Arguments:
 * 0: Kit class <STRING>
 * 1: Something goes in - false when something only comes out <BOOL> (default: true)
 *
 * Return Value:
 * Why not, "" when it may <STRING>
 *
 * Example:
 * ["efak_IFAK_7", false] call einv_compat_efak_fnc_arsenalEditable;
 *
 * Public: No
 */

params [["_kit", "", [""]], ["_adding", true, [false]]];

if (_kit isEqualTo "") exitWith {"Failed"};

private _wait = [] call FUNC(notReady);

if (_wait isNotEqualTo "") exitWith {_wait};

// That mod's words, else ours (an older version, or its arsenal addon not loaded).
private _fnc_words = {
    params ["_key", "_ours"];

    [_ours, localize _key] select (isLocalized _key)
};

private _editing = switch (true) do {
    case (!isNil QEFAKFUNC(core,getArsenalEditing)): {[_kit] call EFAKFUNC(core,getArsenalEditing)};
    case (!isNil QEFAKFUNC(core,canPackInto)): {[EFAK_EDIT_NOTHING, EFAK_EDIT_ALL] select ([_kit, true] call EFAKFUNC(core,canPackInto))};
    default {EFAK_EDIT_ALL};
};

if (_editing == EFAK_EDIT_NOTHING) exitWith {
    ["STR_efak_arsenal_Hint_EditNothing", LLSTRING(ArsenalReadOnly)] call _fnc_words
};

if (_adding && {_editing == EFAK_EDIT_REMOVE}) exitWith {
    ["STR_efak_arsenal_Hint_EditRemove", LLSTRING(ArsenalRemoveOnly)] call _fnc_words
};

if (toLowerANSI _kit in (missionNamespace getVariable [QEFAKGVAR(core,followDefaults), createHashMap])) exitWith {
    ["STR_efak_arsenal_Hint_Locked", LLSTRING(ArsenalLocked)] call _fnc_words
};

""
