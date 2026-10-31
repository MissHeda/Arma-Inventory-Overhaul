#include "script_component.hpp"

// The player's own unit carries what the weight overrides add (fnc_updateVirtualLoad). Everything
// below only says when to work it out again; each of them queues one update for the next frame, so a
// burst - a respawn raises both the unit and the loadout event - costs a single broadcast.
//
// Postinit does not run in Eden, so nothing here does either - there is no player to weigh there.

if (!hasInterface) exitWith {};

// Respawn, team switch and Zeus remote control hand the player a different unit. What was applied to
// each unit is remembered on it, so a unit taken over again is only given the difference. Runs once
// right away too, for the unit the player starts in.
//
// The unit left behind loses what the tiers did to it: its status effects, its duty factor and the marks
// that say what was applied - an AI the player let go of must not stay unable to sprint. The new unit
// is looked at afresh (the same queue), without the message a change of tier would bring.
["unit", {
    params ["_new", "_old"];

    if (!isNull _old && {local _old}) then {
        [_old, TIER_LIGHT] call FUNC(applyEffects);

        _old setVariable [QGVAR(tier), nil];
        _old setVariable [QGVAR(duty), nil];
        _old setVariable [QGVAR(effectsOn), nil];
    };

    GVAR(lastState) = [];
    call FUNC(queueVirtualLoad);
}, true] call CBA_fnc_addPlayerEventHandler;

// Anything put on, taken off, picked up, dropped or moved between the player's uniform, vest and
// backpack. CBA leaves the rounds in the weapons out of it, so firing does not count as a change.
["loadout", {
    call FUNC(queueVirtualLoad);
}] call CBA_fnc_addPlayerEventHandler;

// Another setup - saved in the CBA settings or the setup wizard, or a mission's - may weigh the same
// items differently. Raised on every machine once it has the new rules.
[QEGVAR(items,rulesChanged), {
    call FUNC(queueVirtualLoad);
}] call CBA_fnc_addEventHandler;

// A uniform, vest or backpack lying inside the player's own storage is only a class name in the
// loadout - what is packed into it never raises the loadout event. Looked at again every few seconds,
// and only while the player carries one; the update itself sends nothing when the weight stayed the
// same.
[{
    private _unit = ACE_player;

    if (isNull _unit) exitWith {};

    private _nested = [uniformContainer _unit, vestContainer _unit, backpackContainer _unit] findIf {
        !isNull _x && {(everyContainer _x) isNotEqualTo []}
    };

    if (_nested >= 0) then {
        call FUNC(queueVirtualLoad);
    };
}, NESTED_CHECK_INTERVAL] call CBA_fnc_addPerFrameHandler;

// ACE's fatigue multiplies the cost of every movement by its duty factors, asked of the player every second:
// ours climbs from 1 at the Overloaded mark to OVERLOAD_DUTY_MAX at Critical (fnc_updateTier). Without
// ACE's fatigue there is nothing to register with; the status effects still work. With the tiers switched
// off (aio_weight_enabled) it is 1 at once, not only after the next tier check: ACE's own fatigue alone.
if (!isNil QACEFUNC(advanced_fatigue,addDutyFactor)) then {
    [QUOTE(ADDON), {
        [1, _this getVariable [QGVAR(duty), 1]] select (missionNamespace getVariable [QGVAR(enabled), true])
    }] call ACEFUNC(advanced_fatigue,addDutyFactor);
};

// What no event tells about - a kit's load, another mod's virtual load, a changed setting, ACE's own
// settings or a mission's performance factor for the unit, a looter filling a searched person's backpack -
// is found by looking once a second: the tier is worked out again when the load, the limits or the effects
// switch differ from the last look. The cached limits make that cheap.
[{
    private _unit = ACE_player;

    if (isNull _unit) exitWith {};

    // Strict mode's hidden holder changed (aio_storage_hidden): a tile moved out of a crate into the backpack
    // lands in the holder and raises no loadout event, yet it weighs (fnc_getExtraLoad).
    private _hidden = _unit getVariable [QEGVAR(storage,hidden), []];

    if (_hidden isNotEqualTo GVAR(lastHidden)) then {
        GVAR(lastHidden) = +_hidden;
        call FUNC(queueVirtualLoad);
    };

    private _state = [[_unit] call FUNC(getLoad), ([_unit] call FUNC(getLimits)) get "key", missionNamespace getVariable [QGVAR(effects), true]];

    if (_state isEqualTo GVAR(lastState)) exitWith {};

    GVAR(lastState) = _state;
    [_unit] call FUNC(updateTier);
}, TIER_CHECK_INTERVAL] call CBA_fnc_addPerFrameHandler;
