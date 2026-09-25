/// A vetted numbering system: the ten digits and, for a few systems, the separators a locale renders an
/// amount with, such as Latin `0`–`9`, Arabic-Indic `٠`–`٩` or Devanagari `०`–`९`.
///
/// A value is one of the ``NumberingSystem`` constants or the result of the failable ``init(_:)`` — never
/// an arbitrary string — so every value names a system the engine can actually render (one of the 77
/// CLDR numeric systems whose ten digits are consecutive same-width scalars). Algorithmic systems and
/// `hanidec`, whose digits are not consecutive, are not representable and are absent by construction; a
/// request for one is rejected here and left to the Foundation/ICU fallback.
public struct NumberingSystem: Hashable, Sendable {
    /// The CLDR system name (`"latn"`, `"arab"`, …). A package detail, never public: callers name a
    /// system through a constant, so renaming the CLDR string is an internal change, not a public break.
    package let identifier: String

    /// Wraps a CLDR system name the generator has already proven representable. Not public: only the
    /// generator and the vetted constants below build one, which is what keeps every value renderable.
    package init(cldr identifier: String) {
        self.identifier = identifier
    }

    /// Creates a numbering system from its CLDR name, or `nil` unless it names a supported system.
    ///
    /// Supported means one of the 77 CLDR numeric systems the engine can render; `"hanidec"`, an
    /// algorithmic system, or any unknown name returns `nil`.
    ///
    /// - Parameter identifier: A CLDR numbering-system name, e.g. `"arab"`.
    public init?(_ identifier: String) {
        guard Self.supportedIdentifiers.contains(identifier) else {
            return nil
        }

        self.identifier = identifier
    }
}

public extension NumberingSystem {
    /// The Adlam digits (`adlm`).
    static let adlam = NumberingSystem(cldr: "adlm")

    /// The Ahom digits (`ahom`).
    static let ahom = NumberingSystem(cldr: "ahom")

    /// The Arabic-Indic digits (`arab`).
    static let arabicIndic = NumberingSystem(cldr: "arab")

    /// The extended Arabic-Indic digits (`arabext`).
    static let extendedArabicIndic = NumberingSystem(cldr: "arabext")

    /// The Balinese digits (`bali`).
    static let balinese = NumberingSystem(cldr: "bali")

    /// The Bengali digits (`beng`).
    static let bengali = NumberingSystem(cldr: "beng")

    /// The Bhaiksuki digits (`bhks`).
    static let bhaiksuki = NumberingSystem(cldr: "bhks")

    /// The Brahmi digits (`brah`).
    static let brahmi = NumberingSystem(cldr: "brah")

    /// The Chakma digits (`cakm`).
    static let chakma = NumberingSystem(cldr: "cakm")

    /// The Cham digits (`cham`).
    static let cham = NumberingSystem(cldr: "cham")

    /// The Devanagari digits (`deva`).
    static let devanagari = NumberingSystem(cldr: "deva")

    /// The Dives Akuru digits (`diak`).
    static let divesAkuru = NumberingSystem(cldr: "diak")

    /// The full-width digits (`fullwide`).
    static let fullWidth = NumberingSystem(cldr: "fullwide")

    /// The Garay digits (`gara`).
    static let garay = NumberingSystem(cldr: "gara")

    /// The Gunjala Gondi digits (`gong`).
    static let gunjalaGondi = NumberingSystem(cldr: "gong")

    /// The Masaram Gondi digits (`gonm`).
    static let masaramGondi = NumberingSystem(cldr: "gonm")

    /// The Gujarati digits (`gujr`).
    static let gujarati = NumberingSystem(cldr: "gujr")

    /// The Gurung Khema digits (`gukh`).
    static let gurungKhema = NumberingSystem(cldr: "gukh")

    /// The Gurmukhi digits (`guru`).
    static let gurmukhi = NumberingSystem(cldr: "guru")

    /// The Pahawh Hmong digits (`hmng`).
    static let pahawhHmong = NumberingSystem(cldr: "hmng")

    /// The Nyiakeng Puachue Hmong digits (`hmnp`).
    static let nyiakengPuachueHmong = NumberingSystem(cldr: "hmnp")

    /// The Javanese digits (`java`).
    static let javanese = NumberingSystem(cldr: "java")

    /// The Kayah Li digits (`kali`).
    static let kayahLi = NumberingSystem(cldr: "kali")

    /// The Kawi digits (`kawi`).
    static let kawi = NumberingSystem(cldr: "kawi")

    /// The Khmer digits (`khmr`).
    static let khmer = NumberingSystem(cldr: "khmr")

    /// The Kannada digits (`knda`).
    static let kannada = NumberingSystem(cldr: "knda")

    /// The Kirat Rai digits (`krai`).
    static let kiratRai = NumberingSystem(cldr: "krai")

    /// The Tai Tham Hora digits (`lana`).
    static let taiThamHora = NumberingSystem(cldr: "lana")

    /// The Tai Tham Tham digits (`lanatham`).
    static let taiThamTham = NumberingSystem(cldr: "lanatham")

    /// The Lao digits (`laoo`).
    static let lao = NumberingSystem(cldr: "laoo")

    /// The Latin digits (`latn`).
    static let latin = NumberingSystem(cldr: "latn")

    /// The Lepcha digits (`lepc`).
    static let lepcha = NumberingSystem(cldr: "lepc")

    /// The Limbu digits (`limb`).
    static let limbu = NumberingSystem(cldr: "limb")

    /// The mathematical bold digits (`mathbold`).
    static let mathBold = NumberingSystem(cldr: "mathbold")

    /// The mathematical double-struck digits (`mathdbl`).
    static let mathDoubleStruck = NumberingSystem(cldr: "mathdbl")

    /// The mathematical monospace digits (`mathmono`).
    static let mathMonospace = NumberingSystem(cldr: "mathmono")

    /// The mathematical sans-serif bold digits (`mathsanb`).
    static let mathSansSerifBold = NumberingSystem(cldr: "mathsanb")

    /// The mathematical sans-serif digits (`mathsans`).
    static let mathSansSerif = NumberingSystem(cldr: "mathsans")

    /// The Malayalam digits (`mlym`).
    static let malayalam = NumberingSystem(cldr: "mlym")

    /// The Modi digits (`modi`).
    static let modi = NumberingSystem(cldr: "modi")

    /// The Mongolian digits (`mong`).
    static let mongolian = NumberingSystem(cldr: "mong")

    /// The Mro digits (`mroo`).
    static let mro = NumberingSystem(cldr: "mroo")

    /// The Meetei Mayek digits (`mtei`).
    static let meeteiMayek = NumberingSystem(cldr: "mtei")

    /// The Myanmar digits (`mymr`).
    static let myanmar = NumberingSystem(cldr: "mymr")

    /// The Myanmar Eastern Pwo Karen digits (`mymrepka`).
    static let myanmarEasternPwoKaren = NumberingSystem(cldr: "mymrepka")

    /// The Myanmar Pao digits (`mymrpao`).
    static let myanmarPao = NumberingSystem(cldr: "mymrpao")

    /// The Myanmar Shan digits (`mymrshan`).
    static let myanmarShan = NumberingSystem(cldr: "mymrshan")

    /// The Myanmar Tai Laing digits (`mymrtlng`).
    static let myanmarTaiLaing = NumberingSystem(cldr: "mymrtlng")

    /// The Nag Mundari digits (`nagm`).
    static let nagMundari = NumberingSystem(cldr: "nagm")

    /// The Newa digits (`newa`).
    static let newa = NumberingSystem(cldr: "newa")

    /// The N'Ko digits (`nkoo`).
    static let nko = NumberingSystem(cldr: "nkoo")

    /// The Ol Chiki digits (`olck`).
    static let olChiki = NumberingSystem(cldr: "olck")

    /// The Ol Onal digits (`onao`).
    static let olOnal = NumberingSystem(cldr: "onao")

    /// The Odia digits (`orya`).
    static let odia = NumberingSystem(cldr: "orya")

    /// The Osmanya digits (`osma`).
    static let osmanya = NumberingSystem(cldr: "osma")

    /// The outlined digits (`outlined`).
    static let outlined = NumberingSystem(cldr: "outlined")

    /// The Hanifi Rohingya digits (`rohg`).
    static let hanifiRohingya = NumberingSystem(cldr: "rohg")

    /// The Saurashtra digits (`saur`).
    static let saurashtra = NumberingSystem(cldr: "saur")

    /// The segmented digits (`segment`).
    static let segmented = NumberingSystem(cldr: "segment")

    /// The Sharada digits (`shrd`).
    static let sharada = NumberingSystem(cldr: "shrd")

    /// The Khudawadi digits (`sind`).
    static let khudawadi = NumberingSystem(cldr: "sind")

    /// The Sinhala Lith digits (`sinh`).
    static let sinhalaLith = NumberingSystem(cldr: "sinh")

    /// The Sora Sompeng digits (`sora`).
    static let soraSompeng = NumberingSystem(cldr: "sora")

    /// The Sundanese digits (`sund`).
    static let sundanese = NumberingSystem(cldr: "sund")

    /// The Sunuwar digits (`sunu`).
    static let sunuwar = NumberingSystem(cldr: "sunu")

    /// The Takri digits (`takr`).
    static let takri = NumberingSystem(cldr: "takr")

    /// The New Tai Lue digits (`talu`).
    static let newTaiLue = NumberingSystem(cldr: "talu")

    /// The Tamil digits (`tamldec`).
    static let tamil = NumberingSystem(cldr: "tamldec")

    /// The Telugu digits (`telu`).
    static let telugu = NumberingSystem(cldr: "telu")

    /// The Thai digits (`thai`).
    static let thai = NumberingSystem(cldr: "thai")

    /// The Tibetan digits (`tibt`).
    static let tibetan = NumberingSystem(cldr: "tibt")

    /// The Tirhuta digits (`tirh`).
    static let tirhuta = NumberingSystem(cldr: "tirh")

    /// The Tangsa digits (`tnsa`).
    static let tangsa = NumberingSystem(cldr: "tnsa")

    /// The Tolong Siki digits (`tols`).
    static let tolongSiki = NumberingSystem(cldr: "tols")

    /// The Vai digits (`vaii`).
    static let vai = NumberingSystem(cldr: "vaii")

    /// The Warang Citi digits (`wara`).
    static let warangCiti = NumberingSystem(cldr: "wara")

    /// The Wancho digits (`wcho`).
    static let wancho = NumberingSystem(cldr: "wcho")
}

extension NumberingSystem {
    /// Every supported numbering system, for the generator's coverage guard and blob emission.
    package static let all: [NumberingSystem] = [
        .adlam, .ahom, .arabicIndic, .extendedArabicIndic, .balinese, .bengali, .bhaiksuki, .brahmi, .chakma, .cham, .devanagari, .divesAkuru, .fullWidth, .garay, .gunjalaGondi, .masaramGondi, .gujarati, .gurungKhema, .gurmukhi, .pahawhHmong, .nyiakengPuachueHmong, .javanese, .kayahLi, .kawi, .khmer, .kannada, .kiratRai, .taiThamHora, .taiThamTham, .lao, .latin, .lepcha, .limbu, .mathBold, .mathDoubleStruck, .mathMonospace, .mathSansSerifBold, .mathSansSerif, .malayalam, .modi, .mongolian, .mro, .meeteiMayek, .myanmar, .myanmarEasternPwoKaren, .myanmarPao, .myanmarShan, .myanmarTaiLaing, .nagMundari, .newa, .nko, .olChiki, .olOnal, .odia, .osmanya, .outlined, .hanifiRohingya, .saurashtra, .segmented, .sharada, .khudawadi, .sinhalaLith, .soraSompeng, .sundanese, .sunuwar, .takri, .newTaiLue, .tamil, .telugu, .thai, .tibetan, .tirhuta, .tangsa, .tolongSiki, .vai, .warangCiti, .wancho
    ]

    // The CLDR names ``init(_:)`` accepts, derived from ``all`` so the two cannot drift apart.
    private static let supportedIdentifiers: Set<String> = Set(all.map { $0.identifier })
}
