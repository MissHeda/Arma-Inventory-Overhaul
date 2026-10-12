#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Puts an "Inventory setup" button on CBA's Addon Options, in the free place of its bottom row between
 * Load and Import, and shows it only while this mod's page is the one open. It opens the setup wizard
 * over the menu, in menu mode: what the wizard applies arrives in the menu as a change still to be
 * confirmed - our row turns yellow - and CBA's own OK saves it, or Cancel throws it away, like any other
 * change made there.
 *
 * Runs when the menu loads (Extended_DisplayLoad_EventHandlers >> RscDisplayGameOptions), after CBA's
 * own handler, which made the controls looked for here. Their ids are CBA's internals, not a promise:
 * should any of them be missing or moved, the button is simply not made, and ESC > Options, the keybind,
 * Eden's Tools menu and the inventory's cog still open the wizard.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call einv_setup_fnc_initCbaMenu;
 *
 * Public: No
 */

// CBA's controls on the menu, as CBA 3.19 numbers them (cba_settings, script_component.hpp): the group
// of the addon pages, the list of categories in it, and two buttons of the bottom row.
#define CBA_IDC_ADDONS_GROUP 4301
#define CBA_IDC_ADDONS_LIST 4312
#define CBA_IDC_BTN_IMPORT 9010
#define CBA_IDC_BTN_LOAD 9021

disableSerialization;

params ["_display"];

if (!hasInterface || {isNull _display}) exitWith {};

private _list = _display displayCtrl CBA_IDC_ADDONS_LIST;

// In the main menu CBA stops before it makes the list - its Addon Options need a mission there.
if (isNull _list || {isNull (_display displayCtrl CBA_IDC_ADDONS_GROUP)}) exitWith {};

private _load = _display displayCtrl CBA_IDC_BTN_LOAD;
private _import = _display displayCtrl CBA_IDC_BTN_IMPORT;

if (isNull _load || {isNull _import}) exitWith {};

// Placed by CBA's own buttons rather than by numbers of its grid, so it follows them should CBA move
// its row. CBA keeps its buttons a tenth of a grid apart, a sixtieth of their six grids' width.
(ctrlPosition _load) params ["_loadX", "_loadY", "_loadW", "_loadH"];
(ctrlPosition _import) params ["_importX", "_importY"];

private _gap = _loadW / 60;
private _left = _loadX + _loadW + _gap;
private _width = (_importX - _gap) - _left;

// Not side by side in one row any more, or no room left between them: CBA's layout changed.
if (_width <= 0 || {abs (_importY - _loadY) > _loadH / 2}) exitWith {};

private _button = _display ctrlCreate ["RscButtonMenu", -1];
_button ctrlSetPosition [_left, _loadY, _width, _loadH];
_button ctrlCommit 0;
_button ctrlSetText LLSTRING(OpenWizard);
_button ctrlSetTooltip LLSTRING(OpenWizard_Tooltip);
_button ctrlShow false;
_button ctrlEnable false;

// Straight away rather than a frame later: CBA's frame handlers do not run in Eden, where this menu
// opens as well.
_button ctrlAddEventHandler ["ButtonClick", {
    params ["_button"];

    [ctrlParent _button, "menu", 0, ""] call (missionNamespace getVariable [QFUNC(open), {}]);
}];

// The page of a category is its name in lower case after CBA localized it - read from the setting
// itself, so a category that is ever turned into a stringtable entry still matches in every language.
private _category = CBA_SETTINGS_EINV;
private _defaults = missionNamespace getVariable "cba_settings_default";

if (!isNil "_defaults") then {
    _category = (_defaults getVariable [QEGVAR(items,rules), []]) param [4, CBA_SETTINGS_EINV];
};

_display setVariable [QGVAR(cbaButton), _button];
_display setVariable [QGVAR(cbaCategory), toLower _category];

// Shown while the addon pages are open (not the game's own options) and our category is the one picked.
// CBA tells nobody when its page changes, and some changes never pass through the list's event - the
// first selection is made before this handler exists, the pages appear only after the menu loaded, a
// search can pick another category directly - so this also runs whenever the mouse moves or rests and
// after every key, the way CBA's own export window keeps itself up to date.
//
// Which way the button reads depends on the source picked at the top of the menu: CBA's client values
// never count for a setting that is the same for everyone, and not everyone may change the server's.
// Worked out again only when that source changes.
_display setVariable [QGVAR(cbaSync), {
    params ["_display"];

    private _button = _display getVariable [QGVAR(cbaButton), controlNull];

    if (isNull _button) exitWith {};

    private _list = _display displayCtrl CBA_IDC_ADDONS_LIST;
    private _index = lbCurSel _list;
    private _show = ctrlShown (_display displayCtrl CBA_IDC_ADDONS_GROUP)
        && {_index >= 0}
        && {(_list lbData _index) isEqualTo (_display getVariable [QGVAR(cbaCategory), ""])};

    if (_show isNotEqualTo ctrlShown _button) then {
        _button ctrlShow _show;
        _button ctrlEnable _show;
    };

    private _source = uiNamespace getVariable ["cba_settings_source", ""];

    if (_show && {_source isNotEqualTo (_button getVariable [QGVAR(source), -1])}) then {
        _button setVariable [QGVAR(source), _source];

        private _target = ["menu"] call (missionNamespace getVariable [QFUNC(canEdit), {createHashMap}]);
        private _canSave = !isNil "_target" && {_target isEqualType createHashMap} && {_target getOrDefault ["canSave", false]};

        _button ctrlSetTooltip ([LLSTRING(OpenWizard_ReadOnly), LLSTRING(OpenWizard_Tooltip)] select _canSave);
    };
}];

_display displayAddEventHandler ["MouseMoving", {
    params ["_display"];
    [_display] call (_display getVariable [QGVAR(cbaSync), {}]);
}];

_display displayAddEventHandler ["MouseHolding", {
    params ["_display"];
    [_display] call (_display getVariable [QGVAR(cbaSync), {}]);
}];

// Typing in CBA's search filters the categories without a mouse move. The key stays CBA's.
_display displayAddEventHandler ["KeyUp", {
    params ["_display"];
    [_display] call (_display getVariable [QGVAR(cbaSync), {}]);
    false
}];

_list ctrlAddEventHandler ["LBSelChanged", {
    params ["_list"];

    private _display = ctrlParent _list;
    [_display] call (_display getVariable [QGVAR(cbaSync), {}]);
}];

[_display] call (_display getVariable [QGVAR(cbaSync), {}]);
