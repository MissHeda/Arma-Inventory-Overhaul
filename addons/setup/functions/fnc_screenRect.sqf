#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Where a control is on the screen: inside a controls group its position counts from the group's corner,
 * so every group around it adds its own. For a popover to open below what opened it. How far a group is
 * scrolled is not counted - the wizard opens popovers from places that do not scroll.
 *
 * Arguments:
 * 0: Control <CONTROL>
 *
 * Return Value:
 * [x, y, w, h] on the screen <ARRAY>
 *
 * Example:
 * [_button] call einv_setup_fnc_screenRect;
 *
 * Public: No
 */

disableSerialization;

params ["_ctrl"];

(ctrlPosition _ctrl) params ["_left", "_top", "_width", "_height"];

private _group = ctrlParentControlsGroup _ctrl;

while {!isNull _group} do {
    (ctrlPosition _group) params ["_groupX", "_groupY"];

    _left = _left + _groupX;
    _top = _top + _groupY;
    _group = ctrlParentControlsGroup _group;
};

[_left, _top, _width, _height]
