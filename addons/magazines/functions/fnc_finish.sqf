#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Tells how the repack ended and shows the result. What a stop that moved nothing, a commit that was
 * turned down or one that was done have in common: the hint. The window is built again with the magazines
 * in their cells (einv_gui_fnc_build) and the text written over the hint it ends with - "Repacked: 1 full
 * and 2 rounds left over" in the gain colour when it ran to its end, "Repack stopped: ..." when it did not,
 * the loss colour for "The magazines changed - nothing was repacked" (a magazine was taken meanwhile) and
 * for any other reason a transaction gives (einv_gui_fnc_flashHint).
 *
 * An emptied magazine is gone: one fewer of its kind known in a container that was searched
 * (einv_gui_fnc_learn).
 *
 * The window closed meanwhile: the result is told the way ACE tells it after its own repack, with the
 * magazine's picture (ace_common_fnc_displayTextPicture).
 *
 * Arguments:
 * 0: Result - "" done, "Nothing" nothing was moved, "Gone" or "Moved" a magazine was taken meanwhile,
 *    else a reason (einv_gui_fnc_flashHint) <STRING>
 * 1: Record, see fnc_commit and fnc_stop <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["", _record] call einv_magazines_fnc_finish;
 *
 * Public: No
 */

disableSerialization;

params [["_result", "", [""]], ["_record", createHashMap, [createHashMap]]];

private _capacity = _record get "capacity";

// An emptied magazine is gone from the container it lay in.
if (_result isEqualTo "") then {
    {
        _x params ["_container", "_class", "", "_after"];

        if (_after == 0) then {
            [_container, _class, -1] call EFUNC(gui,learn);
        };
    } forEach (_record get "parts");
};

private _counts = _record get "counts";
private _full = {_x >= _capacity} count _counts;
private _rest = 0;

{
    if (_x < _capacity) then {
        _rest = _rest + _x;
    };
} forEach _counts;

private _done = (_record get "why") isEqualTo "Done";
private _reason = "";

// The text and its colour; a reason of the transaction's own is said by the window's hint.
private _answer = switch (_result) do {
    case "": {
        [format [[LLSTRING(Hint_RepackStopped), LLSTRING(Hint_Repacked)] select _done, _full, _rest], ["text2", "gain"] select _done]
    };
    case "Nothing": {
        [LLSTRING(Hint_RepackNothing), "text2"]
    };
    case "Gone";
    case "Moved": {
        [LLSTRING(Hint_RepackChanged), "loss"]
    };
    default {
        _reason = _result;

        [LELSTRING(gui,Hint_Failed), "loss"]
    };
};

_answer params ["_text", "_colorKey"];

private _display = uiNamespace getVariable [QEGVAR(gui,display), displayNull];

// The window is gone (or going): ACE's way of telling, with the magazine's picture
// (ace_magazinerepack_fnc_magazineRepackFinish).
if ((_record get "why") isEqualTo "Closed" || {isNull _display}) exitWith {
    if (!isNil QACEFUNC(common,displayTextPicture)) then {
        [_text, _record get "picture", nil, nil, 2.5] call ACEFUNC(common,displayTextPicture);
    };
};

[_display] call EFUNC(gui,build);

// The hover first - it writes the hint - then the result over it, until the mouse lands on something else.
[_display, getMousePosition, true] call EFUNC(gui,updateHover);

if (_reason isNotEqualTo "") then {
    [_reason] call EFUNC(gui,flashHint);
} else {
    [_text, _colorKey] call EFUNC(gui,showHint);
};
