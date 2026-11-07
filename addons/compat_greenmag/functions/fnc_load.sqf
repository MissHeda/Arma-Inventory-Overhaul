#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Loads GreenMag Rework's ammunition into the magazine it was let go on (fnc_canLoad said yes): a pack is opened first, the
 * window closes, and GreenMag's own loading takes over - the hold action, or the progress bar when its "Hold to load" is off -,
 * exactly as after its drag in the engine's inventory. GreenMag finds the magazine by its class and rounds.
 *
 * Arguments:
 * 0: The grid the dragged tile comes from <HASHMAP>
 * 1: The dragged tile <HASHMAP>
 * 2: The grid let go on <HASHMAP>
 * 3: The tile let go on <HASHMAP>
 *
 * Return Value:
 * Whether loading starts <BOOL>
 *
 * Example:
 * [_sourceGrid, _entry, _targetGrid, _targetTile] call aio_compat_greenmag_fnc_load;
 *
 * Public: No
 */

params [
    ["_sourceGrid", createHashMap, [createHashMap]], ["_entry", createHashMap, [createHashMap]],
    ["_targetGrid", createHashMap, [createHashMap]], ["_targetTile", createHashMap, [createHashMap]]
];

// Asked again: the inventory may have changed since the drag looked.
if !(([_sourceGrid, _entry, _targetGrid, _targetTile] call FUNC(canLoad)) select 0) exitWith {false};

private _unit = missionNamespace getVariable [QEGVAR(gui,unit), objNull];
private _item = _entry get "class";
private _class = _targetTile get "class";
private _amount = _targetTile getOrDefault ["ammo", 0];
private _facts = [_item] call gmr_main_fnc_itemInfo;
private _isBelt = (_facts select GMR_ITEM_KIND) isEqualTo "belt";
private _ammunition = [_facts select GMR_ITEM_ROUND, _facts select GMR_ITEM_BELT_TYPE] select _isBelt;

// What was dragged is what loads (GreenMag 1.2): loose rounds and their boxes only loose rounds, a stripper clip or a box
// of clips only rounds on clips. A box of clips holds clips, so its rounds are the clips' rounds.
private _from = ["loose", "clips"] select ((_facts select GMR_ITEM_KIND) isEqualTo "clip");
private _inside = [_ammunition] call gmr_main_fnc_itemInfo;

if (!_isBelt && {(_inside param [GMR_ITEM_KIND, ""]) isEqualTo "clip"}) then {
    _ammunition = _inside select GMR_ITEM_ROUND;
    _from = "clips";
};

if (_isBelt) then {
    _from = "auto";
};

if ((_facts select GMR_ITEM_KIND) isEqualTo "pack") then {
    [_unit, _item, true, _sourceGrid getOrDefault ["container", objNull]] call gmr_handling_fnc_unpack;
};

// After this drag has ended: the window closes, and on the frame after GreenMag starts with nothing open, as after its own drag.
[{
    params ["_unit", "_class", "_amount", "_ammunition", "_from"];

    ["GreenMag loading"] call EFUNC(gui,closeDisplay);

    [{
        params ["_unit", "_class", "_amount", "_ammunition", "_from"];

        [_unit, "fill", _class, [_amount], _ammunition, _from] call gmr_handling_fnc_start;
    }, _this] call CBA_fnc_execNextFrame;
}, [_unit, _class, _amount, _ammunition, _from]] call CBA_fnc_execNextFrame;

true
