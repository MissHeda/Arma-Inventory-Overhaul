#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Changes the view the soldier is seen through, as ACE's night vision key does in its window: normal, night
 * vision, thermal imaging, and round again. The camera is the Arsenal's own (camUseNVG, setCamUseTI), so
 * the world is lit for looking at the gear. The header's button and the key of the game's night vision
 * action both come here; a close puts the view back to normal (fnc_cameraStop).
 *
 * Arguments:
 * 0: The view to go to, -1 for the next one - 0 normal, 1 night vision, 2 thermal <NUMBER> (default: -1)
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call einv_arsenal_fnc_cycleVision;
 *
 * Public: No
 */

params [["_view", -1, [0]]];

private _next = [_view, (GVAR(visionMode) + 1) mod VISION_MODES] select (_view < 0);

GVAR(visionMode) = _next;

switch (_next) do {
    case 0: {
        camUseNVG false;
        false setCamUseTI 0;
    };
    case 1: {
        camUseNVG true;
        false setCamUseTI 0;
    };
    default {
        camUseNVG false;
        true setCamUseTI 0;
    };
};

// Only a change the player asked for is announced.
if (_view >= 0) exitWith {};

playSound ["RscDisplayCurator_visionMode", true];

[[LLSTRING(Vision_Normal), LLSTRING(Vision_Night), LLSTRING(Vision_Thermal)] select _next] call FUNC(message);
