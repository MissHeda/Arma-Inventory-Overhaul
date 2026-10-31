#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The editor's picture of a crate or vehicle in a box with round corners, like the glass panels.
 *
 * Editor pictures are rendered on one flat grey backdrop (BIS_fnc_exportEditorPreviews, which mods use
 * as well). So the box is that grey, round at its corners, and the picture lies on it whole, fitted
 * by its own shape: where it ends, the grey goes on, and no edge shows - nothing is cut off, and
 * nothing in the box can be scrolled. A film over both darkens them to sit with the glass.
 *
 * The picture may be drawn larger, smaller or moved by the class's icon=; it is cut at the round box
 * (fnc_uiPictureCut), so its corners are the box's as when it is not.
 *
 * Not every picture lies on exactly that grey: ACE's previews are lighter than BI's, others differ again, and
 * a script cannot read a picture's pixels to match it. Where the image ends inside the box, the backdrop's
 * colour is laid over its edges in a few steps of falling strength, so whatever the difference is it comes
 * in gradually instead of as a rectangle's edge.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in, or controlNull for the display <CONTROL>
 * 2: The box [x, y, w, h] <ARRAY>
 * 3: Texture <STRING>
 * 4: Corner radius, as a height <NUMBER>
 * 5: Film over it, [] for none <ARRAY> (default: [])
 * 6: The backdrop's colour <ARRAY> (default: the editor pictures' grey)
 * 7: How the rules draw the picture, [scale, across, down] (icon=): larger, smaller or moved, cut to the box
 *    (fnc_uiItemPicture) <ARRAY> (default: [1, 0, 0])
 * 8: Report the mouse as the inventory window does - not in the setup wizard <BOOL> (default: true)
 *
 * Return Value:
 * The controls <ARRAY>
 *
 * Example:
 * [_display, controlNull, [0.1, 0.1, 0.2, 0.2], _preview, UNIT * 0.45, [0, 0, 0, 0.4]] call einv_gui_fnc_uiPictureRounded;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_rect", "_texture", ["_radius", 0], ["_film", []], ["_backdrop", EDITOR_PREVIEW_BACKDROP], ["_icon", ICON_PLAIN, [[]]], ["_events", true, [true]]];
_rect params ["_left", "_top", "_width", "_height"];

private _controls = [_display, _parent, _rect, _backdrop, _radius] call FUNC(uiPanel);

// A little air round the picture, so the subject never touches the box's edge.
private _inset = _height * 0.04;
private _pictureBox = [_left + SQUARE(_inset), _top + _inset, _width - SQUARE(_inset) * 2, _height - _inset * 2];

_controls append ([_display, _parent, _pictureBox, _texture, _icon, _rect, _radius, _events] call FUNC(uiPictureCut));

// ----- The picture's edges fade into the backdrop -----
// Where the image really ends, as fnc_uiItemPicture fits it: the picture's own shape in the box, scaled and moved.
_icon params [["_scale", 1], ["_across", 0], ["_down", 0]];
_pictureBox params ["_boxX", "_boxY", "_boxW", "_boxH"];

private _info = getTextureInfo _texture;
private _ratio = 0;

if (_info isEqualType [] && {(_info param [0, 0]) > 0} && {(_info param [1, 0]) > 0}) then {
    _ratio = (_info select 0) / (_info select 1);
};

private _imageW = _boxW * _scale;
private _imageH = _boxH * _scale;

if (_ratio > 0) then {
    if ((_imageW / pixelW) / (_imageH / pixelH) > _ratio) then {
        _imageW = (_imageH / pixelH) * _ratio * pixelW;
    } else {
        _imageH = (_imageW / pixelW) / _ratio * pixelH;
    };
};

private _imageLeft = _boxX + _boxW / 2 + _across * _width - _imageW / 2;
private _imageTop = _boxY + _boxH / 2 + _down * _height - _imageH / 2;
private _imageRight = _imageLeft + _imageW;
private _imageBottom = _imageTop + _imageH;

// The round box's pieces as fnc_uiPanel lays them out: a strip may not reach into the corners, which have no
// backdrop where the box is round.
private _corner = floor (_radius / pixelH) min floor (_width / pixelW / 2) min floor (_height / pixelH / 2);
private _cap = _corner * pixelW;
private _rise = _corner * pixelH;
private _right = _left + _width;
private _bottom = _top + _height;

private _zones = [
    [_top, _top + _rise, _left + _cap, _right - _cap],
    [_top + _rise, _bottom - _rise, _left, _right],
    [_bottom - _rise, _bottom, _left + _cap, _right - _cap]
];

private _fnc_cover = {
    params ["_strip", "_alpha"];
    _strip params ["_stripX", "_stripY", "_stripW", "_stripH"];

    private _stripRight = (_stripX + _stripW) min _right;
    private _stripBottom = (_stripY + _stripH) min _bottom;

    _stripX = _stripX max _left;
    _stripY = _stripY max _top;

    {
        _x params ["_zoneTop", "_zoneBottom", "_zoneLeft", "_zoneRight"];

        private _x0 = _stripX max _zoneLeft;
        private _x1 = _stripRight min _zoneRight;
        private _y0 = _stripY max _zoneTop;
        private _y1 = _stripBottom min _zoneBottom;

        if (_x1 > _x0 && {_y1 > _y0}) then {
            _controls append ([
                _display, _parent, [_x0, _y0, _x1 - _x0, _y1 - _y0], [_backdrop select 0, _backdrop select 1, _backdrop select 2, _alpha]
            ] call FUNC(uiPanel));
        };
    } forEach _zones;
};

// FADE_STEPS strips of whole pixels along each edge of the image that lies inside the box, the outermost the
// backdrop's colour almost whole, the innermost hardly at all.
private _stepH = (round (_height * FADE_SHARE / pixelH / FADE_STEPS)) max 1;
private _stepV = _stepH * pixelH;
private _stepX = _stepH * pixelW;

for "_i" from 0 to (FADE_STEPS - 1) do {
    private _alpha = 1 - (_i + 0.5) / FADE_STEPS;

    if (_imageTop > _top + pixelH * 2) then {
        [[_imageLeft, _imageTop + _i * _stepV, _imageW, _stepV], _alpha] call _fnc_cover;
    };

    if (_imageBottom < _bottom - pixelH * 2) then {
        [[_imageLeft, _imageBottom - (_i + 1) * _stepV, _imageW, _stepV], _alpha] call _fnc_cover;
    };

    if (_imageLeft > _left + pixelW * 2) then {
        [[_imageLeft + _i * _stepX, _imageTop, _stepX, _imageH], _alpha] call _fnc_cover;
    };

    if (_imageRight < _right - pixelW * 2) then {
        [[_imageRight - (_i + 1) * _stepX, _imageTop, _stepX, _imageH], _alpha] call _fnc_cover;
    };
};

if (_film isNotEqualTo []) then {
    _controls append ([_display, _parent, _rect, _film, _radius] call FUNC(uiPanel));
};

_controls
