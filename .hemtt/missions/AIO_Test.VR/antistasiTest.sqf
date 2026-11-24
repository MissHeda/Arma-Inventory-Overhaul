// Checks of compat_antistasi in this test scene, with Antistasi Ultimate loaded (hemtt launch antistasi). Antistasi's
// own mission is not running here, so the few globals its functions read are stubbed below. Run through the clipboard
// driver of init.sqf (scheduled): AIOCMD:<id>|call compile preprocessFileLineNumbers "antistasiTest.sqf"
// Every check writes "PASS"/"FAIL <name>: <detail>" to the RPT and the whole list comes back as the result.
// Pass "halo" as _this to run the HALO jump only (it takes a minute).

private _results = [];
private _fnc_check = {
    params ["_name", "_ok", ["_detail", ""]];
    private _line = format ["%1 %2: %3", ["FAIL", "PASS"] select _ok, _name, _detail];
    diag_log text ("AIO-A3U " + _line);
    _results pushBack _line;
};

if !(isClass (configFile >> "CfgPatches" >> "A3A_core")) exitWith {"Antistasi Ultimate is not loaded"};

// ----- Stubs for Antistasi's mission globals -----
if (isNil "A3A_faction_civ") then {
    A3A_faction_civ = createHashMapFromArray [["currencySymbol", "€"]];
    A3A_faction_occ = createHashMapFromArray [["ammobox", "Box_East_Ammo_F"], ["surrenderCrate", "Box_East_Wps_F"]];
    A3A_faction_inv = createHashMapFromArray [["ammobox", "Box_IND_Ammo_F"], ["surrenderCrate", "Box_IND_Wps_F"]];
    A3A_faction_riv = createHashMapFromArray [["ammobox", "Box_Syndicate_Ammo_F"], ["surrenderCrate", "Box_Syndicate_Wps_F"]];
    Occupants = east;
    Invaders = independent;
    petros = player;
    HALs_money_oldManItemsPrice = [10, 20, 30, 40];
};

if (_this isEqualTo "halo") exitWith {
    // ----- HALO jump: the backpack comes back as it was, places included -----
    private _before = (getUnitLoadout player) select 5;
    private _layoutBefore = [player] call aio_compat_antistasi_fnc_layoutOf;
    private _pos = getPosATL player;
    player setPosATL (_pos vectorAdd [0, 0, 250]);
    [] spawn {sleep 4; player action ["OpenParachute", player]};
    player call SCRT_fnc_paradrop_jump;
    sleep 3;
    private _after = (getUnitLoadout player) select 5;
    private _layoutAfter = [player] call aio_compat_antistasi_fnc_layoutOf;
    ["halo backpack", _after isEqualTo _before, format ["before %1 after %2", _before, _after]] call _fnc_check;
    ["halo places", ((_layoutAfter param [1, []]) param [2, []]) isEqualTo ((_layoutBefore param [1, []]) param [2, []]), format ["%1 vs %2", (_layoutBefore param [1, []]) param [2, []], (_layoutAfter param [1, []]) param [2, []]]] call _fnc_check;
    _results joinString " || "
};

// ----- 1. No extender warning: Antistasi's own detection -----
[] call A3A_fnc_initExtenderDetection;
private _ext = missionNamespace getVariable ["A3A_core_extendersLoaded", []];
private _bad = missionNamespace getVariable ["A3A_core_extendersLoadedInvalid", []];
private _ours = (_ext apply {_x get "extender"}) select {"aio" in toLowerANSI _x};
["extender", _ours isEqualTo [], format ["aio extenders %1, invalid %2", _ours, _bad apply {_x get "extender"}]] call _fnc_check;

// ----- 2. Every patched file found its words -----
private _probe = {
    params ["_key", "_path", "_changes", "_token"];
    private _code = [_key + "_probe", _path, _changes] call aio_compat_antistasi_fnc_patched;
    [_key, (str _code) find _token >= 0, format ["token %1", _token]] call _fnc_check;
};
private _classes = """WeaponHolderSimulated"", ""GroundWeaponHolder"", ""WeaponHolder""";
["gatherLoot", "\x\A3A\addons\scrt\Loot\fn_loot_gatherLoot.sqf", [[_classes, _classes + ", ""GroundWeaponHolder_Scripted"""]], "GroundWeaponHolder_Scripted"] call _probe;
private _find = "nearestObjects [position _unit, [""WeaponHolderSimulated"", ""GroundWeaponHolder"", ""WeaponHolder""], 9]";
["mineSweep", "\x\A3A\addons\core\functions\AI\fn_mineSweep.sqf", [[_find, format ["((%1) select {typeOf _x isNotEqualTo ""GroundWeaponHolder_Scripted""})", _find]]], "GroundWeaponHolder_Scripted"] call _probe;
["useMagazineItem", "\x\A3A\addons\ultimate\functions\Utility\fn_useMagazineItem.sqf", [["private _containers = [backpackContainer _unit, vestContainer _unit, uniformContainer _unit];", "private _containers = [_unit, _magazine] call aio_compat_antistasi_fnc_useOrder;"]], "fnc_useOrder"] call _probe;
["storeMain", "\x\A3A\addons\hals\Addons\store\functions\client\ui\fn_main.sqf", [["_container canAdd [_classname, _amount - 1]", "([_container, _classname, _amount - 1] call aio_compat_antistasi_fnc_canAdd)"], ["_container canAdd [_classname, _amount]", "([_container, _classname, _amount] call aio_compat_antistasi_fnc_canAdd)"]], "fnc_canAdd"] call _probe;
["receiveItems", "\x\A3A\addons\bazaar\functions\fn_receiveItems.sqf", [["player canAdd _class", "([player, _class] call aio_compat_antistasi_fnc_canTake)"]], "fnc_canTake"] call _probe;

// The real functions point at ours.
{
    _x params ["_var", "_ours"];
    private _code = missionNamespace getVariable [_var, {}];
    [_var, (str _code) find _ours >= 0, "overridden"] call _fnc_check;
} forEach [
    ["SCRT_fnc_loot_gatherLoot", "gatherLoot"], ["SCRT_fnc_paradrop_jump", "paradropJump"], ["A3A_fnc_mineSweep", "mineSweep"],
    ["A3U_fnc_useMagazineItem", "useMagazineItem"], ["HALs_store_fnc_canAddItem", "canAddItem"], ["HALs_store_fnc_main", "storeMain"],
    ["ABZ_fnc_receiveItems", "receiveItems"]
];

// ----- 3. Loot around takes our piles -----
private _pile = [player, player, true, true] call aio_storage_fnc_getGroundHolder;
_pile addItemCargoGlobal ["Medikit", 1];
private _truck = "B_Truck_01_transport_F" createVehicle ((getPosATL player) vectorAdd [8, 0, 0]);
clearItemCargoGlobal _truck; clearMagazineCargoGlobal _truck; clearWeaponCargoGlobal _truck; clearBackpackCargoGlobal _truck;
sleep 0.5;
[_truck, 30] call SCRT_fnc_loot_gatherLoot;
sleep 2;
["gatherLoot run", "Medikit" in (itemCargo _truck), format ["pile %1 truck %2", typeOf _pile, itemCargo _truck]] call _fnc_check;
deleteVehicle _truck;

// ----- 4. Grid room for traders -----
private _engine = vestContainer player canAdd ["100Rnd_65x39_caseless_mag", 20];
private _room = [vestContainer player, "100Rnd_65x39_caseless_mag", 20] call aio_compat_antistasi_fnc_gridRoom;
private _canAddItem = [vestContainer player, "100Rnd_65x39_caseless_mag", 20, true] call HALs_store_fnc_canAddItem;
["gridRoom", _room >= 0 && {_canAddItem <= _room}, format ["engine can add 20: %1, grid room %2, canAddItem max %3", _engine, _room, _canAddItem]] call _fnc_check;
private _crateRoom = [cursorObject, "FirstAidKit", 1] call aio_compat_antistasi_fnc_gridRoom;
["gridRoom non-unit", true, format ["cursorObject %1 -> %2", typeOf cursorObject, _crateRoom]] call _fnc_check;

// ----- 5. Bazaar purchase -----
private _fak = {_x == "FirstAidKit"} count (items player);
["FirstAidKit", 1] call ABZ_fnc_receiveItems;
sleep 0.5;
["receiveItems run", ({_x == "FirstAidKit"} count (items player)) == _fak + 1 || {count (nearestObjects [player, ["GroundWeaponHolder"], 3]) > 0}, format ["FAKs %1 -> %2", _fak, {_x == "FirstAidKit"} count (items player)]] call _fnc_check;

// ----- 6. Money -----
player setVariable ["moneyX", 100, true];
[player, "Money_bunch", 1] call aio_storage_fnc_addToUnit;
sleep 3;
private _funds = [player] call HALs_money_fnc_getFunds;
["money convert", _funds == 110 && {!("Money_bunch" in itemsWithMagazines player)}, format ["funds %1, still carried %2, Money_bunch is %3", _funds, "Money_bunch" in itemsWithMagazines player, ["item", "magazine"] select isClass (configFile >> "CfgMagazines" >> "Money_bunch")]] call _fnc_check;
private _text = call aio_compat_antistasi_fnc_moneyText;
["money text", _text isNotEqualTo "", _text] call _fnc_check;
["footerInfo registered", (aio_gui_footerInfo findIf {(str _x) find "moneyText" >= 0 || {_x isEqualTo aio_compat_antistasi_fnc_moneyText}}) >= 0, str count aio_gui_footerInfo] call _fnc_check;

// ----- 7. Undercover -----
private _body = (createGroup east) createUnit ["O_Soldier_F", (getPosATL player) vectorAdd [2, 2, 0], [], 0, "NONE"];
_body setDamage 1;
private _watcher = (createGroup east) createUnit ["O_Soldier_F", (getPosATL player) vectorAdd [30, 0, 0], [], 0, "NONE"];
_watcher reveal [player, 4];
sleep 1;
player setCaptive true;
private _lost = [player, uniformContainer _body, _body] call aio_compat_antistasi_fnc_onLooked;
["undercover body", _lost && {!captive player}, format ["lost %1 captive %2 knows %3", _lost, captive player, _watcher knowsAbout player]] call _fnc_check;
player setCaptive true;
private _kept = [player, objNull, _truck] call aio_compat_antistasi_fnc_onLooked;
["undercover other", !_kept && {captive player}, "nothing for a non-body"] call _fnc_check;
player setCaptive false;
deleteVehicle _watcher;

// ----- 8. Save and load keep the places -----
private _layout = [player] call aio_compat_antistasi_fnc_layoutOf;
private _data = createHashMap;
[_data] call aio_compat_antistasi_fnc_onSave;
["save data", "aio_compat_antistasi_layout" in _data, str keys _data] call _fnc_check;
player setUnitLoadout (getUnitLoadout player);
sleep 1;
[_data] call aio_compat_antistasi_fnc_onLoad;
sleep 4;
private _after = [player] call aio_compat_antistasi_fnc_layoutOf;
["load places", (_after param [1, []]) isEqualTo (_layout param [1, []]), format ["%1 / %2", count ((_layout param [1, []]) param [1, []]), count ((_after param [1, []]) param [1, []])]] call _fnc_check;

// ----- 9. Lockpick order -----
private _was = missionNamespace getVariable ["aio_storage_useBackpack", "all"];
aio_storage_useBackpack = "none";
[] call aio_storage_fnc_useRefresh;
private _order = [player, "30Rnd_65x39_caseless_mag"] call aio_compat_antistasi_fnc_useOrder;
["useOrder", (_order select 2) isEqualTo backpackContainer player, str (_order apply {typeOf _x})] call _fnc_check;
aio_storage_useBackpack = _was;
[] call aio_storage_fnc_useRefresh;

// ----- 10. Mag Repack wrapped -----
if (isNil "outlw_MR_createDialog") then {
    [] execVM "\x\A3A\addons\core\Scripts\MagRepack\MagRepack_init_sv.sqf";
    sleep 8;
};
["magRepack wrapped", !isNil "outlw_MR_createDialog" && {outlw_MR_createDialog isEqualTo aio_compat_antistasi_mrCreateWrapper} && {outlw_MR_onDialogDestroy isEqualTo aio_compat_antistasi_mrDestroyWrapper}, format ["defined %1", !isNil "outlw_MR_createDialog"]] call _fnc_check;

_results joinString " || "
