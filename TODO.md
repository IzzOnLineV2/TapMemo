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

**Se resta com'è**, nella scheda App Store in inglese va scritto esplicitamente che il
riconoscimento è in italiano. Per la stessa ragione le frasi d'esempio restano in italiano
anche nella localizzazione inglese: sono parole da *pronunciare*, non da tradurre.

---

## Altri pendenti dal redesign (21/09/2026)

- **Immagini App Store in inglese.** Il progetto Claude Design ha le headline en-US
  (`Design/AppStore/HEADLINES.md`) ma non ha generato le 7 immagini: vanno chieste e
  riesportate in `Design/AppStore/en-US/`.
- **File `.icon` di Icon Composer.** I tre livelli SVG sono pronti in `Design/AppIcon/`;
  il montaggio è manuale in Xcode (istruzioni in `Design/README.md`). Nel frattempo
  l'asset catalog usa i PNG 1024 delle tre apparenze.
- **Prova su dispositivo.** Microfono, trascrizione live e waveform non sono verificabili nel
  simulatore; da controllare anche la resa in dark mode delle schermate di registrazione e
  conferma.
