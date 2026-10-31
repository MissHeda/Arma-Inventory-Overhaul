#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Shows how the window's moves went.
 *
 * The answer to one of the window's transactions (fnc_onAnswer), once fnc_onFrame finishes it - the
 * places it names arrived, or it waited long enough: its in-flight entry goes (fnc_drawPending), what
 * moved is learnt where it is searched (fnc_learn), the sections it touched are drawn again with the
 * landed tiles lit up - the window is built anew only when sections came or went, or the unit's gear
 * changed (fnc_refresh; a build on every move showed as a small stutter, a tester on 0.4.7) -, and the
 * hint sums it up - why not for a single move, "Moved 3 of 5" for several, what was put back
 * or onto the ground because there was no room any more, "Put elsewhere" when the cell asked for was
 * taken meanwhile. What lies around is read anew first (fnc_readNearby), so a pile the answer names shows
 * at once among the nearby boxes (aio_gui_showNearby); a pile that is not among them - those switched
 * off, or the pile out of their sight or reach - becomes what the window looks into: a new pile has to
 * show up somewhere.
 *
 * The sound of an answer is played here, of the first item that really moved (fnc_feelAnswer, with what
 * fnc_sendMoves worked out when the moves were sent); a refused change is silent, the hint says why. A rebuild
 * the hotbar asks for (binding a slot) is silent too.
 *
 * Also the plain result of a change made some other way (aio_compat_efak): the window built again when
 * it happened, the reason in the hint when not.
 *
 * Arguments - an answer as GVAR(answers) keeps it (also wrapped in an array):
 * 0: Request id <STRING>
 * 1: Summary (aio_storage_fnc_onAnswer) <ARRAY>
 * 2: Revisions, [[holder, revision], ...] <ARRAY>
 * 3: Args fnc_sendMoves gave along, [move records, options, moves of the next chunks] <ARRAY>
 * 4: When it arrived - not looked at here <NUMBER>
 *
 * Arguments - a plain result:
 * 0: Result - "" when it happened, else the reason (fnc_flashHint) <STRING>
 * 1: Container things went into <OBJECT> (default: objNull)
 *
 * Return Value:
 * Something happened <BOOL>
 *
 * Example:
 * _answer call aio_gui_fnc_afterAction;
 * ["", _holder] call aio_gui_fnc_afterAction;
 *
 * Public: No
 */

disableSerialization;

private _input = [_this] param [0, []];

if !(_input isEqualType []) then {
    _input = [_input];
};

// An answer handed over in an array of its own.
if ((_input param [0, ""]) isEqualType []) then {
    _input = _input select 0;
};

private _display = uiNamespace getVariable [QGVAR(display), displayNull];

// Something put on a new pile on the ground has to show up in the loot column, so a pile the window
// does not know yet becomes what it looks into - the first container, or the second next to a crate.
private _fnc_adopt = {
    params ["_pile"];

    if (
        !(_pile isEqualType objNull) || {isNull _pile} || {!([_pile] call EFUNC(storage,isGroundHolder))}
        || {_pile in [GVAR(container), GVAR(secondary)]}
    ) exitWith {};

    if (isNull GVAR(container) || {[GVAR(container)] call EFUNC(storage,isGroundHolder)}) then {
        GVAR(container) = _pile;
    } else {
        GVAR(secondary) = _pile;
    };
};

// ----- An answer of the window's own transactions -----

if ((_input param [1, objNull]) isEqualType []) exitWith {
    _input params [["_id", "", [""]], ["_summary", [], [[]]], "", ["_args", [], [[]]]];

    // How its moves sound (fnc_sendMoves kept it with the record), played below once it is known how many went.
    private _flight = GVAR(inFlight) getOrDefault [_id, []];
    private _feels = _flight param [3, []];

    GVAR(inFlight) deleteAt _id;

    _args params [["_records", [], [[]]], ["_options", createHashMap, [createHashMap]], ["_rest", [], [[]]]];
    _summary params [["_results", [], [[]]], ["_settled", [], [[]]], ["_pile", objNull]];
    _settled params [["_back", 0, [0]], ["_vehicle", 0, [0]], ["_ground", 0, [0]]];

    // The result of the op one of a move's steps became, [status, extra] - a step it does not have
    // passes.
    private _fnc_result = {
        params ["_at"];

        if (_at isEqualTo []) exitWith {["", []]};

        ((_results param [_at select 0, []]) param [_at select 1, []]) params [["_status", "Failed"], ["_extra", []]];

        [_status, _extra]
    };

    // Search knowledge is kept on containers - not on a unit, a kit or the ground.
    private _fnc_learnable = {
        params ["_holder"];

        _holder isEqualType objNull && {!isNull _holder} && {!(_holder isKindOf "CAManBase")}
    };

    private _grids = uiNamespace getVariable [QGVAR(grids), []];
    private _moved = 0;
    private _reason = "";
    private _elsewhere = false;
    private _landed = [];

    {
        private _record = _x;
        private _kind = _record getOrDefault ["kind", "move"];
        private _roles = _record getOrDefault ["roles", createHashMap];
        private _from = _record getOrDefault ["from", objNull];
        private _to = _record getOrDefault ["to", objNull];
        private _class = _record getOrDefault ["class", ""];

        ([_roles getOrDefault ["land", []]] call _fnc_result) params ["_status", "_extra"];

        if !(_extra isEqualType []) then {
            _extra = [];
        };

        if (_status isEqualTo "") then {
            _moved = _moved + 1;

            // Onto the ground: the pile the server put it on.
            if (_to isEqualTo "ground") then {
                _to = _extra param [0, objNull];
            };

            // What you put somewhere you know is there; what you take out is no longer to be found.
            if (_from isNotEqualTo _to) then {
                if (_kind in ["move", "equip"] && {[_from] call _fnc_learnable}) then {
                    [_from, _class, -1] call FUNC(learn);
                };

                if (_kind in ["move", "unequip"] && {[_to] call _fnc_learnable}) then {
                    [_to, _class, 1] call FUNC(learn);
                };
            };

            // The old item of an equip, where it went in.
            if (_kind isEqualTo "equip" && {"old" in _roles} && {(([_roles get "old"] call _fnc_result) select 0) isEqualTo ""}) then {
                private _oldTo = _record getOrDefault ["oldTo", objNull];

                if ([_oldTo] call _fnc_learnable) then {
                    [_oldTo, _record getOrDefault ["oldClass", ""], 1] call FUNC(learn);
                };
            };

            if (_kind in ["move", "unequip"]) then {
                // The cell asked for was taken meanwhile: the authority found it another one.
                if ((_extra param [1, false]) isEqualTo true) then {
                    _elsewhere = true;
                };

                // Where it landed lights up once the window shows it there.
                private _cell = _extra param [0, []];

                if !(_cell isEqualType [] && {count _cell >= 2}) then {
                    _cell = _record getOrDefault ["cell", []];
                };

                if (count _cell >= 2 && {_to isEqualType "" || {!isNull _to}}) then {
                    _cell params ["_col", "_row", ["_block", 0]];

                    private _container = _to;
                    private _kit = "";

                    // A kit's grid has no container: it is told by its kit (fnc_findTile).
                    if (_to isEqualType "") then {
                        private _index = _grids findIf {(_x getOrDefault ["holder", _x getOrDefault ["layoutKey", ""]]) isEqualTo _to};

                        _container = objNull;
                        _kit = if (_index < 0) then {""} else {(_grids select _index) getOrDefault ["kit", ""]};
                    };

                    if (!isNull _container || {_kit isNotEqualTo ""}) then {
                        _landed pushBack [_container, toLowerANSI _class, _row, _col, 0, _block, _kit];
                    };
                };
            };
        } else {
            // Why not: the first step that says so. A step skipped for want of an input, or a put that
            // bounced, only follows from that - what bounced the summary counts.
            if (_reason isEqualTo "") then {
                {
                    private _step = (([_roles getOrDefault [_x, []]] call _fnc_result) select 0);

                    if !(_step in ["", "Skipped", "Bounced", "NotLocal"]) exitWith {
                        _reason = _step;
                    };
                } forEach ["take", "land"];

                // It did not go on - it went back where it came from.
                if (_reason isEqualTo "" && {_kind isEqualTo "equip"} && {_status isEqualTo "Bounced"}) then {
                    _reason = "NoFit";
                };
            };
        };
    } forEach _records;

    private _total = count _records;
    private _hint = [];

    if (_moved < _total) then {
        if (_moved > 0) then {
            _hint = ["MovedSome", [_moved, _total]];
        } else {
            if (_reason isNotEqualTo "") then {
                _hint = [_reason];
            };
        };
    };

    if (_hint isEqualTo []) then {
        // Seated, "the ground" is the vehicle's cargo.
        private _grounded = _vehicle + _ground;

        _hint = switch (true) do {
            case (_grounded > 0): {["Grounded", [_grounded]]};
            case (_back > 0): {["Returned", [_back]]};
            case (_moved < _total): {["Failed"]};
            case (_elsewhere): {["PlacedElsewhere"]};
            case (_rest isEqualTo [] && {(_options getOrDefault ["label", ""]) isNotEqualTo ""}): {[_options get "label"]};
            default {[]};
        };
    };

    if (isNull _display) exitWith {_moved > 0};

    // The sound of the first item that really moved - one per answer, none for a refusal (fnc_feelAnswer).
    [_feels, _moved] call FUNC(feelAnswer);

    // What lies around is read anew first: the pile shows as one of the nearby boxes. One that does not
    // show there all the same - out of sight from the eyes, beyond the reach, the nearby boxes switched
    // off - is looked into instead: what went onto it must never seem to vanish.
    [] call FUNC(readNearby);

    if !(_pile in GVAR(nearby)) then {
        [_pile] call _fnc_adopt;
    };

    // Only what changed is drawn again: the sections the moves touched (and the weight card when one is the
    // unit's own), or the whole window when sections came or went - a pile adopted above, a uniform put on.
    [_display] call FUNC(refresh);

    if (_options getOrDefault ["flash", true]) then {
        {
            [_display, _x, LAND_FLASH_ALPHA, LAND_FLASH] call FUNC(flashTile);
        } forEach _landed;
    };

    // After the drawing, which gives the hint back to what the mouse is on.
    if (_hint isNotEqualTo []) then {
        _hint call FUNC(flashHint);
    };

    _moved > 0
};

// ----- A plain result -----

_input params [["_result", "", [""]], ["_to", objNull]];

if (_result isNotEqualTo "") exitWith {
    [_result] call FUNC(flashHint);
    false
};

if (!isNull _display) then {
    [] call FUNC(readNearby);

    if !(_to in GVAR(nearby)) then {
        [_to] call _fnc_adopt;
    };

    [_display] call FUNC(build);
};

true
