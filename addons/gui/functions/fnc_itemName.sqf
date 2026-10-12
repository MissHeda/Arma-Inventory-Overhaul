#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The name the window shows for an item - on its tile, beside the mouse, in the hint, on the inspect
 * card, in the context menu - and the one the search field matches.
 *
 * A kit of Enhanced First Aid Kits or Enhanced Utility Pouches goes by what that mod calls it: the name
 * a player gave it, the mission's name for its type, and for the short name its own ("IFAK")
 * (einv_compat_efak_fnc_getName - only when that addon is loaded). Anything else, and a kit with no
 * such name, by the rules' name (name=) or its config's (einv_items_fnc_getInfo).
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: The short name <BOOL> (default: false)
 *
 * Return Value:
 * Name, the class when nothing has one <STRING>
 *
 * Example:
 * ["efak_IFAK_7", true] call einv_gui_fnc_itemName;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_short", false, [false]]];

private _name = "";

if (!isNil QEFUNC(compat_efak,getName)) then {
    _name = [_class, _short] call EFUNC(compat_efak,getName);
};

if (_name isEqualTo "") then {
    _name = ([_class] call EFUNC(items,getInfo)) getOrDefault [["name", "short"] select _short, ""];
};

if (_name isEqualTo "") then {
    _name = _class;
};

_name
