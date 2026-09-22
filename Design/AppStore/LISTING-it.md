# App Store listing — it-IT

Rielaborazione della descrizione esistente, allineata alla 1.1 e ripulita dalle
affermazioni che l'app non mantiene.

## Subtitle (max 30)

```
Parla, ed è in calendario
```

## Promotional text (max 170)

```
Tocca, di' «ricordami la spesa domani alle 3», e l'evento è già nel tuo calendario.
Nessun account, nessun server, nessun abbonamento.
```

## Description (max 4000)

```
TapMemo trasforma la tua voce in memo, eventi e promemoria. In un solo tap.

Hai un impegno, un'idea, qualcosa da ricordare? Non serve scrivere: parla e TapMemo fa il
resto. Capisce quando intendi, scrive il titolo e crea l'evento al posto tuo.

«Ricordami la spesa domani alle 3» diventa Spesa, domani alle 15:00, in Calendario.

COME FUNZIONA
1. Tocca il cerchio
2. Parla, come parleresti a una persona
3. Fatto — TapMemo trascrive, capisce la data e crea l'evento

CAPISCE COME PARLI DAVVERO
Domani, dopodomani, sabato 25, stasera, a mezzogiorno, alle 9:15. E anche le forme vaghe:
«alle 3» sono le 15, perché è quello che intendevi.

VEDI QUELLO CHE SENTE
Le parole compaiono mentre le pronunci e l'onda segue la tua voce: sai che TapMemo sta
ascoltando e cosa ha capito. Quando l'evento è creato ti dice esattamente cosa ha fatto e
quando — e con un tocco annulli o correggi l'ora.

CALENDARIO, PROMEMORIA, O NESSUNO DEI DUE
Un memo con una data diventa da solo un evento nel Calendario. Con uno swipe lo mandi anche
nei Promemoria, lo condividi o lo elimini. Senza data resta un memo, finché non decidi tu.
Se cancelli l'evento dal Calendario di Apple, TapMemo se ne accorge e te lo dice.

SEMPRE A UN TOCCO
Widget per la schermata Home in tre dimensioni, widget per la schermata di blocco e un
pulsante nel Centro di Controllo: inizi a parlare senza cercare l'app.

ITALIANO E INGLESE
Riconoscimento vocale, comprensione delle date e interfaccia seguono la lingua del tuo
iPhone. Nessuna delle due è una traduzione dell'altra: l'italiano «alle 3» e l'inglese
«at 3» ricevono lo stesso trattamento.

NESSUN ACCOUNT, NESSUN SERVER
Non c'è registrazione, non c'è abbonamento, non ci sono analytics, tracker o SDK di terze
parti. I memo restano sul tuo iPhone e le uniche cose che TapMemo scrive da qualche parte
sono gli eventi e i promemoria che hai chiesto tu, nel tuo calendario. La trascrizione usa
il riconoscimento vocale di Apple, lo stesso della dettatura di sistema.

PERCHÉ TAPMEMO
- Più veloce che scrivere una nota
- Più organizzato di un'app di note generica
- Zero configurazione: installi e parli

TapMemo è pensato per chi ha le mani occupate e la testa piena di cose da ricordare.

Gratis, senza acquisti e senza nulla da sottoscrivere.
```

## Keywords (max 100, separate da virgola senza spazi)

```
voce,memo,vocale,promemoria,calendario,evento,dettatura,nota,agenda,appuntamento,widget
```

Niente «tapmemo» né parole del sottotitolo: App Store le indicizza a parte.

## Cosa è cambiato rispetto alla versione precedente, e perché

- **Tolto «direttamente sul dispositivo» dalla trascrizione.** Non perché sia sempre falso —
  senza rete la trascrizione è locale davvero — ma perché con la connessione attiva il
  sistema può usare i server di Apple, e la finestra di permesso di iOS dice all'utente
  proprio questo. Una frase assoluta nella scheda verrebbe smentita al primo tap. Anche con
  `requiresOnDeviceRecognition = true` quella finestra resta: è testo di sistema. Vedi
  `TODO.md`.
- **Tolto «Tutto sul dispositivo» come titolo di sezione**, sostituito da «Nessun account,
  nessun server», che è vero e altrettanto forte: parla dell'assenza di *nostri* server.
- **Tolto «Più pratico di dettare a Siri».** Il confronto con una funzione di sistema di
  Apple nella scheda è un rischio gratuito in revisione, e la riga non aggiungeva molto.
- **Corretto «riconosce se è un evento, un promemoria o una nota»**: l'app crea l'evento da
  sola quando sente una data, ma i Promemoria restano una scelta dell'utente con uno swipe.
  Prometteva una decisione automatica che non avviene.
- **Aggiunte le novità della 1.1**: comprensione delle date vaghe, trascrizione live con
  l'onda, foglio di conferma con annulla, widget della schermata di blocco e Centro di
  Controllo, riconoscimento anche in inglese.
