-- Development-only cases for the confidence-based Non-English scorer.
-- These deliberately use variants rather than exact copies of reported ads.
return {
    -- Swedish: generic recruitment and ordinary conversation should be detected.
    { message = "Svensk guild söker medlemmar för raids och dungeons", blocked = true, module = "NonEnglish" },
    { message = "Någon svensk som vill köra dungeon ikväll?", blocked = true, module = "NonEnglish" },
    { message = "Vi behöver fler spelare och gärna folk med bra humör", blocked = true, module = "NonEnglish" },

    -- Short or English-dominant messages should not be classified from one clue.
    { message = "Svenska", blocked = false },
    { message = "Välkomna", blocked = false },
    { message = "Söker", blocked = false },
    { message = "Anyone Swedish for MC?", blocked = false },
    { message = "Need tank och healer for raid", blocked = false },

    -- Spanish variants: vocabulary coverage should carry unseen wording.
    { message = "alguien sabe si vale la pena subir esta clase?", blocked = true, module = "NonEnglish" },
    { message = "buscamos gente nueva para jugar y completar contenido", blocked = true, module = "NonEnglish" },
    { message = "Alguien", blocked = false },
    { message = "Discord", blocked = false },

    -- Existing language profiles should still work without exact ad text.
    { message = "deutsche gilde sucht langfristige spieler", blocked = true, module = "NonEnglish" },
    { message = "guilde active cherche joueurs pour raids", blocked = true, module = "NonEnglish" },
    { message = "polska gildia rekrutuje graczy", blocked = true, module = "NonEnglish" },
    { message = "comunidade portuguesa procura membros", blocked = true, module = "NonEnglish" },
    { message = "nederlandse gilde zoekt spelers", blocked = true, module = "NonEnglish" },

    -- Hungarian: normal vocabulary coverage should generalize beyond one ad.
    { message = "Magyar céh aktív játékosokat keres raidekre", blocked = true, module = "NonEnglish" },
    { message = "Új tagokat várunk, csatlakozz hozzánk", blocked = true, module = "NonEnglish" },
    { message = "Valaki tudja, hol lehet jelentkezni a csapatba?", blocked = true, module = "NonEnglish" },
    { message = "Magyar", blocked = false },
    { message = "Keresi", blocked = false },
    { message = "Need aktív DPS for raid", blocked = false },
    { message = "LF magyar guild", blocked = false },

    -- Common WoW vocabulary must not become language evidence by itself.
    { message = "LFM raid tonight need 2 dps and healer", blocked = false },
    { message = "Need group for mythic dungeon, invite please", blocked = false },
}
