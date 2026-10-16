#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Puts the scroll positions of a step back after it was drawn again (fnc_showStep), so a click on a button, a switch or a
 * stepper does not throw a long page back to its top. A group that was only just made does not know its height yet, and
 * the engine holds a scroll value it cannot reach at the top - so the value is set, read back a moment later, and set
 * again until it holds (at most RESTORE_TRIES times, a few hundredths of a second apart), with at least one check after
 * the last change. Stops as soon as another step is drawn.
 *
 * A group's place is kept as a share of how far it can scroll. A page that came out longer or shorter than it was (a
 * line of warnings that appeared) is put back to the same distance from its top, not the same share: the group says how
 * long its content is (QGVAR(contentH)), the old one's is in the saved entry.
 *
 * Arguments:
 * 0: What was saved, scroll id -> [share, content height, group height] <HASHMAP>
 * 1: The draw they belong to (GVAR(drawn)) <NUMBER>
 * 2: How many times this has run already <NUMBER> (default: 0)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_saved, GVAR(drawn)] call einv_setup_fnc_restoreScroll;
 *
 * Public: No
 */

disableSerialization;

params [["_saved", createHashMap, [createHashMap]], ["_drawn", 0, [0]], ["_tries", 0, [0]]];

private _display = uiNamespace getVariable [QGVAR(display), displayNull];

if (isNull _display || {_drawn != GVAR(drawn)}) exitWith {};

private _holds = true;

{
    private _entry = _saved getOrDefault [_x getVariable [QGVAR(scrollId), ""], []];

    if (_entry isNotEqualTo []) then {
        _entry params ["_share", "_oldContentH", "_oldGroupH"];

        (ctrlPosition _x) params ["", "", "", "_groupH"];

        private _contentH = _x getVariable [QGVAR(contentH), -1];
        private _want = _share;

        if (_oldContentH > 0 && {_contentH > 0}) then {
            private _range = (_contentH - _groupH) max 0;

            _want = [0, (((_share * ((_oldContentH - _oldGroupH) max 0)) / _range) min 1) max 0] select (_range > 0);
        };

        if (_want > 0 && {abs (((ctrlScrollValues _x) select 0) - _want) > 0.005}) then {
            _x ctrlSetScrollValues [_want, -1];

            _holds = false;
        };
    };
} forEach ((allControls _display) select {ctrlType _x == CTRL_TYPE_GROUP});

if (_tries < RESTORE_TRIES && {!_holds || {_tries < 1}}) then {
    [FUNC(restoreScroll), [_saved, _drawn, _tries + 1], 0.04] call FUNC(defer);
};
