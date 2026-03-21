# 2D Arena Survival Játék — Tervezési Dokumentum

## Technológia

- **Motor:** Godot 4
- **Nyelv:** GDScript (vagy C#, később eldöntendő)
- **Platform:** PC (Windows és Linux)
- **Hálózat:** Godot beépített ENet-alapú multiplayer API (LAN)

## Játék Áttekintés

Crimsonland-stílusú, felülnézetes, pixel art aréna túlélő játék. A pálya nem szabad terep — akadályok (sziklák, folyók, hidak) taktikai pozícionálást tesznek lehetővé. LAN-on keresztül 2-4 játékos kooperatív módon játszhat együtt.

## Alap Játékmenet

### Irányítás
- **WASD** — mozgás
- **Egér** — célzás és lövés
- **E** — bolt megnyitása (vásárlási fázisban)
- Képesség-gombok — még meghatározandó

### Kör Struktúra
1. **Harci fázis** — Időzített hullám, szörnyek jelennek meg. Ha lejár az idő mielőtt az összes szörnyet megölnéd, a következő hullám is elindul a maradék mellé.
2. **Vásárlási fázis (~20 mp)** — E gomb megnyomásával bolt nyílik (Counter-Strike stílusú). Pénzből fegyvereket, képességeket és fejlesztéseket lehet venni.
3. **Ismétlés** — A hullámok egyre hosszabbak, több és erősebb szörnyekkel.
4. **Halál** — Ha minden játékos meghal, az eredmény felkerül a ranglistára.

### Nehézség Skálázás
- Minden hullám hosszabb, mint az előző
- Több és erősebb szörnyek hullámról hullámra
- Minden 5. hullám: **Főellenség (Boss)**

## Gazdaság

- Alap pénz minden túlélt hullámért
- Bónusz pénz minden megölt szörnyért
- Bónusz pénz, ha időn belül kiirtod a hullámot
- Fegyverek drágábbak, mint a képességek
- Meglévő fegyverek és képességek fejleszthetők (sebzés, cooldown, stb.)

## Fegyverek

| Fegyver | Leírás |
|---------|--------|
| Pisztoly | Alapfegyver, végtelen lőszer, alacsony sebzés |
| Sörétes puska | Közeli hatótáv, szóródás |
| Géppisztoly | Gyors tüzelés, alacsonyabb sebzés |
| Puska | Magas sebzés, lassú tüzelés |
| Rakétavető | Területi sebzés, önsebzés kockázata |
| Lángszóró | Rövid hatótáv, folyamatos sebzés |
|Minigun | Pontatlan, gyors, sokat sebez|

## Képességek (cooldown-alapúak)

| Képesség | Leírás |
|----------|--------|
| Kitérés (Dash) | Gyors kitérés a mozgás irányába=500 pénz (végtelenszer tudod használni) |
| Területi robbanás (AOE) | Sebzés a játékos körül=5000 pénz (végtelenszer tudod használni) |
| Pajzs | Ideiglenes (5 másodperc) sebzés-elnyelés=3000 pénz (végtelenszer tudod használni) |
| Akna | Robbanó csapda elhelyezése=200 pénz |
| Fagyasztó impulzus | Közeli ellenségek lassítása=4000 pénz (végtelenszer tudod használni) |
|Teleport | biztonságos (szörnymentes) helyre teleportál=5000 pénz (végtelenszer tudod használni)|


## Zsákmány (szörnyekből hullik harc közben)

- Egészség csomag
- Lőszer láda (nem pisztolyhoz)
- Ideiglenes sebesség növelés
- Ideiglenes sebzés növelés
- pénz csomag=100-500 (random, az 500-ra kisseb az esély)

## Szörnyek

| Típus | Leírás |
|-------|--------|
| Rajzó (Swarmer) | Gyors, gyenge, nagy csoportban jön=50 pénz |
| Páncélos (Tank) | Lassú, sok HP, nagy kontakt sebzés=500 Pénz |
| Távharcosok (Ranged) | Távolságot tartanak, lövedékeket lőnek=100pénz |
| Robbantó (Exploder) | A játékos felé rohan, közelségre/halálra robban=200 pénz |
|MegaMonster | Minigunal van felszerelve sok hp=500 pénz |

### Hullám Összetétel
- **1-5. hullám:** Főleg rajzók, minden pár hullámban új típus jelenik meg
- **6+ hullám:** Kevert összetétel, növekvő létszám
- Több játékos = több szörny

### Főellenségek (Boss) — minden 5. hullámnál
- Könnyebb reguláris hullám mellett jelennek meg
- Nagy sprite, egyedi támadási minták
- Garantált magas értékű jutalom
- Példák: Rohamozó óriás páncélos, Rajzókat szülő királynő, Területet ellenőrző tüzér

### Megjelenés (Spawn)
- Szörnyek az aréna széléről jelennek meg, a játékosok látómezején kívül
- A megjelenési ráta nő a hullám időzítőjével
- Főellenség megjelenése előtt figyelmeztető jelzés

## Pálya

- Felülnézetes élethű
- Első verzió: egyetlen, kézzel készített aréna
- Akadályok: sziklák, folyók, hidak — mozgást blokkolják, szűk átjárókat hoznak létre
- Későbbi cél: procedurális pályagenerálás

## Kamera

- Minden játékos saját képernyőt lát (LAN — mindenki saját gépen játszik)
- Kamera a játékosra központosítva

## Multiplayer

- LAN kooperatív mód, 2-4 játékos
- Nincs megosztott képernyő, van PvP

## Ranglista

- Végtelen túlélés — nincs győzelmi feltétel (minden 15-hullám után 1000 pénz)
- A pontszám felkerül a ranglistára halál után

---

## Nyitott Kérdések (még megbeszélendő)

1. **Képesség gombok** — Hány képesség-slot legyen egyszerre? Milyen billentyűk? (pl.  u,i,o,p)
2. **Halál és újraéledés** — Ha egy játékos meghal kooperatív módban, mi történik? Várnia kell a hullám végéig? és utána újraéled (a fegyvereit egy dobozban a halála helyén hagya)
3. **Játékos különbségek** — Minden játékos ugyanolyan? Vannak osztályok (class)=light=gyors kevés hp, normal=normál sebesség normál hp, heavy=lassú, sok hp
4.  Vagy csak kozmetikai különbségek Minden játékos egy random színt kap (Kék, Piros, Sárga, Lila)
5. **Ranglista részletek** — Helyi ranglista? LAN-on megosztott? Mi alapján számítódik a pontszám=pénz
6. **Pálya méret** — Mekkora legyen az aréna? Mekkora legyen a látható terület = 500X500 Méter
7. **Hang és zene** — Kell-e zene és hangeffektek az első verzióba= igen a spotyflyról erről a albumról rakj be zenéket = https://open.spotify.com/playlist/61KZG1N1Noh5B4qNa1HQ1y?si=20bdce3057e64336
8. **Grafikai asset-ek** — Saját élethű stilus Ingyenes asset pack-ek
9.  **Hálózati architektúra** — Az egyik játékos a host (host-client modell)
10. **Lobby és csatlakozás** — Hogyan találják meg egymást a játékosok LAN-on? Szoba létrehozás és IP cím beírás
11. **Szörny típusok jóváhagyása** — A fent leírt szörny típusok megfelelőek

---

## Következő Lépések

1. **Nyitott kérdések megválaszolása** — A fenti kérdéseket meg kell beszélni, mielőtt a fejlesztés elkezdődik
2. **Végleges tervezési dokumentum** — A válaszok alapján véglegesíteni a designt
3. **Implementációs terv készítése** — Részletes, lépésről lépésre haladó fejlesztési terv
4. **Godot 4 projekt létrehozása** — Projekt struktúra, alapbeállítások
5. **Prototípus** — Alap mozgás, lövés, egy szörny típus, egy pálya — a legegyszerűbb játszható verzió
6. **Hálózat** — LAN multiplayer implementálása
7. **Tartalom bővítés** — További fegyverek, képességek, szörnyek, bolt rendszer
8. **Tesztelés és egyensúlyozás** — Játékmenet finomhangolás
