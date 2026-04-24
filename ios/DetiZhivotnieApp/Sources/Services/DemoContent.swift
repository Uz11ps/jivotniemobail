//
//  DemoContent.swift
//  DetiZhivotnieApp
//
//  Fallback content used when Firebase isn't configured (e.g. running the
//  simulator without a GoogleService-Info.plist). Category list + animal
//  order match Figma section "1.1 Categories content" (node 1:8009).
//
//  Six categories in Figma-defined order:
//    1. Pets       — free
//    2. Farm       — paid
//    3. Forest     — paid
//    4. Savannah   — paid
//    5. Pond       — paid
//    6. Jungle     — paid
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
            id: "savannah", order: 3, isVisible: true, isPaid: true,
            iapProductId: "com.app.category.savannah",
            title: .init(ru: "Саванна", en: "Savannah"),
            tabIconAssetPath: "hero_savannah", gridCardStyle: nil
        ),
        Category(
            id: "pond", order: 4, isVisible: true, isPaid: true,
            iapProductId: "com.app.category.pond",
            title: .init(ru: "Пруд", en: "Pond"),
            tabIconAssetPath: "hero_pond", gridCardStyle: nil
        ),
        Category(
            id: "jungle", order: 5, isVisible: true, isPaid: true,
            iapProductId: "com.app.category.jungle",
            title: .init(ru: "Джунгли", en: "Jungle"),
            tabIconAssetPath: "hero_jungle", gridCardStyle: nil
        )
    ]

    // MARK: - Animals — order matches Figma node 1:8009

    static func animals(for categoryId: String) -> [Animal] {
        switch categoryId {
        case "pets":
            return makeAnimals([
                ("cat",       "Кот",             "Cat"),
                ("rabbit",    "Кролик",          "Rabbit"),
                ("iguana",    "Игуана",          "Iguana"),
                ("hamster",   "Хомяк",           "Hamster"),
                ("snail",     "Улитка",          "Snail"),
                ("ferret",    "Хорёк",           "Ferret"),
                ("parrot",    "Попугай",         "Parrot"),
                ("rat",       "Крыса",           "Rat"),
                ("turtle",    "Черепаха",        "Turtle"),
                ("dog",       "Собака",          "Dog"),
                ("chinchilla","Шиншилла",        "Chinchilla"),
                ("guineapig", "Морская свинка",  "Guinea pig")
            ], category: "pets")

        case "farm":
            return makeAnimals([
                ("horse",   "Лошадь",  "Horse"),
                ("pig",     "Свинья",  "Pig"),
                ("cow",     "Корова",  "Cow"),
                ("chicken", "Курица",  "Chicken"),
                ("sheep",   "Овца",    "Sheep"),
                ("quail",   "Перепёл", "Quail"),
                ("ostrich", "Страус",  "Ostrich"),
                ("goose",   "Гусь",    "Goose"),
                ("deer",    "Олень",   "Deer"),
                ("bee",     "Пчела",   "Bee"),
                ("camel",   "Верблюд", "Camel"),
                ("llama",   "Лама",    "Llama")
            ], category: "farm")

        case "forest":
            return makeAnimals([
                ("bear",       "Медведь", "Bear"),
                ("wolf",       "Волк",    "Wolf"),
                ("fox",        "Лиса",    "Fox"),
                ("owl",        "Сова",    "Owl"),
                ("squirrel",   "Белка",   "Squirrel"),
                ("woodpecker", "Дятел",   "Woodpecker"),
                ("hedgehog",   "Ёж",      "Hedgehog"),
                ("elk",        "Лось",    "Elk"),
                ("cuckoo",     "Кукушка", "Cuckoo"),
                ("weasel",     "Ласка",   "Weasel"),
                ("raven",      "Ворон",   "Raven"),
                ("ant",        "Муравей", "Ant")
            ], category: "forest")

        case "savannah":
            return makeAnimals([
                ("lion",         "Лев",         "Lion"),
                ("elephant",     "Слон",        "Elephant"),
                ("leopard",      "Леопард",     "Leopard"),
                ("rhinoceros",   "Носорог",     "Rhinoceros"),
                ("giraffe",      "Жираф",       "Giraffe"),
                ("zebra",        "Зебра",       "Zebra"),
                ("warthog",      "Бородавочник","Warthog"),
                ("meerkat",      "Сурикат",     "Meerkat"),
                ("baboon",       "Бабуин",      "Baboon"),
                ("vulture",      "Гриф",        "Vulture"),
                ("hippopotamus", "Бегемот",     "Hippopotamus"),
                ("wildebeest",   "Антилопа гну","Wildebeest")
            ], category: "savannah")

        case "pond":
            return makeAnimals([
                ("dragonfly",    "Стрекоза",     "Dragonfly"),
                ("crayfish",     "Рак",          "Crayfish"),
                ("beaver",       "Бобр",         "Beaver"),
                ("triton",       "Тритон",       "Triton"),
                ("frog",         "Лягушка",      "Frog"),
                ("divingbeetle", "Жук-плавунец", "Diving beetle"),
                ("waterstrider", "Водомерка",    "Water strider"),
                ("duck",         "Утка",         "Duck"),
                ("heron",        "Цапля",        "Heron"),
                ("perch",        "Окунь",        "Perch"),
                ("pike",         "Щука",         "Pike"),
                ("butterfly",    "Бабочка",      "Butterfly")
            ], category: "pond")

        case "jungle":
            return makeAnimals([
                ("jaguar",      "Ягуар",     "Jaguar"),
                ("sloth",       "Ленивец",   "Sloth"),
                ("anaconda",    "Анаконда",  "Anaconda"),
                ("crocodile",   "Крокодил",  "Crocodile"),
                ("capybara",    "Капибара",  "Capybara"),
                ("anteater",    "Муравьед",  "Anteater"),
                ("chimpanzee",  "Шимпанзе",  "Chimpanzee"),
                ("tiger",       "Тигр",      "Tiger"),
                ("hummingbird", "Колибри",   "Hummingbird"),
                ("mantis",      "Богомол",   "Mantis"),
                ("chameleon",   "Хамелеон",  "Chameleon"),
                ("panther",     "Пантера",   "Panther")
            ], category: "jungle")

        default:
            return []
        }
    }

    /// Builds demo animals with `previewAssetPath` pointing at the bundled
    /// asset-catalog slot `<category>_animal_<n>`. Views check
    /// `UIImage(named:)` first, so missing slots fall through to SF Symbols.
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
