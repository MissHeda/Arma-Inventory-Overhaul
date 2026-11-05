#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Hides rows of the inventory's right-click menu by their id, for some items or for all. Run it on every
 * machine with a player (init.sqf, a postInit, or remoteExec with JIP) - the menu is built where it opens.
 *
 * Ids of the window's own rows: "inspect", "equip", "attach", "load", "detach", "drop", "open" (open or close
 * a uniform, vest or backpack lying in a container), "repack", "hotbar", "kit" (Enhanced First Aid Kits),
 * "radio" (TFAR, ACRE2), "selectAll", "arsenal", "settings", "cancel", "deselect". An option of CBA's item
 * context menu (CBA_fnc_addItemContextMenuOption, CfgAioMenu >> Entries) is hidden by its CBA id.
 *
 * The same in a mod's config, without script:
 *   class CfgAioMenu { class Hide { class myMod_noDrop { entries[] = {"drop", "hotbar"}; items[] = {"myMod_Canteen"}; }; }; };
 * And for everyone, without a mod: the server setting "Hidden menu entries" (aio_gui_menuHidden).
 *
 * Arguments:
 * 0: Ids <ARRAY of STRINGs, or STRING>
 * 1: Items: class names (their child classes too), "##" + subtype, "#" + type (BIS_fnc_itemType) or "#All"
 *    <ARRAY of STRINGs, or STRING> (default: "#All")
 *
 * Return Value:
 * None
 *
 * Example:
 * [["drop", "hotbar"], ["ACE_bodyBag"]] call aio_gui_fnc_hideMenuEntry;
 *
 * Public: Yes
 */

params [["_ids", [], [[], ""]], ["_items", "#All", [[], ""]]];

if (_ids isEqualType "") then {_ids = [_ids]};
if (_items isEqualType "") then {_items = [_items]};
if (_items isEqualTo []) then {_items = ["#All"]};

if (isNil QGVAR(menuHideRules)) then {GVAR(menuHideRules) = createHashMap};

{
    private _key = toLowerANSI _x;
    private _list = GVAR(menuHideRules) getOrDefault [_key, []];

    GVAR(menuHideRules) set [_key, _list];

    {
        if (_x isEqualType "" && {_x isNotEqualTo ""}) then {_list pushBackUnique toLowerANSI _x};
    } forEach _ids;
} forEach (_items select {_x isEqualType "" && {_x isNotEqualTo ""}});
