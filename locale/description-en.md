# Automarket
This extension provides an automarket

## Features
- Integrated UI: the UI is integrated into the game.
![ui integration](https://raw.githubusercontent.com/gynt/ucp-extension-automarket/refs/heads/main/locale/ui-automarket-button.png)
- Works in Multiplayer: everyone needs to have the automarket extension activated.

## Troubleshooting & Known issues
Currently there is a stability issue which makes the game exe crash randomly after the game has loaded (or later).
There is an option in the Customisations tab to hopefully prevent the crash (if this was the cause).

It is called: *Disable Just-in-Time (LuaJIT) which would degrade performance*
Mark the checkbox to prevent the crash.

![stability setting](https://raw.githubusercontent.com/gynt/ucp-extension-automarket/refs/heads/main/locale/stability-debugging-setting.png)

Is your game still crashing? Please report!

## How it works
A button has been added to the Market interface. Upon clicking it, a modal menu will open listing all goods, its stock, and the settings of the automarket.

Every in-game week, the automarket will sell and buy goods (in that order). To configure a goods type, click on it, and then adjust the sliders. When finished, click the checkmark icon to commit your new settings.

Pay attention that your buy cutoff is always lower than your sale cutoff, otherwise you risk spending all your gold on selling and immediately buying. There are countermeasures into the code to avoid this situation.
