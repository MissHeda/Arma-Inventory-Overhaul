// Test mission for Ravage's "Search" with Arma Inventory Overhaul (hemtt launch ravage).
//
// The player stands among furniture: look at a piece and hold "Search", as in a Ravage mission. Ravage's own scripts
// run it - its loot lists, its player handler (fnc_checkLoot) and its search action (loot_action.sqf) - only the map's
// furniture scan is left out: the piece looked at is the search target here, and every search finds something.
// Ravage lets a piece be searched once a day; the action "Reset Ravage searches" (scroll menu) makes them all new.
if (!hasInterface) exitWith {};

if (!isClass (configFile >> "CfgPatches" >> "ravage")) exitWith {
    systemChat "AIO_Ravage: Ravage is not loaded - start with: hemtt launch ravage";
};

[] spawn {
    waitUntil {!isNull player && {time > 0}};

    private _center = [4096, 4096, 0];
    player setPosATL _center;
    player setDir 0;

    // Ravage's loot lists (its gear pool builds them), then its player handler and its search action.
    [0, false, 0, 0, 0, 0, 0, 0, 1, 0, 0] execVM "\ravage\code\scripts\system\gear\gearPool.sqf";
    waitUntil {!isNil "lootVital_list"};

    private _script = [] execVM "\ravage\code\rvgLoot\player_fnc.sqf";
    waitUntil {scriptDone _script};

    // What Ravage's loot module sets up otherwise: its building registry (empty - the furniture here carries its category
    // itself) and the server's list of piles to clean up.
    if (isNil "bldsReg_A3") then {bldsReg_A3 = []; frntData_A3 = []};
    if (isNil "loot_to_clean") then {loot_to_clean = []};

    // Every type of find, always: civil, military and industrial categories.
    spawnClassChance_list = [[100, 100, 100, 100, 100], [100, 100, 100, 100, 100], [100, 100, 100, 100, 100]];

    _script = [] execVM "\ravage\code\rvgLoot\loot_action.sqf";
    waitUntil {scriptDone _script};

    // Furniture around the player, a category each (0 civil, 1 military, 2 industrial). The fridge is one of Ravage's
    // food containers: it only ever holds food.
    private _furniture = [];
    {
        _x params ["_class", "_offset", "_category"];

        if (isClass (configFile >> "CfgVehicles" >> _class)) then {
            private _object = createVehicle [_class, _center vectorAdd _offset, [], 0, "CAN_COLLIDE"];
            _object setDir (_center getDir _object) + 180;
            _object setVariable ["_bldCategory", _category];
            _furniture pushBack _object;
        };
    } forEach [
        ["Land_Fridge_01_closed_F", [0, 3, 0], 0],
        ["Land_ShelvesWooden_F", [2.5, 2, 0], 0],
        ["Land_OfficeCabinet_01_F", [-2.5, 2, 0], 0],
        ["Land_Metal_rack_F", [3.5, -0.5, 0], 1],
        ["Land_CashDesk_F", [-3.5, -0.5, 0], 2]
    ];

    missionNamespace setVariable ["AIO_ravageFurniture", _furniture];

    // Ravage's scan sets rvg_lootTarget [object, model] for the furniture the player looks at; here only for these: the
    // nearest piece in reach that lies in front of the player's eyes (props have no geometry cursorObject always sees).
    [{
        private _eye = eyePos player;
        private _view = getCameraViewDirection player;
        private _near = (AIO_ravageFurniture select {
            (player distance _x) < 2.5 && {(_view vectorCos ((getPosASL _x) vectorAdd [0, 0, 0.8] vectorDiff _eye)) > 0.7}
        }) apply {[player distance _x, _x]};

        _near sort true;

        if (_near isEqualTo []) then {
            rvg_lootTarget = nil;
        } else {
            private _target = (_near select 0) select 1;
            rvg_lootTarget = [_target, (getModelInfo _target) select 0];
        };

        // The action on the player while there is a target, as Ravage's scan has it (its player variable) - a mod may
        // take it off to put its own on.
        if (!isNil "rvg_lootTarget" && {isNil {player getVariable "rvg_lootSearchAction"}}) then {
            player setVariable ["rvg_lootSearchAction", fnc_lootSearchAction call BIS_fnc_holdActionAdd];
        };
    }, 0.1] call CBA_fnc_addPerFrameHandler;

    player addAction ["Reset Ravage searches", {
        {
            private _position = getPosASL _x;
            private _found = missionNamespace getVariable ["foundLoot" + str _position, objNull];

            // Arma Inventory Overhaul's hidden box, or the pile Ravage's own search left.
            if (_found isEqualType objNull && {!isNull _found}) then {
                deleteVehicle _found;
            };

            {
                missionNamespace setVariable [_x + str _position, nil, true];
            } forEach ["dailyLootManager_", "rvgLootTimeStamp_", "foundLoot"];
        } forEach AIO_ravageFurniture;

        systemChat "AIO_Ravage: all furniture can be searched again.";
    }, nil, 0, false, true];

    systemChat "AIO_Ravage: look at a piece of furniture and hold Search.";
};
