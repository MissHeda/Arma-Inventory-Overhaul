#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Creates a flat surface: one rectangle, or with round corners the seven pieces of Enhanced First Aid
 * Kits' panels - three rectangles and four quarter circles (corner_*_ca), so the corners stay round
 * whatever the panel's size and the screen's shape:
 *
 *   TL | Mid | TR        Mid runs the full height between the two sides,
 *   Lft|     | Rgt       Lft and Rgt only between their corners.
 *   BL |     | BR
 *
 * Every edge sits on a screen pixel and the pieces meet without overlapping, so a see-through panel
 * shows no seams. A corner is as many pixels across as down - a quarter circle on any screen - and
 * never more than half the panel, so a short bar comes out as a pill.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in, or controlNull for the display <CONTROL>
 * 2: Position [x, y, w, h] <ARRAY>
 * 3: Colour, [] for no surface <ARRAY>
 * 4: Corner radius, as a height, 0 for square corners <NUMBER> (default: 0)
 * 5: Border colour, [] for none - square panels only <ARRAY> (default: [])
 *
 * Return Value:
 * The controls, rectangles first, then corners, then the border <ARRAY>
 *
 * Example:
 * [_display, controlNull, [0.1, 0.1, 0.3, 0.2], [1, 1, 1, 0.05], 0.01] call einv_gui_fnc_uiPanel;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_rect", "_color", ["_radius", 0], ["_border", []]];
_rect params ["_left", "_top", "_width", "_height"];

private _originX = [safezoneX, 0] select !isNull _parent;
private _originY = [safezoneY, 0] select !isNull _parent;
private _x0 = _originX + round ((_left - _originX) / pixelW) * pixelW;
private _y0 = _originY + round ((_top - _originY) / pixelH) * pixelH;
private _x1 = _originX + round ((_left + _width - _originX) / pixelW) * pixelW;
private _y1 = _originY + round ((_top + _height - _originY) / pixelH) * pixelH;

private _corner = floor (_radius / pixelH) min floor (round ((_x1 - _x0) / pixelW) / 2) min floor (round ((_y1 - _y0) / pixelH) / 2);
private _controls = [];

if (_color isNotEqualTo []) then {
    if (_corner < 1) exitWith {
        private _ctrl = [_display, "EINV_PanelRect", _parent, [_x0, _y0, _x1 - _x0, _y1 - _y0]] call FUNC(uiCreate);
        _ctrl ctrlSetBackgroundColor _color;
        _controls pushBack _ctrl;
    };

    private _cap = _corner * pixelW;
    private _rise = _corner * pixelH;

    {
        // The sides of a pill have no height left between their corners.
        if (_x select 3 <= 0) then {continue};

        private _ctrl = [_display, "EINV_PanelRect", _parent, _x] call FUNC(uiCreate);
        _ctrl ctrlSetBackgroundColor _color;
        _controls pushBack _ctrl;
    } forEach [
        [_x0 + _cap, _y0, _x1 - _x0 - 2 * _cap, _y1 - _y0],
        [_x0, _y0 + _rise, _cap, _y1 - _y0 - 2 * _rise],
        [_x1 - _cap, _y0 + _rise, _cap, _y1 - _y0 - 2 * _rise]
    ];

    {
        _x params ["_texture", "_cornerRect"];

        private _ctrl = [_display, "EINV_PanelCorner", _parent, _cornerRect] call FUNC(uiCreate);
        _ctrl ctrlSetText _texture;
        _ctrl ctrlSetTextColor _color;
        _controls pushBack _ctrl;
    } forEach [
        [UI_TEX(corner_tl_ca), [_x0, _y0, _cap, _rise]],
        [UI_TEX(corner_tr_ca), [_x1 - _cap, _y0, _cap, _rise]],
        [UI_TEX(corner_bl_ca), [_x0, _y1 - _rise, _cap, _rise]],
        [UI_TEX(corner_br_ca), [_x1 - _cap, _y1 - _rise, _cap, _rise]]
    ];
};

// A frame cannot follow round corners.
if (_border isNotEqualTo [] && {_corner < 1}) then {
    _controls pushBack ([_display, _parent, [_x0, _y0, _x1 - _x0, _y1 - _y0], _border] call FUNC(uiFrame));
};

_controls
