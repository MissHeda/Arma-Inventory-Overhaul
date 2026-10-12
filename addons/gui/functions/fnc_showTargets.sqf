#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * While an item is dragged, every one of the player's slots that takes it lights up, as in Tarkov - a
 * green outline and a faint green fill on its round corners: the helmet's slot for a helmet, the
 * weapons a magazine or attachment fits (on the weapon's card as on the part's own slot).
 *
 * A worn item dragged off a slot lights up the same slot of the other units it may be exchanged with
 * (fnc_canSwap) - a body's for the player's own, the player's for a body's -, in the inventory only.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: The dragged entry <HASHMAP>
 * 2: The slot it comes from, [unit, slot id] - [] for a tile <ARRAY> (default: [])
 *
 * Return Value:
 * None - the controls are kept as uiNamespace QGVAR(dragGlow), gone again with fnc_endDrag
 *
 * Example:
 * [_display, _entry] call einv_gui_fnc_showTargets;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_entry", ["_slotSource", [], [[]]]];

private _class = _entry getOrDefault ["class", ""];
private _unit = GVAR(unit);
private _theme = GVAR(theme);
private _color = _theme getOrDefault ["gain", [0.298, 0.765, 0.541, 1]];
private _fill = +_color;
_fill set [3, TARGET_FILL_ALPHA];

private _controls = [];

{
    _x params [["_rect", []], "", "", ["_anchor", createHashMap], "", ["_slot", ""], ["_owner", objNull]];

    if (_slot isEqualTo "" || {_rect isEqualTo []} || {(_x param [7, -1]) >= 0}) then {continue};

    private _fits = if (_slotSource isEqualTo []) then {
        _owner isEqualTo _unit && {
            [_unit, _slot, _class] call EFUNC(storage,slotAccepts) || {
                _slot in ["primary", "handgun", "launcher"] && {([_unit, _slot, _class] call EFUNC(storage,partFor)) isNotEqualTo ""}
            }
        }
    } else {
        !isNull _owner && {_owner isNotEqualTo (_slotSource select 0)} && {_slot isEqualTo (_slotSource select 1)}
        && {[] call FUNC(isInventoryMode)} && {([_slotSource, _owner, _slot] call FUNC(canSwap)) isEqualTo ""}
    };

    if (!_fits) then {continue};

    // In its column's group where it has one, so it scrolls and clips with the slot.
    private _parent = controlNull;
    private _box = _rect;

    if (_anchor isEqualType createHashMap && {"rel" in _anchor} && {!isNull (_anchor getOrDefault ["parent", controlNull])}) then {
        _parent = _anchor get "parent";
        _box = (_anchor get "rel") + [_rect select 2, _rect select 3];
    };

    private _radius = (_theme getOrDefault ["radius", 0]) min ((_box select 3) / 4);

    _controls append ([_display, _parent, _box, _fill, _radius] call FUNC(uiPanel));
    _controls append ([_display, _parent, _box, _color, _radius] call FUNC(uiRing));
} forEach (uiNamespace getVariable [QGVAR(slots), []]);

uiNamespace setVariable [QGVAR(dragGlow), _controls];
