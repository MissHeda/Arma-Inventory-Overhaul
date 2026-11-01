#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Inspect, as in Tarkov: opens the inspect card for an item (fnc_drawInspect) - its picture, name,
 * description and figures - or shows another item on the card that is open. The card is a window of
 * its own: it stays open while the inventory is used, can be moved by its title and closed with its
 * cross or Escape. Kept as GVAR(inspect), so a rebuild of the window brings it back where it was. A short
 * sound of the item for the looter alone (fnc_playSound "inspect").
 *
 * Arguments:
 * 0: Item class <STRING>
 * 1: How many <NUMBER> (default: 1)
 * 2: A magazine's rounds, -1 for full <NUMBER> (default: -1)
 * 3: A weapon's attachments, as fnc_getContents gives them <ARRAY> (default: [])
 * 4: The container it lies in, for how many may share a tile there (a crate stacks higher than a vest,
 *    aio_storage_fnc_stackFor) <OBJECT> (default: objNull)
 * 5: One of the player's weapon slots it is on - "primary", "primary2", "handgun", "launcher" -, to change its parts on the card
 *    (fnc_drawHotspots), "" to look only <STRING> (default: "")
 * 6: Modify: the wide card in 3D, the weapon and its parts alone <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * ["arifle_MX_F"] call aio_gui_fnc_inspect;
 *
 * Public: No
 */

params [
    ["_class", "", [""]], ["_count", 1, [0]], ["_ammo", -1, [0]], ["_attachments", [], [[]]], ["_holder", objNull, [objNull]],
    ["_modify", "", [""]], ["_large", false, [false]]
];

if (_class isEqualTo "") exitWith {};

call FUNC(closeMenu);

GVAR(inspect) = [_class, _count, _ammo, _attachments, _holder, _modify, _large];

call FUNC(drawInspect);

["inspect", _class, objNull, false] call FUNC(playSound);
