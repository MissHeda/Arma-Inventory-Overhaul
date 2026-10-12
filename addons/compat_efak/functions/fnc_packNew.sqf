#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Packs new items into a kit straight from the Enhanced Arsenal's catalog: nothing is taken from anywhere,
 * the kit's contents are written (einv_compat_efak_fnc_putIntoKit, which ends in that mod's setContents) and
 * the item gets a tile in the kit's window, on the cell asked for when that is free, else where the kit's
 * layout puts it. Only while the kit's arsenal setting is everything (fnc_arsenalEditing), and only what
 * that mod would let into the kit by hand: its item rules, the default contents limit, the room left
 * (fnc_canPack). As many as fit go in when not all do.
 *
 * Written where it is called: the kit has to lie under the root named - the Arsenal's unit, whose gear is
 * local to the player, as einv_storage_fnc_addNew's containers are. A kit nobody has carried yet (a
 * prototype, in the Eden editor or on a Zeus unit) holds nothing of its own yet and says so.
 *
 * Arguments:
 * 0: Kit class, an instance <STRING>
 * 1: Item class <STRING>
 * 2: How many <NUMBER> (default: 1)
 * 3: Cell [col, row, compartment, width, height], [] for the first place there is <ARRAY> (default: [])
 * 4: The unit whose gear the kit lies in, objNull to take it for granted <OBJECT> (default: objNull)
 *
 * Return Value:
 * [how many went in, why not - "" when they did, "ReadOnly" for a kit the arsenal may not fill, else a word
 *  for einv_gui_fnc_flashHint or a text -, the cell it landed on or []] <ARRAY>
 *
 * Example:
 * ["efak_IFAK_7", "ACE_morphine", 2, [], player] call einv_compat_efak_fnc_packNew;
 *
 * Public: No
 */

params [
    ["_kit", "", [""]], ["_class", "", [""]], ["_count", 1, [0]], ["_cell", [], [[]]], ["_root", objNull, [objNull]]
];

if (_kit isEqualTo "" || {_class isEqualTo ""} || {_count < 1}) exitWith {[0, "Failed", []]};

if (([_kit] call FUNC(arsenalEditing)) < 2) exitWith {[0, "ReadOnly", []]};

// Whether the kit takes this many more.
private _fnc_takes = {
    params ["_n"];

    ([_kit, _class, _n] call FUNC(canPack)) select 0
};

if !([1] call _fnc_takes) exitWith {
    ([_kit, _class, 1] call FUNC(canPack)) params ["", "_why"];

    [0, [_why, "Failed"] select (_why isEqualTo ""), []]
};

// Not all of them: as many as there is room and allowance for (the answer only ever turns from yes to no).
private _n = _count;

if !([_n] call _fnc_takes) then {
    private _low = 1;
    private _high = _n;

    while {_high - _low > 1} do {
        private _mid = floor ((_low + _high) / 2);

        if ([_mid] call _fnc_takes) then {
            _low = _mid;
        } else {
            _high = _mid;
        };
    };

    _n = _low;
};

// The kit lies under the unit's gear, or the contents are another's. Written here only for a unit of
// this machine: its gear's transactions run here too (einv_storage_fnc_isLocalRoot) - one writer.
if (!isNull _root && {!local _root}) exitWith {[0, "Failed", []]};
if (!isNull _root && {!([("kit:" + toLowerANSI _kit), _root] call FUNC(holderVerify))}) exitWith {[0, "Gone", []]};

([_kit, [_class, _n] call EFUNC(storage,makePayload), _cell] call FUNC(putIntoKit)) params ["_why", "_landed"];

if (_why isNotEqualTo "") exitWith {[0, _why, []]};

[] call FUNC(requestRebuild);

[_n, "", _landed]
