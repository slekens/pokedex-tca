import ComposableArchitecture

/// Todos los destinos presentables desde la lista.
///
/// De momento solo el detalle. Modelarlo como enum desde el inicio deja
/// añadir más pantallas (share, editor, etc.) sin refactor.
@Reducer
enum Destination {
    case detail(PokemonDetailFeature)
}

extension Destination.State: Equatable {}
