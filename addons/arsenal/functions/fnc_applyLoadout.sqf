#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Puts a verified loadout on the soldier: the loadout is set with CBA (full magazines, or as they are),
 * what does not fit goes back, face, voice and insignia follow as ACE's loads do. Says what went back.
 *
 * The places of everything travel in the extended info (einv_layout, written and read by einv_storage when
 * CBA gets and sets a loadout), so what was saved on a cell lies on it again; what has no cell in the
 * container it comes to goes back to the arsenal (fnc_trimToFit), the unique things excepted. A loadout of
 * an older profile, with no places, lies out first-fit.
 *
 * Arguments:
 * 0: The loadout with its extended info, verified by ACE <ARRAY>
 * 1: Its name, "" for none <STRING>
 * 2: Say what was loaded and what went back <BOOL> (default: true)
 * 3: Fill the magazines - a loadout from the clipboard keeps them as they are <BOOL> (default: true)
 *
 * Return Value:
 * What went back, [[class, how many], ...] <ARRAY>
 *
 * Example:
 * [_loadout, "Rifleman"] call einv_arsenal_fnc_applyLoadout;
 *
 * Public: No
 */

params [
    ["_extended", [], [[]]], ["_name", "", [""]], ["_say", true, [true]], ["_fullMagazines", true, [true]]
];

private _unit = GVAR(center);

if (isNull _unit || {count _extended != 2}) exitWith {[]};

_extended params ["_loadout", "_info"];

// CBA sets the loadout and raises its events; ACE's own handler of those puts the face, the voice and the
// insignia of the extended info on the unit, and the places are written by einv_storage's.
[_unit, _extended, _fullMagazines] call CBA_fnc_setLoadout;

if (_info isEqualType []) then {
    _info = createHashMapFromArray _info;
};

// What ACE's session keeps as the soldier's face, voice and insignia, as its loads set it.
if (QACEGVAR(arsenal,insignia) in _info) then {
    missionNamespace setVariable [QACEGVAR(arsenal,currentInsignia), _info getOrDefault [QACEGVAR(arsenal,insignia), ""]];
} else {
    [_unit, ""] call BIS_fnc_setUnitInsignia;
    [_unit, missionNamespace getVariable [QACEGVAR(arsenal,currentInsignia), ""]] call BIS_fnc_setUnitInsignia;
};

if (QACEGVAR(arsenal,face) in _info) then {
    missionNamespace setVariable [QACEGVAR(arsenal,currentFace), _info getOrDefault [QACEGVAR(arsenal,face), face _unit]];
};

if (QACEGVAR(arsenal,voice) in _info) then {
    missionNamespace setVariable [QACEGVAR(arsenal,currentVoice), _info getOrDefault [QACEGVAR(arsenal,voice), ""]];
};

// What he carries now, and what of it the arsenal does not offer.
call ACEFUNC(arsenal,updateCurrentItemsList);
call ACEFUNC(arsenal,updateUniqueItemsList);
GVAR(uniqueCache) = createHashMap;

// ACE raises nothing for the parts of weapons that changed with a whole loadout: the baseline is now.
[true] call FUNC(weaponEvents);

private _went = [_unit] call FUNC(trimToFit);

if (_say) then {
    ["put"] call EFUNC(gui,playSound);

    private _text = format [LLSTRING(Loadouts_Loaded), _name];

    if (_went isNotEqualTo []) then {
        private _names = (_went select [0, 4]) apply {format ["%1× %2", _x select 1, [_x select 0] call EFUNC(gui,itemName)]};

        _text = format ["%1. %2", _text, format [LLSTRING(Hint_WentBack), (_names joinString ", ") + (["", ", ..."] select (count _went > 4))]];
    };

    [_text, ["text2", "loss"] select (_went isNotEqualTo [])] call FUNC(message);
};

// The whole soldier is new: the window looks at once.
call EFUNC(gui,requestRebuild);

_went
