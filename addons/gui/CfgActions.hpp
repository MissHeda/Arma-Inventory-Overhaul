// The engine's own "Open <backpack>" on a living soldier, offered only from behind and only for the
// backpack, gives way to the person's whole inventory (fnc_addPersonAction). show = 0 takes it off the
// action menu on every machine, the way vanilla hides TeamSwitch and SitDown; scripts can still run it
// (action ["OpenBag", unit]), as ACE's backpack interaction and its "Open <backpack>" on bodies do.
// ACE's own patch of the same class (showWindow = 0) merges with this one.
class CfgActions {
    class None;
    class OpenBag: None {
        show = 0;
    };
};
