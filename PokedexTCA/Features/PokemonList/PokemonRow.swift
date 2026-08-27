import SwiftUI

struct PokemonRow: View {
    let pokemon: Pokemon
    let isFavorite: Bool

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: pokemon.spriteURL) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading) {
                Text(pokemon.name.capitalized).font(.headline)
                Text(pokemon.types.map(\.capitalized).joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isFavorite {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
            }
        }
    }
}
