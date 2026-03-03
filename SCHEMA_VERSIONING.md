# SwiftData Schema Versioning — TapMemo

## Perché serve

Quando modifichi il `@Model` (aggiungi/rimuovi/rinomini proprietà), il database SQLite esistente non corrisponde più al nuovo schema. Senza migrazione l'app crasha al primo avvio dopo l'aggiornamento.

**In sviluppo** si cancellava il DB e si ripartiva da zero. **In produzione** questo non è accettabile: i dati dell'utente devono essere preservati.

## Schema attuale (V1)

```swift
// Item.swift — MemoItem
var id: UUID
var originalText: String
var normalizedTitle: String
var dueAt: Date?
var createdAt: Date
var calendarIdentifier: String?
var reminderIdentifier: String?
var isShared: Bool
```

## Come funziona il versioning

SwiftData usa tre componenti:

1. **`VersionedSchema`** — snapshot dello schema ad una versione specifica
2. **`SchemaMigrationPlan`** — definisce l'ordine delle migrazioni
3. **`MigrationStage`** — la singola migrazione (lightweight o custom)

## Esempio pratico: aggiungere un campo `tags`

### 1. Congela lo schema attuale in una V1

```swift
// SchemaVersioning.swift

import SwiftData

enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [MemoItem.self] }

    @Model
    class MemoItem {
        var id: UUID
        var originalText: String
        var normalizedTitle: String
        var dueAt: Date?
        var createdAt: Date
        var calendarIdentifier: String?
        var reminderIdentifier: String?
        var isShared: Bool
    }
}
```

### 2. Crea la V2 con il nuovo campo

```swift
enum SchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] { [MemoItem.self] }

    @Model
    class MemoItem {
        var id: UUID
        var originalText: String
        var normalizedTitle: String
        var dueAt: Date?
        var createdAt: Date
        var calendarIdentifier: String?
        var reminderIdentifier: String?
        var isShared: Bool
        var tags: [String]  // NUOVO
    }
}
```

### 3. Definisci il piano di migrazione

```swift
enum MemoMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    // Lightweight: SwiftData gestisce tutto automaticamente
    // (funziona per aggiunta di campi opzionali o con default)
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )
}
```

### 4. Usa il migration plan nel ModelContainer

```swift
// TapMemoApp.swift
let container = try ModelContainer(
    for: SchemaV2.MemoItem.self,
    migrationPlan: MemoMigrationPlan.self,
    configurations: config
)
```

## Tipi di migrazione

### Lightweight (automatica)

Funziona quando:
- Aggiungi una **proprietà opzionale** (`var tags: [String]?`)
- Aggiungi una proprietà con **valore di default** (`var tags: [String] = []`)
- Rimuovi una proprietà

```swift
static let stage = MigrationStage.lightweight(
    fromVersion: SchemaV1.self,
    toVersion: SchemaV2.self
)
```

### Custom (manuale)

Necessaria quando:
- Rinomini una proprietà
- Cambi il tipo di una proprietà
- Devi trasformare/calcolare dati esistenti

```swift
static let stage = MigrationStage.custom(
    fromVersion: SchemaV1.self,
    toVersion: SchemaV2.self,
    willMigrate: { context in
        // Logica pre-migrazione (schema V1 ancora attivo)
        let memos = try context.fetch(FetchDescriptor<SchemaV1.MemoItem>())
        for memo in memos {
            // trasforma i dati...
        }
        try context.save()
    },
    didMigrate: nil
)
```

## Checklist per ogni modifica allo schema

1. [ ] Creare un nuovo `VersionedSchema` (V*N+1*)
2. [ ] Aggiornare il `@Model` principale (`Item.swift`) con le nuove proprietà
3. [ ] Aggiungere un `MigrationStage` nel `SchemaMigrationPlan`
4. [ ] Aggiornare il `ModelContainer` con il `migrationPlan`
5. [ ] Testare su un dispositivo/simulatore con dati della versione precedente
6. [ ] Verificare che il widget legga correttamente il DB migrato

## Note importanti

- **Widget**: il widget legge il DB in sola lettura. Non può eseguire migrazioni. L'app principale deve essere aperta almeno una volta dopo l'aggiornamento per migrare il DB.
- **App Group**: il DB condiviso (`group.com.smartapibox.tapmemo/TapMemo.sqlite`) è lo stesso per app e widget. La migrazione nell'app si applica anche al widget.
- **Backup**: iOS esegue il backup del DB automaticamente. Se una migrazione fallisce, l'utente può ripristinare da backup.
- **Mai cancellare il DB in produzione**: il codice di cancellazione automatica è stato rimosso da `TapMemoApp.swift` e `TapMemoWidget.swift`.
