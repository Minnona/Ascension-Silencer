# Ascension Silencer

Ascension Silencer is a configurable chat filter for Project Ascension.

It can filter:

- Guild recruitment advertisements
- Non-English messages, including Balkan, Turkish, Spanish and Portuguese text
- Donation Point and Bazaar Token buying or selling spam
- Twitch, Kick and livestream advertisements
- Cross-channel duplicates and repeatedly spammed messages

Public channels are filtered by default. Say and Yell are optional.

## Channel Hygiene

Channel Hygiene keeps public chat organized without hiding the first appropriate copy of a legitimate post.

By default it can:

- Keep buying, selling, trading and crafting-service posts in Trade
- Hide commercial copies posted outside Trade
- Hide unrelated conversation and LFG posts from Trade
- Suppress rapid copies of the same message across several public channels
- Throttle repeated messages from the same sender
- Use a shorter cooldown for LFG and LFM posts

Default timing:

- Cross-channel duplicate window: 12 seconds
- General repeat cooldown: 60 seconds
- LFG/LFM repeat cooldown: 30 seconds
- Fallback Trade channel: `/4`

All Channel Hygiene options and cooldowns are adjustable under **Interface → AddOns → Ascension Silencer → Channel Hygiene**.

Duplicate matching ignores capitalization, raid markers, decorative symbols, repeated punctuation and extra spaces. Meaningful changes such as a different item, price, quantity, dungeon or requested role are treated as a new message.

Channel filters cannot remove a message that has already appeared. Commercial posts are therefore routed by hiding obvious commercial content outside Trade rather than waiting for a later Trade copy.

## Settings

Type `/as` in game.

All settings are also available under **Interface → AddOns → Ascension Silencer**:

- **Filters** — enable or tune individual content filters
- **Exceptions** — whitelist trusted players and phrases
- **Channel Hygiene** — configure routing, duplicate suppression and repeat cooldowns
- **Review** — inspect up to 100 blocked messages in a scrollable history

## Installation

### Windows

1. Download and extract the addon.
2. Place the `AscensionSilencer` folder inside:

```text
C:\AscensionWoW\resources\ascension-live\Interface\AddOns\
```

The final folder should be:

```text
C:\AscensionWoW\resources\ascension-live\Interface\AddOns\AscensionSilencer\
```

### Linux

1. Download and extract the addon.
2. Place the `AscensionSilencer` folder inside:

```text
~/AscensionWoW/resources/ascension-live/Interface/AddOns/
```

The final folder should be:

```text
~/AscensionWoW/resources/ascension-live/Interface/AddOns/AscensionSilencer/
```

Use the location of your own AscensionWoW folder if it is installed elsewhere.

## License

Ascension Silencer is licensed under GPL-3.0-only. Anyone may use, study, modify and redistribute it under the same license.
