# Pokédex TCA

Pokédex de iOS construida con [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) (TCA 1.26). Acompaña la [serie de posts en slekens.dev](https://slekens.dev/es/blog/pokedex-tca-01-arranque/), donde se explica cada decisión de arquitectura sobre este código.

Es también la contraparte TCA de [PokeTracker](https://github.com/slekens/PokeTrack), la misma app hecha con MVVM tradicional. Las dos existen para poder compararlas de verdad, sobre código real y con el mismo alcance.

## Alcance

Cinco pantallas suficientes para ejercitar los patrones más importantes de TCA:

- Lista de Pokémon con paginación y estado remoto como enum
- Detalle con navegación como estado (`@Presents` + `Destination` enum)
- Favoritos compartidos entre lista y detalle con `@Shared` y persistencia en disco
- Búsqueda con debounce y cancelación de efectos en vuelo
- Filtros por tipo modelados como sub-feature con `BindingReducer`

Los datos vienen de la [PokeAPI](https://pokeapi.co).

## Requisitos

- Xcode 26 o superior
- iOS 17 como deployment target
- Swift 6

## Cómo correrla

El proyecto se genera con [XcodeGen](https://github.com/yonaskolb/XcodeGen). El `PokedexTCA.xcodeproj` está commiteado, así que basta con abrirlo:

```bash
open PokedexTCA.xcodeproj
```

Si tocas el `project.yml` para agregar archivos o cambiar configuración, regenera el proyecto:

```bash
brew install xcodegen   # una vez
xcodegen generate
```

## Estructura

```
PokedexTCA/
├── App/                    # Entry point + reducer raíz + Destination enum
├── Features/
│   ├── PokemonList/        # Feature principal (lista, paginación, búsqueda)
│   ├── PokemonDetail/      # Feature de detalle
│   └── Filters/            # Sub-feature de filtros por tipo
└── Core/
    ├── Models/             # Pokemon, PokemonDetail, LoadState, PokemonType
    ├── Clients/            # PokemonClient (dependencia) + PokeAPI (HTTP)
    └── Shared/             # Claves de @Shared (favoritos)
```

Cada feature contiene su `Reducer` y su `View` en la misma carpeta. El proyecto crece por feature, no por tipo de archivo.

## APIs de TCA usadas

- `@Reducer`, `@ObservableState`
- `@Bindable var store` en las vistas (sin `ViewStore`/`WithViewStore`)
- Efectos cancelables con `.cancellable(id:cancelInFlight:)`
- Composición con `Scope`
- Navegación con `@Presents` + `@Reducer enum` para destinos
- `@Shared(.fileStorage)` + `withLock` para favoritos
- `BindingReducer` + `BindableAction` para los toggles de filtros
- `@Dependency(\.continuousClock)` para debounce testeable

## Licencia

MIT.
