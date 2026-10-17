#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What dropping one magazine tile onto another means. Three answers: [true, ""] a repack; [false, ""] not
 * a repack - the window goes on exactly as it would without this addon; [false, text] a repack the player
 * clearly meant that cannot happen - the footprint turns red on the target tile and text is the reason.
 *
 * Checked in this order: repacking off or busy, other classes, a tile not searched yet (nothing is told
 * about what lies under a "?"), not a magazine of more than one round, a grid that is virtual, overflow,
 * a kit's or ACE's list in the Arsenal panel, a living person's gear; then the ones that say why not - a class ACE
 * forbids repacking, a full or empty magazine, magazines under different roots (the player's own gear
 * and a crate, or two crates: "take it into your own gear first").
 *
 * Arguments:
 * 0: Grid the dragged tile lies in <HASHMAP>
 * 1: The dragged tile <HASHMAP>
 * 2: Grid of the tile under the mouse <HASHMAP>
 * 3: The tile under the mouse <HASHMAP>
 *
 * Return Value:
 * [fits, reason] - reason a localized text or "" <ARRAY>
 *
 * Example:
 * [_sourceGrid, _entry, _targetGrid, _under] call einv_magazines_fnc_canRepack;
 *
 * Public: No
 */

params [["_sourceGrid", createHashMap, [createHashMap]], ["_sourceTile", createHashMap, [createHashMap]], ["_targetGrid", createHashMap, [createHashMap]], ["_targetTile", createHashMap, [createHashMap]]];

if !([] call FUNC(isEnabled)) exitWith {[false, ""]};
if ([] call FUNC(isBusy)) exitWith {[false, ""]};

if (count _sourceTile == 0 || {count _targetTile == 0}) exitWith {[false, ""]};

private _class = _sourceTile getOrDefault ["class", ""];

if (_class isEqualTo "" || {toLowerANSI _class isNotEqualTo toLowerANSI (_targetTile getOrDefault ["class", ""])}) exitWith {[false, ""]};

// A tile not searched yet, one kept in the hidden holder (Strict mode - not magazines of the cargo), or one a
// move is under way for.
if (
    _sourceTile getOrDefault ["hidden", false] || {_targetTile getOrDefault ["hidden", false]}
    || {_sourceTile getOrDefault ["strict", false]} || {_targetTile getOrDefault ["strict", false]}
    || {_sourceTile getOrDefault ["pending", false]} || {_targetTile getOrDefault ["pending", false]}
) exitWith {[false, ""]};

private _info = [_class] call EFUNC(items,getInfo);
private _capacity = _info getOrDefault ["capacity", 0];

if ((_info getOrDefault ["kind", ""]) isNotEqualTo "magazine" || {_capacity < 2}) exitWith {[false, ""]};

// Grids that are no place for it: a body's worn gear, the overflow row, a kit's window, ACE's list in the Arsenal panel.
private _fnc_plain = {
    params ["_grid"];

    !isNull (_grid getOrDefault ["container", objNull])
    && {!(_grid getOrDefault ["virtual", true])}
    && {!(_grid getOrDefault ["overflow", false])}
    && {(_grid getOrDefault ["kit", ""]) isEqualTo ""}
    && {(_grid getOrDefault ["source", ""]) isEqualTo ""}
};

if !(([_sourceGrid] call _fnc_plain) && {[_targetGrid] call _fnc_plain}) exitWith {[false, ""]};

// Under a root of its own: the player's gear, or one crate, vehicle, pile or body. A living person's never.
private _sourceRoot = [_sourceGrid] call FUNC(domain);
private _targetRoot = [_targetGrid] call FUNC(domain);

if (isNull _sourceRoot || {isNull _targetRoot}) exitWith {[false, ""]};

if (getNumber (configFile >> "CfgMagazines" >> _class >> "ace_disableRepacking") == 1) exitWith {[false, LLSTRING(Hint_NoRepack)]};

private _sourceAmmo = _sourceTile getOrDefault ["ammo", 0];
private _targetAmmo = _targetTile getOrDefault ["ammo", 0];

if (_sourceAmmo <= 0 || {_sourceAmmo >= _capacity} || {_targetAmmo <= 0} || {_targetAmmo >= _capacity}) exitWith {[false, LLSTRING(Hint_NotPartial)]};

if (_sourceRoot isNotEqualTo _targetRoot) exitWith {[false, LLSTRING(Hint_RepackApart)]};

[true, ""]
