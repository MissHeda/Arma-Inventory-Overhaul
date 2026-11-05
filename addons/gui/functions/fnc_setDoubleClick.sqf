#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What a double click (and the quick move key) does with an item in the inventory, for some items or for all.
 * Run it on every machine with a player. The rule for the most specific class wins (fnc_menuRules); an item
 * without one does what the player's setting "Double click on items with options of other mods" says.
 *
 * Actions:
 *   "move" - moves it to the other side, the window's usual double click
 *   "menu" - opens its right-click menu, as the vanilla inventory does with CBA
 *   any other text - runs the row of its right-click menu with that id (an option of CBA's item context menu by
 *     its CBA id, or a row of the window's own, e.g. "inspect", "hotbar", "drop" - see fnc_hideMenuEntry) or, if
 *     no id matches, with that text as its name ("Drink"). A row that is greyed out does nothing; a row
 *     that is not in the menu for the item now leaves the double click as it was.
 *
 * The same in a mod's config, without script:
 *   class CfgAioMenu { class DoubleClick { class myMod_canteen { items[] = {"myMod_Canteen"}; action = "myMod_drink"; }; }; };
 * An entry of CfgAioMenu >> Entries with doubleClick = 1 sets itself for its items.
 *
 * Arguments:
 * 0: Items: class names (their child classes too), "##" + subtype, "#" + type or "#All" <ARRAY of STRINGs, or STRING>
 * 1: Action <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [["myMod_Canteen"], "myMod_drink"] call aio_gui_fnc_setDoubleClick;
 *
 * Public: Yes
 */

params [["_items", [], [[], ""]], ["_action", "", [""]]];

if (_items isEqualType "") then {_items = [_items]};

if (isNil QGVAR(doubleClickRules)) then {GVAR(doubleClickRules) = createHashMap};

{
    if (_x isEqualType "" && {_x isNotEqualTo ""}) then {
        if (_action isEqualTo "") then {
            GVAR(doubleClickRules) deleteAt toLowerANSI _x;
        } else {
            GVAR(doubleClickRules) set [toLowerANSI _x, _action];
        };
    };
} forEach _items;
