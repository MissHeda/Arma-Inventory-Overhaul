#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A grenade, smoke shell or chemlight on a key.
 *
 * With ACE's advanced throwing: the key takes that throwable into the hand and the left mouse button
 * throws it, as ACE's own throw key does - ACE's throw mode, its arc and its model, nothing rebuilt. A
 * key of another throwable while one is in the hand (not yet primed) swaps it. The two seconds ACE
 * keeps between throws are respected, and a primed one has to be thrown first.
 *
 * Without it: the first press selects the throwable, a second press within a moment throws it
 * (forceWeaponFire); the game's own throw key throws it as well.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Class <STRING>
 * 2: Slot index <NUMBER>
 *
 * Return Value:
 * [done, text] - what to say: for done what happened ("" for nothing), else why not <ARRAY>
 *
 * Example:
 * [player, "HandGrenade", 2] call einv_hotbar_fnc_useThrowable;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_class", "", [""]], ["_index", 0, [0]]];

if (missionNamespace getVariable ["ace_common_isReloading", false]) exitWith {[false, LLSTRING(Reason_Busy)]};

private _name = [_class] call EFUNC(gui,itemName);
private _advanced = !isNil "ace_advanced_throwing_fnc_prepare" && {missionNamespace getVariable ["ace_advanced_throwing_enabled", false]};

if (_advanced) exitWith {
    private _inHand = _unit getVariable ["ace_advanced_throwing_inHand", false];

    // One that is lit already has to go first.
    if (_inHand && {_unit getVariable ["ace_advanced_throwing_primed", false]}) exitWith {[false, LLSTRING(Reason_Primed)]};

    // The one wanted is in the hand.
    if (_inHand && {((currentThrowable _unit) param [0, ""]) == _class}) exitWith {[true, ""]};

    // Another one is: swap. ACE's drawing sees the other type next frame and changes the model.
    if (_inHand) exitWith {
        _unit setAmmo (_unit getVariable ["ace_advanced_throwing_activeMuzzle", ["", -1]]);
        _unit selectThrowable _class;

        [true, format [LLSTRING(Message_InHand), _name]]
    };

    if (!([_unit] call ace_advanced_throwing_fnc_canPrepare)) exitWith {
        // ACE keeps two seconds between throws; anything else is the place or the pose.
        private _since = CBA_missionTime - (_unit getVariable ["ace_advanced_throwing_lastThrownTime", -10]);

        [false, [LLSTRING(Reason_NotHere), LLSTRING(Reason_ThrowWait)] select (_since < THROW_COOLDOWN)]
    };

    _unit selectThrowable _class;
    [_unit] call ace_advanced_throwing_fnc_prepare;

    [true, format [LLSTRING(Message_InHand), _name]]
};

// Without advanced throwing: the engine's own throw.
if (!isNull objectParent _unit && {!(_unit call CBA_fnc_canUseWeapon)}) exitWith {[false, LLSTRING(Reason_NotHere)]};

private _selected = (currentThrowable _unit) param [0, ""];
private _again = (GVAR(lastPress) param [0, -1]) == _index && {(diag_tickTime - (GVAR(lastPress) param [1, -10])) < THROW_AGAIN};

if (_selected == _class && {_again}) exitWith {
    private _muzzle = (currentThrowable _unit) select 1;

    GVAR(lastPress) = [];
    _unit forceWeaponFire [_muzzle, _muzzle];

    [true, ""]
};

_unit selectThrowable _class;
GVAR(lastPress) = [_index, diag_tickTime];

// The slot's key and the game's throw key, as the player has them set (the game quotes the key's name).
private _key = [_index] call FUNC(keyName);

if (_key isEqualTo "") then {
    _key = str (_index + 1);
};

[true, format [LLSTRING(Message_Ready), _name, _key, (actionKeysNames "Throw") regexReplace ["""", ""]]]
