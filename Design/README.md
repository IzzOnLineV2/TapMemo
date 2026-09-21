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

### `TapMemo.icon` — il documento Icon Composer, già montato

`AppIcon/TapMemo.icon` è un documento pronto: aprilo con **Icon Composer** (in
`/Applications`, o dentro Xcode) per vederlo e ritoccarlo.

Il formato è una cartella con un manifest e gli asset, quindi si legge e si versiona come
codice:

```
TapMemo.icon/
  icon.json              manifest
  Assets/segno.svg       il livello di primo piano, vettoriale
```

Com'è composto, e perché così:

- **Sfondo**: `linear-gradient` a due fermate, `#7A63FF → #3A20BE`, gli stessi del design.
  Verificato sul render: `#7664F6` in alto, `#3621B8` in basso.
- **Un solo livello** di primo piano, `segno.svg`, con la fascia come **foro** — il fondo
  passa attraverso, che è ciò che fa funzionare l'apparenza *tinted*.
- **Ombra** `neutral` al **40%**, come chiedeva il design. La profondità che nei vecchi SVG
  era un livello intermedio disegnato a mano ora la genera il sistema: Icon Composer fa
  ombra e specularità da sé, quindi `tapmemo-icon-mid.svg` non serve più al documento e
  resta solo come riferimento.

### Verificarlo senza aprire l'app

Dentro Icon Composer c'è un eseguibile a riga di comando che renderizza qualunque
apparenza:

```sh
"/Applications/Icon Composer.app/Contents/Executables/ictool" \
  Design/AppIcon/TapMemo.icon --export-image --output-file /tmp/out.png \
  --platform iOS --rendition Default --width 1024 --height 1024 --scale 1
```

Apparenze valide: `Default`, `Dark`, `TintedLight`, `TintedDark`, `ClearLight`, `ClearDark`.
Utile anche per controllare la resa a 29 pt (`--width 29 --height 29 --scale 3`), che è la
dimensione su cui il design si giocava tutto.

> Gli SVG piatti (`-def`, `-dark`, `-tint`, `-clear`) restano come mockup: sono quelli che
> compaiono nei poster dell'App Store.

**Nell'app oggi** l'asset catalog usa ancora i PNG 1024 delle tre apparenze
(`1024.png`, `1024-dark.png`, `1024-tinted.png`), **quadrati a pieno formato e senza canale
alpha** — un raggio cotto dentro o una trasparenza fanno rifiutare la build da App Store
Connect. Passare al `.icon` è un cambio di configurazione del progetto, ancora da fare.

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
