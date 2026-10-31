#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A kit's capacity as Enhanced First Aid Kits counts it - the mission's setting for its type over that
 * type's config -, for the setup wizard's "capacity 35 (EFAK)". Where that mod's functions are not
 * there (the game's menus), the capacity its config gives the type (einv_items_fnc_getFacts "maxLoad").
 *
 * Arguments:
 * 0: Kit class, prototype or instance <STRING>
 *
 * Return Value:
 * Capacity in config mass, -1 for anything that is no kit <NUMBER>
 *
 * Example:
 * ["efak_IFAK"] call einv_compat_efak_fnc_capacity;
 *
 * Public: Yes
 */

params [["_kit", "", [""]]];

if (_kit isEqualTo "") exitWith {-1};

if (!isNil QEFAKFUNC(core,getCapacity) && {[_kit] call FUNC(isKit)}) exitWith {
    [_kit] call EFAKFUNC(core,getCapacity)
};

private _facts = [_kit] call EFUNC(items,getFacts);

[-1, _facts getOrDefault ["maxLoad", 0]] select ((_facts getOrDefault ["kind", ""]) isEqualTo "kit")
