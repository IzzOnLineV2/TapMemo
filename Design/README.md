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

### `TapMemo.icon` — il documento che l'app spedisce

Il documento vive in **`TapMemo/TapMemo.icon`**, dentro il target dell'app: è lui l'icona,
non più i PNG. Aprilo con **Icon Composer** per vederlo o ritoccarlo.

Il formato è una cartella con un manifest e gli asset, quindi si legge e si versiona come
codice:

```
TapMemo/TapMemo.icon/
  icon.json              manifest
  Assets/segno.svg       il livello di primo piano, vettoriale
```

Com'è composto, e perché così:

- **Sfondo**: `linear-gradient` a due fermate, `#7A63FF → #3A20BE`, gli stessi del design.
  Verificato sul render: `#7664F6` in alto, `#3621B8` in basso. La chiave
  `automatic-gradient`, che accetta un colore solo, dava un fondo troppo chiaro.
- **Un solo livello** di primo piano, `segno.svg`, con la fascia come **foro** — il fondo
  passa attraverso, che è ciò che fa funzionare l'apparenza *tinted*.
- **Ombra** `neutral` al **40%**, come chiedeva il design. La profondità che negli SVG era un
  livello intermedio disegnato a mano ora la genera il sistema: Icon Composer fa ombra e
  specularità da sé, quindi `tapmemo-icon-mid.svg` resta solo come riferimento.

Nel progetto è collegato da `ASSETCATALOG_COMPILER_APPICON_NAME = TapMemo`. Compilando,
Xcode ne ricava nell'`Assets.car` un `IconGroup` per apparenza, il gradiente come *Named
Gradient* e il segno come *Vector*: resta vettoriale, e le tre immagini 1024 che ne genera
sono `Opaque: True` — requisito di App Store Connect, che rifiuta un'icona con trasparenza.

Il costo è il peso: l'IPA passa da 1,1 a 5,4 MB, perché le apparenze vengono precalcolate
a 1024.

### Verificarlo senza aprire l'app

Dentro Icon Composer c'è un eseguibile a riga di comando che renderizza qualunque
apparenza:

```sh
"/Applications/Icon Composer.app/Contents/Executables/ictool" \
  TapMemo/TapMemo.icon --export-image --output-file /tmp/out.png \
  --platform iOS --rendition Default --width 1024 --height 1024 --scale 1
```

Apparenze valide: `Default`, `Dark`, `TintedLight`, `TintedDark`, `ClearLight`, `ClearDark`.
Utile anche per controllare la resa a 29 pt (`--width 29 --height 29 --scale 3`), che è la
dimensione su cui il design si giocava tutto.

> Gli SVG piatti (`-def`, `-dark`, `-tint`, `-clear`) restano come mockup: sono quelli che
> compaiono nei poster dell'App Store. **Non usarli come icona dell'app**: hanno la squircle
> cotta dentro e il canale alpha, e App Store Connect li rifiuta (errore 90717). Vale lo
> stesso per le esportazioni PNG di Icon Composer.

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
