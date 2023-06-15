# Factorio FilteredLinkedChests

This is a mod for [Factorio](http://factorio.com) that adds a container type
Filtered Linked Chest, each of which globally shares contents with every other
chest of a specified item type.

![Demonstration 1](action1.mp4)
![Demonstration 2](action2.mp4)
![Demonstration 3](action3.mp4)

# How to use

Unlock the technology (requirements configurable in Mod Settings -> Startup)
to access the recipe to craft a Filtered Linked Chest. Crafting cost is also
configurable in Mod Settings -> Startup, along with inventory size.

Once placed, the chest is able to hold a single item type. All chests for a
given item type are "linked", meaning putting e.g. iron ore in one chest will
make it accessible in every chest set to iron ore. The item filter can be set
in several ways:
* In the chest GUI by picking the item type manually
* Copy-pasting from another Filtered Linked Chest, assembling machine (anything
  with a recipe), furnace, burner, rocket silo, lab, or mining drill. Shift +
  right-click to paste inputs, shift + alt + right-click to paste outputs.
  Recipes with multiple inputs/outputs will be cycled through for subsequent
  pastes from the same machine.
* Using the area-select tool. Any chest with a neighboring inserter or mining
  drill will set its recipe to the input or output of the connected entity in
  the same fashion as copy-pasting.