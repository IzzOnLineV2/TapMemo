# TODO — TapMemo

## ~~Supporto multilingua: riconoscimento vocale + parser~~ — fatto il 21/09/2026

L'app capisce **italiano e inglese**. Riconoscimento, parser e interfaccia seguono la lingua
in cui l'app si sta mostrando (`Bundle.main.preferredLocalizations`): chi legge l'interfaccia
in inglese trova il microfono che ascolta in inglese.

**Come è stato fatto.** Strada 1 delle due valutate: un parser vero per lingua, non
`NSDataDetector`. Il vocabolario è uscito dal motore ed è finito in `MemoLanguage.swift`
(`MemoLanguageCatalog.italian`, `.english`); `MemoParser` è rimasto l'unico motore e non
contiene più parole. **Aggiungere una lingua ora significa aggiungere un `MemoLanguage` e
farlo verificare a un madrelingua, senza toccare il motore.**

La regola culturale è stata portata di peso: «alle 3» sono le 15, e in inglese «at 3» è
ambiguo allo stesso modo, quindi vale la stessa regola — con un `am`/`pm` esplicito che batte
tutto. È esattamente ciò che promette l'immagine 3 della scheda inglese, ed è coperto da un test.

**Guadagnati per strada**, perché la scheda li prometteva ma il parser non li faceva:

- «stasera»/«tonight» ora valgono giorno **e** ora (oggi alle 20), come «stamattina» (9) e
  «questo pomeriggio» (15). Prima «cena con anna stasera» non produceva nessuna data.
- Il titolo si taglia al marcatore che viene **prima nella frase**, non al primo della lista:
  «chiama mario alle 3 domani» dà «Chiama mario», non «Chiama mario alle 3».

**Copertura.** `TapMemoTests/MemoParserTests.swift` — 14 test sulle due lingue, con data
fissa e fuso fisso: i due default culturali, il meridiano esplicito, i momenti della giornata,
giorno della settimana con e senza numero, l'assenza di data, l'evidenziazione e la scelta
della lingua.

**Restano fuori:** una terza lingua (serve un madrelingua), e la scelta manuale della lingua
di ascolto dall'app — oggi segue l'interfaccia e non è configurabile, che per un'app da tre
secondi sembra la scelta giusta.

## ~~Il team di firma~~ — risolto il 21/09/2026

TapMemo è passata da **SmartApiBox (32BK2Y9JL3)** a **IzzOnLine / Stefania Izzo
(WF6Z643R96)** con un trasferimento in App Store Connect. Il trasferimento porta con sé la
scheda e il bundle ID principale, **ma non le capability collegate**: l'App Group e l'App ID
del widget erano rimasti nell'account di partenza, e senza di loro nessuna build firmata
IzzOnLine poteva essere caricata.

Sono stati liberati dall'account vecchio e registrati nel nuovo **con gli stessi
identificatori**:

- `group.com.smartapibox.tapmemo` — l'identificatore *è* il percorso del contenitore
  condiviso: averlo conservato identico è ciò che ha salvato i memo degli utenti già
  installati. Cambiarlo avrebbe reso il loro database irraggiungibile.
- `com.smartapibox.tapmemo.widget` — conservato identico, così i widget già piazzati sulla
  Home restano al loro posto dopo l'aggiornamento.

`DEVELOPMENT_TEAM` è ora `WF6Z643R96` in tutte le configurazioni. La 1.1 è firmata
*Apple Distribution: Stefania Izzo* con profili Store che portano l'App Group.

**Da ricordare per il futuro:** se l'app venisse mai trasferita di nuovo, App Group e App ID
delle estensioni non seguono. Vanno liberati e riregistrati a mano, oppure — se l'account di
partenza non è più raggiungibile — si perde l'accesso ai dati condivisi degli utenti.

## Altri pendenti dal redesign (21/09/2026)

- **Immagini App Store in inglese** — *fatte il 21/09/2026*, in `Design/AppStore/en-US/`.
  Il vincolo che le teneva ferme è caduto lo stesso giorno: l'app capisce l'inglese, quindi
  **sono pubblicabili**. La headline 3 «"At 3" means 3 PM.» è vera e coperta da un test.
  Mancano ancora poster frame e formati social in inglese.
- **File `.icon` di Icon Composer.** I tre livelli SVG sono pronti in `Design/AppIcon/`;
  il montaggio è manuale in Xcode (istruzioni in `Design/README.md`). Nel frattempo
  l'asset catalog usa i PNG 1024 delle tre apparenze.
- **Prova su dispositivo.** Microfono, trascrizione live e waveform non sono verificabili nel
  simulatore; da controllare anche la resa in dark mode delle schermate di registrazione e
  conferma.
