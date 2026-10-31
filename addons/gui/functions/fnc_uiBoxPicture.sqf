#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * What fills the square box of a crate or a vehicle (fnc_drawSection, the cargo cards of ACE, the setup wizard's
 * preview of the box): the picture its rules give the class (picture=, einv_picture), else the picture the
 * editor has of it (editorPreview) on its own grey (fnc_uiPictureRounded) - either one drawn by the class's
 * icon= (fnc_uiItemPicture): larger, smaller or moved, and cut to the box's rectangle.
 *
 * A picture of the rules is an item's icon, not an editor picture: it lies on the theme's slot surface
 * like the picture in a slot, with a little air round it. The caller has drawn that surface already when
 * it wants one under a picture of the editor too; this adds it for the rules' picture only.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in, or controlNull for the display <CONTROL>
 * 2: The box [x, y, w, h] <ARRAY>
 * 3: Theme <HASHMAP>
 * 4: The picture the rules give the class, "" for none <STRING>
 * 5: The picture the editor has of it, "" for none <STRING>
 * 6: How it is drawn, [scale, across, down] (icon=) <ARRAY>
 * 7: Corner radius, as a height <NUMBER>
 * 8: Report the mouse as the inventory window does - not in the setup wizard <BOOL> (default: true)
 *
 * Return Value:
 * The controls - [] when there is nothing to draw and the caller shows its placeholder <ARRAY>
 *
 * Example:
 * [_display, _parent, _boxRect, _theme, _own, _preview, [1.4, 0, 0], UNIT * 0.4] call einv_gui_fnc_uiBoxPicture;
 *
 * Public: No
 */

disableSerialization;

params [
    "_display", "_parent", "_rect", ["_theme", createHashMap, [createHashMap]], ["_own", "", [""]], ["_preview", "", [""]],
    ["_icon", ICON_PLAIN, [[]]], ["_radius", 0, [0]], ["_events", true, [true]]
];
_rect params ["_left", "_top", "_width", "_height"];

if (_own isNotEqualTo "") exitWith {
    private _controls = [_display, _parent, _rect, _theme getOrDefault ["slot", [1, 1, 1, 0.06]], _radius, _theme getOrDefault ["slotBorder", []]] call FUNC(uiPanel);
    private _inset = _height * 0.08;

    // Larger than the box it is cut at the round box, not at a square one (fnc_uiPictureCut).
    _controls append ([
        _display, _parent, [_left + SQUARE(_inset), _top + _inset, _width - SQUARE(_inset) * 2, _height - _inset * 2], _own, _icon,
        _rect, _radius, _events
    ] call FUNC(uiPictureCut));

    _controls
};

if (_preview isEqualTo "") exitWith {[]};

// The editor's picture on its own grey, filling the round box without an edge, under a dark film so the grey sits
// with the glass.
[_display, _parent, _rect, _preview, _radius, [0, 0, 0, 0.5], EDITOR_PREVIEW_BACKDROP, _icon, _events] call FUNC(uiPictureRounded)
