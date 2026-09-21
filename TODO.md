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

## Il team di firma: SmartApiBox o IzzOnLine?

**Stato:** da decidere · aperto il 21/09/2026

Il commit `fc50ec6` aveva impostato `DEVELOPMENT_TEAM = WF6Z643R96` (IzzOnLine), ma con quel
team **non si può compilare**: `com.smartapibox.tapmemo`, `com.smartapibox.tapmemo.widget` e
soprattutto l'App Group `group.com.smartapibox.tapmemo` appartengono al team
**32BK2Y9JL3 (SmartApiBox S.r.l.s.)**, che è anche quello con cui l'app è pubblicata — i
profili *Store* locali lo confermano. Gli identificatori di App Group sono unici a livello
globale: IzzOnLine non può registrarne uno già preso.

Il team è quindi stato riportato a `32BK2Y9JL3` per poter produrre la build.

**Se il passaggio a IzzOnLine è voluto**, non è una riga di configurazione ma un'operazione
in tre pezzi:

1. **Trasferimento dell'app** in App Store Connect da SmartApiBox a IzzOnLine. Porta con sé
   il bundle ID e la scheda, con recensioni e utenti.
2. **L'App Group non si trasferisce.** Serve un identificatore nuovo (es.
   `group.com.izzonline.tapmemo`) registrato nel team di destinazione.
3. **Migrazione dei dati.** Il database condiviso vive dentro il gruppo vecchio
   (`group.com.smartapibox.tapmemo/TapMemo.sqlite`): cambiando gruppo, al primo avvio l'app
   deve copiare lo store dal container vecchio al nuovo, o **gli utenti perdono tutti i
   memo**. Vale la stessa regola di `SCHEMA_VERSIONING.md`: mai perdere i dati in produzione.

Finché i tre pezzi non sono pronti insieme, il team resta SmartApiBox.

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
