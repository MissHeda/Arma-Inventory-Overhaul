#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Reads CfgAioMenu, which mods fill without script (see CfgAioMenu.hpp), once at the mission's start on a
 * machine with a player (XEH_postInit):
 *   Entries     - rows of the right-click menu, added as options of CBA's item context menu (fnc_addMenuEntry)
 *   Hide        - ids of rows hidden for items (fnc_hideMenuEntry)
 *   DoubleClick - what a double click does with items (fnc_setDoubleClick)
 * Code is given as text and compiled here. An entry that cannot be read is named in the RPT and left out.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call aio_gui_fnc_menuInit;
 *
 * Public: No
 */

private _root = configFile >> "CfgAioMenu";

// Text to code; an empty text is the default, code that does not compile is named and is the default too.
private _fnc_code = {
    params ["_entry", "_key", "_default"];

    private _text = getText (_entry >> _key);

    if ((_text splitString toString [32, 9, 10, 13]) isEqualTo []) exitWith {_default};

    private _code = compile _text;

    if (isNil "_code") exitWith {
        WARNING_2("CfgAioMenu %1: %2 does not compile.",configName _entry,_key);
        _default
    };

    _code
};

{
    private _entry = _x;
    private _items = getArray (_entry >> "items");

    if (_items isEqualTo []) then {
        WARNING_1("CfgAioMenu >> Entries >> %1 names no items.",configName _entry);
        continue;
    };

    private _slots = getArray (_entry >> "slots");

    if (_slots isEqualTo []) then {_slots = ["ALL"]};

    private _name = getText (_entry >> "displayName");

    if (_name isEqualTo "") then {_name = configName _entry};

    [
        configName _entry,
        _items,
        [_name, getText (_entry >> "tooltip")],
        [_entry, "statement", {}] call _fnc_code,
        [_entry, "condition", {true}] call _fnc_code,
        [_entry, "enabled", {true}] call _fnc_code,
        getNumber (_entry >> "consume") > 0,
        _slots,
        getNumber (_entry >> "doubleClick") > 0,
        getText (_entry >> "icon")
    ] call FUNC(addMenuEntry);
} forEach ("true" configClasses (_root >> "Entries"));

{
    [getArray (_x >> "entries"), getArray (_x >> "items")] call FUNC(hideMenuEntry);
} forEach ("true" configClasses (_root >> "Hide"));

{
    private _change = _x;

    {
        [_x, getArray (_change >> "items"), getText (_change >> "displayName"), getText (_change >> "icon")] call FUNC(changeMenuEntry);
    } forEach getArray (_change >> "entries");
} forEach ("true" configClasses (_root >> "Change"));

{
    private _action = getText (_x >> "action");

    if (_action isEqualTo "") then {
        WARNING_1("CfgAioMenu >> DoubleClick >> %1 has no action.",configName _x);
        continue;
    };

    [getArray (_x >> "items"), _action] call FUNC(setDoubleClick);
} forEach ("true" configClasses (_root >> "DoubleClick"));
