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
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in, or controlNull for the display <CONTROL>
 * 2: The box [x, y, w, h] <ARRAY>
 * 3: Texture <STRING>
 * 4: Corner radius, as a height <NUMBER>
 * 5: Film over it, [] for none <ARRAY> (default: [])
 * 6: The backdrop's colour <ARRAY> (default: the editor pictures' grey)
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

params ["_display", "_parent", "_rect", "_texture", ["_radius", 0], ["_film", []], ["_backdrop", EDITOR_PREVIEW_BACKDROP]];
_rect params ["_left", "_top", "_width", "_height"];

private _controls = [_display, _parent, _rect, _backdrop, _radius] call FUNC(uiPanel);

// A little air round the picture, so the subject never touches the box's edge.
private _inset = _height * 0.04;

_controls pushBack ([_display, _parent, [_left + SQUARE(_inset), _top + _inset, _width - SQUARE(_inset) * 2, _height - _inset * 2], _texture] call FUNC(uiPicture));

if (_film isNotEqualTo []) then {
    _controls append ([_display, _parent, _rect, _film, _radius] call FUNC(uiPanel));
};

_controls
