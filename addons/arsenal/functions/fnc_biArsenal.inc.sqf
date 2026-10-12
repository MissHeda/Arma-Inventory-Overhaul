// BIS_fnc_arsenal, with "Open" asked first whether this mod takes it (einv_arsenal_fnc_handleBIOpen). Every
// other mode runs BI's own code untouched: the Virtual Garage and BI's display call them, the display's draw3D
// every frame. No script_component.hpp: BI's file defines ERROR, CONDITION and more of its own, and every name
// here is prefixed - BI assigns locals without private, which would overwrite ours.
// The unary param, as BI's own first lines: it takes a missing _this ("call BIS_fnc_arsenal" from a scope
// without one), where "_this param" would fail.
private _einvMode = param [0, "Open", [displayNull, ""]];
private _einvTaken = false;

if (_einvMode isEqualType "" && {_einvMode == "Open"} && {!is3DEN}) then {
    // BI calls itself under "with uiNamespace do"; the handler's globals live in the mission namespace.
    with missionNamespace do {
        _einvTaken = [param [1, []]] call (missionNamespace getVariable ["einv_arsenal_fnc_handleBIOpen", {false}]);
    };
};

if (_einvTaken isEqualTo true) exitWith {nil};

// BI's own function, untouched: its "_this = param [1, []]" stays inside this scope, and its return value
// (KeyDown blocking and Preload's "rebuilt" depend on it) is handed on. A missing _this becomes [] - a nil
// left argument would skip the call altogether, and BI reads [] exactly as it reads nothing.
private _einvArgs = if (isNil "_this") then {[]} else {_this};
private _einvResult = _einvArgs call {
    #include "\a3\functions_f_bootcamp\Inventory\fn_arsenal.sqf"
};

// A catalog BI has just built: kept as it came, so an open can tell what a mission changed in it since.
if (_einvMode isEqualTo "Preload" && {!isNil "_einvResult"} && {_einvResult isEqualTo true}) then {
    missionNamespace setVariable ["einv_arsenal_biCatalogBase", +(missionNamespace getVariable ["bis_fnc_arsenal_data", []])];
};

if (isNil "_einvResult") exitWith {nil};

_einvResult
