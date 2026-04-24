//
//  DemoContent.swift
//  DetiZhivotnieApp
//
//  Fallback content used when Firebase isn't configured (e.g. running the
//  simulator without a GoogleService-Info.plist). Lets reviewers see the
//  full UI — Main/Cabinet/Paywall/Animal card — without a backend.
//

import Foundation

enum DemoContent {

    // MARK: - Categories

    static let categories: [Category] = [
        Category(
            id: "pets", order: 0, isVisible: true, isPaid: false,
            iapProductId: nil,
            title: .init(ru: "Питомцы", en: "Pets"),
            tabIconAssetPath: "hero_pets", gridCardStyle: nil
        ),
        Category(
            id: "farm", order: 1, isVisible: true, isPaid: true,
            iapProductId: "com.app.category.farm",
            title: .init(ru: "Ферма", en: "Farm"),
            tabIconAssetPath: "hero_farm", gridCardStyle: nil
        ),
        Category(
            id: "forest", order: 2, isVisible: true, isPaid: true,
            iapProductId: "com.app.category.forest",
            title: .init(ru: "Лес", en: "Forest"),
            tabIconAssetPath: "hero_forest", gridCardStyle: nil
        ),
        Category(
            id: "sea", order: 3, isVisible: true, isPaid: true,
            iapProductId: "com.app.category.sea",
            title: .init(ru: "Море", en: "Sea"),
            tabIconAssetPath: "hero_sea", gridCardStyle: nil
        ),
        Category(
            id: "dream", order: 4, isVisible: true, isPaid: true,
            iapProductId: "com.app.category.dream",
            title: .init(ru: "Сказка", en: "Dream"),
            tabIconAssetPath: "hero_dream", gridCardStyle: nil
        )
    ]

    // MARK: - Animals

    static func animals(for categoryId: String) -> [Animal] {
        switch categoryId {
        case "pets":
            return makeAnimals([
                ("cat",     "Кот",      "Cat"),
                ("rabbit",  "Кролик",   "Rabbit"),
                ("frog",    "Лягушка",  "Frog"),
                ("hamster", "Хомяк",    "Hamster"),
                ("snail",   "Улитка",   "Snail"),
                ("ferret",  "Хорёк",    "Ferret"),
                ("parrot",  "Попугай",  "Parrot"),
                ("mouse",   "Мышь",     "Mouse"),
                ("turtle",  "Черепаха", "Turtle"),
                ("dog",     "Собака",   "Dog"),
                ("guineapig","Морская свинка","Guinea pig")
            ], category: "pets")
        case "farm":
            return makeAnimals([
                ("cow",     "Корова",   "Cow"),
                ("sheep",   "Овца",     "Sheep"),
                ("pig",     "Свинья",   "Pig"),
                ("horse",   "Лошадь",   "Horse"),
                ("chicken", "Курица",   "Chicken"),
                ("rooster", "Петух",    "Rooster"),
                ("goat",    "Коза",     "Goat"),
                ("duck",    "Утка",     "Duck"),
                ("donkey",  "Осёл",     "Donkey"),
                ("bunny",   "Крольчонок","Bunny")
            ], category: "farm")
        case "forest":
            return makeAnimals([
                ("bear",    "Медведь",  "Bear"),
                ("wolf",    "Волк",     "Wolf"),
                ("fox",     "Лиса",     "Fox"),
                ("owl",     "Сова",     "Owl"),
                ("squirrel","Белка",    "Squirrel"),
                ("woodpecker","Дятел", "Woodpecker"),
                ("hedgehog","Ёж",       "Hedgehog"),
                ("deer",    "Олень",    "Deer"),
                ("rabbit2", "Заяц",     "Hare"),
                ("moose",   "Лось",     "Moose"),
                ("badger",  "Барсук",   "Badger")
            ], category: "forest")
        case "sea":
            return makeAnimals([
                ("dolphin", "Дельфин",  "Dolphin"),
                ("whale",   "Кит",      "Whale"),
                ("shark",   "Акула",    "Shark"),
                ("octopus", "Осьминог", "Octopus"),
                ("seahorse","Морской конёк","Seahorse"),
                ("crab",    "Краб",     "Crab"),
                ("fish",    "Рыбка",    "Fish"),
                ("jellyfish","Медуза",  "Jellyfish"),
                ("turtle2", "Черепаха", "Turtle"),
                ("starfish","Морская звезда","Starfish"),
                ("seal",    "Тюлень",   "Seal")
            ], category: "sea")
        case "dream":
            return makeAnimals([
                ("unicorn", "Единорог",  "Unicorn"),
                ("dragon",  "Дракон",    "Dragon"),
                ("phoenix", "Феникс",    "Phoenix"),
                ("pegasus", "Пегас",     "Pegasus"),
                ("mermaid", "Русалка",   "Mermaid"),
                ("yeti",    "Йети",      "Yeti"),
                ("griffin", "Грифон",    "Griffin"),
                ("kraken",  "Кракен",    "Kraken"),
                ("sphinx",  "Сфинкс",    "Sphinx"),
                ("fairy",   "Фея",       "Fairy"),
                ("wizard",  "Волшебник", "Wizard")
            ], category: "dream")
        default:
            return []
        }
    }

    /// Populates previewAssetPath with the bundled asset-catalog name
    /// `<category>_animal_<n>` that we transferred from `img/<Category>/Image<n>.png`.
    /// Callers (AnimalTile / CategoryHero) check `UIImage(named:)` first, so
    /// this doubles as a demo image AND a fallback slot name for later
    /// Firebase-sourced overrides.
    private static func makeAnimals(
        _ rows: [(id: String, ru: String, en: String)],
        category: String
    ) -> [Animal] {
        rows.enumerated().map { idx, row in
            let assetName = "\(category)_animal_\(idx + 1)"
            return Animal(
                id: row.id,
                order: idx,
                isVisible: true,
                name: .init(ru: row.ru, en: row.en),
                bgAssetPath: "hero_\(category)",
                previewAssetPath: assetName,
                voiceAssetPath: nil,
                soundAssetPath: "",
                animationAssetPath: nil,
                animationVideoAssetPath: nil
            )
        }
    }
}
