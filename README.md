# Factorio Unipipe

(see also my Unichest mod: https://mods.factorio.com/mod/Unichest)

This is a mod for [Factorio](http://factorio.com) that implements a type of
"Linked pipe". It adds 2 pump entities - Unipipe Filler and Unipipe Extracter -
which fill or extract from a per-fluid globally shared fluid storage, one per
fluid type.

![Demonstration](action1.gif)

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

# How it works

Each Unipipe is a set of hidden entities - an assembler, inserter, and linked chest.
The linked chest holds the shared storage for each fluid type. The mod generates a
hidden "fluid token" item for each fluid in the game (similar to a fluid barrel, but
without the barrel byproduct). Unipipe Fillers convert fluid to fluid tokens and store
them in the linked chest for that fluid type. Unipipe Extracters do the reverse.

The goal with this technique was to be UPS-efficient. There is no script running on-tick,
unlike other Linked Pipe mods I could find. Instead, the game itself handles the fluid
conversion and transport (using the built in linked-chest entities).

# Limitations

Fluid temperatures are not preserved by the Unipipe Extracters, because the fluid-to-item
conversion process loses the temperature information. This is solvable on a case-by-case
basis, but I can't think of a general case solution. In any case, Unipipe thus far makes
no attempt to address this issue, so fluids are yielded with their default temperatures.
(This means you can't transport 500 degree steam.)