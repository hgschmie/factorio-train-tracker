# Train Tracker

Track what all the trains are doing.

## Features

Train Tracker records:

- time and distance traveled
- time spent waiting at stops and signals
- last, current and next station
- current and total freight moved by a train

![Distance/Time](https://github.com/hgschmie/factorio-train-tracker/raw/main/portal/gui-1.png)
![Stations](https://github.com/hgschmie/factorio-train-tracker/raw/main/portal/gui-2.png)
![Freight](https://github.com/hgschmie/factorio-train-tracker/raw/main/portal/gui-3.png)

Limit, Filter and sorting settings persist across the tabs (it is possible to sort by distance and then switch to another tab to look e.g. at the freight). Freight is sorted by the number of different items/fluids transported.

## Hotkey

The GUI hotkey by default is 'Control + Shift + T' (Option + Shift + T for macOS).

## Support for mod that move trains around

There are a number of mods that provide "travel" for trains (e.g. between surfaces or through portals). Those generally work in the same way: They create a clone of a train in a different location (maybe even a different surface), then assign the schedule of the original train to that clone and then destroy the original train.

Train Tracker generally doesn't know that a train is a clone of another train. So it will create a new train and all the stats (time, distance, freight etc.) of the original train is lost. However, it is possible to add support for such mods to Train Tracker if they offer an API that the train tracker can hook into.

Starting with version 1.1.0, it does support [Space Exploration](https://mods.factorio.com/mod/space-exploration) and its Space Elevator.

### Supporting Space Exploration (and how to support other mods)

All the support is in [the space exploration module](https://github.com/hgschmie/factorio-train-tracker/blob/main/lib/other-mods/space-exploration.lua). In addition, the mod needs to be registered in the [main module](https://github.com/hgschmie/factorio-train-tracker/blob/main/lib/this.lua).

- create a table that will contain all the functionality
- train tracker will call the `runtime` function when it initialized in the runtime stage. *Important* Do not load any dependencies outside this function that require runtime specific globals (such as `script` or `game`). The file will be loaded in all stages of the Factorio lifecycle and only the `runtime` method is guaranteed to be called only in the runtime stage.
- setup `on_load` and `on_init` events. You can use all functionality from the builtin `stdlib` library. In the Space Exploration case, there are two mod events that the train-tracker subscribes to, one when teleport starts and one when teleport ends.
- It also registers a blacklist function to suppress an internal entity ("se_tug") which will not show in the train tracker. This is a temporary train that gets created to nudge the actual train through the space elevator and it does not need to show on the GUI.

When the Space Elevator moves a train from the planet into orbit (or back), it fires the `space-exploration:on_train_teleport_started` event. When this happens,

- the existing train info for the old train is marked as "will be renamed". That locks down the internal statistics so that removing the old train will not delete it (otherwise, when a train gets deleted, it removes all its internal statistics)
- updates the "current_station" field as the train has reached the space elevator
- processes the internal "arrivalUpdate" so that all the statistics are correct

When the train has been successfully moved, Space Exploration fires the `space-exploration:on_train_teleport_finished` event. Now train tracker will

- finish the actual renaming by unlocking the statistics for the old train and assigning them to the new train
- mark the current stop as not temporary (the current stop is now the other end of the space elevator) in the train tracker statistics. This is necessary to ensure that the departure update is actually applied.
- finally update the internal statistics as if the train were leaving a regular stop.

To support other mods, they should

- provide an API where train tracker can register for events. If the mod does not have an API it can not be supported
- provide events that fire at the start and the finish of a train move operation.
- the `start` event SHOULD contain information about the old and new train. It MUST be fired *before* the old train is destroyed. It SHOULD contain a reference to the old and new `LuaTrain` object. At a minimum, it MUST contain either old or new and the train id of the other.
- the `finish` event SHOULD also contain information about the old and new train. The "old" train information MUST be the same as in the `start` event. The "new" MAY be the same or a different train. Similar to the start event, one of the two MUST be a `LuaTrain` object, the other can be a number.

Space Exploration provides the "old train" id as a number and the "new train" information as a `LuaTrain` object. If you want to implement an API for your mod, you should model your API on the Space Exploration API.

----

## Legal and other stuff

(C) 2025 Henning Schmiedehausen (hgschmie)

Report Bugs either directly [on github](https://github.com/hgschmie/factorio-train-tracker/issues) (preferred!) or on the [Mod discussion forum](https://mods.factorio.com/mod/train-tracker/discussion). Pull requests for mod support or questions are very welcome.

I occasionally hang out [on the official Factorio discord](https://discord.gg/factorio). Find me on `#mod-dev-help` or `#mod-dev-discussion`.
