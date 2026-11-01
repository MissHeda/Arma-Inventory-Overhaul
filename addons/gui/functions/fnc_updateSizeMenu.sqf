#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Shows the sizes in the size popover under its button in the header (fnc_openSizeMenu), in place: each slider's fill and knob
 * and its value - the tiles and the text in per cent, the rows per page as a number or "All" at the right end -, and the
 * Default button only while a size differs from its default. Asked whenever a size changes (fnc_sizeChanged), so a slider
 * follows the mouse - and a change made in CBA's options shows - without the popover being made again. Neutral greys only; a
 * size the server set is dim. Nothing happens while the popover is not open.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call aio_gui_fnc_updateSizeMenu;
 *
 * Public: No
 */

disableSerialization;

(uiNamespace getVariable [QGVAR(sizeMenuRows), []]) params [["_rows", []], ["_reset", []]];

if (_rows isEqualTo []) exitWith {};

private _defs = call FUNC(sizeDefs);
private _text = [1, 1, 1, 1];
private _text2 = [0.78, 0.78, 0.78, 1];
private _muted = [0.56, 0.56, 0.56, 1];
private _fillOn = [0.72, 0.72, 0.72, 1];
private _changed = false;

{
    _x params ["_index", "_forced", "_label", "_fill", "_thumb", "_valueCtrl", "_geo", ["_idle", false]];
    _geo params ["_left", "_top", "_width", "_height", "_thumbW", "_thumbH", "_thumbTop"];
    (_defs select _index) params ["_setting", "", "", "_least", "_most", "", "_default"];

    private _value = [_index] call FUNC(sizeValue);
    private _place = ((_value - _least) / ((_most - _least) max 0.001)) max 0 min 1;

    if (!_forced && {(abs (_value - (([_default, _most] select (_default <= 0)) max _least min _most))) > 0.001}) then {
        _changed = true;
    };

    // A size the server set, or the rows per page with nothing tall enough looted, has a dim name.
    _label ctrlSetTextColor ([_text, _muted] select (_forced || _idle));

    _fill ctrlSetBackgroundColor ([_fillOn, _muted] select _forced);
    _fill ctrlSetPosition [_left, _top, _width * _place, _height];
    _fill ctrlCommit 0;

    _thumb ctrlSetTextColor ([_text, _muted] select _forced);
    _thumb ctrlSetPosition [_left + _width * _place - _thumbW / 2, _thumbTop, _thumbW, _thumbH];
    _thumb ctrlCommit 0;

    _valueCtrl ctrlSetText (if (_setting isEqualTo QGVAR(pageRows)) then {
        [str round _value, LLSTRING(Size_All)] select (_value >= _most)
    } else {
        (str round (_value * 100)) + "%"
    });
    _valueCtrl ctrlSetTextColor ([_text2, _muted] select _forced);
} forEach _rows;

// Default only where there is something to take back.
{_x ctrlShow _changed} forEach _reset;
