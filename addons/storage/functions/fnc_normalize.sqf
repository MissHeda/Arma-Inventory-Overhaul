#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Makes the stored places of a holder cover what it holds - on its authority only: the uniforms, vests
 * and backpacks lying in it tagged (fnc_tagNested), its entries laid out (fnc_getLayout) and, when the
 * records drifted from the cargo, the layout's records written (fnc_writePlaces).
 *
 * fnc_getLayout is pure and gives every machine the same picture from the same data, so what this writes
 * is exactly what every viewer already showed: nothing visibly moves when it lands.
 *
 * Within a running phase the layout starts from the phase's buffered records (fnc_readPlaces), and what
 * comes out is written whenever it differs from what is stored - so the phase's own changes are written
 * by it as well (fnc_execute).
 *
 * A holder of another type that lists nothing (a kit of Enhanced First Aid Kits before that mod has
 * synced its contents here) keeps its records: fnc_getLayout hands them back as they were.
 *
 * Arguments:
 * 0: Holder <OBJECT or STRING>
 *
 * Return Value:
 * Places were written <BOOL>
 *
 * Example:
 * [cursorObject] call aio_storage_fnc_normalize;
 *
 * Public: No
 */

params [["_holder", objNull, [objNull, ""]]];

private _isKey = _holder isEqualType "";

if ((_isKey && {_holder isEqualTo ""}) || {!_isKey && {isNull _holder}}) exitWith {false};

// Only the authority writes; a phase running here was checked for that already.
private _authority = !isMultiplayer || {GVAR(executing)} || {GVAR(journalKey) isNotEqualTo ""} || {
    private _root = [_holder] call FUNC(rootOf);

    if (isNull _root) then {isServer} else {local _root}
};

if (!_authority) exitWith {false};

private _entries = [];

if (_isKey) then {
    private _type = GVAR(holderTypes) getOrDefault [(_holder splitString ":") param [0, ""], createHashMap];
    private _code = _type get "entries";

    if (!isNil "_code") then {
        _entries = [_holder] call _code;
    };

    if (isNil "_entries" || {!(_entries isEqualType [])}) then {_entries = []};
} else {
    [_holder] call FUNC(tagNested);
    _entries = [_holder] call FUNC(getContents);
};

private _before = ([_holder, true] call FUNC(readPlaces)) select 0;
private _layout = [_holder, _entries] call FUNC(getLayout);

([_holder, _layout get "records"] call FUNC(writePlaces)) > _before
