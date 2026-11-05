#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Gives a row of the right-click menu another name or picture for some items, by the row's id - also the window's own rows
 * (their ids are in fnc_contextMenu). Applied as a menu opens (fnc_menuFilter). Run it on every machine with a player.
 *
 * The same in a mod's config, without script (read once at the mission's start, fnc_menuInit):
 *   class CfgAioMenu {
 *       class Change {
 *           class myMod_canteenDrop {
 *               entries[] = {"drop"};
 *               items[] = {"myMod_Canteen"};    // classes (child classes too), "##" + subtype, "#" + type, "#All"
 *               displayName = "$STR_myMod_Pour"; // a $STR_ key or plain text; "" keeps the name
 *               icon = "myMod\ui\pour_ca.paa";   // "" keeps the picture
 *           };
 *       };
 *   };
 *
 * Arguments:
 * 0: Id of the row <STRING>
 * 1: Items <ARRAY of STRINGs, or STRING> (default: "#All")
 * 2: Name, a $STR_ key or plain text, "" to keep it <STRING> (default: "")
 * 3: Picture, "" to keep it <STRING> (default: "")
 *
 * Return Value:
 * None
 *
 * Example:
 * ["drop", ["myMod_Canteen"], "Pour out", "myMod\ui\pour_ca.paa"] call aio_gui_fnc_changeMenuEntry;
 *
 * Public: Yes
 */

params [["_id", "", [""]], ["_items", "#All", [[], ""]], ["_name", "", [""]], ["_icon", "", [""]]];

if (_id isEqualTo "") exitWith {};

if (_items isEqualType "") then {_items = [_items]};
if (_items isEqualTo []) then {_items = ["#All"]};

if ((_name select [0, 5]) == "$STR_") then {
    _name = localize _name;
};

if (isNil QGVAR(menuChangeRules)) then {GVAR(menuChangeRules) = createHashMap};

{
    private _key = toLowerANSI _x;
    private _list = GVAR(menuChangeRules) getOrDefault [_key, []];

    GVAR(menuChangeRules) set [_key, _list];
    _list pushBack [toLowerANSI _id, _name, _icon];
} forEach (_items select {_x isEqualType "" && {_x isNotEqualTo ""}});
