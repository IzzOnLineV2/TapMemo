# App Store — copy e ordine

Dal progetto Claude Design: turno t6 per la serie italiana, turno t10 per l'inglese.

## Headline applicate

| # | it-IT | en-US |
|---|---|---|
| 1 | **Parla. È in calendario.**<br>Un tap, una frase, l'evento è creato. | **Say it. It's set.**<br>One tap and it's on. |
| 2 | **Dillo. Lo capisce.**<br>Titolo pulito e data, estratti dalla frase. | **It gets the when.**<br>A clean title and a date. |
| 3 | **Parla italiano. Davvero.**<br>«alle 3» sono le 15. Lo sa. | **"At 3" means 3 PM.**<br>Loose times, read right. |
| 4 | **Calendario o Promemoria**<br>Uno swipe e va dove serve. | **Calendar or Reminders**<br>One swipe, wherever you need. |
| 5 | **Un tap dal blocco.**<br>Widget, schermata di blocco, Control Center. | **One tap, locked.**<br>Widgets and Lock Screen. |
| 6 | **Resta sul telefono.**<br>Nessun account, nessun server, zero tracker. | **Stays on your iPhone.**<br>No account, zero trackers. |
| 7 | **Parla. È in calendario.**<br>Gratis, in italiano, senza account. | **Say it. It's set.**<br>Free, no account, iPhone only. |

La 7 chiude con la stessa frase della 1: l'arco si chiude. Tutte le headline stanno su due
righe, il sottotitolo su una: il corpo varia per riempire la misura (140–180 px reali) così
la gabbia resta identica nelle due lingue, senza sillabazioni né terze righe.

## L'immagine 3, e perché in inglese è diversa

In italiano la 3 vende «capisce l'italiano davvero». In inglese quell'argomento cade con la
release multilingua, ma la posizione deve continuare a rispondere a **perché funziona per
me** — e l'argomento equivalente esiste: in inglese *«at 3»* è ambiguo esattamente come
*«alle 3»*, e il default sensato resta il pomeriggio.

Tre opzioni, dal progetto (10a):

| | Headline | Sottotitolo | Nota |
|---|---|---|---|
| **applicata** | **"At 3" means 3 PM.** | Loose times, read right. | Concreta e verificabile: dimostra l'intelligenza con un numero, non con un aggettivo. Le virgolette reggono la miniatura a 3 cm. |
| alternativa | It knows you meant 3 PM. | Vague words in, exact times out. | Più calda, mette l'app dalla parte dell'utente. Rischio: «knows» suona come AI in cloud, il contrario del messaggio della 6. |
| alternativa | Speak loosely. Land exactly. | Tonight, Saturday the 25th, at noon — all understood. | La più elegante e la più astratta: bella come claim, meno efficace come prova. Da tenere se la 3 venisse spostata più in fondo. |

Nella serie inglese il chip «9:15» è stato tolto dalla 3: in inglese le espressioni sono più
lunghe e il dispositivo scendeva sotto la linea di base della serie.

### Alternative per le altre posizioni

| # | it-IT | en-US |
|---|---|---|
| 1 | «Dillo e basta.» · «Una frase, un evento.» | "Just say when." · "One phrase, one event." |
| 2 | «Dalla voce all'evento.» · «Capisce il quando.» | "Voice to event." · "It understands you." |
| 4 | «Uno swipe, due app.» · «Tu scegli dove.» | "One swipe, two apps." · "You pick where." |
| 5 | «Senza aprire l'app.» · «Sempre a portata.» | "Never open the app." · "Always one tap away." |
| 6 | «Niente account, niente server.» · «Solo tuo.» | "No account, no server." · "Yours only." |

## Ordine raccomandato

1 (promessa) → 2 (la trasformazione) → 3 (perché funziona per me) → 4 (dove finisce)
→ 5 (widget) → 6 (privacy) → 7 (chiusura).

Le prime tre rispondono, nell'ordine, alle tre domande della miniatura: **cosa fa**,
**come lo fa**, **perché funziona per me**. La privacy è al 6° posto e non al 2° perché
convince chi sta già valutando, non chi sta scorrendo: spostarla in alto costa la
spiegazione della funzione. Se un test A/B dice il contrario, l'unica coppia da scambiare
è 3 ↔ 6.

## Light o dark

Sistema misto a dominante scura: **1-3 e 6-7** su indaco profondo, **4-5** su indaco
chiaro. La scheda dell'App Store ha quasi sempre fondo chiaro, quindi le immagini scure
staccano di più in miniatura; le due chiare al centro danno respiro e mostrano l'app come
la si usa di giorno.

Contrasto: headline bianche su fondo saturo **8.9:1**, `#1A0F52` su fondo chiaro **12.4:1**.

## Stato

- **it-IT** — 7 immagini, poster frame, 1:1 e 16:9. Pubblicabili.
- **en-US** — 7 immagini. **Pubblicabili dal 21/09/2026**: l'app capisce l'inglese, quindi la
  frase mostrata nell'immagine 2 crea davvero l'evento e «"At 3" means 3 PM.» è una promessa
  che il parser mantiene (verificata in `TapMemoTests/MemoParserTests.swift`).
  Poster frame e formati social in inglese non sono ancora stati generati.
