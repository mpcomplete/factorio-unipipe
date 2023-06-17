# Factorio Unipipe

(see also my Unichest mod: https://mods.factorio.com/mod/Unichest)

This is a mod for [Factorio](http://factorio.com) that implements a type of
"Linked pipe". It adds 2 pump entities - Unipipe Filler and Unipipe Extracter
- which fill or extract from a per-fluid globally shared fluid storage, one per
fluid type.

![Demonstration 1](action1.gif)
![Demonstration 2](action2.gif)
![Demonstration 3](action3.gif)

# How to use

Unlock the technology (requirements configurable in Mod Settings -> Startup)
to access the recipe to craft the Unipipes. Crafting cost is also
configurable in Mod Settings -> Startup, along with storage size.

Once placed, connect a Filler pump to a fluid network to fill the global storage
with the connected fluid type. Elsewhere, connect an Extracter pump to extract
that fluid from global storage.

The fluid type to fill/extract is automatically determined by from the pipes
connected to it. If this should fail (it can be finnicky), you can either
reconstruct the pump, set the fluid type in the pump's GUI, or use Unichest's
selection tool to reset the fluid filter.