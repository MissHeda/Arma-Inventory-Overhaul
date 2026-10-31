#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether an item may be used while it lies in one of the unit's containers - the one question behind the
 * padlocks, the hint, the hotbar and the reload key:
 *
 *   ""         nothing limits it: the container is on Everything, or the item is no kind that is used from
 *              where it lies (a rifle, an attachment, clothing)
 *   "allowed"  the container is on Only whitelisted or Strict and the item is whitelisted for it (use=,
 *              aio_use)
 *   "blocked"  it cannot be used from there: Only whitelisted or Strict and not whitelisted, or Nothing. On
 *              Strict a blocked item is also kept out of the container's cargo, in the unit's hidden holder
 *              (fnc_opStrict) - the answer is the same.
 *
 * Arguments:
 * 0: Item class <STRING>
 * 1: Container: "uniform", "vest" or "backpack" - "" for any other place <STRING>
 *
 * Return Value:
 * "", "allowed" or "blocked" <STRING>
 *
 * Example:
 * ["HandGrenade", "backpack"] call aio_storage_fnc_useState;
 *
 * Public: Yes
 */

params [["_class", "", [""]], ["_kind", "", [""]]];

if (_kind isEqualTo "" || {!(missionNamespace getVariable [QGVAR(useActive), false])}) exitWith {""};

private _mode = [_kind] call FUNC(useMode);

if (_mode isEqualTo USE_ALL) exitWith {""};

private _info = [_class] call EFUNC(items,getInfo);

if !((_info get "kind") in USE_ITEM_KINDS) exitWith {""};

if (_mode isEqualTo USE_NONE) exitWith {"blocked"};

["blocked", "allowed"] select (_kind in (_info get "use"))
