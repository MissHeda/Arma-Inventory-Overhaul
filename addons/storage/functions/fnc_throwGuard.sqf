#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The throw key honours the "Use items from ..." settings as far as a mod can make it. The game throws the
 * selected throwable from whichever container holds one, and nothing a mod runs before the throw can say
 * from which - so the key is held back where it would throw from a closed container only:
 *
 *   - the unit carries throwables, but all of them lie in containers that are closed to them: the game's
 *     "Throw" key does nothing, and a line says from where to take one out
 *   - some may be thrown, but the selected one may not: the selection moves on to the next one that may
 *     be thrown (the same as fnc_throwTick does a quarter of a second after the selection), and the key
 *     is left to the game
 *   - everything that is carried may be thrown, or nothing is limited: the key is the game's
 *
 * ACE's advanced throwing is a CBA key ("Prepare grenade", ACE3 Weapons) that runs beside this handler and
 * cannot be swallowed from here: with nothing to throw, fnc_throwTick has it blocked through ACE's own
 * "blockThrow" status effect, and this handler only says why when that key is pressed.
 *
 * On foot only. A handler of the main display's KeyDown event (XEH_postInit); its return value true
 * swallows the key.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Key code <NUMBER>
 * 2: Shift <BOOL>
 * 3: Ctrl <BOOL>
 * 4: Alt <BOOL>
 *
 * Return Value:
 * Whether the key is swallowed <BOOL>
 *
 * Example:
 * [_display, 34, false, false, false] call aio_storage_fnc_throwGuard;
 *
 * Public: No
 */

params ["", ["_key", 0, [0]], ["_shift", false, [false]], ["_ctrl", false, [false]], ["_alt", false, [false]]];

if !(missionNamespace getVariable [QGVAR(useActive), false]) exitWith {false};

// The game's own key: plain keys only, as the reload key (a code with modifiers built in is a combination
// the event reports separately).
private _vanilla = !_shift && {!_ctrl} && {!_alt} && {_key in ((actionKeys "Throw") + (actionKeys "ThrowGrenade"))};

// ACE's advanced throwing: its key as the player has set it (CBA keybind "Prepare grenade").
private _ace = false;

if (!_vanilla && {!isNil "CBA_fnc_getKeybind"} && {!isNil "ace_advanced_throwing_fnc_prepare"}) then {
    private _entry = ["ACE3 Weapons", "ace_advanced_throwing_prepare"] call CBA_fnc_getKeybind;

    if (!isNil "_entry") then {
        {
            if (_x isEqualType [] && {(_x param [0, -1]) == _key} && {(_x param [1, []]) isEqualTo [_shift, _ctrl, _alt]}) exitWith {
                _ace = true;
            };
        } forEach (_entry param [8, []]);
    };
};

if (!_vanilla && {!_ace}) exitWith {false};

private _unit = missionNamespace getVariable ["ACE_player", player];

if (isNull _unit || {!alive _unit} || {!isNull objectParent _unit}) exitWith {false};

([_unit] call FUNC(throwState)) params ["_usable", "_blocked"];

// Nothing is held back: no throwable lies where it is closed.
if (_blocked isEqualTo []) exitWith {false};

// Some may be thrown: the selection moves to one of them, the key stays the game's.
if (_usable isNotEqualTo []) exitWith {
    [_unit, _usable, _blocked] call FUNC(throwSelect);

    false
};

// Only closed ones. A key held down repeats; answered once.
if (diag_tickTime < (missionNamespace getVariable [QGVAR(throwAt), 0])) exitWith {_vanilla};

GVAR(throwAt) = diag_tickTime + RELOAD_GUARD_GAP;

private _where = [];

{
    private _class = _x;

    {
        _where pushBackUnique _x;
    } forEach ([_unit, _class] call FUNC(useBlockedIn));
} forEach _blocked;

// Not found where they lie: every container a setting limits.
if (_where isEqualTo []) then {
    _where = USE_KINDS select {([_x] call FUNC(useMode)) isNotEqualTo USE_ALL};
};

[format [localize "STR_aio_storage_Hint_NoThrow", [USE_KINDS select {_x in _where}] call FUNC(useKindName)]] call FUNC(useHint);

// ACE's key is not held back here; the status effect does it.
_vanilla
