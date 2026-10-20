#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Brings the open window up to date with what the containers hold, as cheaply as that can be done: the
 * signature now (fnc_getSignature) is compared part by part with the one the window was last drawn from.
 *
 *   - the unit's gear, or which sections the columns show (own, list), changed - or a section came or went:
 *     the window is built anew (fnc_build);
 *   - only what some sections hold or where it lies (loot, storage): those sections draw their tiles again
 *     (fnc_redrawTiles) - and when one of the unit's own sections is among them, the weight card and the
 *     hotbar's counts as well (fnc_redrawPart);
 *   - only what else the weight card shows (card - ACE's virtual load a moment after a move, the limits):
 *     only the card and the hotbar are drawn again;
 *   - nothing: nothing is drawn.
 * Whatever cannot be drawn again in place builds the window after all; so does a change of the unit's own
 * storage in a window that attached (the Arsenal's), which draws that column its own way, and a section
 * button drawn held back for a move that is no longer under way.
 *
 * Called once a second by fnc_onFrame and after each answer to the window's own moves (fnc_afterAction): a
 * move used to build the whole window - every control deleted and made again, every grid's cells, the
 * camera on the soldier started anew - which showed as a small stutter on every move (a tester, 0.4.7).
 *
 * Tiles still marked as under way whose moves have been answered meanwhile are let go first - faded back
 * in, unless the search field fades them (fnc_applyFilter) -, and what is still under way is shown again
 * (fnc_drawPending): a section that is not drawn again keeps its tiles.
 *
 * With einv_gui_debugTiming on, the RPT gets one line per refresh that did something - how long it took
 * (the build writes its own).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * What it did - "" nothing had changed, "redraw", "build" <STRING>
 *
 * Example:
 * [_display] call einv_gui_fnc_refresh;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]]];

if (isNull _display) exitWith {""};

private _start = diag_tickTime;
private _signature = call FUNC(getSignature);
private _signatureTook = (diag_tickTime - _start) * 1000;
private _before = GVAR(signatureParts);

_signature params ["_own", "_list", "_loot", "_storage", "_card"];

// Built anew: the build takes its own signature at its end.
private _fnc_build = {
    [_display] call FUNC(build);
    "build"
};

// A section's Sort drawn held back while a move from it was under way (fnc_drawSection)
// is given back by a build once no move is left: a redraw leaves the caption line as it is.
if (
    count _before != count _signature || {_own isNotEqualTo (_before select 0)} || {_list isNotEqualTo (_before select 1)}
    || {GVAR(opened) findIf {isNull (_x select 1)} >= 0}
    || {count _loot != count (_before select 2)} || {count _storage != count (_before select 3)}
    || {count GVAR(inFlight) == 0 && {(uiNamespace getVariable [QGVAR(sectionInfo), []]) findIf {_x getOrDefault ["busy", false]} >= 0}}
) exitWith {call _fnc_build};

// The sections whose part changed, by their number.
private _fnc_changed = {
    params ["_now", "_then"];

    private _changed = [];

    {
        if (_x isNotEqualTo (_then param [_forEachIndex, []])) then {
            _changed pushBack (_x select 0);
        };
    } forEach _now;

    _changed
};

private _lootChanged = [_loot, _before select 2] call _fnc_changed;
private _storageChanged = [_storage, _before select 3] call _fnc_changed;
private _cardChanged = _storageChanged isNotEqualTo [] || {_card isNotEqualTo (_before select 4)};

// Tiles of moves that were answered meanwhile are no longer under way: faded back in, and what is still
// under way marked again (fnc_drawPending) - only when there were such tiles, which is after a move. A tile that
// waits in the hands' queue is not one of them: it stays marked and faded (fnc_drawQueue keeps its mark), so a
// long queue is not faded in and out again at each answer.
private _fnc_settle = {
    private _found = false;

    {
        {
            if (_x getOrDefault ["pending", false] && {(_x getOrDefault ["queued", 0]) == 0}) then {
                _x set ["pending", false];
                _found = true;

                {
                    _x ctrlSetFade 0;
                    _x ctrlCommit 0;
                } forEach (_x getOrDefault ["controls", []]);
            };
        } forEach (_x getOrDefault ["tiles", []]);
    } forEach (uiNamespace getVariable [QGVAR(grids), []]);

    _found
};

private _fnc_pending = {
    call FUNC(drawPending);

    if (GVAR(filter) isNotEqualTo "" || {GVAR(groupFilters) isNotEqualTo []}) then {
        [] call FUNC(applyFilter);
    };
};

if (_lootChanged isEqualTo [] && {!_cardChanged}) exitWith {
    if (call _fnc_settle) then {
        call _fnc_pending;
    };

    ""
};

if (_cardChanged && {!([] call FUNC(isInventoryMode))}) exitWith {call _fnc_build};

private _settled = call _fnc_settle;

// The tiles: fnc_redrawTiles shows again what is under way and the search field's fading.
if ((_lootChanged isNotEqualTo [] || {_storageChanged isNotEqualTo []}) && {!([_lootChanged, _storageChanged] call FUNC(redrawTiles))}) exitWith {call _fnc_build};

// The weight card and the hotbar's counts follow what the unit carries. The card is always there in the
// inventory: a build without it is drawn anew whole.
private _parts = uiNamespace getVariable [QGVAR(parts), createHashMap];

if (_cardChanged && {!("weight" in _parts) || {(keys _parts) findIf {!([_x] call FUNC(redrawPart))} >= 0}}) exitWith {call _fnc_build};

if (_settled && {_lootChanged isEqualTo []} && {_storageChanged isEqualTo []}) then {
    call _fnc_pending;
};

GVAR(signatureParts) = _signature;

// For the tester's numbers (einv_gui_debugTiming): with the signature it compared.
if (missionNamespace getVariable [QGVAR(debugTiming), false]) then {
    private _took = ((diag_tickTime - _start) * 1000) toFixed 1;
    private _what = format ["%1 loot and %2 storage sections%3", count _lootChanged, count _storageChanged, ["", ", weight card"] select _cardChanged];

    // How many tiles stayed as they were and how many were made (fnc_redrawTiles), and the signature's share.
    if (_lootChanged isNotEqualTo [] || {_storageChanged isNotEqualTo []}) then {
        GVAR(redrawCounts) params [["_kept", 0], ["_made", 0], ["_tilesTook", 0]];

        _what = _what + format [", %1 tiles kept, %2 made in %3 ms", _kept, _made, _tilesTook toFixed 1];
    };

    _what = _what + format [", signature %1 ms", _signatureTook toFixed 2];

    INFO_2("timing: redraw %1 ms (%2)",_took,_what);
};

"redraw"
