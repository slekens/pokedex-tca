import Foundation

/// Los 18 tipos oficiales de Pokémon.
///
/// Usados por la feature de filtros y para pintar los chips en la fila.
enum PokemonType: String, CaseIterable, Identifiable, Hashable, Sendable {
    case normal, fire, water, electric, grass, ice, fighting, poison
    case ground, flying, psychic, bug, rock, ghost, dragon, dark, steel, fairy

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }
}
