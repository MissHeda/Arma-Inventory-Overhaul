#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Adds a row to the right-click menu of items - in this inventory and in the vanilla one alike, as it is an
 * option of CBA's item context menu (CBA_fnc_addItemContextMenuOption, which can be called directly as well).
 * Optionally the row is what a double click on those items does (fnc_setDoubleClick). Run it on every machine
 * with a player.
 *
 * The same in a mod's config, without script (read once at the mission's start, fnc_menuInit):
 *   class CfgAioMenu {
 *       class Entries {
 *           class myMod_drink {                     // the class name is the row's id
 *               displayName = "Drink";               // or a $STR_ key
 *               tooltip = "";
 *               icon = "";
 *               items[] = {"myMod_Canteen"};          // classes (child classes too), "##" + subtype, "#" + type, "#All"
 *               slots[] = {"ALL"};                    // CBA's slots: "CONTAINER", "UNIFORM_CONTAINER", "GROUND", ...
 *               condition = "true";                   // shown at all: _this = [unit, container, item, slot, params, id]
 *               enabled = "true";                     // greyed out while false
 *               statement = "systemChat 'Gulp'";      // run on a click; true keeps the menu open
 *               consume = 0;                          // 1: the item is used up first (never from the ground or a crate)
 *               doubleClick = 1;                      // a double click on these items runs it
 *           };
 *       };
 *   };
 *
 * Arguments:
 * 0: Id - also the row's id for fnc_hideMenuEntry and fnc_setDoubleClick <STRING>
 * 1: Items <ARRAY of STRINGs, or STRING>
 * 2: Name, or [name, tooltip] <STRING or ARRAY>
 * 3: Statement, _this = [unit, container, item, slot, params, id] <CODE>
 * 4: Condition to show it <CODE> (default: {true})
 * 5: Condition to enable it <CODE> (default: {true})
 * 6: Consume the item first <BOOL> (default: false)
 * 7: Slots <ARRAY of STRINGs, or STRING> (default: "ALL")
 * 8: Double click runs it <BOOL> (default: false)
 * 9: Icon <STRING> (default: "")
 * 10: Params handed to the codes as _this select 4 <ANY> (default: [])
 *
 * Return Value:
 * The id, "" when it could not be added <STRING>
 *
 * Example:
 * ["myMod_drink", ["myMod_Canteen"], "Drink", {systemChat "Gulp"}, {true}, {true}, false, "ALL", true] call aio_gui_fnc_addMenuEntry;
 *
 * Public: Yes
 */

params [
    ["_id", "", [""]],
    ["_items", [], [[], ""]],
    ["_name", "", ["", []]],
    ["_statement", {}, [{}]],
    ["_show", {true}, [{}]],
    ["_enable", {true}, [{}]],
    ["_consume", false, [false]],
    ["_slots", "ALL", [[], ""]],
    ["_doubleClick", false, [false]],
    ["_icon", "", [""]],
    ["_params", []]
];

if (!hasInterface || {isNil "CBA_fnc_addItemContextMenuOption"}) exitWith {""};

if (_id isEqualTo "") exitWith {
    WARNING("addMenuEntry: an entry needs an id.");
    ""
};

if (_items isEqualType "") then {_items = [_items]};
if (_slots isEqualType "") then {_slots = [_slots]};

{
    [_x, _slots, _name, nil, _icon, [_enable, _show], _statement, _consume, _params, _id] call CBA_fnc_addItemContextMenuOption;
} forEach (_items select {_x isEqualType "" && {_x isNotEqualTo ""}});

if (_doubleClick) then {
    [_items, _id] call FUNC(setDoubleClick);
};

_id
