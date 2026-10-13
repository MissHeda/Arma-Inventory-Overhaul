// The presets a rules text builds on: "base=default" in its first statement (einv_items_rules,
// einv_items_fnc_compileRules). A preset is a list of statements in the same language as the text,
// one statement per element and no commas in it. Its own base is read first and the preset's rules
// come after it, so they win - up to MAX_CHAIN presets deep.
//
//   name, description - for the setup wizard
//   revision          - shown only; base= always means the preset as installed
//   base              - the preset it builds on, "" for none
//   cell              - config mass per grid cell, -1 to leave it to its base or to the slider
//                       einv_items_massPerCell. cell= in a text's own header beats it.
//   rules[]           - its statements
//   class Groups      - the setup wizard's rows: a label, a family (its filter chip), an example
//                       class for the row's picture, and overlay = 1 for a group that overlaps the
//                       others on purpose (its rules go after theirs)
//
// The group ids are what own rules refer to (@mag_rifle > size=1x3): never rename one. Nor a preset's
// id: a text names it in base=. The one that was renamed (tarkov, now realism) is read under its new
// name (PRESET_ALIASES, fnc_parseRules) - unless a preset of the old name exists. Other mods may add presets
// of their own as classes here.
class CfgEinvRulesets {
    // Relaxed: the sizes and stacks from before rules existed, and a fifth more room in uniforms,
    // vests and backpacks than their load gives (grid=120%) - the owner found them tight once she
    // played with them; crates and vehicles stay by their load. The groups are a partition: an item
    // is in at most one of them (but medical, which is only a handle for the wizard), so that a rule
    // for one of them never reaches into another. The magazine groups leave each other out for that
    // reason.
    class default {
        name = CSTRING(Ruleset_Default);
        description = CSTRING(Ruleset_Default_Desc);
        revision = 2;
        base = "";
        cell = -1;
        rules[] = {
            "size=1x1 stack=1",

            "@rifle_light: kind=rifle mass<=55",
            "@rifle_medium: kind=rifle mass>55 mass<=90",
            "@rifle_heavy: kind=rifle mass>90 mass<=150",
            "@rifle_xheavy: kind=rifle mass>150",
            "@handgun: kind=handgun",
            "@launcher: kind=launcher",
            "@rifle_light > size=3x2",
            "@rifle_medium > size=4x2",
            "@rifle_heavy > size=5x2",
            "@rifle_xheavy > size=6x2",
            "@handgun > size=2x1",
            "@launcher > size=6x2",

            "@belt: kind=magazine rounds>=50 mass>15",
            "@rocket: kind=magazine rounds=1 mass>15 mass<=60",
            "@rocket_heavy: kind=magazine rounds=1 mass>60",
            "@mag_small: kind=magazine mass<=5",
            "@mag_rifle: kind=magazine mass>5 mass<=20 !@belt !@rocket",
            "@mag_large: kind=magazine mass>20 !@belt !@rocket !@rocket_heavy",
            "@grenade: kind=grenade",
            "@belt > size=2x2",
            "@rocket > size=1x3",
            "@rocket_heavy > size=2x3",
            "@mag_small > size=1x1",
            "@mag_rifle > size=1x2",
            "@mag_large > size=2x2",
            "@grenade > size=1x1 stack=5",

            "@optic_small: kind=optic mass<=8",
            "@optic_large: kind=optic mass>8",
            "@muzzle: kind=muzzle",
            "@rail_bipod: kind=rail|bipod",
            "@optic_small > size=1x1",
            "@optic_large > size=2x1",
            "@muzzle > size=2x1",
            "@rail_bipod > size=1x1",

            "@item_small: kind=item mass<=10",
            "@item_medium: kind=item mass>10 mass<=30",
            "@item_large: kind=item mass>30 mass<=60",
            "@item_xlarge: kind=item mass>60",
            "@item_small > size=1x1 stack=10",
            "@item_medium > size=2x1",
            "@item_large > size=2x2",
            "@item_xlarge > size=3x2",
            "@medical: cat=medical",

            "@assigned: kind=map|gps|radio|compass|watch",
            "@goggles: kind=goggles",
            "@nvg_binocular: kind=nvg|binocular",
            "@headgear: kind=headgear",
            "@assigned > size=1x1",
            "@goggles > size=1x1",
            "@nvg_binocular > size=2x1",
            "@headgear > size=2x2",

            "@uniform: kind=uniform",
            "@vest: kind=vest",
            "@backpack_small: kind=backpack load<=160",
            "@backpack_medium: kind=backpack load>160 load<=280",
            "@backpack_large: kind=backpack load>280",
            "@crate: kind=crate|vehicle",
            "@uniform > size=2x2 grid=120%",
            "@vest > size=3x3 grid=120%",
            "@backpack_small > size=3x3 grid=120%",
            "@backpack_medium > size=4x4 grid=120%",
            "@backpack_large > size=4x5 grid=120%",
            "@crate > grid=auto"
        };

        // Examples only where the class surely lands in that group; the others stay "" until they
        // have been checked in the game.
        class Groups {
            class rifle_light { name = CSTRING(Group_rifle_light); family = "weapons"; example = ""; };
            class rifle_medium { name = CSTRING(Group_rifle_medium); family = "weapons"; example = ""; };
            class rifle_heavy { name = CSTRING(Group_rifle_heavy); family = "weapons"; example = ""; };
            class rifle_xheavy { name = CSTRING(Group_rifle_xheavy); family = "weapons"; example = ""; };
            class handgun { name = CSTRING(Group_handgun); family = "weapons"; example = "hgun_P07_F"; };
            class launcher { name = CSTRING(Group_launcher); family = "weapons"; example = "launch_NLAW_F"; };
            class belt { name = CSTRING(Group_belt); family = "ammo"; example = "100Rnd_65x39_caseless_mag"; };
            class rocket { name = CSTRING(Group_rocket); family = "ammo"; example = ""; };
            class rocket_heavy { name = CSTRING(Group_rocket_heavy); family = "ammo"; example = ""; };
            class mag_small { name = CSTRING(Group_mag_small); family = "ammo"; example = ""; };
            class mag_rifle { name = CSTRING(Group_mag_rifle); family = "ammo"; example = "30Rnd_65x39_caseless_mag"; };
            class mag_large { name = CSTRING(Group_mag_large); family = "ammo"; example = ""; };
            class grenade { name = CSTRING(Group_grenade); family = "ammo"; example = "HandGrenade"; };
            class optic_small { name = CSTRING(Group_optic_small); family = "attachments"; example = ""; };
            class optic_large { name = CSTRING(Group_optic_large); family = "attachments"; example = ""; };
            class muzzle { name = CSTRING(Group_muzzle); family = "attachments"; example = "muzzle_snds_H"; };
            class rail_bipod { name = CSTRING(Group_rail_bipod); family = "attachments"; example = "acc_flashlight"; };
            class item_small { name = CSTRING(Group_item_small); family = "items"; example = ""; };
            class item_medium { name = CSTRING(Group_item_medium); family = "items"; example = ""; };
            class item_large { name = CSTRING(Group_item_large); family = "items"; example = ""; };
            class item_xlarge { name = CSTRING(Group_item_xlarge); family = "items"; example = ""; };
            class medical { name = CSTRING(Group_medical); family = "items"; example = "FirstAidKit"; overlay = 1; };
            class assigned { name = CSTRING(Group_assigned); family = "worn"; example = "ItemMap"; };
            class goggles { name = CSTRING(Group_goggles); family = "worn"; example = "G_Shades_Black"; };
            class nvg_binocular { name = CSTRING(Group_nvg_binocular); family = "worn"; example = "NVGoggles"; };
            class headgear { name = CSTRING(Group_headgear); family = "worn"; example = "H_HelmetB"; };
            class uniform { name = CSTRING(Group_uniform); family = "containers"; example = "U_B_CombatUniform_mcam"; };
            class vest { name = CSTRING(Group_vest); family = "containers"; example = "V_PlateCarrier1_rgr"; };
            class backpack_small { name = CSTRING(Group_backpack_small); family = "containers"; example = "B_AssaultPack_rgr"; };
            class backpack_medium { name = CSTRING(Group_backpack_medium); family = "containers"; example = "B_Kitbag_rgr"; };
            class backpack_large { name = CSTRING(Group_backpack_large); family = "containers"; example = "B_Carryall_cbr"; };
            class crate { name = CSTRING(Group_crate); family = "containers"; example = "Box_NATO_Ammo_F"; };
        };
    };

    // Realistic sizes: longer rifles, fixed grids per backpack size, vests as magazine rigs and
    // uniforms with four pockets. Stacks as in default - single bandages, one to a tile, were more
    // clicking than realism. Was "tarkov" until 0.4.0.
    class realism {
        name = CSTRING(Ruleset_Realism);
        description = CSTRING(Ruleset_Realism_Desc);
        revision = 2;
        base = "default";
        cell = -1;
        rules[] = {
            "@rifle_light > size=4x2",
            "@rifle_medium > size=5x2",
            "@rifle_heavy > size=6x2",
            "@rifle_xheavy > size=7x2",
            "@uniform > grid=pockets:4",
            "@vest > grid=rig",
            "@backpack_small > size=4x4 grid=4x5",
            "@backpack_medium > size=5x5 grid=5x6",
            "@backpack_large > size=5x6 grid=6x7"
        };
    };

    // Room follows weight: every item takes as many cells as it weighs, so a full grid is a full load -
    // which is why its containers keep exactly their load, not default's fifth more.
    class weight {
        name = CSTRING(Ruleset_Weight);
        description = CSTRING(Ruleset_Weight_Desc);
        revision = 2;
        base = "default";
        cell = 4;
        rules[] = {
            "size=mass",
            "@uniform|@vest|@backpack_small|@backpack_medium|@backpack_large > grid=auto",
            "@grenade|@item_small|@mag_small > stack=10"
        };
    };
};
