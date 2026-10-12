#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The row of an item for the catalog, read once and kept: class, the text the search looks in, name, short
 * name, picture, true size, tile category, kind, stack, rounds, weight, the mod it comes from, category and
 * layout key - by the rules in force (einv_items_fnc_getInfo). The cache is emptied when the rules change.
 *
 * A face, a voice or an insignia (the second argument names which) has no item behind it: its row holds the
 * name and picture ACE's lists and the config give, in a size of one cell.
 *
 * Reads nothing of the session.
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: "face", "voice" or "insignia" for a piece of identity, "" for an item <STRING> (default: "")
 *
 * Return Value:
 * Row (the ROW_* places) <ARRAY>
 *
 * Example:
 * ["arifle_MX_F"] call einv_arsenal_fnc_catalogRow;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_identity", "", [""]]];

if (_class isEqualTo "") exitWith {[]};

private _lc = toLowerANSI _class;
private _cacheKey = [_lc, _identity + "|" + _lc] select (_identity isNotEqualTo "");
private _cached = GVAR(rows) get _cacheKey;

if (!isNil "_cached") exitWith {_cached};

private _row = [];

if (_identity isNotEqualTo "") then {
    private _name = _class;
    private _picture = "";

    switch (_identity) do {
        case "face": {
            // ACE's cache holds [name, the mod's logo, face type]; the card shows the logo.
            private _face = (missionNamespace getVariable [QACEGVAR(arsenal,faceCache), createHashMap]) getOrDefault [_class, []];

            _name = _face param [0, _class];
            _picture = _face param [1, ""];
        };
        case "voice": {
            private _voice = getText (configFile >> "CfgVoice" >> _class >> "displayName");

            if (_voice isNotEqualTo "") then {
                _name = _voice;
            };
        };
        default {
            // An insignia lies in the game's config, the campaign's or the mission's (ACE's cache says which).
            private _where = (missionNamespace getVariable [QACEGVAR(arsenal,insigniaCache), createHashMap]) getOrDefault [_class, 0];
            private _config = ([configFile, campaignConfigFile, missionConfigFile] param [_where, configFile]) >> "CfgUnitInsignia" >> _class;
            private _title = getText (_config >> "displayName");

            if (_title isNotEqualTo "") then {
                _name = _title;
            };

            _picture = getText (_config >> "texture");
        };
    };

    _row = [_class, toLowerANSI format ["%1|%2", _name, _class], _name, _name, _picture, 1, 1, CATEGORY_MISC, _identity, 1, 0, 0, "", _identity, _lc];
} else {
    private _info = [_class] call EFUNC(items,getInfo);
    private _name = [_class] call EFUNC(gui,itemName);
    private _short = [_class, true] call EFUNC(gui,itemName);

    // The mod it comes from, by name: kept per mod folder.
    private _modName = "";
    private _root = _info getOrDefault ["root", ""];

    if (_root isNotEqualTo "") then {
        private _source = configSourceMod (configFile >> _root >> _class);

        if (_source isNotEqualTo "") then {
            private _names = uiNamespace getVariable [QGVAR(modNames), createHashMap];

            uiNamespace setVariable [QGVAR(modNames), _names];
            _modName = _names getOrDefault [_source, ""];

            if (_modName isEqualTo "") then {
                _modName = (modParams [_source, ["name"]]) param [0, _source];
                _names set [_source, _modName];
            };
        };
    };

    private _size = _info getOrDefault ["size", [1, 1]];

    _row = [
        _class, toLowerANSI format ["%1|%2|%3|%4", _name, _short, _class, _modName], _name, _short,
        _info getOrDefault ["picture", ""], _size select 0, _size select 1, _info getOrDefault ["category", CATEGORY_MISC],
        _info getOrDefault ["kind", ""], _info getOrDefault ["stack", 1], _info getOrDefault ["capacity", 0],
        _info getOrDefault ["mass", 0], _modName, "", [_class] call EFUNC(storage,layoutKey)
    ];
};

GVAR(rows) set [_cacheKey, _row];

_row
