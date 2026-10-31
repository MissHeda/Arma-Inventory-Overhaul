#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Keeps a heavy action from being run once per click when the player clicks fast (Mia, 0.5.7: spamming the fold button of a
 * backpack took the game down to 15 fps - every click built the whole window). The state a click changes is changed at
 * once by the caller (cheap); what is heavy - building, redrawing, a network request - goes through here under a key, and
 * runs at most once per gap with the latest code and arguments given for that key ("latest wins"), never queued once per click.
 *
 * Throttle (the default): the first request of a quiet moment runs at once, as before. A request that comes while the
 * key is resting (a gap of at least `gap` seconds, or COALESCE_REST times as long as the last run took, whichever is longer, so
 * a slow action is left alone longer) only marks the key as due: one run when the rest is over, from fnc_onFrame
 * (fnc_coalesceTick), with the arguments of the last request. However many clicks come, at most one run waits per key.
 * Debounce: nothing runs until `gap` seconds after the last request (a search typed in).
 *
 * The code runs outside any control's event only when the caller was outside one: callers that rebuild the window call
 * from fnc_later, as they always did. Nothing is kept past the window (fnc_attach, fnc_onUnload empty the table), and a
 * window that is covered by another one runs nothing until it is uncovered (fnc_onFrame).
 *
 * Arguments:
 * 0: The key, one per action and thing it is done to ("build", "filter", "sort|<holder>") <STRING>
 * 1: Code, called with the arguments <CODE>
 * 2: Arguments for it <ANY> (default: [])
 * 3: The least time between two runs, or the time to wait after the last request for a debounce, in seconds <NUMBER> (default: COALESCE_GAP)
 * 4: Debounce instead of throttle <BOOL> (default: false)
 *
 * Return Value:
 * It ran now <BOOL>
 *
 * Example:
 * ["filter", {[true] call aio_gui_fnc_applyFilter}, [], COALESCE_TYPING, true] call aio_gui_fnc_coalesce;
 *
 * Public: No
 */

params [["_key", "", [""]], ["_code", {}, [{}]], ["_args", []], ["_gap", COALESCE_GAP, [0]], ["_debounce", false, [false]]];

if (_key isEqualTo "") exitWith {false};

private _now = diag_tickTime;

// [code, arguments, due (-1: nothing waits), rests until, gap]. Arrays are references: the one the table holds is the one changed.
private _state = GVAR(coalesced) getOrDefault [_key, [{}, [], -1, 0, _gap]];

_state set [0, _code];
_state set [1, _args];
_state set [4, _gap];
GVAR(coalesced) set [_key, _state];

if (_debounce) exitWith {
    _state set [2, _now + _gap];

    false
};

// Something waits already: it runs with these arguments when its time comes.
if ((_state select 2) >= 0) exitWith {false};

_state set [2, _now max (_state select 3)];

if ((_state select 2) > _now) exitWith {false};

[_key] call FUNC(coalesceRun);

true
