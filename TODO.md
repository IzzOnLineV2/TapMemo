# TODO — TapMemo

## Supporto multilingua: riconoscimento vocale + parser

**Stato:** da valutare · aperto il 21/09/2026

Oggi l'interfaccia è bilingue (italiano sorgente + inglese completo, `knownRegions = en, it`),
ma **la funzione è solo italiana**. Un utente con il telefono in inglese vede i pulsanti in
inglese, parla inglese e non ottiene nulla.

### Dove è vincolato all'italiano

| Punto | Cosa fa |
|---|---|
| `TapMemo/VoiceManager.swift:29` | `SFSpeechRecognizer(locale: "it-IT")` — ascolta solo italiano, qualunque sia la lingua del dispositivo |
| `TapMemo/MemoParser.swift:18` | default `it-IT`; **tutte** le euristiche sono liste di parole italiane |

Il riconoscitore è una riga: basta seguire `Locale.current` e verificare
`SFSpeechRecognizer.supportedLocales()`. Il lavoro vero è il parser.

### Cosa comporta il parser

`MemoParser` sono ~380 righe di euristiche italiane, non traducibili meccanicamente:

- liste di parole: *oggi, domani, dopodomani, stasera, stamattina, a mezzogiorno, a mezzanotte*,
  i sette giorni della settimana, i marcatori *alle / ore / all'*;
- prefissi da togliere dal titolo: *ricordami di, promemoria, aggiungi appuntamento, devo, fare*;
- **la regola culturale**: «alle 3» in italiano significa le 15, non le 3 del mattino
  (`adjustHourHeuristic`). Ogni lingua ha la sua convenzione, e l'inglese con l'AM/PM
  esplicito ne ha una diversa.

### Due strade

1. **Un parser per lingua.** Estrarre un protocollo `MemoDateParser` con l'implementazione
   italiana attuale come prima conforme, e aggiungerne una per lingua. Preciso, ma è lavoro
   linguistico vero per ogni lingua nuova, e va testato da un madrelingua.
2. **`NSDataDetector` come ripiego.** È locale-aware e riconosce le date in molte lingue senza
   scrivere euristiche. Meno preciso dell'attuale parser italiano — non estrae un titolo pulito
   e non applica convenzioni culturali — quindi va usato **solo fuori dall'italiano**, tenendo
   `MemoParser` come percorso privilegiato per `it`.

La 2 è la via economica per aprire l'app a più lingue in fretta; la 1 è l'unica che mantiene
la qualità che l'app ha oggi in italiano.

### Come deciderlo

Non è una scelta tecnica ma di posizionamento: oggi «capisce l'italiano davvero» è il punto di
forza (headline 3 della scheda App Store, en-US: *«Built for Italian.»*). Aprire ad altre
lingue con un parser più debole indebolisce proprio quell'argomento. Ragionevole farlo solo
quando i numeri mostrano richiesta da fuori Italia.

### Deciso il 21/09/2026: si fa, e gli asset inglesi si preparano prima

Le 7 immagini dell'App Store in inglese vengono prodotte **già completamente tradotte**,
frasi pronunciate comprese, in attesa che il riconoscimento le regga.

Due conseguenze da non perdere di vista:

- **Non pubblicare la galleria inglese prima di questa release.** Mostrerebbe una frase
  inglese che crea un evento mentre l'app non lo fa: discrepanza contestabile in review e
  recensioni a una stella da chi scarica.
- **L'immagine 3 va ripensata, non tradotta.** Oggi in en-US dice *«Built for Italian.»*
  (alternative: *«Real Italian dates.»*, *«Speaks your Italian.»*): se l'app capisce anche
  l'inglese, l'argomento non regge più. L'equivalente inglese della stessa idea esiste — in
  inglese «at 3» è ambiguo quanto «alle 3» e il default sensato resta le 15 — ma è una
  headline diversa, da far rigenerare al progetto Design.

Finché la release non esce, nella scheda inglese va scritto esplicitamente che il
riconoscimento è in italiano.

Nel codice invece le frasi d'esempio **restano italiane** finché il parser lo è: sono parole
da *pronunciare*, e tradurle prima del tempo sarebbe un invito a fallire
(`EmptyStateView.swift`, chiavi `«ricordami la spesa domani alle 3»` e
`dopodomani, sabato 25, stasera, a mezzogiorno.` nei cataloghi).

---

## Altri pendenti dal redesign (21/09/2026)

- **Immagini App Store in inglese** — *fatte il 21/09/2026*, tradotte per intero, in
  `Design/AppStore/en-US/`. **Restano non pubblicate** finché il riconoscimento non capisce
  l'inglese: mostrano una frase inglese che crea un evento. La headline 3 è stata ripensata
  come previsto — «"At 3" means 3 PM.» — con due alternative registrate in `HEADLINES.md`.
  Mancano ancora poster frame e formati social in inglese.
- **File `.icon` di Icon Composer.** I tre livelli SVG sono pronti in `Design/AppIcon/`;
  il montaggio è manuale in Xcode (istruzioni in `Design/README.md`). Nel frattempo
  l'asset catalog usa i PNG 1024 delle tre apparenze.
- **Prova su dispositivo.** Microfono, trascrizione live e waveform non sono verificabili nel
  simulatore; da controllare anche la resa in dark mode delle schermate di registrazione e
  conferma.
