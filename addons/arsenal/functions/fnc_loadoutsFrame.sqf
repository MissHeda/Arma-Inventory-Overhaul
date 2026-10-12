#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What the Loadouts view does every frame: checks loadouts (fnc_verifyStep) and writes each answer into its
 * row where it stands, notes how far the list is scrolled (so a redraw can put it back), and draws the view
 * again when a loadout changed - the player's own, a default or a shared one (GVAR(loadoutsDirty)) - or when
 * the answer for the loadout that is picked came in and its card has to say it.
 *
 * It does not draw the view again while the cursor is in the field for the name: the field would be made
 * anew and lose it.
 *
 * Arguments:
 * 0: Time of the frame <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [diag_tickTime] call einv_arsenal_fnc_loadoutsFrame;
 *
 * Public: No
 */

params [["_now", 0, [0]]];

private _column = uiNamespace getVariable [QGVAR(column), createHashMap];
private _display = uiNamespace getVariable [QEGVAR(gui,display), displayNull];

// The view is not there (the Items are shown, or the window is about to be built).
if (isNull _display || {isNull (_column getOrDefault ["loadoutsGroup", controlNull])}) exitWith {};

// How far the list is scrolled, for the next time it is drawn - not right after it was, when it still
// stands at the top.
private _list = _column getOrDefault ["listGroup", controlNull];

if (!isNull _list && {diag_frameNo > (_column getOrDefault ["scrollHold", 0])}) then {
    _column set ["listScroll", (((ctrlScrollValues _list) select 0) max 0) * (_column getOrDefault ["listRange", 0])];
};

// ----- Checking -----

private _done = [] call FUNC(verifyStep);

if (_done isNotEqualTo []) then {
    private _rowCtrls = _column getOrDefault ["rowCtrls", createHashMap];
    private _fnc_status = _column getOrDefault ["fnc_status", {["", "muted", ""]}];
    private _pickedKey = _column getOrDefault ["selectedKey", ""];

    {
        private _controls = _rowCtrls getOrDefault [_x, []];

        // The card of the picked loadout lists what is missing.
        if (_x isEqualTo _pickedKey) then {
            _column set ["detailStale", true];
        };

        if (_controls isNotEqualTo []) then {
            _controls params ["_status", "_hit"];

            private _check = (GVAR(verified) getOrDefault [_x, []]) param [2, []];

            ([_check] call _fnc_status) params ["_text", "_colorKey", "_tip"];

            _status ctrlSetText _text;
            _status ctrlSetTextColor (EGVAR(gui,theme) getOrDefault [_colorKey, [1, 1, 1, 1]]);
            _hit ctrlSetTooltip _tip;
        };
    } forEach _done;
};

// ----- Drawing again -----

private _typing = focusedCtrl _display;

if (
    (GVAR(loadoutsDirty) || {_column getOrDefault ["detailStale", false]})
    && {isNull _typing || {_typing isNotEqualTo (_column getOrDefault ["nameEdit", controlNull])}}
) then {
    _column set ["detailStale", false];

    [_display, _column getOrDefault ["rect", [0, 0, 0, 0]], EGVAR(gui,theme), "loadouts"] call FUNC(drawColumn);
};
