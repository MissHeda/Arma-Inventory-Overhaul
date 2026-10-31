#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Where the tiers start for a unit: Heavy, Overloaded and Critical, in config mass and in kilograms.
 *
 * Overloaded and Critical are the settings (aio_weight_overloadedAt, aio_weight_criticalAt, the latter at
 * least 1 kg above the first). Heavy is the setting too (aio_weight_heavyAt), or - at 0, the default -
 * follows ACE Advanced Fatigue: the load at which ACE's jog tires the unit (fnc_heavyFromAce), by ACE's load
 * factor and the unit's performance factor. With ACE's fatigue off, Heavy is a share of Overloaded
 * (NO_ACE_HEAVY_SHARE). It is never later than Overloaded, so the bar always has its order.
 *
 * With the tiers switched off (aio_weight_enabled) the marks are still worked out - the bar still needs
 * an end - but "enabled" says so, and fnc_getTier, fnc_tierText and fnc_updateTier answer by it, so they
 * agree with the limits they were handed. It is part of the key too: the window's signature redraws the
 * weight card when the switch flips, and the tier check (XEH_postInit) looks again.
 *
 * Every input is read on every call and the answer kept under a key made of them all, so a changed
 * setting, ACE setting or performance factor simply makes a new entry - nothing has to be told. The settings
 * are read with their defaults: in the Eden editor, where the Arsenal draws the weight card too, no
 * setting script runs.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * The limits <HASHMAP>
 *   "heavy", "overloaded", "critical"         - config mass <NUMBER>
 *   "heavyKg", "overloadedKg", "criticalKg"   - the same in kilograms <NUMBER>
 *   "fromAce"     - Heavy comes from ACE's fatigue model <BOOL>
 *   "aceFatigue"  - ACE Advanced Fatigue is on <BOOL>
 *   "enabled"     - the tiers count at all (aio_weight_enabled) <BOOL>
 *   "key"         - changes whenever any limit does <STRING>
 *
 * Example:
 * [player] call aio_weight_fnc_getLimits;
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]]];

private _aceOn = (missionNamespace getVariable [QACEGVAR(advanced_fatigue,enabled), false]) && {!isNil QACEFUNC(advanced_fatigue,addDutyFactor)};

private _performance = 1;
private _loadFactor = 1;

if (_aceOn) then {
    _performance = missionNamespace getVariable [QACEGVAR(advanced_fatigue,performanceFactor), 1];
    _loadFactor = missionNamespace getVariable [QACEGVAR(advanced_fatigue,loadFactor), 1];

    // A mission may give one unit its own performance factor.
    if (!isNull _unit) then {
        _performance = _unit getVariable [QACEGVAR(advanced_fatigue,performanceFactor), _performance];
    };
};

private _heavyAt = missionNamespace getVariable [QGVAR(heavyAt), 0];
private _overloadedAt = missionNamespace getVariable [QGVAR(overloadedAt), 45];
private _criticalAt = (missionNamespace getVariable [QGVAR(criticalAt), 60]) max (_overloadedAt + 1);

private _enabled = missionNamespace getVariable [QGVAR(enabled), true];

private _key = str [_aceOn, _performance, _loadFactor, _heavyAt, _overloadedAt, _criticalAt, _enabled];
private _known = GVAR(limitsCache) get _key;

if (!isNil "_known") exitWith {_known};

private _heavyKg = -1;
private _fromAce = false;

if (_heavyAt > 0) then {
    _heavyKg = _heavyAt;
} else {
    if (_aceOn) then {
        _heavyKg = [_performance, _loadFactor] call FUNC(heavyFromAce);
        _fromAce = _heavyKg >= 0;
    } else {
        _heavyKg = _overloadedAt * NO_ACE_HEAVY_SHARE;
    };
};

// Never getting heavy by ACE's numbers: the first mark is the red one.
if (_heavyKg < 0) then {
    _heavyKg = _overloadedAt;
};

_heavyKg = (_heavyKg min _overloadedAt) max 0;

private _limits = createHashMapFromArray [
    ["heavy", _heavyKg * KG_TO_MASS], ["overloaded", _overloadedAt * KG_TO_MASS], ["critical", _criticalAt * KG_TO_MASS],
    ["heavyKg", _heavyKg], ["overloadedKg", _overloadedAt], ["criticalKg", _criticalAt],
    ["fromAce", _fromAce], ["aceFatigue", _aceOn], ["enabled", _enabled], ["key", _key]
];

GVAR(limitsCache) set [_key, _limits];

_limits
