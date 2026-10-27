#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The place records that still fit a container's grid - for records noted on another object (ACE Arsenal makes
 * all three worn containers new objects whenever one is picked, einv_arsenal_fnc_keepPlaces), which may be of
 * another class with other compartments. A record fits when its compartment exists, its box lies inside it, none
 * of its cells is a hole of the compartment, and it takes no cell an earlier record that fits already took. Those
 * are kept as they are, in their order; the rest drop out, and their items get a fresh first fit at the next layout
 * (fnc_getLayout). The same grid keeps every record that was valid on it, so a swap for a container with the exact
 * same layout - or the same class again - keeps everything where it lay.
 *
 * A single slot (a sixth element of its compartment, fnc_slotOf) takes its tile whole: a record there fits when its
 * first cell lies in the slot and the slot is still empty. A shaped item is asked with its own holes as it lies
 * (einv_items_fnc_footprintAs), when the record's size is the item's; otherwise as a full box. Which item a record
 * belongs to, its size and its compartment's categories are the layout's to decide, as for any record.
 *
 * A container without compartments of its own (the ground, fnc_getBlocks) has no edge: every well-formed record is
 * kept.
 *
 * Arguments:
 * 0: Container <OBJECT>
 * 1: Records, [key, col, row, w, h, block, rot (, count)] each (fnc_readPlaces) <ARRAY>
 *
 * Return Value:
 * The records that fit, in their order <ARRAY>
 *
 * Example:
 * [vestContainer player, _oldRecords] call einv_storage_fnc_fitRecords;
 *
 * Public: No
 */

params [["_container", objNull, [objNull]], ["_records", [], [[]]]];

if (isNull _container || {_records isEqualTo []}) exitWith {[]};

private _wellFormed = _records select {_x isEqualType [] && {(_x select [0, 6]) isEqualTypeArray ["", 0, 0, 0, 0, 0]}};
private _blocks = [_container] call FUNC(getBlocks);

if (_blocks isEqualTo []) exitWith {_wellFormed};

// Per compartment, rows of booleans: its holes taken from the start (fnc_seedTaken), then every record kept.
private _taken = [_blocks] call FUNC(seedTaken);
private _kept = [];

{
    _x params ["_key", "_col", "_row", "_w", "_h", "_block", ["_rot", -1]];

    if (_block < 0 || {_block >= count _blocks}) then {continue};

    private _spec = _blocks select _block;

    _spec params ["_cols", "_rows"];

    if (_col < 0 || {_row < 0} || {_col >= _cols} || {_row >= _rows}) then {continue};

    // A single slot: the compartment whole, while nothing lies in it yet.
    if ((_spec param [5, false]) isEqualTo true) then {
        ([_spec] call FUNC(slotOf)) params ["_slotCol", "_slotRow", "_slotW", "_slotH", "_slotHoles"];

        if ([_taken select _block, _slotCol, _slotRow, _slotW, _slotH, _slotHoles] call FUNC(cellsFree)) then {
            [_taken select _block, _cols, _slotCol, _slotRow, _slotW, _slotH, _slotHoles] call FUNC(takeCells);
            _kept pushBack _x;
        };

        continue;
    };

    if (_w < 1 || {_h < 1} || {_col + _w > _cols} || {_row + _h > _rows}) then {continue};

    // Its own holes as it lies - turned when the record says so, or (a record from before rot) when it is not as
    // wide as the item upright.
    private _class = (_key splitString "|") param [0, ""];
    private _info = [_class] call EFUNC(items,getInfo);
    private _turned = if (_rot isEqualTo 0 || {_rot isEqualTo 1}) then {
        _rot isEqualTo 1
    } else {
        _w != ((_info getOrDefault ["size", [_w, _h]]) param [0, _w])
    };

    ([_info, _turned] call EFUNC(items,footprintAs)) params [["_fw", 0], ["_fh", 0], ["_fHoles", []]];

    private _holes = [[], _fHoles] select ([_fw, _fh] isEqualTo [_w, _h]);

    if ([_taken select _block, _col, _row, _w, _h, _holes] call FUNC(cellsFree)) then {
        [_taken select _block, _cols, _col, _row, _w, _h, _holes] call FUNC(takeCells);
        _kept pushBack _x;
    };
} forEach _wellFormed;

_kept
