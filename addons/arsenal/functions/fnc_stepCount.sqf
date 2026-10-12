#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The arrow keys over a card or an item of the soldier's: one more of that class, or one less (Shift:
 * five), at most one step every STEP_REPEAT seconds while held. Over a card one is added like a Ctrl+click
 * does, over a tile of his own one more goes into the same container; one less is given back from the
 * soldier's storage, the last tile of the class first. Over anything else nothing happens.
 *
 * The caller can say whether Shift is held; without it ACE's own record of the key is read.
 *
 * Arguments:
 * 0: Direction, 1 to add and -1 to give back <NUMBER>
 * 1: Shift held <BOOL> (default: ACE's record of it)
 *
 * Return Value:
 * None
 *
 * Example:
 * [1] call einv_arsenal_fnc_stepCount;
 *
 * Public: No
 */

params [["_delta", 1, [0]], ["_shift", missionNamespace getVariable [QACEGVAR(arsenal,shiftState), false], [false]]];

private _unit = GVAR(center);
private _column = uiNamespace getVariable [QGVAR(column), createHashMap];
private _now = diag_tickTime;

if (isNull _unit || {_now < (_column getOrDefault ["stepAt", 0]) + STEP_REPEAT}) exitWith {};

private _hover = EGVAR(gui,hover);

if ((_hover param [0, ""]) isNotEqualTo "tile") exitWith {};

private _grid = (uiNamespace getVariable [QEGVAR(gui,grids), []]) param [_hover param [1, -1], createHashMap];
private _tile = (_grid getOrDefault ["tiles", []]) param [_hover param [2, -1], createHashMap];
private _class = _tile getOrDefault ["class", ""];

// Not on identity, kits' windows or a tile a move is waiting for.
if (
    _class isEqualTo "" || {(_tile getOrDefault ["kind", ""]) in ["face", "voice", "insignia"]}
    || {(_grid getOrDefault ["kit", ""]) isNotEqualTo ""} || {_tile getOrDefault ["pending", false]}
) exitWith {};

_column set ["stepAt", _now];

private _n = [1, 5] select _shift;
private _fromCatalog = (_grid getOrDefault ["source", ""]) isNotEqualTo "";

if (_delta > 0) exitWith {
    // Over a card like Ctrl+click; over his own tile into the container it lies in.
    [_class, _n, [_grid getOrDefault ["container", objNull], objNull] select _fromCatalog] call FUNC(quickAdd);
};

// ----- One less: the last tile of the class, in the container of this tile first -----
private _first = [_grid getOrDefault ["container", objNull], objNull] select _fromCatalog;
private _containers = [uniformContainer _unit, vestContainer _unit, backpackContainer _unit] select {!isNull _x};

if (!isNull _first && {_first in _containers}) then {
    _containers = [_first] + (_containers - [_first]);
};

private _key = toLowerANSI _class;

// Something this arsenal does not have is thrown away after the second click.
private _go = true;

if ([_class] call FUNC(isUnique)) then {
    _go = ["step|" + _key, format [LLSTRING(Hint_ConfirmUnique), [_class] call EFUNC(gui,itemName)]] call FUNC(arm);
};

if (!_go) exitWith {};

private _done = 0;

for "_i" from 1 to _n do {
    private _found = [];

    {
        private _container = _x;
        private _placed = ([_container, [_container] call EFUNC(storage,getContents)] call EFUNC(storage,getLayout)) get "entries";
        private _at = -1;

        {
            if (toLowerANSI (_x getOrDefault ["class", ""]) isEqualTo _key) then {
                _at = _forEachIndex;
            };
        } forEach _placed;

        if (_at >= 0) exitWith {
            _found = [_container, _placed select _at];
        };
    } forEach _containers;

    if (_found isEqualTo [] || {!([_found, 1, true] call FUNC(giveBack))}) exitWith {};

    _done = _done + 1;
};

if (_done == 0) exitWith {};

[_class, -1, _done] call FUNC(aceCargoEvent);
["giveBack"] call EFUNC(gui,playSound);

private _name = [_class] call EFUNC(gui,itemName);

[format [LLSTRING(Hint_GivenBack), [_name, format ["%1× %2", _done, _name]] select (_done > 1)]] call FUNC(message);

call EFUNC(gui,requestRebuild);
