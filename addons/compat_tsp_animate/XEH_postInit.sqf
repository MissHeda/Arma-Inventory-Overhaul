#include "script_component.hpp"

if (!hasInterface) exitWith {};

// TSP Animate plays its attachment gestures from the engine's "Take" and "Put" events while the vanilla
// inventory (display 602) is open - neither of which this window has: it changes attachments by script. So the
// current weapon's attachments are compared while the window is open, and a change plays TSP's own gesture.
[{call FUNC(tick)}, TSP_TICK] call CBA_fnc_addPerFrameHandler;
