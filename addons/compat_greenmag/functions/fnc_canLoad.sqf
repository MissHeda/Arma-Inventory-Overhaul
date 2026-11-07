#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What letting a tile go on a magazine tile means with GreenMag Rework loaded: its loose rounds, a pack of them or a belt
 * loaded into that magazine, as GreenMag's own drag onto a magazine in the engine's inventory does (gmr_handling_fnc_dropOnMagazine)
 * - the same rules, the same reasons. Three answers, as aio_magazines_fnc_canRepack gives them: [true, ""] it loads; [false, ""]
 * nothing of GreenMag's, the drag goes on as it always did; [false, reason] it would be, but cannot - the footprint is red and
 * says why.
 *
 * GreenMag takes the rounds and the magazine from the player's own uniform, vest and backpack only, so both tiles must lie there.
 *
 * Arguments:
 * 0: The grid the dragged tile comes from <HASHMAP>
 * 1: The dragged tile <HASHMAP>
 * 2: The grid let go on <HASHMAP>
 * 3: The tile let go on <HASHMAP>
 *
 * Return Value:
 * [loads, reason] <ARRAY>
 *
 * Example:
 * [_sourceGrid, _entry, _targetGrid, _targetTile] call aio_compat_greenmag_fnc_canLoad;
 *
 * Public: No
 */

params [
    ["_sourceGrid", createHashMap, [createHashMap]], ["_entry", createHashMap, [createHashMap]],
    ["_targetGrid", createHashMap, [createHashMap]], ["_targetTile", createHashMap, [createHashMap]]
];

// GreenMag loaded, on, and its drag to load not switched off.
if (
    isNil "gmr_handling_fnc_start"
    || {!(missionNamespace getVariable ["gmr_main_enabled", false])}
    || {!(missionNamespace getVariable ["gmr_main_dragToLoad", true])}
) exitWith {[false, ""]};

private _item = _entry getOrDefault ["class", ""];

if ((toLowerANSI _item) find "gmr_" != 0) exitWith {[false, ""]};

private _facts = [_item] call gmr_main_fnc_itemInfo;

if !((_facts param [GMR_ITEM_KIND, ""]) in ["round", "clip", "pack", "belt"]) exitWith {[false, ""]};

private _class = _targetTile getOrDefault ["class", ""];

if (_class isEqualTo "" || {!isClass (configFile >> "CfgMagazines" >> _class)}) exitWith {[false, ""]};

// A magazine GreenMag knows nothing of - a grenade, a launcher's round - is no place to load: the drag goes on.
private _magazine = [_class] call gmr_main_fnc_magazineInfo;

if !(_magazine param [GMR_MAG_OK, false]) exitWith {[false, ""]};

// A tile not searched yet, one in the hidden holder, or one a move is under way for.
if (
    _entry getOrDefault ["hidden", false] || {_targetTile getOrDefault ["hidden", false]}
    || {_entry getOrDefault ["pending", false]} || {_targetTile getOrDefault ["pending", false]}
) exitWith {[false, ""]};

// Both in the player's own gear, plain grids: not a kit's window, not the Arsenal's list.
private _unit = missionNamespace getVariable [QEGVAR(gui,unit), objNull];
private _own = [uniformContainer _unit, vestContainer _unit, backpackContainer _unit] - [objNull];
private _fnc_own = {
    params ["_grid"];

    ((_grid getOrDefault ["container", objNull]) in _own)
    && {(_grid getOrDefault ["kit", ""]) isEqualTo ""}
    && {(_grid getOrDefault ["source", ""]) isEqualTo ""}
};

if (isNull _unit || {!([_sourceGrid] call _fnc_own)} || {!([_targetGrid] call _fnc_own)}) exitWith {
    [false, LLSTRING(Hint_OwnGear)]
};

// Its caliber, or universal ammunition where the server allows it; a belt for a belt magazine only.
private _isBelt = (_facts select GMR_ITEM_KIND) isEqualTo "belt";
private _universal = ["", "universal"] select (missionNamespace getVariable ["gmr_main_universalAmmo", false]);

if (
    !((_facts param [GMR_ITEM_CALIBER, ""]) in [_magazine param [GMR_MAG_CALIBER, ""], _universal])
    || {_isBelt isNotEqualTo (_magazine param [GMR_MAG_BELT, false])}
) exitWith {
    [false, localize "STR_gmr_handling_Hint_WrongAmmo"]
};

private _amount = _targetTile getOrDefault ["ammo", 0];

if (_amount >= (_magazine param [GMR_MAG_CAPACITY, 0])) exitWith {[false, LLSTRING(Hint_Full)]};

// The kind of round the magazine may take (GreenMag's "Ammo rules", a tracer magazine, mixed rounds).
private _ammunition = [_facts select GMR_ITEM_ROUND, _facts select GMR_ITEM_BELT_TYPE] select _isBelt;

// A box of stripper clips (GreenMag 1.1) holds clips: their rounds are what loads.
private _inside = [_ammunition] call gmr_main_fnc_itemInfo;

if (!_isBelt && {(_inside param [GMR_ITEM_KIND, ""]) isEqualTo "clip"}) then {
    _ammunition = _inside select GMR_ITEM_ROUND;
};

private _why = ([_class, _amount, _ammunition] call gmr_handling_fnc_loadRule) param [1, ""];

if (_why isNotEqualTo "") exitWith {[false, _why]};

if ((_facts select GMR_ITEM_KIND) isEqualTo "pack" && {missionNamespace getVariable ["gmr_main_packsMustOpen", false]}) exitWith {
    [false, localize "STR_gmr_handling_Hint_OpenPack"]
};

[true, ""]
