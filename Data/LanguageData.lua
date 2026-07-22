local AS = AscensionSilencer
AS.Data = AS.Data or {}

AS.Data.languages = {
    Turkish = {
        words = {
            ["ve"] = 1, ["bir"] = 1, ["bu"] = 1, ["için"] = 2, ["icin"] = 2, ["ile"] = 1,
            ["oyuncu"] = 2, ["oyuncular"] = 2, ["arıyoruz"] = 3, ["ariyoruz"] = 3, ["aranıyor"] = 3,
            ["lazım"] = 2, ["lazim"] = 2, ["satılık"] = 3, ["satilik"] = 3, ["satıyorum"] = 3,
            ["alıyorum"] = 3, ["alınır"] = 3, ["uygun"] = 2, ["fiyat"] = 2, ["merhaba"] = 2,
            ["selam"] = 2, ["arkadaşlar"] = 2, ["gel"] = 1, ["katıl"] = 2, ["guildimize"] = 3,
            ["loncamıza"] = 3, ["takım"] = 2, ["grup"] = 1, ["davet"] = 2, ["var mı"] = 2,
        },
        phrases = {
            { "oyuncu arıyoruz", 4 }, { "oyuncu ariyoruz", 4 }, { "guildimize katıl", 4 },
            { "guildimize katil", 4 }, { "tank lazım", 3 }, { "tank lazim", 3 },
            { "uygun fiyat", 3 }, { "satılık dp", 4 }, { "satilik dp", 4 },
        },
        chars = { "ç", "ğ", "ı", "ö", "ş", "ü" },
    },
    SouthSlavic = {
        label = "Balkan / South Slavic",
        words = {
            ["i"] = 1, ["je"] = 1, ["za"] = 1, ["se"] = 1, ["da"] = 1, ["na"] = 1,
            ["smo"] = 2, ["sam"] = 1, ["ste"] = 2, ["ima"] = 1, ["treba"] = 2, ["tražimo"] = 3,
            ["trazimo"] = 3, ["igrače"] = 3, ["igrace"] = 3, ["igrača"] = 3, ["igraca"] = 3,
            ["pridruži"] = 3, ["pridruzi"] = 3, ["ceh"] = 2, ["gilda"] = 2, ["guilda"] = 2,
            ["prodajem"] = 3, ["kupujem"] = 3, ["cijena"] = 2, ["cena"] = 2, ["pozdrav"] = 2,
            ["ekipa"] = 2, ["ljudi"] = 2, ["večeras"] = 2, ["veceras"] = 2, ["može"] = 2, ["moze"] = 2,
        },
        phrases = {
            { "tražimo igrače", 5 }, { "trazimo igrace", 5 }, { "pridruži se", 4 },
            { "pridruzi se", 4 }, { "prodajem dp", 4 }, { "kupujem dp", 4 },
        },
        chars = { "č", "ć", "š", "ž", "đ" },
    },
    Slovenian = {
        words = {
            ["in"] = 1, ["za"] = 1, ["se"] = 1, ["smo"] = 2, ["iščemo"] = 3, ["iscemo"] = 3,
            ["igralce"] = 3, ["igralci"] = 2, ["pridruži"] = 3, ["pridruzi"] = 3,
            ["prodajam"] = 3, ["kupujem"] = 3, ["cena"] = 2, ["živjo"] = 2, ["zivjo"] = 2,
        },
        phrases = {
            { "iščemo igralce", 5 }, { "iscemo igralce", 5 }, { "pridruži se", 4 }, { "pridruzi se", 4 },
        },
        chars = { "č", "š", "ž" },
    },
    Albanian = {
        words = {
            ["dhe"] = 2, ["per"] = 1, ["për"] = 2, ["nga"] = 1, ["me"] = 1, ["kemi"] = 2,
            ["kerkojme"] = 3, ["kërkojmë"] = 3, ["lojtar"] = 2, ["lojtare"] = 3, ["lojtarë"] = 3,
            ["bashkohu"] = 3, ["shes"] = 3, ["blej"] = 3, ["cmim"] = 2, ["çmim"] = 2,
            ["pershendetje"] = 2, ["përshëndetje"] = 2,
        },
        phrases = {
            { "kërkojmë lojtarë", 5 }, { "kerkojme lojtare", 5 }, { "bashkohu me", 4 },
        },
        chars = { "ë", "ç" },
    },
    Romanian = {
        words = {
            ["și"] = 2, ["si"] = 1, ["pentru"] = 2, ["cu"] = 1, ["sunt"] = 2, ["caut"] = 2,
            ["căutăm"] = 3, ["cautam"] = 3, ["jucători"] = 3, ["jucatori"] = 3, ["alătură"] = 3,
            ["alatura"] = 3, ["vând"] = 3, ["vand"] = 3, ["cumpăr"] = 3, ["cumpar"] = 3,
            ["preț"] = 2, ["pret"] = 2, ["salut"] = 2, ["breaslă"] = 3, ["breasla"] = 3,
        },
        phrases = {
            { "căutăm jucători", 5 }, { "cautam jucatori", 5 }, { "alătură te", 4 }, { "alatura te", 4 },
        },
        chars = { "ă", "â", "î", "ș", "ţ", "ț" },
    },
    Polish = {
        words = {
            ["polska"] = 3, ["polski"] = 3, ["polskie"] = 3, ["gildia"] = 3,
            ["która"] = 2, ["ktora"] = 2, ["stale"] = 1, ["się"] = 1, ["sie"] = 1,
            ["rozrasta"] = 3, ["zaprasza"] = 3, ["wspólnej"] = 3, ["wspolnej"] = 3,
            ["rozgrywki"] = 3, ["przyszłości"] = 3, ["przyszlosci"] = 3,
            ["także"] = 2, ["takze"] = 2, ["które"] = 2, ["ktore"] = 2,
            ["czekamy"] = 3, ["weekendowym"] = 3, ["gracz"] = 3, ["gracze"] = 3,
            ["znajdzie"] = 3, ["miejsce"] = 2, ["ciebie"] = 2,
        },
        phrases = {
            { "polska gildia", 6 }, { "polski gildia", 5 },
            { "stale się rozrasta", 5 }, { "stale sie rozrasta", 5 },
            { "zaprasza do wspólnej rozgrywki", 6 }, { "zaprasza do wspolnej rozgrywki", 6 },
            { "w przyszłości także raidy", 5 }, { "w przyszlosci takze raidy", 5 },
            { "znajdzie się u nas miejsce", 6 }, { "znajdzie sie u nas miejsce", 6 },
            { "miejsce dla ciebie", 4 },
        },
        chars = { "ą", "ć", "ę", "ł", "ń", "ó", "ś", "ź", "ż" },
    },
    CzechSlovak = {
        label = "Czech / Slovak",
        words = {
            ["guilda"] = 3, ["nabírá"] = 4, ["nabira"] = 4, ["nábor"] = 3, ["nabor"] = 3,
            ["atmosféra"] = 2, ["atmosfera"] = 2, ["pohodová"] = 2, ["pohodova"] = 2,
            ["parta"] = 2, ["nováčci"] = 3, ["novacci"] = 3, ["novácci"] = 3,
            ["zkušení"] = 3, ["zkuseni"] = 3, ["hráči"] = 3, ["hraci"] = 3, ["hráci"] = 3,
            ["vítáni"] = 3, ["vitani"] = 3, ["každý"] = 2, ["kazdy"] = 2,
            ["místo"] = 2, ["misto"] = 2, ["přidej"] = 3, ["pridej"] = 3,
        },
        phrases = {
            { "guilda nabírá", 6 }, { "guilda nabira", 6 },
            { "chill atmosféra", 4 }, { "chill atmosfera", 4 },
            { "pohodová parta", 4 }, { "pohodova parta", 4 },
            { "nováčci i zkušení hráči vítáni", 8 }, { "novacci i zkuseni hraci vitani", 8 },
            { "novácci i zkušení hráci vítáni", 8 },
            { "každý má místo", 5 }, { "kazdy ma misto", 5 },
            { "whisper pro invite", 4 },
        },
        chars = { "á", "ä", "č", "ď", "é", "ě", "í", "ĺ", "ľ", "ň", "ó", "ô", "ŕ", "ř", "š", "ť", "ú", "ů", "ý", "ž" },
    },
    Spanish = {
        words = {
            ["y"] = 1, ["para"] = 2, ["con"] = 1, ["que"] = 1, ["somos"] = 2, ["busco"] = 2,
            ["buscamos"] = 3, ["jugadores"] = 3, ["unete"] = 3, ["únete"] = 3, ["vendo"] = 3,
            ["compro"] = 3, ["precio"] = 2, ["hola"] = 2, ["gente"] = 2, ["necesito"] = 2,
            ["más"] = 1, ["mas"] = 1, ["española"] = 3, ["espanola"] = 3,
            ["latam"] = 2, ["no"] = 1, ["whisp"] = 1, ["pancho"] = 1,
            ["si"] = 1, ["quieren"] = 3, ["susurrenme"] = 4, ["susúrrenme"] = 4,
            ["habla"] = 2, ["hispana"] = 3, ["hispano"] = 3, ["latina"] = 3, ["latino"] = 3,
            ["enfocada"] = 2, ["enfocado"] = 2, ["contenido"] = 2, ["reclutamos"] = 4,
            ["completar"] = 2, ["ambiente"] = 2,
        },
        phrases = {
            { "buscamos jugadores", 5 }, { "únete a", 4 }, { "unete a", 4 }, { "vendo dp", 4 },
            { "guild más española", 5 }, { "guild mas española", 5 },
            { "guild más espanola", 5 }, { "guild mas espanola", 5 },
            { "no latam", 3 }, { "whisp no latam", 4 },
            { "si quieren", 3 }, { "guild latam", 4 },
            { "susurrenme", 4 }, { "susúrrenme", 4 },
            { "habla hispana", 5 }, { "habla latina", 4 }, { "hispana latina", 4 },
            { "enfocada en", 3 }, { "enfocado en", 3 }, { "reclutamos gente", 5 },
            { "contenido pve", 3 }, { "contenido de classic", 4 }, { "ambiente chill", 3 },
        },
        chars = { "ñ", "¿", "¡" },
    },
    Portuguese = {
        words = {
            ["e"] = 1, ["para"] = 1, ["com"] = 1, ["somos"] = 2, ["procuro"] = 2,
            ["procuramos"] = 3, ["jogadores"] = 3, ["junte"] = 2, ["vendendo"] = 3,
            ["compro"] = 3, ["preço"] = 2, ["preco"] = 2, ["olá"] = 2, ["ola"] = 1,
            ["está"] = 1, ["esta"] = 1, ["portas"] = 2, ["abertas"] = 2,
            ["você"] = 2, ["voce"] = 2, ["participe"] = 3, ["batalhas"] = 2,
            ["muito"] = 1, ["todos"] = 1, ["são"] = 2, ["sao"] = 2,
            ["bem"] = 1, ["vindos"] = 2, ["veteranos"] = 2, ["novatos"] = 2,
            ["venha"] = 3, ["fazer"] = 1, ["parte"] = 1, ["nossa"] = 1,
            ["irmandade"] = 3, ["aguarda"] = 2,
        },
        phrases = {
            { "procuramos jogadores", 5 }, { "junte se", 4 }, { "vendendo dp", 4 },
            { "de portas abertas", 4 }, { "participe de raids", 4 },
            { "todos são bem vindos", 5 }, { "todos sao bem vindos", 5 },
            { "veteranos ou novatos", 4 }, { "venha fazer parte", 5 },
            { "nossa irmandade", 4 }, { "aguarda por você", 4 }, { "aguarda por voce", 4 },
        },
        chars = { "ã", "õ", "ç" },
    },
    French = {
        words = {
            ["et"] = 1, ["pour"] = 2, ["avec"] = 2, ["nous"] = 1, ["sommes"] = 2,
            ["cherche"] = 2, ["cherchons"] = 3, ["joueurs"] = 3, ["joueur"] = 3, ["rejoignez"] = 3,
            ["recrute"] = 4, ["recrutons"] = 4, ["ouvert"] = 2, ["ouverte"] = 2,
            ["tout"] = 1, ["type"] = 1, ["hordeux"] = 3,
            ["vends"] = 3, ["achète"] = 3, ["achete"] = 3, ["prix"] = 2, ["bonjour"] = 2,
        },
        phrases = {
            { "cherchons joueurs", 5 }, { "rejoignez nous", 4 }, { "vends dp", 4 },
            { "recrute des", 4 }, { "recrutons des", 4 },
            { "ouvert à tout type de joueur", 6 }, { "ouverte à tout type de joueur", 6 },
            { "ouvert a tout type de joueur", 6 }, { "ouverte a tout type de joueur", 6 },
            { "pour la horde", 4 },
        },
        chars = { "é", "è", "ê", "à", "ç" },
    },
    German = {
        words = {
            ["und"] = 2, ["für"] = 2, ["fur"] = 1, ["mit"] = 1, ["wir"] = 2, ["suchen"] = 3,
            ["sucht"] = 4, ["spieler"] = 3, ["beitreten"] = 3, ["verkaufe"] = 3, ["kaufe"] = 3,
            ["preis"] = 2, ["hallo"] = 2, ["brauchen"] = 2, ["gilde"] = 3,
            ["auf"] = 1, ["starke"] = 2, ["starken"] = 2, ["langfristige"] = 3,
            ["langfristigen"] = 3, ["anspruch"] = 3, ["oder"] = 1, ["erfolge"] = 2,
        },
        phrases = {
            { "wir suchen", 4 }, { "suchen spieler", 5 }, { "verkaufe dp", 4 },
            { "gilde sucht", 5 }, { "sucht starke", 5 }, { "sucht starken", 5 },
            { "langfristige spieler", 5 }, { "langfristigen spieler", 5 },
            { "spieler mit anspruch", 5 }, { "first kills auf", 4 },
        },
        chars = { "ä", "ö", "ü", "ß" },
    },
    Italian = {
        words = {
            ["e"] = 1, ["per"] = 1, ["con"] = 1, ["siamo"] = 2, ["cerco"] = 2,
            ["cerchiamo"] = 3, ["giocatori"] = 3, ["unisciti"] = 3, ["vendo"] = 3,
            ["compro"] = 3, ["prezzo"] = 2, ["ciao"] = 2, ["gilda"] = 3,
        },
        phrases = {
            { "cerchiamo giocatori", 5 }, { "unisciti a", 4 }, { "vendo dp", 4 },
        },
        chars = { "à", "è", "é", "ì", "ò", "ù" },
    },
}
