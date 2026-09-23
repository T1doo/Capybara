# Stage 3 UI visual direction — reusable prototype

This is a working component direction for CAP-0520, not an approved final UI master. The purpose is to make the pause, settings, inventory, storage and key-remapping screens read as one family while keeping the existing real controls, localization and keyboard/controller focus behavior. The reusable Godot resource is [`storybook_ui_theme.tres`](../../game/scenes/ui/storybook_ui_theme.tres).

- Panel: warm parchment `#f2e9cf`, deep sage text `#304138`, a broad 20px corner and a shaded edge. It separates UI from the painted world without baking letters into art.
- Action controls: deep river-green `#31574f`, light text, 10px corners. Hover brightens and gains an ochre border; pressed darkens. The `hover_pressed` combination has an explicit style because omitting it made one selected CheckButton draw white text on bare parchment at English 150% scale.
- Focus: a 3px outer pale-gold ring with extra margin, visually different from normal, hover and press even without relying on hue alone. The real pause/settings fixture navigates keyboard and synthetic controller actions through the screens.
- Disabled: light muted panel and dark text, instead of the active dark-green surface. Dynamic inventory and storage slot buttons inherit the same focus language.
- Danger actions: reusable warm umber `DangerButton` variation for leaving the game or discarding an item. It changes the surface as well as the border while keeping the same focus ring and legible light text.
- Storage: six columns on each side at the 1280px prototype size, so translated item names stay readable and the panel fits horizontally; the item count and transfer semantics are unchanged.

Final prototype Compatibility GPU screenshots are in ignored `build/art-pipeline/preview_ui_storybook_final_20260923` and `build/art-pipeline/inventory_storage_storybook_final_20260923`. Earlier trial captures remain in separate build folders and show the missing combination state and overflowing storage layout before repair. The final screenshots verify the named prototype views on this machine, not full four-resolution or physical-controller acceptance. The existing responsive scroll behavior remains for constrained displays.

The current design still needs a custom panel/9-slice surface, approved iconography and typography, a proper title screen and interaction prompt, texture/material harmony with the final environment, and visual checks at all target resolutions and high-contrast modes. Do not mark CAP-0520 or Stage 3 complete from this flat-color prototype.
