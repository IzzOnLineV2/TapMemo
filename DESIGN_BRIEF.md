# TapMemo — Design Brief

Brief completo per il redesign di TapMemo: nuova icona, design system, interfaccia,
widget e asset marketing per l'App Store.

**Come si usa.** Il documento è scritto per essere dato a un designer — umano o a Claude
Design. Puoi incollarlo tutto, oppure una parte alla volta: ogni parte è autonoma.
Se lo usi a pezzi, anteponi sempre le sezioni *Il prodotto* e *Vincoli tecnici*, che fanno
da contesto a tutte le altre.

**Ordine di lavoro consigliato.** Parte 1 (icona) → Parte 2 (token) → Parte 3 (schermate)
→ Parte 4 (widget) → implementazione → Parte 5 (App Store). La Parte 5 va per ultima
perché i poster devono mostrare l'interfaccia vera dell'app pubblicata.

---

## Il prodotto

TapMemo trasforma una frase parlata in un memo e, se le parole contengono una data o
un'ora, crea automaticamente l'evento in Calendario o il promemoria in Promemoria.
Claim: **"Parla, ed è in calendario."**

Un solo gesto: tap sul microfono → parli (*"ricordami la spesa domani alle 3"*) → il testo
viene trascritto, un parser italiano ne estrae titolo e data → l'evento è creato.
Nessun account, nessun backend, nessun tracking: tutto resta sul dispositivo e scrive solo
nel calendario dell'utente.

- **Pubblico:** utenti italiani, età mista, uso in mobilità (in auto, per strada, con una mano).
- **Lingua sorgente:** italiano, localizzata anche in inglese. Tutte le copy dei mockup in italiano.
- **Tono del brand:** rapido, essenziale, affidabile, *invisibile*. L'app deve sparire in 3 secondi.
- **Proprietà:** IzzOnLine di Stefania Izzo. Il nome resta "TapMemo".
- Il codice è MIT, ma **nome, icona e branding non sono coperti dalla licenza**.

---

## Stato attuale — cosa non va

Audit del repository al 21/09/2026.

### Icona

`TapMemo/Assets.xcassets/AppIcon.appiconset/1024.png`: sfera blu lucida con gradiente,
microfono bianco al centro, anello orbitale con sei pallini, la scritta "TAPMEMO" in bianco
sotto e una fogliolina sulla "O".

- Il wordmark dentro l'icona è illeggibile sotto i 60 px e viola le HIG.
- Lo stile *glossy sphere* è fermo al 2012 e stona con iOS 26.
- `Contents.json` dichiara le apparenze **dark** e **tinted** *senza `filename`*: sono
  placeholder vuoti. Non esiste nessun `.icon` di Icon Composer per il Liquid Glass.
- I 35 PNG dell'`appiconset` diventeranno superflui una volta adottato Icon Composer.

### Interfaccia

`TapMemo/ContentView.swift`, schermata unica:

- `Color.blue` / `Color.red` scritti a mano, nessun token.
- `AccentColor.colorset` è **vuoto** in entrambi i target (app e widget): l'accento è il blu
  di sistema per default, cioè nessuna scelta di brand.
- `List` + `Divider` = aspetto Xcode-default.
- Badge "EVENT / REMINDER / NOTE" in maiuscolo inglese dentro un'interfaccia italiana.
- Lo stato del memo è comunicato **tre volte in tre linguaggi diversi**: badge maiuscolo,
  riga di testo "In Calendario", pallino colorato nel widget.
- Nessun empty state al primo avvio.
- Durante la registrazione c'è solo un cerchio che pulsa: `VoiceManager` non pubblica il
  livello audio e ha `shouldReportPartialResults = false`, quindi niente waveform e niente
  trascrizione live. **Queste due scelte di design richiedono una modifica al codice.**
- Errori e permessi negati finiscono in una `alert` di sistema anonima.

### Widget

`TapMemo/TapMemoWidget.swift`: stesso blu grezzo, `containerBackground(.fill.tertiary)`,
nessuna variante Lock Screen, StandBy o Control Center.

---

## Vincoli tecnici (non negoziabili)

- iOS 26.2+, SwiftUI + SwiftData, **solo iPhone** (`TARGETED_DEVICE_FAMILY = 1`: no iPad, no Mac).
- **Zero librerie esterne.** Tutto dev'essere realizzabile con SwiftUI nativo, SF Symbols e
  Icon Composer. Niente illustrazioni raster custom, niente font a pagamento: SF Pro e stili
  di sistema con Dynamic Type.
- Design language **iOS 26 (Liquid Glass)**: materiali traslucidi, profondità, bordi morbidi,
  concentricità dei raggi rispetto al corner radius del display. Niente skeuomorfismo, niente
  gradienti lucidi anni 2010, niente ombre pesanti.
- Light e Dark mode, Dynamic Type fino alle taglie accessibilità, Reduce Motion, Increase
  Contrast. Contrasto minimo WCAG AA (4.5:1 sul testo).

---

## Parte 1 — Nuova icona app

Priorità massima. Sostituisce l'icona descritta sopra.

Progetta una nuova icona che:

1. **Non contenga testo** né wordmark.
2. Esprima il concetto centrale — *la voce che diventa tempo/agenda* — non solo "un microfono".
   Esplora almeno **3 direzioni concettuali diverse**, per esempio:
   - onda vocale che si trasforma in linee/griglia di calendario,
   - impulso/ripple del *tap* che si propaga e si chiude in un cerchio-orologio,
   - forma astratta a bolla di memo con un accento temporale,
   e proponi anche direzioni non elencate qui.
3. Sia leggibile e riconoscibile a **29 pt** (Impostazioni), **60 pt** (Home) e **1024 pt**
   (App Store): una sola idea forte, massimo 2-3 elementi, silhouette chiara.
4. Sia costruita su **livelli separati** per Icon Composer (background / middle / foreground),
   perché iOS 26 li usa per generare profondità, specularità e varianti di sistema. Ogni
   concept va consegnato con i livelli espliciti e separabili.
5. Includa le **4 apparenze**: Default (light), Dark, Clear e Tinted. La tinted è
   monocromatica e il colore lo decide l'utente: la forma deve reggere in solo-bianco su
   fondo neutro.
6. Regga il confronto sulla Home accanto a Calendario, Promemoria, Note e Memo Vocali di
   Apple — mockup di una schermata Home per verificarlo.

**Consegna per ogni concept:** 1024 px, 180 px, 120 px, 60 px, 29 px affiancati, più tinted
e dark. Poi una raccomandazione finale motivata.

---

## Parte 2 — Design system

Definisci i token, pronti da tradurre in un Asset Catalog e in un file Swift di costanti.

- **Palette.** Un colore accento di brand — oggi è il blu di sistema di default, cioè nessuna
  scelta — con un'identità riconoscibile che non litighi con i colori semantici di iOS. Più i
  colori di stato già usati dall'app: calendario, promemoria, nota locale, successo, errore,
  registrazione in corso. Ogni colore con valore light e dark.
- **Tipografia.** Scala basata sugli stili di sistema, con i pesi per titolo memo, data,
  trascrizione originale, badge.
- **Spaziature, corner radius, elevazione/materiali, durate e curve di animazione.**
- **Icone.** Mappa ogni concetto a un SF Symbol preciso.

---

## Parte 3 — Schermate dell'app

L'app oggi è una sola schermata: un grosso cerchio microfono in alto, un `Divider`, e sotto
una lista di memo con swipe action. Molto funzionale, visivamente anonima.

Ridisegna questi stati, **tutti in light e dark**:

1. **Idle** — pulsante di registrazione + lista memo. È la schermata principale.
2. **Empty state** — primo avvio, nessun memo: oggi manca del tutto. Deve insegnare in una riga
   cosa dire (*"prova: ricordami la spesa domani alle 3"*).
3. **Recording** — l'utente sta parlando. Serve un feedback vivo che reagisce alla voce
   (livello audio / waveform) e, se possibile, la trascrizione parziale in tempo reale.
   Progetta anche come si annulla.
4. **Processing** — parsing e creazione evento in corso (oggi è una `ProgressView` nuda).
5. **Conferma** — il memo è diventato un evento: oggi è un banner verde generico in alto.
   Serve una conferma che mostri **cosa** è stato creato e **quando**, e permetta di correggere
   o annullare subito.
6. **Riga memo** nella lista. Ogni memo ha titolo normalizzato, data/ora opzionale, la
   trascrizione originale (*"🎤 così come l'hai detta"*) e uno stato fra tre: in Calendario,
   in Promemoria, solo in TapMemo. Unifica i tre linguaggi visivi attuali in uno solo, in italiano.
7. **Swipe action** sulla riga: Calendario, Promemoria, Condividi, Elimina. Le prime due
   compaiono solo se il memo non è già lì.
8. **Errore / permessi negati** — microfono, riconoscimento vocale, calendario o promemoria
   rifiutati. Oggi è una alert di sistema anonima.

Per ogni schermata annota le **note di accessibilità**: label VoiceOver, target tap ≥ 44 pt,
comportamento con Dynamic Type grande, alternativa per Reduce Motion.

---

## Parte 4 — Widget ed estensioni

Esistono già widget small / medium / large che mostrano i memo recenti e un pulsante che apre
la registrazione via deep link `tapmemo://record`. Sono grigi e generici.

Ridisegnali coerenti con la nuova identità, e proponi in più:

- widget **Lock Screen** (circolare, rettangolare, inline),
- un controllo per **Control Center / Action Button** per registrare senza aprire l'app,
- come appare il widget in **StandBy** e in **tinted mode**.

---

## Parte 5 — Asset marketing per l'App Store

I "poster" promozionali che l'utente vede nella scheda prima di scaricare l'app.

### Specifiche tecniche

- Formato principale: **iPhone 6.9" verticale, 1320 × 2868 px** (accettato anche 1290 × 2796).
  È l'unico set obbligatorio: l'App Store scala automaticamente per gli altri formati, e
  TapMemo è solo iPhone, quindi niente set iPad.
- Fino a 10 immagini: progettane **7**.
- **Due localizzazioni complete**: italiano (it-IT, principale) e inglese (en-US). Le headline
  italiane sono mediamente il 20% più lunghe: il layout deve reggere entrambe senza cambiare
  gabbia né ridurre il corpo del testo.
- Anche un **poster frame** verticale per l'App Preview video, sulla stessa gabbia grafica ma
  leggibile come copertina isolata.
- Extra: una versione **1:1** e una **16:9** della prima immagine, per social e comunicati stampa.

> Le specifiche Apple cambiano spesso: verifica i formati correnti in App Store Connect prima
> dell'export finale.

### Regole non negoziabili

1. Le **prime 3** immagini sono le uniche visibili nei risultati di ricerca, spesso affiancate
   e alte 3 cm. La headline deve restare leggibile a quella dimensione: testo grande, poche
   parole, alto contrasto. Progettale pensando prima alla miniatura, poi al dettaglio.
2. Le schermate mostrate **devono essere l'interfaccia reale** dell'app ridisegnata (Parte 3):
   Apple rifiuta le schede con screenshot che non corrispondono all'app. Nessuna funzione
   inventata, nessuna UI che non esiste.
3. **Mockup del dispositivo**: cornice iPhone neutra e corretta per il modello, oppure
   schermate a pieno formato senza cornice. Nessun logo Apple, nessuna riproduzione
   approssimativa dell'hardware.
4. **Coerenza totale** con l'icona e i token delle Parti 1 e 2: stesso accento, stessa
   tipografia, stesse curve. Galleria e icona devono sembrare la stessa cosa vista da due distanze.
5. Niente claim che l'app non può mantenere, niente prezzi, niente badge finti tipo "App
   dell'anno", niente riferimenti ad altre piattaforme.
6. Nelle schermate uniforma la **status bar** (ora, batteria, segnale) su tutte le immagini.

### Le 7 immagini

1. **Hero.** La promessa in una riga: la voce che diventa un appuntamento.
   Headline it: *"Parla. È in calendario."* (proponi 3 alternative). Schermata: registrazione in corso.
2. **Il cuore dell'app.** La frase detta a voce che si trasforma in evento: *"ricordami la
   spesa domani alle 3"* → titolo pulito + data + evento creato. È la funzione che nessun
   concorrente fa in italiano: rendila visivamente **la trasformazione**, non due schermate affiancate.
3. **Italiano vero.** Il parser capisce *domani, dopodomani, sabato 25, stasera, a mezzogiorno,
   alle 3* letto come le 15. Mostra la ricchezza delle espressioni riconosciute senza
   trasformarlo in un elenco noioso.
4. **Calendario e Promemoria.** Un memo diventa evento automatico se ha una data; con uno swipe
   lo mandi anche in Promemoria, lo condividi o lo elimini. Mostra le swipe action reali.
5. **Widget.** Widget home nelle tre misure e registrazione con un tap dalla schermata di
   blocco, senza aprire l'app.
6. **Privacy.** Nessun account, nessun server, nessun tracker, nessun SDK di terze parti: tutto
   resta sul telefono e scrive solo nel *tuo* calendario. In Italia è un argomento di vendita
   forte: trattalo come tale, non come una postilla legale.
7. **Chiusura.** Invito all'azione + icona grande. È quella che vede chi ha scorso tutto: deve
   chiudere il cerchio con la prima.

### Sistema grafico

Non 7 immagini scollegate, ma un **sistema**:

- Una gabbia unica: posizione della headline, posizione e scala del dispositivo, margini di
  sicurezza, ritmo dello sfondo che scorre da un'immagine alla successiva.
- Gerarchia a due livelli: headline breve (max 5 parole) + eventuale sottotitolo di una riga.
  Mai più di due righe di testo per immagine.
- Fondi costruiti con i colori di brand della Parte 2, non gradienti casuali: devono far
  risaltare lo screenshot, non competere con esso.
- Contrasto testo/fondo almeno 4.5:1, verificato.
- Versione light e dark del sistema, con raccomandazione finale su quale usare per la scheda.

### Consegna

- Le 7 immagini in italiano e inglese alla dimensione reale, più poster frame e i due formati social.
- Una vista d'insieme delle 7 in fila, come si vedranno scorrendo la scheda, e un mockup delle
  prime 3 in miniatura nei risultati di ricerca.
- Le headline definitive in it e en, con 2 alternative ciascuna.
- Una nota su quale ordine massimizza l'installazione e perché.

---

## Cosa consegnare — riepilogo

1. Proposte di icona: 3 direzioni, ognuna con i suoi livelli e le 4 apparenze, con
   raccomandazione finale motivata.
2. Tavola dei token del design system.
3. Mockup delle 8 schermate/stati, light e dark, a misura iPhone.
4. Mockup dei widget e delle estensioni.
5. Asset marketing per l'App Store (Parte 5).
6. Una nota finale con: cosa cambia rispetto a oggi e perché, in ordine di impatto sull'utente,
   e quali scelte di design richiedono anche una **modifica al codice** — per esempio la
   waveform richiede di esporre il livello audio da `VoiceManager`, la trascrizione live
   richiede `shouldReportPartialResults = true`.

---

## Note di implementazione

- L'output del designer va portato in **Icon Composer** (Xcode 26) per generare il `.icon` con
  le quattro apparenze: per questo il brief insiste sui livelli separati. Gli attuali 35 PNG in
  `AppIcon.appiconset` diventeranno superflui.
- Prima di implementare le schermate servono le fondamenta: popolare `AccentColor.colorset` nei
  due target, creare i color set semantici e un file Swift di token che sostituisca i
  `Color.blue` sparsi in `ContentView.swift` e `TapMemoWidget.swift`.
- Se i poster servono prima del redesign completo, produci solo le immagini 1, 2 e 6 con
  l'interfaccia attuale e rifai l'intera galleria dopo il rilascio.
