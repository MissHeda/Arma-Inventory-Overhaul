// Sounds of the inventory, by family and action (einv_gui_fnc_playSound). Every file is Arma 3's own, from the
// base game's always-loaded PBOs, used by its path - nothing is shipped with this mod.
//
// A family is a class, its actions are classes inside it. An action sounds as one of its variants[], picked at
// random but never the same one twice in a row. A variant is up to three layers played together:
//     {file, volume, lowest pitch, highest pitch, offset in s, length in s (0 = to the end), delay in s}
// "@name" stands for the file of Surfaces >> name for the ground the player stands on (fnc_groundSurface), whose
// volume, offset and length it takes - the layer's volume is a factor then. "@getIn" / "@getOut" stands for the
// opened vehicle's own door sound. A layer whose file cannot be found is left out; a variant left empty plays
// fallback[] instead.
// use = "x": sounds as this family's x, times volume and pitch. world = 1: players up to range metres away hear
// it as well, at most one such sound every worldGap seconds (fnc_sendNoise).
// Volumes are levelled by the files' measured loudness: a main layer at its volume is as loud as 0.1.15's rustle.
// Mods and missions add families or replace actions here; an item picks its family with einv_sound = "name".

class CfgEinvSounds {
    class Surfaces {
        // A hand on the ground: {file, volume, offset, length}
        class crawl {
            dirt[] = {"a3\sounds_f\characters\crawl\Dirt_crawl_1.wss", 0.32, 0.15, 0.35};
            grass[] = {"a3\sounds_f\characters\crawl\Grass_crawl_1.wss", 0.76, 0.15, 0.35};
            gravel[] = {"a3\sounds_f\characters\crawl\Gravel_crawl_1.wss", 0.39, 0.15, 0.35};
            sand[] = {"a3\sounds_f\characters\crawl\Sand_crawl_1.wss", 0.71, 0.15, 0.35};
            hard[] = {"a3\sounds_f\characters\crawl\concrete_crawl_1.wss", 0.56, 0.15, 0.35};
            water[] = {"a3\sounds_f\characters\crawl\crawl_water_1.wss", 0.46, 0.25, 0.4};
            wood[] = {"a3\sounds_f\characters\crawl\concrete_crawl_1.wss", 0.56, 0.15, 0.35};
            metal[] = {"a3\sounds_f\characters\crawl\concrete_crawl_1.wss", 0.56, 0.15, 0.35};
            indoor[] = {"a3\sounds_f\characters\crawl\concrete_crawl_1.wss", 0.56, 0.15, 0.35};
        };
        class crawl2 {
            dirt[] = {"a3\sounds_f\characters\crawl\Dirt_crawl_2.wss", 0.41, 0.15, 0.35};
            grass[] = {"a3\sounds_f\characters\crawl\Grass_crawl_2.wss", 1.28, 0.15, 0.35};
            gravel[] = {"a3\sounds_f\characters\crawl\Gravel_crawl_2.wss", 0.47, 0.15, 0.35};
            sand[] = {"a3\sounds_f\characters\crawl\Sand_crawl_2.wss", 1.17, 0.15, 0.35};
            hard[] = {"a3\sounds_f\characters\crawl\concrete_crawl_2.wss", 1.02, 0.15, 0.35};
            water[] = {"a3\sounds_f\characters\crawl\crawl_water_2.wss", 0.69, 0.2, 0.4};
            wood[] = {"a3\sounds_f\characters\crawl\concrete_crawl_2.wss", 1.02, 0.15, 0.35};
            metal[] = {"a3\sounds_f\characters\crawl\concrete_crawl_2.wss", 1.02, 0.15, 0.35};
            indoor[] = {"a3\sounds_f\characters\crawl\concrete_crawl_2.wss", 1.02, 0.15, 0.35};
        };
        // Arma's own hand grenade landing on that ground, whole
        class grenade {
            dirt[] = {"a3\sounds_f\weapons\Grenades\handgrenade_drops\handg_drop_dirt_1.wss", 0.65, 0, 0};
            grass[] = {"a3\sounds_f\weapons\Grenades\handgrenade_drops\handg_drop_grass_2.wss", 0.58, 0, 0};
            gravel[] = {"a3\sounds_f\weapons\Grenades\handgrenade_drops\handg_drop_gravel_1.wss", 0.57, 0, 0};
            sand[] = {"a3\sounds_f\weapons\Grenades\handgrenade_drops\handg_drop_dirt_2.wss", 0.68, 0, 0};
            hard[] = {"a3\sounds_f\weapons\Grenades\handgrenade_drops\handg_drop_concrete_1.wss", 0.62, 0, 0};
            water[] = {"a3\sounds_f\weapons\Grenades\handgrenade_drops\handg_drop_water_1.wss", 1.01, 0, 0};
            wood[] = {"a3\sounds_f\weapons\Grenades\handgrenade_drops\handg_drop_wood_ext_1.wss", 0.55, 0, 0};
            metal[] = {"a3\sounds_f\weapons\Grenades\handgrenade_drops\handg_drop_metal_1.wss", 0.33, 0, 0};
            indoor[] = {"a3\sounds_f\weapons\Grenades\handgrenade_drops\handg_drop_interiors_2.wss", 0.54, 0, 0};
        };
    };

    // Anything without a family of its own - and, as a container, a crate.
    class Default {
        class lift {
            world = 1; range = 12; volume = 0.85;
            variants[] = {
                {{"a3\sounds_f\characters\stances\adjust_short1.wss", 0.48, 1.08, 1.2, 0, 0, 0}},
                {{"a3\sounds_f\characters\stances\adjust_short4.wss", 0.45, 1.08, 1.2, 0, 0, 0}},
                {{"a3\sounds_f\characters\stances\adjust_short5.wss", 0.44, 1.08, 1.2, 0, 0, 0}}
            };
        };
        class move {
            world = 1; range = 12; volume = 0.8;
            variants[] = {
                {{"a3\sounds_f\characters\stances\adjust_short2.wss", 0.31, 0.95, 1.05, 0, 0, 0}},
                {{"a3\sounds_f\characters\stances\adjust_short3.wss", 0.77, 0.95, 1.05, 0, 0, 0}},
                {{"a3\sounds_f\characters\stances\adjust_short1.wss", 0.48, 0.95, 1.05, 0, 0.35, 0}}
            };
        };
        class drop {
            world = 1; range = 15; volume = 1;
            variants[] = {
                {{"a3\sounds_f\characters\stances\adjust_short4.wss", 0.45, 0.9, 1, 0, 0, 0}, {"@crawl", 0.5, 0.95, 1.05, 0, 0, 0.12}},
                {{"a3\sounds_f\characters\stances\adjust_short5.wss", 0.44, 0.9, 1, 0, 0, 0}, {"@crawl2", 0.5, 0.95, 1.05, 0, 0, 0.12}}
            };
        };
        class equip {use = "move";};
        class unequip {use = "lift";};
        class attach {use = "move";};
        class detach {use = "attach"; pitch = 0.9;};
        class loadMag {use = "move";};
        class loadMagHandgun {use = "loadMag";};
        class loadMagLauncher {use = "loadMag";};
        class loadMagUgl {use = "loadMag";};
        class unloadMag {use = "lift";};
        class rotate {
            world = 0; volume = 0.6;
            variants[] = {
                {{"a3\sounds_f\arsenal\sfx\shared\zeroing_knob_tick_plastic.wss", 2.5, 0.9, 1, 0, 0, 0}, {"a3\sounds_f\characters\stances\adjust_short2.wss", 0.12, 1.4, 1.5, 0, 0.2, 0}},
                {{"a3\sounds_f\arsenal\sfx\shared\zeroing_knob_tick_plastic.wss", 2.5, 0.95, 1.05, 0, 0, 0}}
            };
        };
        class uncover {use = "lift"; volume = 0.6; pitch = 1.05; world = 0;};
        class inspect {use = "lift"; volume = 0.5; world = 0;};
        class giveBack {use = "move"; volume = 0.5; pitch = 0.82; world = 0;};
        // As a container: a crate's metal latch, things shifting inside
        class open {
            world = 1; range = 15; volume = 0.9;
            variants[] = {
                {{"a3\sounds_f\structures\doors\MetalDoors\MetalDoorsKnob.wss", 0.63, 0.95, 1.05, 0, 0, 0}, {"a3\sounds_f\characters\stances\adjust_short2.wss", 0.16, 0.95, 1.05, 0, 0, 0.15}},
                {{"a3\sounds_f\structures\doors\MetalDoors\MetalDoorsKnob.wss", 0.63, 1, 1.1, 0, 0, 0}, {"a3\sounds_f\characters\stances\adjust_short4.wss", 0.22, 0.95, 1.05, 0, 0, 0.12}}
            };
        };
        class close {
            world = 1; range = 15; volume = 0.75;
            variants[] = {
                {{"a3\sounds_f\characters\stances\adjust_short4.wss", 0.22, 0.95, 1.05, 0, 0, 0}, {"a3\sounds_f\structures\doors\MetalDoors\MetalDoorsKnob.wss", 0.63, 0.8, 0.86, 0, 0, 0.08}}
            };
        };
        class search {
            world = 1; range = 10; volume = 0.55; worldGap = 1;
            variants[] = {
                {{"a3\sounds_f\characters\stances\adjust_short1.wss", 0.48, 0.85, 0.95, 0, 0, 0}},
                {{"a3\sounds_f\characters\stances\adjust_short3.wss", 0.77, 0.85, 0.95, 0, 0, 0}},
                {{"a3\sounds_f\characters\stances\adjust_short5.wss", 0.44, 0.85, 0.95, 0, 0, 0}},
                {{"a3\sounds_f\characters\stances\adjust_short2.wss", 0.31, 0.85, 0.95, 0, 0, 0}, {"a3\sounds_f\weapons\Other\sfx1.wss", 0.27, 0.8, 0.9, 0, 0, 0.1}}
            };
        };
    };
    class crate: Default {};

    // Weapons: Arma's own sounds of a soldier lifting, lowering, resting and slinging them
    class rifle: Default {
        class lift {
            world = 1; range = 15; volume = 0.85;
            variants[] = {
                {{"a3\sounds_f\characters\stances\lift_rifle.wss", 1.48, 0.95, 1.05, 0, 0, 0}},
                {{"a3\sounds_f\characters\stances\lift_rifle.wss", 1.48, 0.95, 1.05, 0, 0, 0}, {"a3\sounds_f\characters\stances\weapon_resting_off.wss", 2.5, 0.95, 1.05, 0, 0, 0}}
            };
        };
        class move {
            world = 1; range = 15; volume = 0.8;
            variants[] = {
                {{"a3\sounds_f\characters\stances\low_rifle.wss", 1.54, 0.95, 1.05, 0, 0, 0}, {"a3\sounds_f\characters\stances\weapon_resting_on.wss", 0.69, 0.95, 1.05, 0, 0, 0.3}},
                {{"a3\sounds_f\characters\stances\rifle_lowering.wss", 0.9, 0.95, 1.05, 0, 0, 0}, {"a3\sounds_f\characters\stances\weapon_resting_on.wss", 0.69, 0.95, 1.05, 0, 0, 0.35}}
            };
        };
        class drop {
            world = 1; range = 20; volume = 1;
            variants[] = {
                {{"a3\sounds_f\characters\stances\rifle_lowering.wss", 0.9, 0.92, 1, 0, 0, 0}, {"a3\sounds_f\characters\stances\weapon_resting_on.wss", 0.69, 0.9, 1, 0, 0, 0.3}, {"@crawl", 0.6, 0.9, 1, 0, 0, 0.3}}
            };
        };
        class equip {
            world = 1; range = 15; volume = 1;
            variants[] = {{{"a3\sounds_f\characters\stances\unarmed_to_rifle.wss", 0.8, 0.97, 1.03, 0, 0, 0}}};
        };
        class unequip {
            world = 1; range = 15; volume = 0.95;
            variants[] = {{{"a3\sounds_f\characters\stances\rifle_to_unarmed.wss", 0.84, 0.97, 1.03, 0, 0, 0}}};
        };
    };
    class handgun: Default {
        class lift {
            world = 1; range = 12; volume = 0.85;
            variants[] = {{{"a3\sounds_f\characters\stances\lift_handgun.wss", 1.62, 0.95, 1.05, 0, 0, 0}}};
        };
        class move {
            world = 1; range = 12; volume = 0.8;
            variants[] = {{{"a3\sounds_f\characters\stances\low_handgun.wss", 1.8, 0.95, 1.05, 0, 0, 0}, {"a3\sounds_f\characters\stances\weapon_resting_on.wss", 0.5, 1.15, 1.25, 0, 0, 0.25}}};
        };
        class drop {
            world = 1; range = 15; volume = 1;
            variants[] = {{{"a3\sounds_f\characters\stances\low_handgun.wss", 1.8, 0.92, 1, 0, 0, 0}, {"@crawl", 0.5, 1.05, 1.15, 0, 0, 0.25}}};
        };
        class equip {
            world = 1; range = 12; volume = 1;
            variants[] = {{{"a3\sounds_f\characters\stances\unarmed_to_handgun.wss", 0.95, 0.97, 1.03, 0, 0, 0}}};
        };
        class unequip {
            world = 1; range = 12; volume = 0.95;
            variants[] = {{{"a3\sounds_f\characters\stances\handgun_to_unarmed.wss", 1.15, 0.97, 1.03, 0, 0, 0}}};
        };
    };
    class launcher: Default {
        class lift {
            world = 1; range = 15; volume = 0.85;
            variants[] = {{{"a3\sounds_f\characters\stances\lift_rifle.wss", 1.48, 0.8, 0.86, 0, 0, 0}, {"a3\sounds_f\characters\stances\adjust_short4.wss", 0.22, 0.8, 0.85, 0, 0, 0}}};
        };
        class move {
            world = 1; range = 15; volume = 0.8;
            variants[] = {{{"a3\sounds_f\characters\stances\low_rifle.wss", 1.54, 0.8, 0.86, 0, 0, 0}, {"a3\sounds_f\characters\stances\weapon_resting_on.wss", 0.69, 0.78, 0.82, 0, 0, 0.35}}};
        };
        class drop {
            world = 1; range = 20; volume = 1;
            variants[] = {{{"a3\sounds_f\characters\stances\rifle_lowering.wss", 0.9, 0.8, 0.86, 0, 0, 0}, {"@crawl", 0.7, 0.85, 0.9, 0, 0, 0.35}}};
        };
        class equip {
            world = 1; range = 15; volume = 1;
            variants[] = {{{"a3\sounds_f\characters\stances\unarmed_to_launcher.wss", 0.81, 0.97, 1.03, 0, 0, 0}}};
        };
        class unequip {
            world = 1; range = 15; volume = 0.95;
            variants[] = {{{"a3\sounds_f\characters\stances\launcher_to_unarmed.wss", 0.87, 0.97, 1.03, 0, 0, 0}}};
        };
    };

    // Weapon parts: small metal and polymer - clicks, ticks and clamps
    class part: Default {
        class lift {
            world = 1; range = 8; volume = 0.85;
            variants[] = {
                {{"a3\sounds_f\weapons\Closure\firemode_changer_3.wss", 0.59, 1, 1.1, 0, 0, 0}, {"a3\sounds_f\characters\movements\suit_sprint_04.wss", 0.2, 1.25, 1.35, 0, 0, 0}},
                {{"a3\sounds_f\weapons\Other\sfx2.wss", 0.57, 1, 1.1, 0, 0, 0}, {"a3\sounds_f\characters\movements\suit_sprint_01.wss", 0.24, 1.25, 1.35, 0, 0, 0}}
            };
        };
        class move {
            world = 1; range = 8; volume = 0.8;
            variants[] = {
                {{"a3\sounds_f\weapons\Other\sfx3.wss", 0.43, 0.95, 1.05, 0, 0, 0}, {"a3\sounds_f\characters\stances\adjust_short2.wss", 0.16, 1.35, 1.45, 0, 0, 0}},
                {{"a3\sounds_f\weapons\Other\sfx5.wss", 0.35, 0.95, 1.05, 0, 0, 0}, {"a3\sounds_f\characters\stances\adjust_short2.wss", 0.16, 1.35, 1.45, 0, 0, 0}}
            };
        };
        class drop {
            world = 1; range = 10; volume = 1;
            variants[] = {{{"a3\sounds_f\weapons\Other\sfx4.wss", 0.25, 0.9, 1, 0, 0, 0}, {"@crawl", 0.4, 1.1, 1.2, 0, 0, 0.05}}};
        };
        class equip {use = "attach";};
        class unequip {use = "detach";};
        class attach {
            world = 1; range = 10; volume = 1;
            variants[] = {{{"a3\sounds_f\weapons\Closure\firemode_changer_4.wss", 0.81, 0.95, 1.05, 0, 0, 0}, {"a3\sounds_f\weapons\Closure\closure_rifle_10.wss", 0.31, 0.95, 1.05, 0, 0, 0.12}}};
        };
        class detach {
            world = 1; range = 10; volume = 0.9;
            variants[] = {{{"a3\sounds_f\weapons\Closure\closure_rifle_10.wss", 0.31, 0.88, 0.92, 0, 0, 0}, {"a3\sounds_f\weapons\Closure\firemode_changer_5.wss", 0.86, 0.95, 1.05, 0, 0, 0.08}}};
        };
    };
    // A suppressor is screwed on: a turn, then it locks
    class muzzle: part {
        class attach {
            world = 1; range = 10; volume = 1;
            variants[] = {
                {{"a3\sounds_f\weapons\Closure\revolver_cylinder_turn_1.wss", 0.27, 0.95, 1.05, 0, 0, 0}, {"a3\sounds_f\weapons\Closure\closure_rifle_9.wss", 0.17, 0.95, 1.05, 0, 0, 0.3}},
                {{"a3\sounds_f\weapons\Closure\revolver_cylinder_turn_2.wss", 0.27, 0.95, 1.05, 0, 0, 0}, {"a3\sounds_f\weapons\Closure\closure_rifle_9.wss", 0.17, 0.95, 1.05, 0, 0, 0.3}}
            };
        };
        class detach {
            world = 1; range = 10; volume = 0.9;
            variants[] = {{{"a3\sounds_f\weapons\Closure\closure_rifle_9.wss", 0.17, 0.88, 0.92, 0, 0, 0}, {"a3\sounds_f\weapons\Closure\revolver_cylinder_turn_2.wss", 0.27, 0.85, 0.92, 0, 0, 0.08}}};
        };
    };
    // An optic slides along its rail, tick, tick, and its clamp closes
    class optic: part {
        class attach {
            world = 1; range = 10; volume = 1;
            variants[] = {{{"a3\sounds_f\arsenal\sfx\shared\zeroing_knob_tick_metal.wss", 2.5, 0.95, 1.05, 0, 0, 0}, {"a3\sounds_f\arsenal\sfx\shared\zeroing_knob_tick_metal.wss", 2.5, 1, 1.1, 0, 0, 0.07}, {"a3\sounds_f\weapons\Closure\closure_rifle_6.wss", 0.32, 0.95, 1.05, 0, 0, 0.18}}};
        };
        class detach {
            world = 1; range = 10; volume = 0.9;
            variants[] = {{{"a3\sounds_f\weapons\Closure\closure_rifle_6.wss", 0.32, 0.88, 0.92, 0, 0, 0}, {"a3\sounds_f\arsenal\sfx\shared\zeroing_knob_tick_metal.wss", 2.5, 0.9, 1, 0, 0, 0.1}}};
        };
    };
    class rail: part {};
    // A bipod snaps into place
    class bipod: part {
        class attach {
            world = 1; range = 10; volume = 1;
            variants[] = {{{"a3\sounds_f\weapons\Closure\closure_rifle_7.wss", 0.47, 0.95, 1.05, 0, 0, 0}, {"a3\sounds_f\arsenal\weapons\UGL\Closure_UGL.wss", 0.29, 0.95, 1.05, 0, 0, 0.15}}};
        };
        class detach {
            world = 1; range = 10; volume = 0.9;
            variants[] = {{{"a3\sounds_f\arsenal\weapons\UGL\Closure_UGL.wss", 0.29, 0.85, 0.9, 0, 0, 0}, {"a3\sounds_f\weapons\Closure\closure_rifle_7.wss", 0.47, 0.88, 0.92, 0, 0, 0.1}}};
        };
    };

    // Magazines: out of a pouch, a metal clink, seated with a click
    class magazine: Default {
        class lift {
            world = 1; range = 10; volume = 0.85;
            variants[] = {
                {{"a3\sounds_f\characters\movements\suit_sprint_02.wss", 0.28, 1.1, 1.2, 0, 0, 0}, {"a3\sounds_f\weapons\Other\sfx5.wss", 0.18, 0.95, 1.05, 0, 0, 0.05}},
                {{"a3\sounds_f\characters\movements\suit_sprint_05.wss", 0.3, 1.1, 1.2, 0, 0, 0}, {"a3\sounds_f\weapons\Other\sfx3.wss", 0.22, 0.95, 1.05, 0, 0, 0.05}},
                {{"a3\sounds_f\characters\movements\suit_sprint_06.wss", 0.29, 1.1, 1.2, 0, 0, 0}, {"a3\sounds_f\weapons\Closure\firemode_changer_2.wss", 0.27, 0.95, 1.05, 0, 0, 0.05}}
            };
        };
        class move {
            world = 1; range = 10; volume = 0.8;
            variants[] = {
                {{"a3\sounds_f\weapons\Grenades\Grenade_Drop.wss", 0.34, 1.3, 1.45, 0, 0, 0}, {"a3\sounds_f\characters\movements\suit_sprint_03.wss", 0.14, 1.2, 1.3, 0, 0, 0}},
                {{"a3\sounds_f\weapons\Grenades\Grenade_Drop.wss", 0.34, 1.3, 1.45, 0, 0, 0}, {"a3\sounds_f\characters\movements\suit_sprint_01.wss", 0.24, 1.2, 1.3, 0, 0, 0}}
            };
        };
        class drop {
            world = 1; range = 15; volume = 1;
            variants[] = {{{"a3\sounds_f\weapons\Grenades\Grenade_Drop.wss", 0.34, 1.15, 1.25, 0, 0, 0}, {"@crawl", 0.5, 1.1, 1.2, 0, 0, 0}}};
        };
        class loadMag {
            world = 1; range = 15; volume = 1;
            variants[] = {{{"a3\sounds_f\weapons\Grenades\Grenade_Drop.wss", 0.34, 1.4, 1.5, 0, 0, 0}, {"a3\sounds_f\weapons\Closure\closure_rifle_10.wss", 0.31, 0.95, 1.05, 0, 0, 0.1}}};
        };
        class loadMagHandgun {
            world = 1; range = 12; volume = 1;
            variants[] = {{{"a3\sounds_f\weapons\Grenades\Grenade_Drop.wss", 0.34, 1.5, 1.6, 0, 0, 0}, {"a3\sounds_f\weapons\Closure\closure_handgun_2.wss", 0.29, 0.95, 1.05, 0, 0, 0.08}}};
        };
        class loadMagLauncher {
            world = 1; range = 15; volume = 1;
            variants[] = {{{"a3\sounds_f\characters\movements\soldier_gear_run_03.wss", 0.49, 0.8, 0.85, 0, 0, 0}, {"a3\sounds_f\weapons\Closure\HMG_closure.wss", 0.17, 0.95, 1.05, 0, 0, 0.2}}};
        };
        class loadMagUgl {
            world = 1; range = 15; volume = 1;
            variants[] = {{{"a3\sounds_f\arsenal\weapons\UGL\Closure_UGL.wss", 0.29, 0.95, 1.05, 0, 0, 0}, {"a3\sounds_f\weapons\Other\sfx1.wss", 0.27, 0.95, 1.05, 0, 0, 0.06}}};
        };
        class unloadMag {
            world = 1; range = 10; volume = 0.9;
            variants[] = {{{"a3\sounds_f\weapons\Closure\firemode_changer_1.wss", 0.5, 0.95, 1.05, 0, 0, 0}, {"a3\sounds_f\characters\movements\suit_sprint_04.wss", 0.2, 1.1, 1.2, 0, 0, 0.08}}};
        };
    };
    class grenade: Default {
        class lift {
            world = 1; range = 10; volume = 0.85;
            variants[] = {{{"a3\sounds_f\characters\stances\adjust_short2.wss", 0.31, 1.25, 1.35, 0, 0, 0}, {"a3\sounds_f\weapons\Other\sfx3.wss", 0.22, 0.95, 1.05, 0, 0, 0.04}}};
        };
        class move {
            world = 1; range = 12; volume = 0.8;
            variants[] = {{{"a3\sounds_f\weapons\Grenades\Grenade_Drop.wss", 0.34, 0.95, 1.05, 0, 0, 0}}};
        };
        class drop {
            world = 1; range = 18; volume = 1;
            variants[] = {{{"@grenade", 1, 0.95, 1.05, 0, 0, 0}}};
        };
    };

    // Load-bearing gear: webbing, buckles and plates
    class vest: Default {
        class lift {
            world = 1; range = 12; volume = 0.85;
            variants[] = {
                {{"a3\sounds_f\characters\movements\soldier_gear_walk_05.wss", 0.32, 0.95, 1.05, 0, 0, 0}},
                {{"a3\sounds_f\characters\movements\soldier_gear_walk_07.wss", 0.86, 0.95, 1.05, 0, 0, 0}},
                {{"a3\sounds_f\characters\movements\soldier_gear_walk_02.wss", 0.79, 0.95, 1.05, 0, 0, 0}}
            };
        };
        class move {
            world = 1; range = 12; volume = 0.8;
            variants[] = {
                {{"a3\sounds_f\characters\movements\soldier_gear_walk_06.wss", 0.44, 0.95, 1.05, 0, 0, 0}, {"a3\sounds_f\characters\movements\suit_run_04.wss", 0.16, 0.95, 1.05, 0, 0, 0.05}},
                {{"a3\sounds_f\characters\movements\soldier_gear_walk_01.wss", 0.82, 0.95, 1.05, 0, 0, 0}, {"a3\sounds_f\characters\movements\suit_run_06.wss", 0.15, 0.95, 1.05, 0, 0, 0.05}}
            };
        };
        class drop {
            world = 1; range = 15; volume = 1;
            variants[] = {{{"a3\sounds_f\characters\movements\soldier_gear_walk_04.wss", 1.19, 0.9, 1, 0, 0, 0}, {"@crawl", 0.7, 0.9, 1, 0, 0, 0.15}}};
        };
        class equip {
            world = 1; range = 15; volume = 1;
            variants[] = {{{"a3\sounds_f\characters\movements\soldier_gear_walk_06.wss", 0.44, 0.95, 1.05, 0, 0, 0}, {"a3\sounds_f\characters\movements\suit_run_04.wss", 0.31, 0.95, 1.05, 0, 0, 0.1}, {"a3\sounds_f\characters\movements\soldier_gear_run_05.wss", 0.23, 0.95, 1.05, 0, 0, 0.35}}};
        };
        class unequip {
            world = 1; range = 15; volume = 0.95;
            variants[] = {{{"a3\sounds_f\characters\movements\soldier_gear_walk_04.wss", 1.19, 0.95, 1.05, 0, 0, 0}, {"a3\sounds_f\characters\movements\suit_run_06.wss", 0.3, 0.95, 1.05, 0, 0, 0.1}}};
        };
        class open {
            world = 1; range = 12; volume = 0.9;
            variants[] = {{{"a3\sounds_f\characters\movements\soldier_gear_run_05.wss", 0.45, 0.95, 1.05, 0, 0, 0}, {"a3\sounds_f\characters\movements\suit_run_02.wss", 0.13, 0.95, 1.05, 0, 0, 0.05}}};
        };
        class close {
            world = 1; range = 12; volume = 0.75;
            variants[] = {{{"a3\sounds_f\characters\movements\soldier_gear_run_03.wss", 0.49, 0.9, 0.95, 0, 0, 0}}};
        };
        class search {
            world = 1; range = 10; volume = 0.55; worldGap = 1;
            variants[] = {
                {{"a3\sounds_f\characters\movements\soldier_gear_run_01.wss", 0.84, 0.9, 1, 0, 0, 0}},
                {{"a3\sounds_f\characters\movements\soldier_gear_run_04.wss", 0.55, 0.9, 1, 0, 0, 0}},
                {{"a3\sounds_f\characters\movements\soldier_gear_run_06.wss", 0.84, 0.9, 1, 0, 0, 0}}
            };
        };
    };
    class backpack: Default {
        class lift {
            world = 1; range = 12; volume = 0.85;
            variants[] = {
                {{"a3\sounds_f\characters\movements\soldier_gear_walk_03.wss", 0.56, 0.95, 1.05, 0, 0, 0}, {"a3\sounds_f\characters\movements\suit_run_02.wss", 0.13, 0.95, 1.05, 0, 0, 0.05}},
                {{"a3\sounds_f\characters\movements\soldier_gear_walk_09.wss", 0.5, 0.95, 1.05, 0, 0, 0}, {"a3\sounds_f\characters\movements\suit_run_08.wss", 0.15, 0.95, 1.05, 0, 0, 0.05}}
            };
        };
        class move {
            world = 1; range = 12; volume = 0.8;
            variants[] = {
                {{"a3\sounds_f\characters\movements\soldier_gear_walk_08.wss", 0.81, 0.95, 1.05, 0.4, 0.7, 0}},
                {{"a3\sounds_f\characters\movements\soldier_gear_walk_01.wss", 0.82, 0.9, 0.95, 0, 0, 0}, {"a3\sounds_f\characters\movements\suit_walk_05.wss", 0.17, 0.95, 1.05, 0, 0, 0.1}}
            };
        };
        class drop {
            world = 1; range = 18; volume = 1;
            variants[] = {{{"a3\sounds_f\characters\movements\soldier_gear_walk_04.wss", 1.19, 0.85, 0.92, 0, 0, 0}, {"a3\sounds_f\characters\movements\suit_walk_05.wss", 0.17, 0.9, 1, 0, 0, 0}, {"@crawl", 0.8, 0.85, 0.95, 0, 0, 0.2}}};
        };
        class equip {
            world = 1; range = 15; volume = 1;
            variants[] = {{{"a3\sounds_f\characters\movements\soldier_gear_walk_08.wss", 0.88, 0.97, 1.03, 0, 0, 0}}};
        };
        class unequip {
            world = 1; range = 15; volume = 0.95;
            variants[] = {{{"a3\sounds_f\characters\movements\soldier_gear_walk_03.wss", 0.56, 0.95, 1.05, 0, 0, 0}, {"a3\sounds_f\characters\movements\suit_walk_07.wss", 0.17, 0.95, 1.05, 0, 0, 0.15}}};
        };
        class open {
            world = 1; range = 12; volume = 0.9;
            variants[] = {{{"a3\sounds_f\characters\movements\soldier_gear_walk_05.wss", 0.32, 0.95, 1.05, 0, 0, 0}, {"a3\sounds_f\characters\movements\suit_run_02.wss", 0.26, 0.95, 1.05, 0, 0, 0.05}}};
        };
        class close {
            world = 1; range = 12; volume = 0.75;
            variants[] = {{{"a3\sounds_f\characters\movements\suit_run_04.wss", 0.31, 0.88, 0.92, 0, 0, 0}, {"a3\sounds_f\characters\movements\soldier_gear_run_03.wss", 0.25, 0.95, 1.05, 0, 0, 0.05}}};
        };
        class search {
            world = 1; range = 10; volume = 0.55; worldGap = 1;
            variants[] = {
                {{"a3\sounds_f\characters\movements\suit_run_02.wss", 0.26, 0.85, 0.95, 0, 0, 0}},
                {{"a3\sounds_f\characters\movements\suit_run_06.wss", 0.3, 0.85, 0.95, 0, 0, 0}},
                {{"a3\sounds_f\characters\movements\soldier_gear_run_04.wss", 0.55, 0.9, 1, 0, 0, 0}}
            };
        };
    };
    // Cloth
    class uniform: Default {
        class lift {
            world = 1; range = 10; volume = 0.85;
            variants[] = {
                {{"a3\sounds_f\characters\movements\suit_walk_03.wss", 0.28, 0.95, 1.05, 0.1, 0.6, 0}},
                {{"a3\sounds_f\characters\movements\suit_run_08.wss", 0.29, 0.95, 1.05, 0, 0, 0}}
            };
        };
        class move {
            world = 1; range = 10; volume = 0.8;
            variants[] = {
                {{"a3\sounds_f\characters\movements\suit_run_04.wss", 0.31, 0.9, 1, 0, 0, 0}},
                {{"a3\sounds_f\characters\movements\suit_run_06.wss", 0.3, 0.9, 1, 0, 0, 0}}
            };
        };
        class drop {
            world = 1; range = 12; volume = 1;
            variants[] = {{{"a3\sounds_f\characters\movements\suit_walk_05.wss", 0.35, 0.9, 0.95, 0, 0, 0}, {"@crawl", 0.4, 0.95, 1.05, 0, 0, 0.2}}};
        };
        class equip {
            world = 1; range = 12; volume = 1;
            variants[] = {{{"a3\sounds_f\characters\movements\suit_walk_02.wss", 0.28, 0.95, 1.05, 0, 0, 0}, {"a3\sounds_f\characters\movements\suit_walk_07.wss", 0.33, 0.95, 1.05, 0, 0, 0.4}}};
        };
        class unequip {
            world = 1; range = 12; volume = 0.95;
            variants[] = {{{"a3\sounds_f\characters\movements\suit_walk_05.wss", 0.35, 0.95, 1.05, 0, 0, 0}, {"a3\sounds_f\characters\movements\suit_walk_03.wss", 0.28, 0.95, 1.05, 0.1, 0.6, 0.35}}};
        };
        class open {
            world = 1; range = 10; volume = 0.9;
            variants[] = {{{"a3\sounds_f\characters\movements\suit_run_02.wss", 0.26, 0.95, 1.05, 0, 0, 0}}};
        };
        class close {
            world = 1; range = 10; volume = 0.75;
            variants[] = {{{"a3\sounds_f\characters\movements\suit_sprint_03.wss", 0.28, 0.88, 0.92, 0, 0, 0}}};
        };
        class search {
            world = 1; range = 10; volume = 0.55; worldGap = 1;
            variants[] = {
                {{"a3\sounds_f\characters\movements\suit_sprint_01.wss", 0.48, 0.9, 1, 0, 0, 0}},
                {{"a3\sounds_f\characters\movements\suit_sprint_03.wss", 0.28, 0.9, 1, 0, 0, 0}},
                {{"a3\sounds_f\characters\movements\suit_sprint_05.wss", 0.3, 0.9, 1, 0, 0, 0}}
            };
        };
    };
    // Helmets, NVGs, goggles: a strap and a hollow plastic knock
    class headgear: Default {
        class lift {
            world = 1; range = 10; volume = 0.85;
            variants[] = {{{"a3\sounds_f\characters\stances\adjust_short5.wss", 0.44, 1, 1.1, 0, 0, 0}, {"a3\sounds_f\structures\doors\PlasticDoors\PlasticDoorsKnob.wss", 0.09, 1.3, 1.4, 0, 0, 0}}};
        };
        class move {
            world = 1; range = 10; volume = 0.8;
            variants[] = {{{"a3\sounds_f\structures\doors\PlasticDoors\PlasticDoorsSlam.wss", 0.09, 1.35, 1.45, 0, 0, 0}, {"a3\sounds_f\characters\stances\adjust_short2.wss", 0.16, 1.05, 1.15, 0, 0, 0}}};
        };
        class drop {
            world = 1; range = 12; volume = 1;
            variants[] = {{{"a3\sounds_f\structures\doors\PlasticDoors\PlasticDoorsSlam.wss", 0.12, 1.15, 1.25, 0, 0, 0}, {"@crawl", 0.5, 1, 1.1, 0, 0, 0}}};
        };
        class equip {
            world = 1; range = 10; volume = 1;
            variants[] = {{{"a3\sounds_f\characters\stances\adjust_short2.wss", 0.31, 1, 1.05, 0, 0, 0}, {"a3\sounds_f\structures\doors\PlasticDoors\PlasticDoorsKnob.wss", 0.09, 1.25, 1.35, 0, 0, 0.2}}};
        };
        class unequip {
            world = 1; range = 10; volume = 0.95;
            variants[] = {{{"a3\sounds_f\structures\doors\PlasticDoors\PlasticDoorsKnob.wss", 0.09, 1.35, 1.45, 0, 0, 0}, {"a3\sounds_f\characters\stances\adjust_short5.wss", 0.44, 1, 1.05, 0, 0, 0.08}}};
        };
    };

    // Medical: packets crinkle, a medic bag rips open - pieces of Arma's own first aid foley
    class medic: Default {
        class lift {
            world = 1; range = 8; volume = 0.85;
            variants[] = {
                {{"a3\sounds_f\characters\human-sfx\Other\firstaid_04.wss", 0.34, 0.95, 1.05, 0.15, 0.6, 0}},
                {{"a3\sounds_f\characters\human-sfx\Other\firstaid_06.wss", 0.56, 0.95, 1.05, 0.2, 0.45, 0}},
                {{"a3\sounds_f\characters\human-sfx\Other\firstaid_06.wss", 0.48, 0.95, 1.05, 2, 0.5, 0}}
            };
        };
        class move {
            world = 1; range = 8; volume = 0.8;
            variants[] = {
                {{"a3\sounds_f\characters\human-sfx\Other\firstaid_05.wss", 0.49, 0.95, 1.05, 0.35, 0.45, 0}},
                {{"a3\sounds_f\characters\human-sfx\Other\firstaid_05.wss", 0.35, 0.95, 1.05, 3.95, 0.45, 0}},
                {{"a3\sounds_f\characters\human-sfx\Other\fak1_loop.wss", 0.34, 0.95, 1.05, 3.3, 0.35, 0}}
            };
        };
        class drop {
            world = 1; range = 10; volume = 1;
            variants[] = {{{"a3\sounds_f\characters\human-sfx\Other\firstaid_01.wss", 0.52, 0.95, 1.05, 2.6, 0.6, 0}, {"@crawl", 0.4, 1, 1.1, 0, 0, 0.15}}};
        };
        class open {
            world = 1; range = 12; volume = 0.9;
            variants[] = {
                {{"a3\sounds_f\characters\ingame\AinvPknlMstpSlayWpstDnon_medicIn.wss", 0.73, 0.97, 1.03, 0, 0, 0}, {"a3\sounds_f\characters\human-sfx\Other\fak2_loop.wss", 0.13, 0.95, 1.05, 0.65, 0.7, 0.1}},
                {{"a3\sounds_f\characters\ingame\AinvPpneMstpSlayWpstDnon_medicIn.wss", 0.96, 0.97, 1.03, 0, 0, 0}, {"a3\sounds_f\characters\human-sfx\Other\fak2_loop.wss", 0.14, 0.95, 1.05, 3.2, 0.45, 0.1}}
            };
        };
        class close {
            world = 1; range = 10; volume = 0.75;
            variants[] = {{{"a3\sounds_f\characters\ingame\AinvPknlMstpSlayWpstDnon_medicOut.wss", 0.95, 0.97, 1.03, 0, 0, 0}}};
        };
        class search {use = "move";};
    };

    // Radios, GPS, UAV terminals, ACRE/TFAR radios: plastic clicks, a beep when switched on
    class device: Default {
        class lift {
            world = 1; range = 8; volume = 0.85;
            variants[] = {{{"a3\sounds_f\arsenal\sfx\shared\zeroing_knob_tick_plastic.wss", 2.5, 0.95, 1.05, 0, 0, 0}, {"a3\sounds_f\characters\stances\adjust_short2.wss", 0.16, 1.3, 1.4, 0, 0, 0}}};
        };
        class move {
            world = 1; range = 8; volume = 0.8;
            variants[] = {{{"a3\sounds_f\structures\doors\PlasticDoors\PlasticDoorsKnob.wss", 0.07, 1.5, 1.6, 0, 0, 0}, {"a3\sounds_f\arsenal\sfx\shared\zeroing_knob_tick_plastic.wss", 2, 0.95, 1.05, 0, 0, 0.03}}};
        };
        class drop {
            world = 1; range = 10; volume = 1;
            variants[] = {{{"a3\sounds_f\structures\doors\PlasticDoors\PlasticDoorsSlam.wss", 0.09, 1.45, 1.55, 0, 0, 0}, {"@crawl", 0.4, 1.1, 1.2, 0, 0, 0}}};
        };
        class equip {
            world = 1; range = 8; volume = 1;
            variants[] = {{{"a3\sounds_f\weapons\Closure\firemode_changer_2.wss", 0.54, 0.95, 1.05, 0, 0, 0}, {"a3\sounds_f\arsenal\sfx\shared\zeroing_knob_tick_plastic.wss", 2.5, 0.95, 1.05, 0, 0, 0.06}, {"a3\sounds_f\arsenal\Tools\MineDetector_Beep_01.wss", 0.07, 1.15, 1.25, 0, 0, 0.3}}};
        };
        class unequip {
            world = 1; range = 8; volume = 0.95;
            variants[] = {{{"a3\sounds_f\weapons\Closure\firemode_changer_5.wss", 0.86, 0.95, 1.05, 0, 0, 0}, {"a3\sounds_f\characters\stances\adjust_short3.wss", 0.31, 1.15, 1.25, 0, 0, 0.05}}};
        };
    };
    class binocular: device {
        class equip {
            world = 1; range = 10; volume = 1;
            variants[] = {{{"a3\sounds_f\characters\stances\unarmed_to_binoculars.wss", 2.5, 0.97, 1.03, 0, 0, 0}}};
        };
        class unequip {
            world = 1; range = 10; volume = 0.95;
            variants[] = {{{"a3\sounds_f\characters\stances\binoculars_to_unarmed.wss", 2.5, 0.97, 1.03, 0, 0, 0}}};
        };
    };

    // Containers opened, closed and searched
    class vehicle: Default {
        class open {
            world = 1; range = 15; volume = 0.9;
            variants[] = {{{"@getIn", 0.6, 1, 1, 0, 1.2, 0}}};
            fallback[] = {{"a3\sounds_f\structures\doors\GenericDoors\knob1.wss", 0.89, 0.95, 1.05, 0, 0, 0}};
        };
        class close {
            world = 1; range = 15; volume = 0.75;
            variants[] = {{{"@getOut", 0.6, 1, 1, 0, 1.2, 0}}};
            fallback[] = {{"a3\sounds_f\structures\doors\GenericDoors\knob1.wss", 0.89, 0.85, 0.9, 0, 0, 0}};
        };
        class search {
            world = 1; range = 10; volume = 0.55; worldGap = 1;
            variants[] = {
                {{"a3\sounds_f\characters\stances\adjust_short1.wss", 0.48, 0.8, 0.9, 0, 0, 0}},
                {{"a3\sounds_f\characters\movements\soldier_gear_run_04.wss", 0.55, 0.8, 0.9, 0, 0, 0}},
                {{"a3\sounds_f\characters\stances\adjust_short3.wss", 0.77, 0.8, 0.9, 0, 0, 0}}
            };
        };
    };
    class body: Default {
        class open {
            world = 1; range = 12; volume = 0.9;
            variants[] = {{{"a3\sounds_f\characters\movements\suit_walk_02.wss", 0.28, 0.95, 1.05, 0, 0, 0}, {"a3\sounds_f\characters\movements\soldier_gear_run_05.wss", 0.23, 0.95, 1.05, 0, 0, 0.15}}};
        };
        class close {
            world = 1; range = 12; volume = 0.75;
            variants[] = {{{"a3\sounds_f\characters\movements\suit_run_06.wss", 0.3, 0.9, 0.95, 0, 0, 0}}};
        };
        class search {
            world = 1; range = 10; volume = 0.55; worldGap = 1;
            variants[] = {
                {{"a3\sounds_f\characters\movements\suit_sprint_01.wss", 0.48, 0.9, 1, 0, 0, 0}},
                {{"a3\sounds_f\characters\movements\suit_sprint_05.wss", 0.3, 0.9, 1, 0, 0, 0}},
                {{"a3\sounds_f\characters\movements\soldier_gear_run_01.wss", 0.84, 0.9, 1, 0, 0, 0}},
                {{"a3\sounds_f\characters\movements\suit_sprint_03.wss", 0.28, 0.9, 1, 0, 0, 0}, {"a3\sounds_f\characters\movements\soldier_gear_run_03.wss", 0.25, 0.95, 1.05, 0, 0, 0.1}}
            };
        };
    };
    class ground: Default {
        class open {
            world = 1; range = 12; volume = 0.9;
            variants[] = {{{"@crawl", 1, 0.95, 1.05, 0, 0, 0}, {"a3\sounds_f\characters\stances\adjust_short4.wss", 0.22, 0.95, 1.05, 0, 0, 0.1}}};
        };
        class close {
            world = 1; range = 10; volume = 0.75;
            variants[] = {{{"a3\sounds_f\characters\stances\adjust_short1.wss", 0.48, 0.88, 0.92, 0, 0.35, 0}}};
        };
        class search {
            world = 1; range = 10; volume = 0.55; worldGap = 1;
            variants[] = {
                {{"@crawl", 1, 0.9, 1.1, 0, 0, 0}},
                {{"@crawl2", 1, 0.9, 1.1, 0, 0, 0}},
                {{"a3\sounds_f\characters\stances\adjust_short3.wss", 0.77, 0.9, 0.95, 0, 0, 0}, {"@crawl", 0.5, 0.95, 1.05, 0, 0, 0.1}}
            };
        };
    };
};
