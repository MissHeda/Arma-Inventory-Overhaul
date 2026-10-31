#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Keeps the player's throwing inside the "Use items from ..." settings, a few times a second (THROW_TICK,
 * XEH_postInit):
 *
 *   - the unit carries throwables that lie only where they are closed: ACE's "blockThrow" status effect is set
 *     for the unit (reason "aio_storage"), which ACE's advanced throwing asks before it prepares a throw, and
 *     a throwable in the hands is put away for the weapon
 *   - some may be thrown but the selected one may not: the selection moves to one that may (fnc_throwSelect)
 *   - nothing is carried that lies where it is closed, or nothing is limited: the status effect is taken away
 *
 * The effect is only ever set by this and taken away by this - it follows the unit it was set on. Without
 * ACE it is not set, and only the throw key is held back (fnc_throwGuard).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call aio_storage_fnc_throwTick;
 *
 * Public: No
 */

private _unit = missionNamespace getVariable ["ACE_player", player];
private _wanted = false;
private _state = [[], []];

if (GVAR(useActive) && {!isNull _unit} && {alive _unit} && {isNull objectParent _unit}) then {
    _state = [_unit] call FUNC(throwState);
};

_state params ["_usable", "_blocked"];

if (_blocked isNotEqualTo []) then {
    if (_usable isEqualTo []) then {
        _wanted = true;

        // Throwing mode with a throwable that may not be thrown: back to the weapon.
        if ((currentWeapon _unit) isEqualTo "Throw") then {
            private _back = [primaryWeapon _unit, handgunWeapon _unit] select {_x isNotEqualTo ""};

            if (_back isNotEqualTo []) then {
                _unit selectWeapon (_back select 0);
            };
        };
    } else {
        [_unit, _usable, _blocked] call FUNC(throwSelect);
    };
};

// The effect follows the unit: taken off the one it was set on when that is not the one wanted.
if (GVAR(throwBlocked) && {!_wanted || {_unit isNotEqualTo GVAR(throwUnit)}}) then {
    if (!isNull GVAR(throwUnit) && {!isNil QACEFUNC(common,statusEffect_set)}) then {
        [GVAR(throwUnit), "blockThrow", QUOTE(ADDON), false] call ACEFUNC(common,statusEffect_set);
    };

    GVAR(throwBlocked) = false;
};

if (_wanted && {!GVAR(throwBlocked)}) then {
    if (!isNil QACEFUNC(common,statusEffect_set)) then {
        [_unit, "blockThrow", QUOTE(ADDON), true] call ACEFUNC(common,statusEffect_set);
    };

    GVAR(throwBlocked) = true;
    GVAR(throwUnit) = _unit;
};
