// Test mission for Arma Inventory Overhaul: a soldier with full gear, and around him what there is to loot -
// a crate, an ACE Arsenal box, a vehicle with things loaded into it (ACE cargo), a body, things on the
// ground (a vest with things in it), crates locked to a side and a long-range radio and an ACRE2 radio in
// the crate (TFAR or ACRE2 when that mod is loaded; a class a mod does not have only logs a line).
//
// Driven from outside through the clipboard, like the screenshot missions: every new
// "EINVCMD:<id>|<code>" on the clipboard is run once, spawned; what the code returns comes back on the
// clipboard as "EINVRES:<id>|<result>". Only works in singleplayer (Eden "Play Scenario").
if (!hasInterface) exitWith {};

[] spawn {
    sleep 1;

    // The hand-written mission.sqm has been known to load without a player.
    if (isNull player) then {
        private _unit = (createGroup west) createUnit ["B_Soldier_F", [4096, 4096, 0], [], 0, "NONE"];
        selectPlayer _unit;
    };

    waitUntil {!isNull player && {time > 0}};

    private _center = [4096, 4096, 0];
    player setPosATL _center;
    player setDir 0;

    // The player: a rifle with optic, pistol, launcher, vest full of magazines, a backpack of medical
    // things - enough to fill every column.
    player setUnitLoadout [
        ["arifle_MX_F", "muzzle_snds_H", "acc_pointer_IR", "optic_Hamr", ["30Rnd_65x39_caseless_mag", 30], [], "bipod_01_F_snd"],
        [],
        ["hgun_P07_F", "", "", "", ["16Rnd_9x21_Mag", 16], [], ""],
        ["U_B_CombatUniform_mcam", [["ACE_fieldDressing", 6], ["ACE_morphine", 2], ["ACE_tourniquet", 2], ["16Rnd_9x21_Mag", 2, 16]]],
        ["V_PlateCarrier1_rgr", [["30Rnd_65x39_caseless_mag", 6, 30], ["HandGrenade", 2, 1], ["SmokeShell", 2, 1]]],
        ["B_Kitbag_rgr", [["ACE_elasticBandage", 10], ["ACE_packingBandage", 10], ["ACE_quikclot", 10], ["ACE_epinephrine", 4], ["ACE_salineIV_500", 2], ["ACE_splint", 2], ["optic_Aco", 1]]],
        "H_HelmetB", "G_Combat",
        ["Binocular", "", "", "", [], [], ""],
        ["ItemMap", "ItemGPS", "ItemRadio", "ItemCompass", "ItemWatch", "NVGoggles"]
    ];

    // A crate with a bit of everything.
    private _crate = "Box_NATO_Ammo_F" createVehicle (_center vectorAdd [3, 2, 0]);
    clearItemCargoGlobal _crate;
    clearMagazineCargoGlobal _crate;
    clearWeaponCargoGlobal _crate;
    clearBackpackCargoGlobal _crate;
    _crate addMagazineCargoGlobal ["30Rnd_65x39_caseless_mag", 8];
    _crate addMagazineCargoGlobal ["100Rnd_65x39_caseless_mag", 2];
    _crate addMagazineCargoGlobal ["HandGrenade", 6];
    _crate addItemCargoGlobal ["ACE_fieldDressing", 20];
    _crate addItemCargoGlobal ["optic_Holosight", 1];
    _crate addWeaponCargoGlobal ["arifle_MX_SW_F", 1];
    _crate addBackpackCargoGlobal ["B_AssaultPack_rgr", 1];

    // An ACE Arsenal box.
    private _arsenal = "B_supplyCrate_F" createVehicle (_center vectorAdd [-3, 2, 0]);
    if (!isNil "ace_arsenal_fnc_initBox") then {
        [_arsenal, true] call ace_arsenal_fnc_initBox;
    };

    // A vehicle.
    private _vehicle = "B_MRAP_01_F" createVehicle (_center vectorAdd [0, 9, 0]);
    _vehicle setDir 90;
    _vehicle addItemCargoGlobal ["FirstAidKit", 4];

    // ACE cargo: a weapons crate loaded into the vehicle, and a spare wheel loaded by class (no object yet).
    private _cargoCrate = "Box_NATO_Wps_F" createVehicle (_center vectorAdd [6, 6, 0]);
    _cargoCrate addItemCargoGlobal ["ACE_fieldDressing", 5];

    if (!isNil "ace_cargo_fnc_loadItem") then {
        [_cargoCrate, _vehicle, true] call ace_cargo_fnc_loadItem;
        ["ACE_Wheel", _vehicle, 1, true] call ace_cargo_fnc_addCargoItem;
    };

    // Locks: one crate for OPFOR only (the player is BLUFOR), one for BLUFOR (open to him, with the open
    // padlock on its section).
    private _redCrate = "Box_East_Ammo_F" createVehicle (_center vectorAdd [5, -2, 0]);
    private _blueCrate = "Box_NATO_Support_F" createVehicle (_center vectorAdd [6, 1, 0]);

    if (!isNil "einv_locks_fnc_setLock") then {
        [_redCrate, "side", east] call einv_locks_fnc_setLock;
        [_blueCrate, "side", west] call einv_locks_fnc_setLock;
    };

    // Radios: a long-range backpack in the crate (TFAR), an ACRE2 radio (the ACRE2 profile).
    _crate addBackpackCargoGlobal ["TFAR_rt1523g", 1];
    _crate addItemCargoGlobal ["ACRE_PRC152", 1];

    // A body with its gear.
    private _body = (createGroup east) createUnit ["O_Soldier_F", _center vectorAdd [2, -3, 0], [], 0, "NONE"];
    _body setDamage 1;

    // Things on the ground, among them a vest with magazines in it.
    private _pile = createVehicle ["GroundWeaponHolder", _center vectorAdd [-2, -2, 0], [], 0, "CAN_COLLIDE"];
    _pile addItemCargoGlobal ["V_TacVest_khk", 1];
    _pile addMagazineCargoGlobal ["30Rnd_65x39_caseless_mag", 3];
    _pile addItemCargoGlobal ["ACE_morphine", 3];

    [] spawn {
        sleep 1;
        private _pile = (nearestObjects [player, ["GroundWeaponHolder"], 5]) param [0, objNull];
        private _vest = (everyContainer _pile) param [0, ["", objNull]];
        (_vest select 1) addMagazineCargoGlobal ["30Rnd_65x39_caseless_mag", 2];
    };

    EINVCMD_last = "";

    while {true} do {
        private _clip = copyFromClipboard;

        if ((_clip select [0, 8]) == "EINVCMD:" && {_clip != EINVCMD_last}) then {
            EINVCMD_last = _clip;

            private _bar = _clip find "|";
            private _id = _clip select [8, _bar - 8];
            private _code = compile (_clip select [_bar + 1]);

            [_id, _code] spawn {
                params ["_id", "_code"];

                private _result = call _code;

                if (isNil "_result") then {_result = "nil"};

                copyToClipboard format ["EINVRES:%1|%2", _id, _result];
                EINVCMD_last = copyFromClipboard;
            };
        };

        sleep 0.3;
    };
};
