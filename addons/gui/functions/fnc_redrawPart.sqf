#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Draws a part of the window again on its own (fnc_drawPart): the group inside the part's group goes with
 * everything in it, and the part is drawn into a new one in the same place - under whatever was made after
 * the build, as it was.
 *
 * What pointed into the old drawing is let go first: its slots (the hotbar's) and its hint areas (the weight
 * card's) are left in their lists as dead entries that nothing can hit - the hover, the context menu and a
 * drag find slots by their number, and the others keep theirs - and the new drawing adds its own. The ring
 * of the slot under the mouse goes, and the hover is looked at again; a context menu opened on one of the
 * slots that went is closed.
 *
 * Arguments:
 * 0: Key of the part <STRING>
 *
 * Return Value:
 * Drawn - false when this build has no such part <BOOL>
 *
 * Example:
 * ["weight"] call einv_gui_fnc_redrawPart;
 *
 * Public: No
 */

disableSerialization;

params [["_key", "", [""]]];

private _part = (uiNamespace getVariable [QGVAR(parts), createHashMap]) getOrDefault [_key, []];

if (_part isEqualTo []) exitWith {false};

_part params ["_outer", "_inner", "_code", "_args", "_rect"];

if (isNull _outer) exitWith {false};

private _display = ctrlParent _outer;

// An entry whose anchor lies in the old drawing (fnc_drawSlot, fnc_drawWeightCard).
private _fnc_inside = {
    params ["_entry"];

    private _anchor = _entry param [3, createHashMap];

    _anchor isEqualType createHashMap && {(_anchor getOrDefault ["parent", controlNull]) isEqualTo _inner}
};

if (!isNull _inner) then {
    private _slots = uiNamespace getVariable [QGVAR(slots), []];
    private _dead = [];

    {
        if ([_x] call _fnc_inside) then {
            _slots set [_forEachIndex, [[-1, -1, 0, 0], "", "", createHashMap, [], "", objNull, -1, objNull]];
            _dead pushBack _forEachIndex;
        };
    } forEach _slots;

    private _areas = uiNamespace getVariable [QGVAR(infoAreas), []];

    {
        if ([_x] call _fnc_inside) then {
            _areas set [_forEachIndex, [[-1, -1, 0, 0], "", "", createHashMap, "", []]];
        };
    } forEach _areas;

    // A menu opened on a slot that goes would act on a dead entry.
    if (_dead isNotEqualTo [] && {(uiNamespace getVariable [QGVAR(menu), []]) isNotEqualTo []}) then {
        GVAR(menuFor) params [["_menuKind", ""], ["_menuIndex", -1]];

        if (_menuKind isEqualTo "slot" && {_menuIndex in _dead}) then {
            call FUNC(closeMenu);
        };
    };

    ctrlDelete _inner;
};

// The ring of the slot under the mouse may have lain in it; the hover is looked at again (fnc_updateHover).
{ctrlDelete _x} forEach (uiNamespace getVariable [QGVAR(hoverRing), []]);
uiNamespace setVariable [QGVAR(hoverRing), []];
GVAR(hover) = [];
GVAR(lastMouse) = [];

(ctrlPosition _outer) params ["_outerX", "_outerY", "_outerW", "_outerH"];

_inner = [_display, "EINV_Group", _outer, [0, 0, _outerW, _outerH]] call FUNC(uiCreate);
_inner setVariable [QGVAR(hooked), true];
_inner ctrlAddEventHandler ["MouseButtonDown", {[true, _this] call FUNC(onMouseButton)}];
_inner ctrlAddEventHandler ["MouseButtonUp", {[false, _this] call FUNC(onMouseButton)}];
_inner ctrlAddEventHandler ["MouseZChanged", {[_this] call FUNC(onMouseZ)}];

_part set [1, _inner];

// What was asked for at its place, from the group's own corner - the group lies on a whole pixel, so
// everything in it lands on the same pixels as drawn on the display.
_rect params ["_left", "_top", "_width", "_height"];

([_display, _inner, [_left - _outerX, _top - _outerY, _width, _height]] + _args) call _code;

true
