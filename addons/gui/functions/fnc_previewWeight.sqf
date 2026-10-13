#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Shows, the moment something is lifted, what it would add to the soldier: when the item comes from outside
 * his own gear - another container, a body, a catalog - the weight card gets a preview of the weight it
 * would add, as a lighter segment after the fill in the colour of the tier it would put him in
 * (fnc_weightColor). Weight limits no container, so nothing else is marked: the cells alone decide where
 * it fits.
 *
 * Called at lift with create true (fnc_startDrag; the preview is made before the ghost, which has to stay
 * the last control made) and again after every change of count (fnc_onMouseZ), when it only moves and
 * colours the one lift made. Not for several tiles at once (fnc_groupMode shows those), nor for what lies
 * in a kit's grid (Enhanced First Aid Kits decides for itself). fnc_clearWeightPreview puts everything back.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Entry that is dragged <HASHMAP>
 * 2: How many of a stack, at least 1 <NUMBER>
 * 3: Make the preview - at lift <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _entry, 5, true] call einv_gui_fnc_previewWeight;
 *
 * Public: No
 */

disableSerialization;

params ["_display", ["_entry", createHashMap, [createHashMap]], ["_count", 1, [0]], ["_create", false, [false]]];

if (count _entry == 0) exitWith {};

private _theme = GVAR(theme);

// Where it comes from: none for a slot's item.
GVAR(press) params ["_sourceIndex", "", "", "", "", ["_slotSource", []]];

private _sourceGrid = if (_slotSource isEqualTo []) then {(uiNamespace getVariable [QGVAR(grids), []]) param [_sourceIndex, createHashMap]} else {createHashMap};
private _sourceBox = _sourceGrid getOrDefault ["container", objNull];

// What goes, in config mass.
private _stack = (_entry getOrDefault ["count", 1]) max 1;
private _taking = (_count max 1) min _stack;
private _need = ([[_entry]] call EFUNC(storage,getMass)) * _taking / _stack;

private _bar = uiNamespace getVariable [QGVAR(weightBar), createHashMap];

private _external = switch (true) do {
    case ((_sourceGrid getOrDefault ["kit", ""]) isNotEqualTo ""): {false};
    case (_slotSource isNotEqualTo []): {(_slotSource select 0) isNotEqualTo GVAR(unit)};
    case ((_sourceGrid getOrDefault ["source", ""]) isNotEqualTo ""): {true};
    default {!isNull _sourceBox && {!([_sourceBox] call FUNC(isOwnStorage))}};
};

// fnc_updateDrag warns what a pick-up would make of the soldier only for what comes from outside his gear.
uiNamespace setVariable [QGVAR(dragExternal), _external];

if (count _bar > 0 && {_external}) then {
    private _limits = _bar get "limits";
    private _load = _bar get "load";
    private _end = (_limits get "critical") max 1;
    (_bar get "rect") params ["_barX", "_barY", "_barW", "_barH"];

    private _from = (_load / _end) min 1;
    private _to = ((_load + _need) / _end) min 1;
    private _rect = [_barX + _barW * _from, _barY, (_barW * (_to - _from)) max pixelW, _barH];

    // The colour the fill would have with it, lighter: no mark on the bar, the segment says how far it goes.
    private _color = [_bar get "unit", _load + _need, _theme] call FUNC(weightColor);
    _color = [_color select 0, _color select 1, _color select 2, PREVIEW_ALPHA];

    private _preview = uiNamespace getVariable [QGVAR(weightPreview), controlNull];

    if (_create && {isNull _preview}) then {
        _preview = [_display, "EINV_PanelRect", _bar get "parent", _rect] call FUNC(uiCreate);
        uiNamespace setVariable [QGVAR(weightPreview), _preview];
    };

    if (!isNull _preview) then {
        _preview ctrlSetPosition _rect;
        _preview ctrlSetBackgroundColor _color;
        _preview ctrlCommit 0;
    };
};
