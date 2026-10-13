#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The layout of the panel (the "layout" hook): the uniform, vest or backpack whose tab is open in ACE's
 * left bar, as one section of the inventory's own (einv_gui_fnc_drawColumn with einv_gui_fnc_drawSection) -
 * titled with its name, its caption with what it holds weighs, its compartments and tiles - in the panel
 * beside ACE's list (fnc_panelRect), and under it the line for the hints (fnc_footer). Nothing while another
 * tab is open, that slot is empty, or ACE's panels are hidden (Backspace).
 *
 * The section always opens unfolded, whatever the inventory last did with its caption. ACE's list is
 * registered as a zone of the engine: whatever is let go outside the panel is shown going there, out of
 * the container (fnc_dragCheck).
 *
 * Arguments:
 * 0: ACE Arsenal's display <DISPLAY>
 * 1: Theme <HASHMAP>
 * 2: Context <HASHMAP>
 *
 * Return Value:
 * Where the soldier stands - nothing: the camera is ACE's <ARRAY>
 *
 * Example:
 * [_display, _theme, _context] call einv_arsenal_fnc_layout;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]], ["_theme", createHashMap, [createHashMap]], ["_context", createHashMap, [createHashMap]]];

GVAR(panelRect) = [];
GVAR(hintRect) = [];
GVAR(removeZone) = -1;

(call FUNC(selected)) params ["_id", "_container"];

if (_id isEqualTo "" || {!GVAR(shown)}) exitWith {[]};

private _index = (_context getOrDefault ["ownSections", []]) findIf {(_x getOrDefault ["container", objNull]) isEqualTo _container};

if (_index < 0) exitWith {[]};

private _section = (_context get "ownSections") select _index;
private _rect = [_display] call FUNC(panelRect);

if (_rect isEqualTo []) exitWith {[]};

_rect params ["_left", "_top", "_width", "_height"];

// Folded is what a section starts as, turned round by the inventory's clicks on its caption
// (einv_gui_collapsed): starting as that list has it, it is always open here.
_section set ["folded", _container in EGVAR(gui,collapsed)];

private _hintH = SNAP_H(UNIT * HINT_LINE_H);
private _gap = SNAP_H(UNIT * HINT_LINE_GAP);
private _columnH = _height - _hintH - _gap;

if (_columnH < UNIT * 4) exitWith {[]};

[
    _display, [_left, _top, _width, _columnH], [_section], _theme, _section getOrDefault ["title", ""], "",
    QEFUNC(gui,drawSection), "storage"
] call EFUNC(gui,drawColumn);

GVAR(panelRect) = _rect;
GVAR(hintRect) = [_left, _top + _columnH + _gap, _width, _hintH];

// The hint line is part of the panel: a drag let go over it is no drop outside.
EGVAR(gui,panels) pushBack GVAR(hintRect);

// ACE's list takes back what is let go outside the panel.
private _list = _display displayCtrl ARSENAL_IDC_LIST;

if (!isNull _list) then {
    private _zones = uiNamespace getVariable [QEGVAR(gui,zones), []];

    GVAR(removeZone) = count _zones;
    _zones pushBack [ctrlPosition _list, "remove"];

    uiNamespace setVariable [QEGVAR(gui,zones), _zones];
};

[]
