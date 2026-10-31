// Eden: leave a crate, a vehicle or a body out of the search. The box sits in the category the locks addon made ("Enhanced
// Inventory" in an object's attributes, which this addon loads after). The expression marks the object on every machine
// when the mission starts, so it needs no broadcast and a player who joins later has it as well; it runs in the running
// mission, not in the editor itself (!is3DEN). The mark is the same one aio_gui_fnc_setSearchable sets.
class Cfg3DEN {
    class Object {
        class AttributeCategories {
            class AIO_Attributes {
                class Attributes {
                    class GVAR(edenNoSearch) {
                        displayName = CSTRING(Eden_NoSearch);
                        tooltip = CSTRING(Eden_NoSearch_Tooltip);
                        property = QGVAR(edenNoSearch);
                        control = "Checkbox";
                        expression = QUOTE(if (!is3DEN && {_value}) then {_this setVariable [ARR_2('aio_noSearch',true)]});
                        defaultValue = "false";
                        typeName = "BOOL";
                        condition = "objectHasInventoryCargo";
                    };
                };
            };
        };
    };
};
