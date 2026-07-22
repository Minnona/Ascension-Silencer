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

Channel Hygiene keeps posts in the right public channel and reduces repeated spam from the same sender.

- Commercial posts are kept in Trade and hidden elsewhere
- Non-commercial posts can be hidden from Trade
- Cross-channel duplicates are suppressed
- Repeated messages are throttled with adjustable cooldowns
- LFG/LFM posts use a shorter cooldown by default

Configure it under **Interface → AddOns → Ascension Silencer → Channel Hygiene**.

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
