# Design — asset generati dal progetto Claude Design

Tutto quello che c'è qui è ricavato dal progetto Claude Design **"Mobile app design"**
(`c6c2cfa7-4030-4aa4-8098-0146a1d84029`, file `TapMemo Redesign.dc.html`), che resta la
fonte di verità. Questi file sono un'esportazione, non un originale da modificare a mano:
se il design cambia, si riesporta.

## `AppIcon/` — per Icon Composer

L'icona è il concept **8b** del turno t9: tre barre di voce in crescendo che si chiudono in
un giorno di calendario. Cinque forme, nessun testo, nessun microfono.

| File | Cos'è |
|---|---|
| `tapmemo-icon-bg.svg` | **Livello sfondo** — gradiente indaco `#7A63FF → #3A20BE`, a pieno formato |
| `tapmemo-icon-mid.svg` | **Livello intermedio** — le stesse forme spostate di 34 px in giù: è la profondità |
| `tapmemo-icon-fg.svg` | **Livello primo piano** — barre + giorno, con la fascia come foro |
| `tapmemo-icon-def/dark/tint/clear.svg` | Le quattro apparenze già appiattite, per confronto e mockup |
| `tapmemo-icon-clear.png` | Anteprima dell'apparenza Clear |

### Come montarla in Icon Composer (Xcode 26+)

1. Nuovo documento `.icon`, piattaforma iOS.
2. Importa i tre SVG **in quest'ordine**: `bg` → `mid` → `fg`.
3. Lascia la specularità di default e porta l'ombra del livello di primo piano al **40%**.
4. Verifica le quattro apparenze (Default, Dark, Clear, Tinted) e la resa a 29 pt.
5. Sostituisci `AppIcon.appiconset` con il `.icon` risultante.

> Lo sfondo è esportato **quadrato a pieno formato**: la maschera a squircle la applica
> Icon Composer. Non arrotondarlo a mano, o si vedrebbe un bordo rientrato.

Nel frattempo l'asset catalog contiene i PNG 1024 delle tre apparenze richieste da iOS
(`1024.png`, `1024-dark.png`, `1024-tinted.png`), che funzionano già senza Icon Composer.

Geometria, su griglia 1024: barre larghe 84, raggio 42, a x 214 / 322 / 430, alte
240 / 460 / 320; giorno 236 × 236 raggio 62 a x 578; fascia 236 × 18 a y 452, **foro** nel
riquadro — in tinted prende il neutro di sistema.

## `AppStore/` — immagini della scheda

Renderizzate alla misura reale dal sistema grafico del turno t6.

- `it-IT/01…07.png` — le 7 immagini della galleria, **1320 × 2868** (iPhone 6.9").
- `poster-frame.png` — fotogramma di copertina dell'App Preview, stessa gabbia.
- `social-1x1.png` (1200 × 1200) e `social-16x9.png` (1920 × 1080) — stampa e social.
- `HEADLINES.md` — headline definitive it/en, alternative, ordine consigliato.

**Mancano le immagini in inglese.** Il progetto Design contiene le headline en-US (sono in
`HEADLINES.md`) ma non ha generato le 7 immagini tradotte: vanno chieste al progetto
("le 7 immagini anche in inglese") e riesportate qui sotto `en-US/`.

Prima di caricarle su App Store Connect, verifica che i formati richiesti non siano
cambiati: Apple li ha modificati più volte.
