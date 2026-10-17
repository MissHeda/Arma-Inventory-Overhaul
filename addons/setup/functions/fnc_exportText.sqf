#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The draft as text to share:
 *   - "own": the setting's text itself - the preset by name and the own statements. Short, and follows
 *     the preset as the mod improves it.
 *   - "full": the preset written out, base=none: every statement of the preset and the presets it builds
 *     on, then the own ones, with the cell size in effect - so it stays exactly the same whatever later
 *     versions of the mod do to the preset. A group redefined on the way keeps its meaning (see below).
 *     One thing does change: the preset's rules become own rules, which win over sizes a mod sets in its
 *     config (einv_gridSize and the like) where the preset's did not. The older table settings
 *     (einv_items_sizeTable and the like) are settings of their own and not part of either text.
 *   - "cba": the lines for a cba_settings.sqf, or CBA's Import box: force einv_items_rules = "...";
 *     and, when any server setting is off its default, force einv_main_settings = "..."; - forced over the
 *     mission when the wizard would save it so.
 * "own" and "full" one statement per line, with a comma at its end - the line breaks are read as commas
 * again - so a long setup stays readable. "cba" one line for each of the two settings, as CBA's files want
 * them. The server settings are no part of "own" and "full": they are no rules.
 *
 * Arguments:
 * 0: "own", "full" or "cba" <STRING> (default: "own")
 *
 * Return Value:
 * Text <STRING>
 *
 * Example:
 * ["cba"] call einv_setup_fnc_exportText;
 *
 * Public: No
 */

params [["_variant", "own", [""]]];

private _lineBreak = "," + toString [10];

switch (_variant) do {
    case "cba": {
        private _forced = (GVAR(target) getOrDefault ["source", ""]) isEqualTo "server" && {GVAR(override)} && {GVAR(target) getOrDefault ["override", false]};

        private _prefix = ["force ", "force force "] select _forced;
        private _lines = [format ["%1%2 = %3;", _prefix, RULES_SETTING, str GVAR(draftText)]];

        if (GVAR(draftSettingsText) isNotEqualTo "") then {
            _lines pushBack format ["%1%2 = %3;", _prefix, SETTINGS_SETTING, str GVAR(draftSettingsText)];
        };

        _lines joinString toString [10]
    };
    case "full": {
        // The layers, as the rules engine stacks them (einv_items_fnc_compileRules): the presets it builds
        // on, the first base first, then the own statements. One text has a single layer, so their order
        // is kept - a later rule wins - and each group is given the meaning it has in the stack.
        private _presets = configFile >> "CfgEinvRulesets";
        private _layers = [];

        {
            private _preset = _x;
            private _statements = (getArray (_presets >> _preset >> "rules")) select {_x isEqualType ""};

            _layers pushBack [_preset, [(["einv1 base=none"] + _statements) joinString ", "] call EFUNC(items,parseRules)];
        } forEach ((GVAR(draftRules) getOrDefault ["chain", []]) select {isClass (_presets >> _x)});

        _layers pushBack ["own", GVAR(draft)];

        // Where each group is defined. A later layer's definition replaces an earlier one; in one text two
        // definitions of a name would both count. So the one in effect keeps the name, and every one it
        // replaced gets a name of its own (mag_rifle_default) - inside a definition, the group's own name
        // stands for the one it replaces, and now says so.
        private _definedIn = createHashMap;

        {
            private _layer = _forEachIndex;

            {
                private _layersOf = _definedIn getOrDefault [_x select 0, []];
                _layersOf pushBackUnique _layer;
                _definedIn set [_x select 0, _layersOf];
            } forEach ((_x select 1) getOrDefault ["groups", []]);
        } forEach _layers;

        private _names = createHashMap;

        {
            private _id = _x;
            private _last = _y select (count _y - 1);

            {
                private _name = _id;

                if (_x != _last) then {
                    _name = format ["%1_%2", _id, (_layers select _x) select 0];

                    while {_name in _definedIn || {_name in values _names}} do {
                        _name = _name + "_";
                    };
                };

                _names set [format ["%1#%2", _id, _x], _name];
            } forEach _y;
        } forEach _definedIn;

        // A statement's conditions with the groups named as above: a group's own name inside its
        // definition is the definition below it - or, with none below, stays and means nothing, as before.
        private _fnc_conds = {
            params ["_conds", "_self", "_layer"];

            _conds apply {
                _x params ["_negated", "_key", "_op", "_values"];

                if (_key isEqualTo "@") then {
                    [_negated, _key, _op, _values apply {
                        private _id = _x;
                        private _below = (_definedIn getOrDefault [_id, []]) select {_x < _layer};

                        if (_id isEqualTo _self && {_below isNotEqualTo []}) then {
                            _names getOrDefault [format ["%1#%2", _id, _below select (count _below - 1)], _id]
                        } else {
                            _id
                        }
                    }]
                } else {
                    _x
                }
            }
        };

        private _groups = [];
        private _rules = [];

        {
            private _layer = _forEachIndex;
            private _ast = _x select 1;

            {
                _x params ["_id", "_conds"];

                _groups pushBack [_names getOrDefault [format ["%1#%2", _id, _layer], _id], [_conds, _id, _layer] call _fnc_conds];
            } forEach (_ast getOrDefault ["groups", []]);

            {
                _x params ["_conds", "_values"];

                _rules pushBack [[_conds, "", _layer] call _fnc_conds, _values];
            } forEach (_ast getOrDefault ["rules", []]);
        } forEach _layers;

        private _full = createHashMapFromArray [
            ["version", 1],
            ["base", "none"],
            ["cell", GVAR(draftRules) getOrDefault ["cell", -1]],
            ["categories", +(GVAR(draft) getOrDefault ["categories", []])],
            ["groups", _groups],
            ["rules", _rules],
            ["warnings", []]
        ];
        private _parts = [[_full] call EFUNC(items,writeRules)] call FUNC(statements);

        ([_parts select 0] + (_parts select 1)) joinString _lineBreak
    };
    default {
        ([GVAR(draftText)] call FUNC(statements)) params ["_head", "_statements"];

        ([_head] + _statements) joinString _lineBreak
    };
};
