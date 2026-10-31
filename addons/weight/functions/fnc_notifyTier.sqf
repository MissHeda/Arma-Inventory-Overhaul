#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Tells the player in one line that the load changed tier - while the inventory is closed. Things are
 * picked up outside the window too (other mods, scripts, a looter filling a searched person's backpack), and
 * the player would otherwise only find out by not being able to sprint. With the window open its weight bar
 * shows it, so nothing is said then. Nor with the tiers switched off (aio_weight_enabled): there is no
 * tier to tell about.
 *
 * ACE's own message, with the weight icon in the tier's colour: white, yellow or red.
 *
 * Arguments:
 * 0: The new tier, TIER_* <NUMBER>
 * 1: The tier it was, TIER_* <NUMBER>
 * 2: The limits (fnc_getLimits) <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [TIER_HEAVY, TIER_LIGHT, _limits] call aio_weight_fnc_notifyTier;
 *
 * Public: No
 */

params [["_tier", TIER_LIGHT, [0]], ["_old", TIER_LIGHT, [0]], ["_limits", createHashMap, [createHashMap]]];

if (
    !hasInterface || {_tier == _old} || {!(missionNamespace getVariable [QGVAR(notify), true])}
    || {!(_limits getOrDefault ["enabled", missionNamespace getVariable [QGVAR(enabled), true]])}
    || {!isNull (uiNamespace getVariable [QEGVAR(gui,display), displayNull])}
    || {isNil QACEFUNC(common,displayTextPicture)}
) exitWith {};

([_tier, _limits] call FUNC(tierText)) params ["_word", "_effect"];

private _text = [format [LLSTRING(Notify_Format), _word, _effect], _word] select (_effect isEqualTo "");

// The colours of the window's bar (the gui theme's warn and loss) - white for Light.
private _color = switch (_tier) do {
    case TIER_HEAVY: {[0.98, 0.8, 0.24]};
    case TIER_OVERLOADED;
    case TIER_CRITICAL: {[0.941, 0.333, 0.353]};
    default {[1, 1, 1]};
};

[_text, QPATHTOEF(gui,ui\icon_weight_ca.paa), _color, ACE_player, 2] call ACEFUNC(common,displayTextPicture);
