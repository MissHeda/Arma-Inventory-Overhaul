#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The highlight of one equipment slot that takes what is dragged: a faint green fill on round corners and a
 * green outline (fnc_uiPanel and fnc_uiRing - with the theme's corners some fifteen controls, which is what
 * made lifting an item hitch). It is made once per build and kept by the slot's number in
 * uiNamespace glowCache; a drag only shows it and hides it again (fnc_showTargets, fnc_endDrag), and
 * fnc_warmTargets makes the ones to come while the window is idle. Asked for again, it makes the controls
 * anew only when they are gone (the part they lay in was drawn again) or the slot stands elsewhere now; a
 * build empties the cache along with the controls.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Number of the slot in uiNamespace slots <NUMBER>
 *
 * Return Value:
 * The controls - as they were kept, a new one shown - or [] for a slot with no place <ARRAY>
 *
 * Example:
 * [_display, 3] call aio_gui_fnc_glowSlot;
 *
 * Public: No
 */

disableSerialization;

params ["_display", ["_index", -1, [0]]];

private _record = (uiNamespace getVariable [QGVAR(slots), []]) param [_index, []];

if (_record isEqualTo []) exitWith {[]};

_record params [["_rect", []], "", "", ["_anchor", createHashMap]];

if (_rect isEqualTo []) exitWith {[]};

// In its column's group where it has one, so it scrolls and clips with the slot.
private _parent = controlNull;
private _box = _rect;

if (_anchor isEqualType createHashMap && {"rel" in _anchor} && {!isNull (_anchor getOrDefault ["parent", controlNull])}) then {
    _parent = _anchor get "parent";
    _box = (_anchor get "rel") + [_rect select 2, _rect select 3];
};

private _cache = uiNamespace getVariable QGVAR(glowCache);

if (isNil "_cache") then {
    _cache = createHashMap;
    uiNamespace setVariable [QGVAR(glowCache), _cache];
};

private _signature = [_box, _parent];
private _kept = _cache getOrDefault [_index, []];

// Made already and still where the slot is.
if (_kept isNotEqualTo [] && {(_kept select 0) isEqualTo _signature} && {((_kept select 1) findIf {isNull _x}) < 0}) exitWith {
    _kept select 1
};

// Gone, or the slot moved: what is left of the old ones goes.
{ctrlDelete _x} forEach (_kept param [1, []]);

private _theme = GVAR(theme);
private _color = _theme getOrDefault ["gain", [0.298, 0.765, 0.541, 1]];
private _fill = +_color;
_fill set [3, TARGET_FILL_ALPHA];

private _radius = (_theme getOrDefault ["radius", 0]) min ((_box select 3) / 4);
private _controls = [];

_controls append ([_display, _parent, _box, _fill, _radius] call FUNC(uiPanel));
_controls append ([_display, _parent, _box, _color, _radius] call FUNC(uiRing));

_cache set [_index, [_signature, _controls]];

_controls
