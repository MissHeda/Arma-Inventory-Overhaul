#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Puts a part on a weapon that lies in a container, or takes one off it (#56) - from the attachments view of a weapon tile
 * (Attachments in its menu, fnc_partChoices), or a part dropped on a weapon's tile (fnc_endDrag). One transaction (fnc_sendMoves
 * "fit"): the part taken out, the weapon taken out, the part put on it (op "fit", aio_storage_fnc_opFit - checked there again),
 * the weapon put back onto its cell, and what was on that part before put where the new one lay. Taken off, the part goes into
 * the player's own gear, the first of uniform, vest and backpack with room, else into the weapon's container.
 *
 * Only what may be touched (fnc_checkTouch), and only what fits that part of the weapon (aio_storage_fnc_partFits) - else the
 * hint says why and nothing moves.
 *
 * Arguments:
 * 0: Part - "muzzle", "optic", "rail", "bipod", "mag" or "mag2" <STRING>
 * 1: The weapon's container <OBJECT>
 * 2: The weapon's tile <HASHMAP>
 * 3: The part's container, objNull to take the part off <OBJECT> (default: objNull)
 * 4: The part's tile <HASHMAP> (default: empty)
 * 5: Taken off: where it goes - a container or "ground" -, objNull to let it go into the player's gear <OBJECT, STRING>
 *    (default: objNull)
 * 6: Taken off into a container: the cell, [] for the first free one <ARRAY> (default: [])
 *
 * Return Value:
 * Asked for <BOOL>
 *
 * Example:
 * ["optic", backpackContainer player, _weaponTile, vestContainer player, _opticTile] call aio_gui_fnc_doFit;
 *
 * Public: No
 */

params [
    ["_part", "", [""]], ["_from", objNull, [objNull]], ["_entry", createHashMap, [createHashMap]],
    ["_partFrom", objNull, [objNull]], ["_partEntry", createHashMap, [createHashMap]],
    ["_offTo", objNull, [objNull, ""]], ["_offCell", [], [[]]]
];

if (_part isEqualTo "" || {isNull _from} || {count _entry == 0}) exitWith {false};
if (_entry getOrDefault ["pending", false]) exitWith {false};

private _why = [_from, "items"] call FUNC(checkTouch);

if (_why isEqualTo "" && {!isNull _partFrom}) then {
    _why = [_partFrom, "items"] call FUNC(checkTouch);
};

if (_why isNotEqualTo "") exitWith {
    [_why] call FUNC(flashHint);
    false
};

// Put on: it has to fit.
if (!isNull _partFrom) exitWith {
    if (_partEntry getOrDefault ["pending", false] || {_partEntry getOrDefault ["hidden", false]}) exitWith {false};

    if !([_entry getOrDefault ["class", ""], _part, _partEntry getOrDefault ["class", ""]] call EFUNC(storage,partFits)) exitWith {
        ["NoFit"] call FUNC(flashHint);
        false
    };

    [[createHashMapFromArray [
        ["kind", "fit"], ["from", _from], ["entry", _entry], ["part", _part], ["partFrom", _partFrom], ["partEntry", _partEntry]
    ]]] call FUNC(sendMoves)
};

// Taken off: into the player's own gear where it fits, else back into the weapon's container.
private _old = (_entry getOrDefault ["attachments", []]) param [["", "muzzle", "rail", "optic", "mag", "mag2", "bipod"] find _part, ""];
private _oldClass = if (_old isEqualType []) then {_old param [0, ""]} else {_old};

if (_oldClass isEqualTo "") exitWith {false};

// Dragged out to a place of its own (fnc_doUnequip): there.
if (_offTo isEqualType "" || {!isNull _offTo}) exitWith {
    if (_offTo isEqualType objNull && {([_offTo, "items"] call FUNC(checkTouch)) isNotEqualTo ""}) exitWith {
        [([_offTo, "items"] call FUNC(checkTouch))] call FUNC(flashHint);
        false
    };

    [[createHashMapFromArray [
        ["kind", "fit"], ["from", _from], ["entry", _entry], ["part", _part], ["to", _offTo], ["cell", _offCell]
    ]]] call FUNC(sendMoves)
};

private _unit = GVAR(unit);
private _probe = createHashMapFromArray [["class", _oldClass], ["count", 1]];
private _own = [uniformContainer _unit, vestContainer _unit, backpackContainer _unit] select {!isNull _x};
private _index = _own findIf {[_x, _probe] call EFUNC(storage,hasRoom)};

[[createHashMapFromArray [
    ["kind", "fit"], ["from", _from], ["entry", _entry], ["part", _part], ["to", if (_index >= 0) then {_own select _index} else {_from}]
]]] call FUNC(sendMoves)
