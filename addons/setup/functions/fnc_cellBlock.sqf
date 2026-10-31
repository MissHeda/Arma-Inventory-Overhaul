#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A compartment of the Blocks way (fnc_drawCellBlocks) in the one form its working copy keeps: [cols, rows, holes] for a
 * compartment that takes anything and is a compartment like any other, [cols, rows, holes, [], accepts, single] once it
 * accepts only some categories or is a single slot - the form aio_items_fnc_parseGrid gives and fnc_formatGrid writes, so the
 * working copy goes to the preview, to the total and to Apply as it is, and two copies of the same thing compare equal.
 *
 * Arguments:
 * 0: The compartment, [cols, rows, holes] and anything after <ARRAY>
 * 1: The categories it accepts, built-in or the draft's own, [] for all <ARRAY of STRING> (default: its own, else [])
 * 2: Whether it is a single slot <BOOL> (default: its own, else false)
 *
 * Return Value:
 * The compartment <ARRAY>
 *
 * Example:
 * [[1, 1, []], ["grenade"], true] call aio_setup_fnc_cellBlock; // [1, 1, [], [], ["grenade"], true]
 *
 * Public: No
 */

params [["_block", [1, 1, []], [[]]], ["_accepts", nil, [[]]], ["_single", nil, [false]]];

if (isNil "_accepts") then {
    _accepts = _block param [4, []];
};

if (isNil "_single") then {
    _single = _block param [5, false];
};

private _plain = [_block select 0, _block select 1, +(_block param [2, []])];

if (_accepts isEqualTo [] && {!_single}) exitWith {_plain};

_plain + [[], [_accepts] call EFUNC(items,orderGroups), _single]
