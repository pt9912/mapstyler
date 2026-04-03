# Layers

Kein neues Paket noetig. `Layer` soll ein Kernmodell-Typ in
`mapstyler_style` werden.

Der Zweck ist nicht, Renderer- oder Dateiformat-Logik in ein neues Paket
auszulagern, sondern das gemeinsame Stilmodell von einem flachen
`Style -> List<Rule>` auf ein explizites Layer-Modell zu erweitern.

## Zielbild

Heute:

```text
Style
└── rules: List<Rule>
```

Kuenftig:

```text
Style
├── name
└── children: List<LayerNode>          (sealed: Layer | LayerGroup)
    │
    ├── Layer
    │   ├── name
    │   ├── sourceRef: String?
    │   ├── visible: bool
    │   ├── opacity: double?
    │   ├── zIndex: int?
    │   ├── extent: EnvelopeGeometry?
    │   ├── scaleDenominator: ScaleDenominator?
    │   └── rules: List<Rule>
    │
    └── LayerGroup
        ├── name
        ├── visible: bool
        ├── opacity: double?
        ├── zIndex: int?
        └── children: List<LayerNode>  (rekursiv verschachtelbar)
```

Ein Style besteht aus geordneten Knoten. Ein `Layer` gruppiert Rules
mit gemeinsamer fachlicher und darstellungsbezogener Bedeutung. Ein
`LayerGroup` buendelt Layer und weitere Gruppen zu einer logischen
Einheit mit gemeinsamer Sichtbarkeit, Opacity und Reihenfolge.

## Warum `Layer` ins Kernmodell gehoert

`Layer` und `LayerGroup` sind hier bewusst **keine** Flutter-Widget-
Konzepte und auch keine reinen Mapbox- oder SLD-Sonderfaelle, sondern
gemeinsame Zwischentypen fuer:

- Style-Gruppierung (flach und verschachtelt)
- optionale Bindung an Datenquellen
- optionale Darstellungs-Hinweise fuer Renderer und Editor
- hierarchische Sichtbarkeits- und Opacity-Steuerung

Das passt in `mapstyler_style`, wenn die Typen sauber geschnitten
bleiben und nur allgemeine, formatuebergreifende Semantik enthalten.

## Semantik der Layer-Felder

Die Felder sollten im Dokument und spaeter im DartDoc klar in drei
Gruppen getrennt werden.

### 1. Struktureller Kern

Diese Felder definieren den eigentlichen Knoten:

**Layer:**

- `name`
- `rules`

Ohne diese beiden Felder ist `Layer` nicht sinnvoll.

**LayerGroup:**

- `name`
- `children`

Ohne `children` ist `LayerGroup` nicht sinnvoll. `name` dient als
Anzeigename in Editor-UIs und zur Identifikation bei Round-Trips.

### 2. Format- und Datenbindungs-Metadaten

Diese Felder sind optional und nicht fuer jeden Adapter relevant:

- `sourceRef`
- `extent`

Semantik:

- `sourceRef` ist eine **logische Quellen-Referenz**, kein harter
  Verweis auf einen konkreten Loader, Dateipfad oder GDAL-Layername
- `extent` ist ein optionaler raeumlicher Hinweis fuer Host-App,
  Tooling oder spaetere Optimierungen, aber kein Pflichtfeld fuer das
  Rendering

### 3. Darstellungs- und UI-Metadaten

Diese Felder duerfen im Kernmodell liegen, sind aber als optionale
Metadaten zu behandeln:

- `visible`
- `opacity`
- `zIndex`
- `scaleDenominator`

Semantik:

- `visible` blendet den gesamten Layer oder die gesamte Gruppe
  logisch ein oder aus
- `opacity` wirkt als Layer-weite Multiplikation auf die Symbolizer-
  Darstellung. Der Typ ist bewusst `double?`, nicht `Expression<double>?`.
  Layer-Opacity ist eine UI-Steuerung (Schieberegler, Layer-Panel),
  nicht feature-abhaengig. Expressions wuerden hier keinen Kontext
  haben, weil kein einzelnes Feature ausgewertet wird.
- `zIndex` steuert Layer-Reihenfolge, nicht die Reihenfolge innerhalb
  der `rules`
- `scaleDenominator` ist eine Layer-weite Einschraenkung zusaetzlich zu
  regelbezogenen `ScaleDenominator` (nur auf `Layer`, nicht auf
  `LayerGroup`). Kombinationssemantik: **Intersection**. Beide muessen
  gelten, der effektive Bereich ist der engste Schnitt
  (`effektiv.min = max(layer.min, rule.min)`,
  `effektiv.max = min(layer.max, rule.max)`). Ergibt die Intersection
  einen leeren Bereich, wird die Rule bei keiner Zoomstufe gerendert.

Wichtig: Diese Felder sind **allgemeine Stil-Metadaten**, keine
Flutter-spezifischen Render-Implementierungsdetails.

### 4. Vererbung in LayerGroups

`LayerGroup` besitzt `visible`, `opacity` und `zIndex`, aber weder
`sourceRef`, `extent`, `scaleDenominator` noch `rules`. Die Gruppe
definiert keine eigene Darstellung, sondern beeinflusst die ihrer
Kinder.

Vererbungsregeln (analog zu OpenLayers `LayerGroup.getLayerStatesArray`):

- **visible**: AND-Verknuepfung. Ist die Gruppe unsichtbar, sind alle
  Kinder unsichtbar — unabhaengig von deren eigenem `visible`-Wert.
- **opacity**: Multiplikation. Kind-Opacity wird mit Gruppen-Opacity
  multipliziert (`effektiv = group.opacity * child.opacity`). Beide
  Werte liegen im Bereich 0..1.
- **zIndex**: Kinder ohne eigenen `zIndex` erben den Wert der Gruppe.
  Kinder mit eigenem `zIndex` behalten ihren Wert. Innerhalb gleicher
  `zIndex`-Stufe gilt die Listenposition in `children`.

Diese Regeln gelten rekursiv ueber beliebig tiefe Verschachtelung.

## Modellvorschlag

```dart
class Style {
  final String? name;
  final List<LayerNode> children;

  @Deprecated('Use children')
  List<Rule> get rules;
}

sealed class LayerNode {
  String? get name;
  bool get visible;
  double? get opacity;
  int? get zIndex;
}

class Layer extends LayerNode {
  final String? name;
  final String? sourceRef;
  final bool visible;
  final double? opacity;
  final int? zIndex;
  final EnvelopeGeometry? extent;
  final ScaleDenominator? scaleDenominator;
  final List<Rule> rules;
}

class LayerGroup extends LayerNode {
  final String? name;
  final bool visible;
  final double? opacity;
  final int? zIndex;
  final List<LayerNode> children;
}
```

Empfehlungen:

- `visible` default: `true` (auf `Layer` und `LayerGroup`)
- `opacity` default: `null` oder `1.0`; das muss einmal sauber
  entschieden und konsistent dokumentiert werden
- `zIndex` default: `null`; ohne expliziten Wert gilt Listenposition
  in `children`
- `rules` defensiv kopieren wie heute `Style.rules` und
  `Rule.symbolizers`
- `children` in `Style` und `LayerGroup` defensiv kopieren
- `Layer` und `LayerGroup` mit `copyWith()` ausstatten. Kein
  `copyWith()` auf dem sealed Basistyp `LayerNode` — die gemeinsamen
  Felder (`name`, `visible`, `opacity`, `zIndex`) sind zu wenig fuer
  eine sinnvolle API, und die interessanten Aenderungen betreffen
  subtypspezifische Felder (`rules`, `sourceRef`, `children`). Caller
  arbeiten nach Pattern-Match ohnehin mit dem konkreten Subtyp.
- `==`/`hashCode` auf allen drei Typen implementieren, konsistent
  mit `Style`, `Rule`, `Symbolizer`. Alle Felder fliessen in den
  Vergleich ein — auch `visible`, `opacity` und `zIndex`. Diese
  Felder wirken zwar veraenderlich (UI-Steuerung), aber `Layer` und
  `LayerGroup` sind immutable Werttypen wie alle anderen Kernmodell-
  Klassen. Zustandsaenderungen laufen ueber `copyWith()`, nicht ueber
  Mutation. Zwei Layer mit unterschiedlicher `visible`-Einstellung
  sind somit unterschiedliche Werte.

## Migration von `Style.rules` zu `Style.children`

Der Uebergang sollte explizit als Migrationspfad beschrieben werden,
nicht als "bricht schon irgendwie nicht".

### Empfohlener Weg: Option C mit klarer Uebergangsphase

Ein Style mit genau einem impliziten Default-Layer (ohne Gruppen) ist
semantisch aequivalent zum heutigen Modell.

Das bedeutet fuer Phase 1:

- `Style` bekommt `children: List<LayerNode>`
- `Style.rules` bleibt als deprecated Getter erhalten
- `Style.rules` traversiert den Baum rekursiv (Tiefensuche) und
  sammelt alle Rules aller `Layer`-Knoten
- `LayerGroup`-Knoten werden dabei transparent durchlaufen
- die Reihenfolge folgt der **Baumposition** (Tiefensuche, pre-order),
  nicht `zIndex`. Begruendung: der deprecated Getter soll sich fuer
  migrierenden Code moeglichst vorhersagbar verhalten. `zIndex`-
  Sortierung waere ueberraschend fuer einen einfachen Getter und wuerde
  eine Rendering-Semantik in ein reines Datenmodell-API ziehen. Code
  der `zIndex`-bewusstes Rendering braucht, soll auf `children`
  umsteigen.
- bestehender Code kann kurzfristig weiterlaufen
- neue Logik soll auf `children` aufbauen

Empfohlener Default-Layer:

- `name == null`
- `sourceRef == null`
- `visible == true`
- `opacity == null` oder `1.0`
- `zIndex == null`
- `extent == null`
- `scaleDenominator == null`

### JSON-Migration

Auch das JSON-Format braucht einen klaren Vertrag:

- Lesen von altem JSON mit `rules` bleibt unterstuetzt
- altes JSON wird intern auf einen Default-Layer gemappt
- neues JSON darf `children` enthalten
- `children` ist ein Array aus `Layer`- und `LayerGroup`-Objekten
- der Typ wird ueber ein Diskriminator-Feld unterschieden (z.B.
  `"type": "layer"` vs. `"type": "group"`)
- enthaelt ein JSON-Objekt sowohl `rules` als auch `children`, ist das
  ein Parse-Fehler (`ReadStyleFailure`). Beide Felder gleichzeitig
  sind mehrdeutig — stilles Ignorieren wuerde zu verdecktem Datenverlust
  fuehren. Der Writer erzeugt nie beide Felder gleichzeitig, daher
  tritt dieser Fall nur bei fehlerhaften oder manuell gemischten
  Dokumenten auf.
- waehrend der Uebergangszeit kann der Writer fuer einfache Styles
  optional weiter das flache Format erzeugen, falls Abwaertskompatibilitaet
  wichtig ist

Beispiel neues Format:

```json
{
  "name": "Land use",
  "children": [
    {
      "type": "group",
      "name": "Base layers",
      "visible": true,
      "children": [
        {
          "type": "layer",
          "name": "Buildings",
          "sourceRef": "osm-buildings",
          "rules": [...]
        },
        {
          "type": "layer",
          "name": "Roads",
          "sourceRef": "osm-roads",
          "rules": [...]
        }
      ]
    },
    {
      "type": "layer",
      "name": "Labels",
      "rules": [...]
    }
  ]
}
```

Ohne diese Regeln wird die Aenderung sonst faktisch doch eine Breaking
Change.

## Auswirkungen auf die Adapter

### 1. `mapstyler_mapbox_adapter`

Heute werden Mapbox-Layer beim Read-Pfad in flache `Rule`-Listen
uebersetzt. Dabei gehen `source` und `source-layer` im Kernmodell
verloren.

Kuenftig:

- Mapbox-Layer werden in `Layer`-Instanzen ueberfuehrt
- `layer.id` kann auf `Layer.name` gemappt werden
- `source` bzw. eine Kombination aus `source` und `source-layer` kann in
  `sourceRef` ueberfuehrt werden
- `paint`/`layout` werden wie bisher auf `Rule`/`Symbolizer` gemappt
- der Adapter erzeugt **keine** automatische `LayerGroup`-Gruppierung
  nach `source`. Mapbox-Layer-Reihenfolge, `source-layer`, Filter und
  Paint/Layout-Semantik ergeben nicht automatisch eine logische Gruppe —
  eine Heuristik hier wuerde Reihenfolge und Semantik verzerren.
  Falls eine Host-App source-basierte Gruppierung wuenscht, kann sie
  das nachtraeglich ueber einen expliziten, verlustbehafteten
  Transformationsschritt tun. Das ist kein Default-Mapping des Adapters.

Wichtig: `sourceRef` ist dabei eine logische Kernmodell-Referenz. Ob sie
nur `source`, `source/source-layer` oder ein eigenes Mapping-Schema
enthaelt, muss adapterseitig klar definiert werden.

### 2. `mapstyler_sld_adapter`

Heute flacht der Adapter die SLD-Hierarchie
`NamedLayer -> UserStyle -> FeatureTypeStyle -> Rule` zu einer reinen
`List<Rule>` ab.

Kuenftig:

- `NamedLayer` wird auf `Layer` gemappt
- hat ein `NamedLayer` mehrere `UserStyle`- oder `FeatureTypeStyle`-
  Ebenen, kann eine `LayerGroup` die aeussere Struktur bewahren:
  `NamedLayer` → `LayerGroup`, jeder `FeatureTypeStyle` → `Layer`
- bei einfachen SLD-Dokumenten (ein NamedLayer, ein UserStyle, ein
  FeatureTypeStyle) bleibt das Ergebnis ein einzelner `Layer` ohne
  unnoetige Gruppierung
- enthaltene Regeln werden in `Layer.rules` uebernommen

Das bewahrt die Dokumentstruktur besser als bisher, ohne das Kernmodell
direkt mit allen SLD-Zwischenebenen aufzuladen.

### 3. `mapstyler_qml_adapter`

Analog zu SLD: vorhandene Renderer-/Layer-Gruppierungen werden soweit
sinnvoll auf `Layer` und `LayerGroup` gemappt, nicht mehr komplett in
eine flache Regelliste zerlegt.

## Auswirkungen auf `flutter_mapstyler`

Der Renderer sollte **nicht** von heute auf morgen seine einzige
oeffentliche API auf `Map<String, StyledFeatureCollection>` umstellen.
Das waere zu invasiv und wuerde den bestehenden einfachen Pfad
unnötig brechen.

Empfohlene Zielrichtung:

- die bestehende API `renderStyle(style, features)` bleibt erhalten
- fuer Styles ohne `sourceRef` oder fuer den einfachen Host-Fall bleibt
  das Verhalten unveraendert
- fuer source-gebundene Layer kommt ein zusaetzlicher Multi-Source-Pfad
  hinzu, statt den Single-Source-Pfad zu ersetzen

Beispielhaft:

```dart
List<Widget> renderStyle({
  required Style style,
  required StyledFeatureCollection features,
  ...
});

List<Widget> renderStyleWithSources({
  required Style style,
  required Map<String, StyledFeatureCollection> sources,
  StyledFeatureCollection? defaultFeatures,
  ...
});
```

Dann ist die Semantik klar:

- Layer ohne `sourceRef` nutzen `defaultFeatures`
- Layer mit `sourceRef` ziehen ihre Daten aus `sources[sourceRef]`
- Host-Apps koennen klein anfangen und muessen nur fuer echte
  Multi-Source-Stile den erweiterten Pfad nutzen

Rendering-Regeln fuer `flutter_mapstyler`:

- **Baum-Traversierung**: Der Renderer traversiert `Style.children` per
  Tiefensuche (pre-order), wendet die Vererbungsregeln aus Abschnitt 4
  an und erzeugt eine flache Liste effektiver Layer-Zustaende. Jeder
  Eintrag enthaelt den aufgeloesten `Layer` mit effektiver `visible`,
  `opacity` und `zIndex`.
- **zIndex-Aufloesung**: `zIndex` wirkt **global** ueber alle
  effektiven Layer nach der Baum-Aufloesung, nicht lokal innerhalb
  einer Gruppe. Die Traversierung erzeugt eine flache Liste; diese
  wird anschliessend stabil nach `zIndex` sortiert (Layers ohne
  `zIndex` behalten ihre Traversierungsposition). Das entspricht dem
  OpenLayers-Verhalten, bei dem `getLayerStatesArray()` den Baum
  flattened und die Map-Rendering-Pipeline anschliessend global nach
  `zIndex` sortiert.
- **Opacity-Kombination**: Dreistufige Multiplikation:
  `group.opacity * layer.opacity * symbolizer.opacity`. Alle Werte
  im Bereich 0..1, `null` wird als `1.0` behandelt.
- **Cache-Keys**: Der bestehende Frame-Cache nutzt
  `identityHashCode(features)` fuer eine einzelne
  `StyledFeatureCollection`. Bei Multi-Source muss der Cache-Key alle
  Source-Collections einbeziehen (z.B. kombinierter Hash ueber
  `identityHashCode` jeder Collection in `sources`). Aendert sich eine
  einzelne Source-Collection, muss der Cache invalidiert werden.

## Auswirkungen auf Editor und Tooling

Ein Layer-Modell mit Gruppen hilft dem geplanten Editor deutlich:

- Regeln koennen innerhalb eines Layers bearbeitet werden
- Layer-Sichtbarkeit und Reihenfolge werden explizit editierbar
- `LayerGroup` ermoeglicht eine Baumansicht (wie in QGIS oder
  OpenLayers Layer-Panel), in der Gruppen auf-/zugeklappt und
  als Einheit ein-/ausgeblendet werden koennen
- Drag-and-Drop von Layern zwischen Gruppen ist im Modell abgebildet
- spaetere Source-Bindung ist im Modell vorgesehen, ohne Flutter-
  Abhaengigkeit

Gleichzeitig sollte der Editor `sourceRef` nur als Metadatum behandeln,
nicht als verpflichtende Laufzeit-Infrastruktur.

## Zusammenfassung

| Bereich | Aenderung | Anmerkung |
|---|---|---|
| `mapstyler_style` | `LayerNode` (sealed), `Layer`, `LayerGroup` | groesste Modell-Aenderung |
| `mapstyler_style` | `Style.children` plus deprecated `Style.rules` | Migrationspfad statt harter Bruch |
| `mapstyler_mapbox_adapter` | Layer-Struktur und `sourceRef` erhalten | optionale Gruppierung nach Source |
| `mapstyler_sld_adapter` | `NamedLayer` → `Layer`/`LayerGroup` | Struktur geht weniger verloren |
| `mapstyler_qml_adapter` | vorhandene Layer-Gruppierung erhalten | analog zu SLD |
| `flutter_mapstyler` | Baum-Traversierung, Multi-Source ergaenzen | keine abrupte API-Abloesung |
| Neues Paket | keines | Layer bleibt Teil des Kernmodells |

## Entscheidung

`Layer` und `LayerGroup` sollen Kernmodell-Typen werden.

Die tragfaehige Variante dafuer ist:

- `LayerNode` als sealed Basistyp mit `Layer` und `LayerGroup` in
  `mapstyler_style`
- klare Trennung zwischen Kernfeldern und optionalen Metadaten
- Vererbung von `visible`, `opacity`, `zIndex` in Gruppen nach
  definierten Regeln (AND, Multiplikation, Fallback)
- Migration ueber impliziten Default-Layer und deprecated `Style.rules`
- Renderer-Erweiterung zusaetzlich, nicht ersetzend

Damit bleibt das Modell ausbaubar, ohne den heutigen Codepfad unnoetig
hart zu brechen. Einfache Styles ohne Gruppen sind weiterhin moeglich
und erfordern keinerlei Verschachtelung.
