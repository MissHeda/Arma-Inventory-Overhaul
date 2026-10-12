#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The categories of the catalog: id, group, label, where ACE keeps their items and where a slot of the
 * soldier leads to them. Those with nothing offered are left out; a custom button of ACE's right panel is a
 * category of the Items group.
 *
 * Each is [id, group, label, picture, classes]: the ids are rifle, handgun, launcher, binocular (group
 * "weapons"); optic, rail, muzzle, bipod ("parts"); magazine, grenade, explosive ("ammo"); headgear, uniform,
 * vest, backpack, goggles, nvg ("gear"); map, compass, watch, radio, gps, misc and custom<n> ("items");
 * face, voice, insignia ("identity"). The picture is a custom button's own, else "". The classes are the
 * ones offered, in the case of ACE's lists. The result is kept until the supply changes - do not change it.
 *
 * Reads the lists of the session only (GVAR(catalogItems), else ACE's virtual items) and the soldier it
 * dresses (GVAR(center)). If the category shown is not among them, the first one is chosen.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Categories <ARRAY>
 *
 * Example:
 * call einv_arsenal_fnc_categories;
 *
 * Public: No
 */

private _stamp = GVAR(availableStamp);
private _key = [_stamp, typeOf GVAR(center), is3DEN, missionNamespace getVariable [QACEGVAR(arsenal,enableIdentityTabs), true]];
private _kept = GVAR(lists) getOrDefault ["#categories", []];
private _result = [];

if ((_kept param [0, []]) isEqualTo _key) then {
    _result = _kept param [1, []];
} else {
    private _items = GVAR(catalogItems);

    if !(_items isEqualType createHashMap) then {
        _items = missionNamespace getVariable [QACEGVAR(arsenal,virtualItems), createHashMap];
    };

    // The map at the end of a path of ACE's indices.
    private _fnc_map = {
        params ["_path"];

        private _map = _items;

        {
            if (_map isEqualType createHashMap) then {
                _map = _map getOrDefault [_x, createHashMap];
            };
        } forEach _path;

        if (_map isEqualType createHashMap) then {_map} else {createHashMap}
    };

    // The classes a map offers: those whose value is nil. A value of true marks something the soldier
    // carries that the arsenal does not have.
    private _fnc_offered = {
        params ["_paths"];

        private _classes = [];

        {
            {
                if (isNil "_y") then {
                    _classes pushBack _x;
                };
            } forEach ([_x] call _fnc_map);
        } forEach _paths;

        _classes
    };

    private _table = [
        ["rifle", "weapons", LLSTRING(Cat_Rifles), [[ACE_IDX_WEAPONS, ACE_IDX_PRIMARY]]],
        ["handgun", "weapons", LLSTRING(Cat_Handguns), [[ACE_IDX_WEAPONS, ACE_IDX_HANDGUN]]],
        ["launcher", "weapons", LLSTRING(Cat_Launchers), [[ACE_IDX_WEAPONS, ACE_IDX_LAUNCHER]]],
        ["binocular", "weapons", LLSTRING(Cat_Binoculars), [[ACE_IDX_BINO]]],
        ["optic", "parts", LLSTRING(Cat_Optics), [[ACE_IDX_ATTACHMENTS, ACE_IDX_OPTIC]]],
        ["rail", "parts", LLSTRING(Cat_Rails), [[ACE_IDX_ATTACHMENTS, ACE_IDX_RAIL]]],
        ["muzzle", "parts", LLSTRING(Cat_Muzzles), [[ACE_IDX_ATTACHMENTS, ACE_IDX_MUZZLE]]],
        ["bipod", "parts", LLSTRING(Cat_Bipods), [[ACE_IDX_ATTACHMENTS, ACE_IDX_BIPOD]]],
        ["magazine", "ammo", LLSTRING(Cat_Magazines), [[ACE_IDX_ITEMS_ALL]]],
        ["grenade", "ammo", LLSTRING(Cat_Grenades), [[ACE_IDX_GRENADES]]],
        ["explosive", "ammo", LLSTRING(Cat_Explosives), [[ACE_IDX_EXPLOSIVES]]],
        ["headgear", "gear", LLSTRING(Cat_Headgear), [[ACE_IDX_HEADGEAR]]],
        ["uniform", "gear", LLSTRING(Cat_Uniforms), [[ACE_IDX_UNIFORM]]],
        ["vest", "gear", LLSTRING(Cat_Vests), [[ACE_IDX_VEST]]],
        ["backpack", "gear", LLSTRING(Cat_Backpacks), [[ACE_IDX_BACKPACK]]],
        ["goggles", "gear", LLSTRING(Cat_Facewear), [[ACE_IDX_GOGGLES]]],
        ["nvg", "gear", LLSTRING(Cat_NVG), [[ACE_IDX_NVG]]],
        ["map", "items", LLSTRING(Cat_Maps), [[ACE_IDX_MAP]]],
        ["compass", "items", LLSTRING(Cat_Compasses), [[ACE_IDX_COMPASS]]],
        ["watch", "items", LLSTRING(Cat_Watches), [[ACE_IDX_WATCH]]],
        ["radio", "items", LLSTRING(Cat_Radios), [[ACE_IDX_RADIO]]],
        ["gps", "items", LLSTRING(Cat_GPS), [[ACE_IDX_COMMS]]]
    ];

    {
        _x params ["_id", "_group", "_label", "_paths"];

        private _classes = [_paths] call _fnc_offered;

        if (_classes isNotEqualTo []) then {
            _result pushBack [_id, _group, _label, "", _classes];
        };
    } forEach _table;

    // Misc items are what the custom buttons of ACE's right panel do not take away (ACE's own rule).
    private _misc = [[[ACE_IDX_MISC_ITEMS], [ACE_IDX_MISC_GOGGLES]]] call _fnc_offered;
    private _taken = createHashMap;
    private _custom = [];

    {
        if (!isNil "_x") then {
            _x params [["_buttonItems", [], [[]]], ["_picture", "", [""]], ["_tooltip", "", [""]]];

            {
                _taken set [toLowerANSI _x, true];
            } forEach _buttonItems;

            if ((_tooltip select [0, 1]) isEqualTo "$") then {
                _tooltip = localize (_tooltip select [1]);
            };

            private _offeredHere = _buttonItems select {_x in _misc};

            if (_offeredHere isNotEqualTo []) then {
                _custom pushBack [format ["custom%1", _forEachIndex], "items", _tooltip, _picture, _offeredHere];
            };
        };
    } forEach (missionNamespace getVariable [QACEGVAR(arsenal,customRightPanelButtons), []]);

    private _rest = _misc select {!((toLowerANSI _x) in _taken)};

    if (_rest isNotEqualTo []) then {
        _result pushBack ["misc", "items", LLSTRING(Cat_Misc), "", _rest];
    };

    _result append _custom;

    // The identity: not in the editor, and while ACE has its tabs off. Faces by the soldier's face type.
    if (!is3DEN && {missionNamespace getVariable [QACEGVAR(arsenal,enableIdentityTabs), true]}) then {
        private _faceType = getText (configOf GVAR(center) >> "faceType");
        private _faces = [];

        {
            if ((_y param [2, ""]) isEqualTo _faceType) then {
                _faces pushBack _x;
            };
        } forEach (missionNamespace getVariable [QACEGVAR(arsenal,faceCache), createHashMap]);

        private _voices = keys (missionNamespace getVariable [QACEGVAR(arsenal,voiceCache), createHashMap]);
        private _insignia = keys (missionNamespace getVariable [QACEGVAR(arsenal,insigniaCache), createHashMap]);

        {
            _x params ["_id", "_label", "_classes"];

            if (_classes isNotEqualTo []) then {
                _result pushBack [_id, "identity", _label, "", _classes];
            };
        } forEach [
            ["face", LLSTRING(Cat_Faces), _faces],
            ["voice", LLSTRING(Cat_Voices), _voices],
            ["insignia", LLSTRING(Cat_Insignia), _insignia]
        ];
    };

    GVAR(lists) set ["#categories", [_key, _result]];
};

// The one shown has to exist: the last shown in the group, else the first of the first group.
if (_result isNotEqualTo [] && {(_result findIf {(_x select 0) isEqualTo GVAR(category)}) < 0}) then {
    private _last = GVAR(lastCategory) getOrDefault [GVAR(group), ""];
    private _index = _result findIf {(_x select 0) isEqualTo _last};

    if (_index < 0) then {
        _index = 0;
    };

    GVAR(category) = (_result select _index) select 0;
    GVAR(group) = (_result select _index) select 1;
    GVAR(fits) = "";
};

_result
