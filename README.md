# Rush Duel Pack Simulator

A Godot-based simulator for opening Yu-Gi-Oh! Rush Duel card packs, building decks, managing binders, and creating banlists.

Special thanks to Konami for the amazing game we still don't have, and Cimoooooooo and Nyhmnim's progression series which inspired this for Rush Duel!
---

## Main Menu

The main menu is the central hub of the application. From here you can navigate to any of the four main tools:

- **Open Pack** — Simulate opening card packs
- **Deck Editor** — Build and manage Rush Duel decks
- **Binder Editor** — Organize your card collection into binders
- **Banlist Editor** — Create and manage custom banlists
- **Exit** — Close the application

---

## Pack Opening

### 1. Pack Selection Screen

After clicking **Open Pack**, you are taken to the pack selection screen.

- All available packs are displayed as image tiles in a grid.
- **Select a pack** by clicking its tile (radio button — only one pack can be selected at a time).
- Use the **SpinBox** to choose how many packs to open (e.g., 1, 5, 10...).
- Click **Open Pack** to proceed. The button is disabled until a pack is selected.
- A **Main Menu** button returns you to the hub at any time.

### 2. Pack Opening Screen

Cards are dealt face-down and must be revealed individually or all at once.

| Control | Description |
|---|---|
| **Flip Cards** | Reveals all face-down cards in the current pack with a short animation. |
| **Auto Flip** (toggle) | When enabled, cards flip automatically as each pack is generated. |
| **Next Pack** | Advances to the next pack. All cards in the current pack must be flipped first. |
| **Open Remaining** | Rapidly opens and flips all remaining packs in sequence, then unlocks save options. |

On the right side, a **summary panel** lists all cards pulled so far, grouped by rarity (Fabled, Marvel, Legendary, Majestic, Super Rare, Rare, Common) with a running total count.

Hovering over a card shows a **hover panel** with the card's full details.

#### Saving Opened Cards

Once all packs have been opened, the save controls become active:

- **Save Cards** — Saves the pulled cards to an existing binder selected from the **Binder List** dropdown.
- **Save As** — Prompts you to create a new binder and saves to it.
- **Add Binder** — Adds a new binder to the dropdown list without immediately saving.

---

## Binder Editor

The Binder Editor lets you organize and manage your card collection across named binders.

### Layout

The screen is split into two panels:

- **Left panel** — The currently selected binder's contents.
- **Right panel** — Your **All Cards** pool (the master collection), with a filter/search panel to narrow down cards.

### Workflow

1. Use the **Binder List** dropdown to select an existing binder, or click **Add Binder** to create a new one.
2. Browse or filter the All Cards pool on the left.
3. Click a card to add it to the active binder (up to 3 copies per card).
4. Hover over any card to see its full details in the hover panel.
5. Cards already in the binder show their quantity. Right-click or use the remove button on a card to decrease/remove it.
6. A **Banlist** dropdown lets you apply a banlist so restricted cards are visually flagged.

### Toolbar Buttons

| Button | Description |
|---|---|
| **Add Binder** | Creates a new named binder. |
| **Save** | Overwrites the current binder with the displayed cards. |
| **Save As** | Creates a new binder pre-populated with the current contents. |
| **Export** | Exports the binder's card list to a file. |
| **Delete** | Permanently removes the selected binder. |
| **Main Menu** | Returns to the main hub. |

---

## Deck Editor

The Deck Editor is used to build Rush Duel-legal decks from your binder collections.

### Layout

The screen has three sections on the right:

- **Main Deck** — Cards designated as your main deck.
- **Inventory** — Cards you own/plan to acquire (sideboard-style tracking).
- **Maybe** — Cards you're considering but haven't committed to.

On the left, the **BinderCards** panel shows a selected binder's card pool for browsing and adding.

### Workflow

1. Select a **Binder** from the top dropdown to populate the card pool.
2. Select a **Deck** from the Deck List dropdown, or click **Add Deck** to create a new one.
3. Click cards in the pool to add them to **Main**, **Inventory**, or **Maybe** sections (right-click or button context).
4. Hover over a card to see full details in the hover panel.
5. Optionally select a **Banlist** to see which cards are restricted, limited, or semi-limited.

### Deck-Building Rules (enforced automatically)

- Maximum **3 copies** of any single card across all three sections combined.
- Maximum **1 Legend card per card type** (Monster/Spell/Trap) across all sections.

### Toolbar Buttons

| Button | Description |
|---|---|
| **Add Deck** | Creates a new named deck. |
| **Save** | Saves changes to the currently selected deck. |
| **Save As** | Saves current cards as a new deck. |
| **Export** | Exports the deck list to a file. |
| **Main Menu** | Returns to the main hub. |

---

## Banlist Editor

The Banlist Editor lets you create custom restriction lists to use in the Deck Editor and Binder Editor.

### Layout

The left panel shows three restriction tiers:

- **Banned** — Cards that cannot be used.
- **Limited** — Cards restricted to 1 copy.
- **Semi-Limited** — Cards restricted to 2 copies.

The right panel shows the full All Cards pool for browsing.

### Workflow

1. Select a **Banlist** from the dropdown, or click **Add Banlist** to create one.
2. Click a card in the All Cards pool and assign it to a restriction tier.
3. Cards already in the banlist show their restriction status. Use the remove button to lift a restriction.
4. Hovering any card shows its details in the hover panel.

### Toolbar Buttons

| Button | Description |
|---|---|
| **Add Banlist** | Creates a new named banlist. |
| **Save** | Saves changes to the current banlist. |
| **Save As** | Saves current restrictions as a new banlist. |
| **Export** | Exports the banlist to a file. |
| **Delete** | Permanently removes the selected banlist. |
| **Main Menu** | Returns to the main hub. |

---

## Card Filters

A **filter panel** is available in the Binder Editor, Deck Editor, and Banlist Editor to narrow down the All Cards pool.

Available filters:

- **Attribute** — DARK, LIGHT, FIRE, WATER, WIND, EARTH, DIVINE (checkboxes)
- **Card Type** — Monster, Spell, Trap (checkboxes)
- **Monster Type** — Dragon, Warrior, Spellcaster, etc. (checkboxes)
- **Monster Ability** — Normal, Effect, Fusion, etc. (checkboxes)
- **Level / ATK / DEF** — Minimum value spinboxes (set to -1 to ignore)

Click **Set Filters** to apply, or **Clear Filters** to reset all selections.
