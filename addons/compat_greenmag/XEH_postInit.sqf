#include "script_component.hpp"

if (!hasInterface || {isNil "gmr_handling_fnc_unpack"}) exitWith {};

// A box of rounds opens where it lies, and a double click opens it (fnc_unpackHere): in the place of GreenMag's own "Unpack",
// which the menu leaves out (fnc_hideCbaOption) - that one gives the rounds to the player wherever there is room.
[
    "greenmag_unpack", ["gmr_pack_base"], [localize "STR_gmr_handling_Unpack", ""],
    {
        params ["_unit", "_container", "_item"];

        [_unit, _container, _item] call FUNC(unpackHere);
        false
    },
    {missionNamespace getVariable ["gmr_main_enabled", false]},
    {true}, false, "ALL", true, "\z\gmr\addons\handling\data\action_unpack.paa"
] call EFUNC(gui,addMenuEntry);

// A stripper clip (GreenMag 1.1) is stripped the same way: its rounds lie where it lay, and a double click strips it. In the place
// of GreenMag's own "Strip rounds off the clip", which gives the rounds wherever there is room.
[
    "greenmag_strip", ["gmr_clip_base"], [localize "STR_gmr_handling_StripClip", ""],
    {
        params ["_unit", "_container", "_item"];

        [_unit, _container, _item] call FUNC(unpackHere);
        false
    },
    {missionNamespace getVariable ["gmr_main_enabled", false]},
    {true}, false, "ALL", true, "\z\gmr\addons\handling\data\action_unpack.paa"
] call EFUNC(gui,addMenuEntry);
