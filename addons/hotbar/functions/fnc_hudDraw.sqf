#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Paints the seven boxes of the bar from the slots: the item's picture (faded when none is carried), the
 * key, the number carried (in the error colour at none), and the box itself in the interface background
 * colour, half as strong while the slot is empty. Called when what the bar shows has changed
 * (fnc_hudFrame compares), not every frame; the lit boxes of a treatment, a grenade in the hand and a
 * refused press are fnc_hudFrame's.
 *
 * Arguments:
 * 0: Count per slot (fnc_counts) <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [call einv_hotbar_fnc_counts] call einv_hotbar_fnc_hudDraw;
 *
 * Public: No
 */

disableSerialization;

params [["_counts", [], [[]]]];

private _ctrls = uiNamespace getVariable [QGVAR(hudCtrls), createHashMap];

if (count _ctrls == 0) exitWith {};

private _slotCtrls = _ctrls get "slots";
private _bcg = GVAR(hudColors) getOrDefault ["bcg", [0, 0, 0, 0.5]];
private _text = GVAR(hudColors) getOrDefault ["text", [1, 1, 1, 0.8]];
private _error = GVAR(hudColors) getOrDefault ["error", [0.8, 0, 0, 0.8]];
private _kinds = [];

for "_i" from 0 to (SLOT_COUNT - 1) do {
    private _info = [_i, _counts param [_i, 0]] call FUNC(slotInfo);
    private _empty = (_info get "class") isEqualTo "";
    private _count = _info get "count";
    private _ctrl = _slotCtrls select _i;

    _kinds pushBack (_info get "kind");

    (_ctrl get "picture") ctrlSetText (_info get "picture");
    (_ctrl get "picture") ctrlSetTextColor [1, 1, 1, [1, 0.65] select (_count == 0)];

    (_ctrl get "key") ctrlSetText (_info get "key");

    (_ctrl get "count") ctrlSetText (["", str _count] select !_empty);
    (_ctrl get "count") ctrlSetTextColor ([_text, _error] select (_count == 0));

    // Half as strong while nothing lies on it.
    private _background = +_bcg;

    if (_empty) then {
        _background set [3, (_background select 3) / 2];
    };

    (_ctrl get "box") ctrlSetBackgroundColor _background;

    // The lit boxes are painted over this again by the next frame.
    (_ctrl get "bar") progressSetPosition 0;
};

GVAR(hudKinds) = _kinds;
_ctrls set ["states", _kinds apply {"base"}];
