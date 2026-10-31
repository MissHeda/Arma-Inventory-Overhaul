#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * How heavy a unit may be before ACE's jog tires it, in kilograms: the load at which ACE Advanced
 * Fatigue's running cost at its own jog speed (12 km/h, weapon lowered) is more than the body keeps up
 * aerobically. Below it a soldier can jog all day; above it ACE's anaerobic reserve drains while jogging,
 * and ACE blocks the sprint, then forces walking, once it runs low. ACE's formulas, copied: they are not
 * public, and the answer has to be steady - the live loop's breathing and wounds would make the yellow
 * mark wander.
 *
 * What ACE computes, in short: the body's aerobic power follows from its performance factor (VO2 max
 * 35 + 20 x performance, in the units ACE uses); the cost of running is (2.1 m + 4 (m + g) (g / m)^2 +
 * (m + g) 0.9 v^2) x efficiency, with m the body mass, g the gear mass and v the speed. The gear mass
 * where the two meet is found by halving, and turned back into a total load with ACE's own conversion,
 * gear = (total - underwear) x load factor.
 *
 * Arguments:
 * 0: ACE performance factor <NUMBER>
 * 1: ACE load factor <NUMBER>
 *
 * Return Value:
 * Total load in kg where Heavy starts - 0 when even an unloaded jog tires, -1 when the load never
 * matters (load factor 0, or not even HEAVY_GEAR_MAX kg of gear tires a jog) <NUMBER>
 *
 * Example:
 * [1, 1] call aio_weight_fnc_heavyFromAce; // 26.7
 *
 * Public: No
 */

params [["_performance", 1, [0]], ["_loadFactor", 1, [0]]];

// The gear does not matter to ACE's fatigue at all: it never gets heavy.
if (_loadFactor <= 0) exitWith {-1};

// ACE's power, from its performance factor (fnc_handlePlayerChanged): VO2 max, the power it gives, the peak
// and the aerobic pathways' share of it (13.3 + 16.7 per cent of the peak power, 0.8 of the pathways'
// oxygen, 1.362 as ACE scales it).
private _vo2Max = 35 + 20 * _performance;
private _vo2MaxPower = _vo2Max * ACE_BODY_MASS * ACE_EFFICIENCY * 20.9 / 60;
private _peakPower = 4.1 * _vo2MaxPower;
private _aerobic = _peakPower / 143.3 * (13.3 + 16.7) * (0.8 ^ 1.28) * 1.362;
private _target = _aerobic * AEROBIC_SHARE;

// The cost of jogging with a gear mass, in watts (fnc_getMetabolicCosts, running, level ground, duty 1).
private _fnc_cost = {
    params ["_gear"];

    (
        2.1 * ACE_BODY_MASS
        + 4 * (ACE_BODY_MASS + _gear) * ((_gear / ACE_BODY_MASS) ^ 2)
        + (ACE_BODY_MASS + _gear) * 0.9 * (JOG_SPEED ^ 2)
    ) * ACE_EFFICIENCY
};

// Tired even without gear: yellow from the first kilogram, as ACE would have it.
if (([0] call _fnc_cost) >= _target) exitWith {0};

// Not within reach however much is carried.
if (([HEAVY_GEAR_MAX] call _fnc_cost) < _target) exitWith {-1};

private _low = 0;
private _high = HEAVY_GEAR_MAX;

for "_i" from 1 to HEAVY_STEPS do {
    private _middle = (_low + _high) / 2;

    if (([_middle] call _fnc_cost) < _target) then {
        _low = _middle;
    } else {
        _high = _middle;
    };
};

(_low + _high) / 2 / _loadFactor + ACE_UNDERWEAR_KG
