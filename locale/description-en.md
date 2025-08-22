# Stronghold Crusader Automarket (UCP3)
This repository contains the source code for the Automarket extension.

The extension works with the [Unofficial Crusader Patch 3 framework](https://github.com/UnofficialCrusaderPatch/UnofficialCrusaderPatch), more information can be found [here](https://unofficialcrusaderpatch.github.io/).

## Features
- Integrated UI: the UI is integrated into the game.
- Works in Multiplayer: everyone needs to have the automarket extension activated.

## Upcoming features
- Market fee: buys and sales are more expensive and have less profit according to a preset percentage as set in the UCP3 GUI.
- Customisations: customisations can be added based on popular demand. 

## Known issues
Currently there is a stability issue which makes the game exe crash when the load bar is full.
I am investigating the issue, it has probably to do with a bug in the `cffi` library.

## Usage
A button has been added to the Market interface. Upon clicking it, a modal menu will open listing all goods, its stock, and the settings of the automarket.

Every in-game week, the automarket will sell and buy goods (in that order). To configure a goods type, click on it, and then adjust the sliders. When finished, click the checkmark icon to commit your new settings.

Pay attention that your buy cutoff is always lower than your sale cutoff, otherwise you risk spending all your gold on selling and immediately buying. There are countermeasures into the code to avoid this situation.
