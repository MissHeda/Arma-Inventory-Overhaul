#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Where a control is on the screen: inside a controls group its position counts from the group's corner, so
 * every group around it adds its own - and takes off how far that group is scrolled, which the position does not
 * say (a control halfway down a scrolled page is that much higher on the screen than its position). For a popover
 * to open at what opened it. How far a group is scrolled is its scroll bar's place (ctrlScrollValues, 0 to 1) times
 * how much of its content lies beyond its own height; the content's height is what the step that drew the group
 * says (QGVAR(contentH)), else the lowest bottom edge of its own controls.
 *
 * Arguments:
 * 0: Control <CONTROL>
 *
 * Return Value:
 * [x, y, w, h] on the screen <ARRAY>
 *
 * Example:
 * [_button] call aio_setup_fnc_screenRect;
 *
 * Public: No
 */

disableSerialization;

params ["_ctrl"];

(ctrlPosition _ctrl) params ["_left", "_top", "_width", "_height"];

private _group = ctrlParentControlsGroup _ctrl;

while {!isNull _group} do {
    (ctrlPosition _group) params ["_groupX", "_groupY", "", "_groupH"];

    _left = _left + _groupX;
    _top = _top + _groupY;

    // Scrolled: what lies above the group's top edge.
    private _scroll = ((ctrlScrollValues _group) select 0) max 0;

    if (_scroll > 0) then {
        private _contentH = _group getVariable [QGVAR(contentH), -1];

        if (_contentH < 0) then {
            _contentH = 0;

            {
                (ctrlPosition _x) params ["", "_childY", "", "_childH"];

                _contentH = _contentH max (_childY + _childH);
            } forEach ((allControls _group) select {ctrlParentControlsGroup _x isEqualTo _group});
        };

        _top = _top - (_scroll min 1) * ((_contentH - _groupH) max 0);
    };
    _group = ctrlParentControlsGroup _group;
};

[_left, _top, _width, _height]
