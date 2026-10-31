#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The caption lines' activity chips, every frame while one stands (fnc_onFrame, GVAR(statusLive)): the ring goes round
 * (one ctrlSetAngle on one control per chip) and the words are written in place when they changed - the hands' count
 * when an item of the queue finished, the search's time once a second (fnc_statusWords). Nothing is made here. A chip
 * whose box has nothing left to do (the queue's last item was sent, the last item found), or whose words took another
 * shape than it was made for (fnc_updateStatus sizes it to them), asks fnc_updateStatus, which makes it true again.
 *
 * The search's time is what is left of the box's items: their cells at the box's time per cell, less what its run has done.
 *
 * A sealed block (fnc_drawSection) takes nothing: a tile dragged over it finds no grid there, so the drag would just do
 * nothing. While a drag is held over one, the block says why - a film in the loss colour over it and "Search it first"
 * in its line - and let go there, the footer's hint says it too (fnc_flashHint). The drag itself is left alone. A drag
 * ends the frame before the chips are looked at (fnc_onFrame), so it asks for this part alone.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Now, diag_tickTime <NUMBER>
 * 2: Only the sealed block under a drag, not the chips <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, diag_tickTime] call aio_gui_fnc_animateStatus;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_now", ["_dragOnly", false, [false]]];

if (!GVAR(statusLive)) exitWith {};

private _second = floor _now;
private _tick = _second != GVAR(statusSecond);

if (!_dragOnly) then {
    GVAR(statusSecond) = _second;
};

private _resync = false;
private _infos = uiNamespace getVariable [QGVAR(sectionInfo), []];

{
    // A sealed block's ring (fnc_drawSection), shown while its box is searched (fnc_updateStatus).
    private _sealArc = (_x getOrDefault ["seal", createHashMap]) getOrDefault ["arc", controlNull];

    if (!isNull _sealArc && {ctrlShown _sealArc}) then {
        _sealArc ctrlSetAngle [(_now * STATUS_SPIN_SPEED) mod 360, 0.5, 0.5];
    };

    private _status = _x getOrDefault ["status", createHashMap];

    if (count _status == 0) then {continue};

    private _kind = _status get "kind";
    private _text = _status get "text";

    // The ring: round and round.
    private _arc = _status get "arc";

    if (!isNull _arc) then {
        _arc ctrlSetAngle [(_now * STATUS_SPIN_SPEED) mod 360, 0.5, 0.5];
    };

    // The search's time changes once a second; the hands' count whenever an item of the queue finished.
    if (_kind isEqualTo "search" && {!_tick}) then {continue};

    private _words = [
        _x getOrDefault ["holder", objNull], _kind, _status get "stopped", _status getOrDefault ["idle", false],
        _status getOrDefault ["sealed", false], _now, _status get "room", _status get "font", _status get "size"
    ] call FUNC(statusWords);

    if (_words isEqualTo _text) then {continue};

    // Nothing left, or words of another width: the chip is made again to them.
    if (_words isEqualTo "" || {(_words regexReplace ["[0-9]", "0"]) isNotEqualTo (_status get "shape")}) then {
        _resync = true;
        continue;
    };

    (_status get "label") ctrlSetText _words;
    _status set ["text", _words];
} forEach ([_infos, []] select _dragOnly);

// A drag held over a sealed block: the block it is over, found by where the block lies on the screen now (its column
// scrolls) and only where its column shows it.
private _over = createHashMap;

if (GVAR(dragging)) then {
    getMousePosition params ["_mouseX", "_mouseY"];

    {
        private _seal = _x getOrDefault ["seal", createHashMap];

        if (count _seal == 0) then {continue};

        ([_seal get "frame"] call FUNC(gridOrigin)) params ["_frameX", "_frameY"];
        (_seal get "frameSize") params ["_frameW", "_frameH"];

        if (_mouseX < _frameX || {_mouseX >= _frameX + _frameW} || {_mouseY < _frameY} || {_mouseY >= _frameY + _frameH}) then {continue};

        ([_seal get "anchor"] call FUNC(gridOrigin)) params ["_blockX", "_blockY"];
        (_seal get "blockSize") params ["_blockW", "_blockH"];

        if (_mouseX >= _blockX && {_mouseX < _blockX + _blockW} && {_mouseY >= _blockY} && {_mouseY < _blockY + _blockH}) exitWith {
            _over = _seal;
        };
    } forEach _infos;
};

if ((count _over > 0 || {count GVAR(sealDragOver) > 0}) && {!(_over isEqualRef GVAR(sealDragOver))}) then {
    private _before = GVAR(sealDragOver);
    private _theme = GVAR(theme);

    // The block it left has its own words and colour back. Let go over it, the footer says why nothing happened - not
    // when a build ended the drag, which made the block anew.
    if (count _before > 0) then {
        {_x ctrlShow false} forEach (_before getOrDefault ["film", []]);

        private _line = _before getOrDefault ["line", controlNull];

        if (!isNull _line) then {
            _line ctrlSetText (_before getOrDefault ["words", ""]);
            _line ctrlSetTextColor (_theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]]);

            if (!GVAR(dragging)) then {
                [LLSTRING(Seal_Refused)] call FUNC(flashHint);
            };
        };
    };

    if (count _over > 0) then {
        {_x ctrlShow true} forEach (_over getOrDefault ["film", []]);

        private _line = _over get "line";

        _line ctrlSetText ([LLSTRING(Seal_Refused), _over get "width", _theme getOrDefault ["font", "PuristaMedium"], _over get "size"] call FUNC(fitText));
        _line ctrlSetTextColor (_theme getOrDefault ["loss", [0.941, 0.333, 0.353, 1]]);
    };

    GVAR(sealDragOver) = _over;
};

// Something ended: the chips are made true again (one pass, and the next frame finds nothing to ask).
if (_resync) then {
    [_display] call FUNC(updateStatus);
};
