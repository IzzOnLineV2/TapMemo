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

**L'avviso 90076 al caricamento è previsto e innocuo.** App Store Connect segnala «Potential
Loss of Keychain Access» perché il prefisso dell'`application-identifier` cambia
(`32BK2Y9JL3.` → `WF6Z643R96.`). I gruppi del portachiavi sono prefissati dal team, quindi si
rompono davvero — ma **TapMemo non usa il portachiavi**: nessun `SecItem`, nessun entitlement
`keychain-access-groups`. I contenitori App Group, al contrario, sono indirizzati dal solo
identificatore del gruppo senza prefisso di team, ed è per questo che conservarlo identico ha
salvato i dati. L'avviso comparirà al massimo ancora una volta.

## Riconoscimento vocale: sui server di Apple o sul dispositivo?

**Stato:** da decidere · aperto il 21/09/2026

`requiresOnDeviceRecognition = false` **non** significa «manda ai server»: significa «non
pretendere il locale, sceglie il sistema». Verificato sul campo il 22/09/2026: la 1.1, che
ha `false`, trascrive perfettamente in modalità aereo — segno che iOS usa il modello sul
dispositivo quando la rete non c'è.

La differenza fra `false` e `true` sta quindi **solo nel caso con connessione attiva**:

| | `false` (1.1) | `true` (1.1.1) |
|---|---|---|
| Senza rete | sul dispositivo | sul dispositivo |
| Con rete | il sistema può usare i server di Apple | non li usa mai |

Indipendentemente dall'impostazione, iOS mostra comunque la finestra «I dati vocali di
quest'app verranno inviati ad Apple per l'elaborazione» al momento dell'autorizzazione:
quel testo è di sistema e compare prima che qualunque richiesta venga configurata. Nessuna
modifica al codice lo toglie.

È in tensione con il posizionamento dell'app. L'immagine 6 della scheda App Store dice
«Resta sul telefono», e la descrizione italiana precedente affermava che la trascrizione
avviene sul dispositivo: non era vero, ed è stato corretto in `Design/AppStore/LISTING-it.md`.
Un utente che legge quella frase e poi vede la finestra di Apple si sente preso in giro.

**La correzione è di due righe:**

```swift
request.requiresOnDeviceRecognition = speechRecognizer?.supportsOnDeviceRecognition ?? false
```

Condizionarla a `supportsOnDeviceRecognition` è necessario: se il modello linguistico non è
scaricato, imporre il riconoscimento locale fa fallire la trascrizione.

**Il compromesso da valutare:** con `true` si rinuncia al riconoscimento sui server, che
Apple usa quando può perché di solito è più accurato — e qui l'accuratezza è tutto, un'ora
sbagliata rende l'app inutile.

**Come provarlo davvero:** non in modalità aereo, dove le due versioni si comportano
identiche. Con la **rete accesa**, dettare le stesse frasi su entrambe le build e
confrontare gli errori, in italiano e in inglese, su frasi con ore e date precise.

Se si adotta, la descrizione può tornare a dire che tutto resta sul telefono, ed è l'unica
condizione in cui può dirlo.

## Altri pendenti dal redesign (21/09/2026)

- **Immagini App Store in inglese** — *fatte il 21/09/2026*, in `Design/AppStore/en-US/`.
  Il vincolo che le teneva ferme è caduto lo stesso giorno: l'app capisce l'inglese, quindi
  **sono pubblicabili**. La headline 3 «"At 3" means 3 PM.» è vera e coperta da un test.
  Mancano ancora poster frame e formati social in inglese.
- ~~**File `.icon` di Icon Composer**~~ — *fatto il 21/09/2026*. `TapMemo/TapMemo.icon` è
  l'icona che l'app spedisce: gradiente a due fermate, segno vettoriale, fascia forata,
  ombra al 40%. L'`appiconset` con i PNG è stato rimosso. Dettagli in `Design/README.md`.
- ~~**Prova su dispositivo**~~ — *fatta il 21/09/2026* con la build TestFlight 1.1 (7)
  installata **sopra** la versione dell'App Store. L'app funziona e **i memo preesistenti
  sono stati conservati**: è la conferma che il contenitore dell'App Group è sopravvissuto al
  passaggio da SmartApiBox a IzzOnLine, l'unica cosa che nessun simulatore poteva dimostrare.
  Restano da guardare con calma, quando capita: la resa in dark mode delle schermate di
  registrazione e conferma, e l'icona a 29 pt su schermo vero.
