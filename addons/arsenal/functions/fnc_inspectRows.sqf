#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The rows ACE's stats add to the inspect card for an item (the "inspectRows" hook): whether this arsenal
 * offers it, then the bars and texts ACE's own window shows for the item's tab - rate of fire, accuracy,
 * scope magnification, protection and so on, also what other mods register with ace_arsenal_fnc_addStat
 * (ACRE's radio figures among them) -, at most eight.
 *
 * The tab is found from the item's kind. A stat is shown when its condition holds for the item's config,
 * its bar and text come from the statements ACE compiled, exactly as ACE's handleStats calls them. The
 * impact bar looks at the weapon tab that is open to tell a launcher from other weapons
 * (ace_arsenal_currentLeftPanel), so that is set to the weapon's tab while the statements run and cleared
 * again after. The weight, the load and the round count are left out: the card shows those itself.
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: How many <NUMBER>
 * 2: Rounds, -1 for none <NUMBER>
 * 3: Attachments, a weapon's array <ARRAY>
 *
 * Return Value:
 * Rows [label, text] or [label, how full 0 to 1, text] <ARRAY>
 *
 * Example:
 * ["arifle_MX_F", 1, -1, []] call einv_arsenal_fnc_inspectRows;
 *
 * Public: No
 */

// Only the class is needed: the rest of the hook's arguments is for windows that look at the stack.
params [["_class", "", [""]]];

if (_class isEqualTo "") exitWith {[]};

// ----- Whether it is here -----

private _rows = [
    [LLSTRING(Inspect_InArsenal), [LLSTRING(Inspect_Yes), LLSTRING(Inspect_No)] select ([_class] call FUNC(isUnique))]
];

// ----- Which of ACE's tabs it belongs to -----

private _kind = ([_class] call EFUNC(items,getInfo)) getOrDefault ["kind", ""];

// The left panel's tabs in ACE's order, then the right panel's (compileStats).
private _left = [
    "rifle", "handgun", "launcher", "uniform", "vest", "backpack", "headgear", "goggles", "nvg", "binocular", "map", "gps",
    "radio", "compass", "watch"
] find _kind;
private _right = -1;

if (_left < 0) then {
    _right = switch (true) do {
        case (_kind in ["optic", "rail", "muzzle", "bipod"]): {["optic", "rail", "muzzle", "bipod"] find _kind};
        case (_kind in ["magazine", "grenade"]): {
            // Explosives are ACE's "put" tab, hand grenades and smokes its "throw" tab.
            if (_class in (uiNamespace getVariable [QACEGVAR(arsenal,putCache), []])) then {
                6
            } else {
                [4, 5] select (_kind isEqualTo "grenade")
            }
        };
        case (_kind isEqualTo "item"): {7};
        default {-1};
    };
};

if (_left < 0 && {_right < 0}) exitWith {_rows};

// ACE builds its stat tables when it first needs them.
if (isNil QACEGVAR(arsenal,statsListLeftPanel) && {!isNil QACEFUNC(arsenal,compileStats)}) then {
    call ACEFUNC(arsenal,compileStats);
};

private _tab = if (_left >= 0) then {
    (missionNamespace getVariable [QACEGVAR(arsenal,statsListLeftPanel), []]) param [_left, []]
} else {
    (missionNamespace getVariable [QACEGVAR(arsenal,statsListRightPanel), []]) param [_right, []]
};

private _config = _class call CBA_fnc_getItemConfig;

if (_tab isEqualTo [] || {isNull _config}) exitWith {_rows};

// ----- The weapon tab the open window stands for -----

private _panel = switch (_kind) do {
    case "rifle": {2002};
    case "handgun": {2004};
    case "launcher": {2006};
    default {-1};
};

if (_panel > 0) then {
    missionNamespace setVariable [QACEGVAR(arsenal,currentLeftPanel), _panel];
};

// ----- The stats -----

private _stats = 0;

{
    // [priority, config entries, title, [bar, text], [bar code, text code, condition], id]
    _x params ["", "_entries", "_title", "_shows", "_statements", ["_id", ""]];
    _shows params ["_showBar", "_showText"];
    _statements params [["_barCode", {}, [{}]], ["_textCode", {}, [{}]], ["_condition", {true}, [{}]]];

    // What the card shows by itself.
    if (["ACE_mass", "ACE_load", "ACE_magCount"] findIf {(_id select [0, count _x]) isEqualTo _x} >= 0) then {
        continue;
    };

    if (_stats >= 8 || {!([_entries, _config] call _condition)}) then {
        continue;
    };

    if ((_title select [0, 1]) isEqualTo "$") then {
        _title = localize (_title select [1]);
    };

    private _bar = -1;
    private _text = "";

    if (_showBar) then {
        private _fill = [_entries, _config] call _barCode;

        if (isNil "_fill" || {!(_fill isEqualType 0)}) then {
            _fill = 0;
        };

        _bar = (_fill max 0) min 1;
    };

    if (_showText) then {
        _text = [_entries, _config] call _textCode;

        if (isNil "_text") then {
            _text = "";
        };

        if (_text isEqualType []) then {
            _text = _text joinString ", ";
        } else {
            if !(_text isEqualType "") then {
                _text = str _text;
            };
        };

        // One line: the card's rows are one line high.
        _text = (_text splitString (toString [10, 13])) joinString ", ";
    };

    switch (true) do {
        case (_showBar && {_showText}): {_rows pushBack [_title, _bar, _text]};
        case _showBar: {_rows pushBack [_title, _bar, ""]};
        case _showText: {_rows pushBack [_title, _text]};
        default {};
    };

    _stats = _stats + 1;
} forEach _tab;

if (_panel > 0) then {
    missionNamespace setVariable [QACEGVAR(arsenal,currentLeftPanel), nil];
};

_rows
