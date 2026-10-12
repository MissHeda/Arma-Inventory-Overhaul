#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Applies a face, a voice or an insignia to the soldier and remembers it in ACE's session, as ACE's own
 * tabs do. The insignia is applied again after every uniform swap. A new voice says a line, as ACE's voice
 * tab does, and a new insignia is saluted (fnc_showItem).
 *
 * Arguments:
 * 0: "face", "voice" or "insignia" <STRING>
 * 1: Class <STRING>
 * 2: Show it - the voice speaks, the insignia is saluted; false for putting it back after a uniform
 *    swap <BOOL> (default: true)
 *
 * Return Value:
 * None
 *
 * Example:
 * ["face", "WhiteHead_01"] call einv_arsenal_fnc_applyIdentity;
 *
 * Public: No
 */

params [["_kind", "", [""]], ["_class", "", [""]], ["_show", true, [true]]];

private _unit = GVAR(center);

if (isNull _unit) exitWith {};

switch (_kind) do {
    case "face": {
        private _face = [_class, "Default"] select (_class isEqualTo "");

        _unit setFace _face;
        missionNamespace setVariable [QACEGVAR(arsenal,currentFace), _face];
    };
    case "voice": {
        _unit setSpeaker _class;
        missionNamespace setVariable [QACEGVAR(arsenal,currentVoice), _class];

        if (_show) then {
            ["voice"] call FUNC(showItem);
        };
    };
    case "insignia": {
        // The old one off first, as ACE does: a new one on top of it would not show.
        [_unit, ""] call BIS_fnc_setUnitInsignia;
        [_unit, _class] call BIS_fnc_setUnitInsignia;
        missionNamespace setVariable [QACEGVAR(arsenal,currentInsignia), _class];

        if (_show) then {
            ["insignia"] call FUNC(showItem);
        };
    };
    default {};
};
