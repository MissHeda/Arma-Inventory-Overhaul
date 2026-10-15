#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The words for a tier: its name, and what it does to the soldier - "jogging tires you", "no sprinting,
 * tiring faster", "walking only". The effect is "" where it does not apply: Heavy does nothing of its own
 * unless it follows ACE's fatigue (the yellow mark is then where ACE's jog starts to tire), and Overloaded
 * and Critical do nothing while einv_weight_effects is off - the bar still shows them.
 *
 * With the tiers switched off (einv_weight_enabled, read from the limits) there are no words at all: every
 * load is Light then (fnc_getTier), and a "Light" beside the kilograms would suggest a scale that is not
 * there.
 *
 * Arguments:
 * 0: Tier, TIER_* <NUMBER>
 * 1: The unit's limits (fnc_getLimits) <HASHMAP>
 *
 * Return Value:
 * [name, effect] <ARRAY>
 *
 * Example:
 * [TIER_HEAVY, _limits] call einv_weight_fnc_tierText;
 *
 * Public: Yes
 */

params [["_tier", TIER_LIGHT, [0]], ["_limits", createHashMap, [createHashMap]]];

if !(_limits getOrDefault ["enabled", missionNamespace getVariable [QGVAR(enabled), true]]) exitWith {["", ""]};

private _effects = missionNamespace getVariable [QGVAR(effects), true];

switch (_tier) do {
    case TIER_HEAVY: {
        [LLSTRING(Tier_Heavy), [LLSTRING(Effect_Heavy), ""] select !(_limits getOrDefault ["fromAce", false])]
    };
    case TIER_OVERLOADED: {
        [LLSTRING(Tier_Overloaded), [LLSTRING(Effect_Overloaded), ""] select !_effects]
    };
    case TIER_CRITICAL: {
        [LLSTRING(Tier_Critical), [LLSTRING(Effect_Critical), ""] select !_effects]
    };
    default {
        [LLSTRING(Tier_Light), ""]
    };
}
