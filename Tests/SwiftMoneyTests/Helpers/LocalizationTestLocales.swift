import Foundation

/// Shared locale list for parameterized localisation tests.
///
/// Covers a broad range of scripts, number-formatting conventions, and
/// currency-symbol placement rules:
///   - Western European (Latin script, various decimal/grouping separators)
///   - Eastern European (Cyrillic and Latin)
///   - RTL scripts (Arabic, Hebrew, Persian)
///   - South/South-East Asian (Devanagari, Thai, Latin)
///   - CJK (Japanese, Chinese Simplified/Traditional, Korean)
///   - Caucasian (Georgian)
///
/// Each entry is a fixed locale (not autoupdating) so tests are
/// deterministic regardless of the host machine's current locale.
let localizationTestLocales: [Locale] = [
    // Western European — Latin script
    Locale(identifier: "en_US"),
    Locale(identifier: "en_GB"),
    Locale(identifier: "en_CA"),
    Locale(identifier: "en_AU"),
    Locale(identifier: "fr_FR"),
    Locale(identifier: "de_DE"),
    Locale(identifier: "de_CH"),
    Locale(identifier: "es_ES"),
    Locale(identifier: "es_MX"),
    Locale(identifier: "pt_BR"),
    Locale(identifier: "it_IT"),
    Locale(identifier: "nl_NL"),
    Locale(identifier: "pl_PL"),
    Locale(identifier: "sv_SE"),
    Locale(identifier: "nb_NO"),
    Locale(identifier: "da_DK"),
    Locale(identifier: "fi_FI"),
    // Eastern European
    Locale(identifier: "ru_RU"),
    Locale(identifier: "uk_UA"),
    Locale(identifier: "cs_CZ"),
    Locale(identifier: "ro_RO"),
    Locale(identifier: "hu_HU"),
    Locale(identifier: "bg_BG"),
    // RTL / non-Latin scripts
    Locale(identifier: "ar_SA"),
    Locale(identifier: "ar_AE"),
    Locale(identifier: "he_IL"),
    Locale(identifier: "fa_IR"),
    // South / South-East Asian
    Locale(identifier: "hi_IN"),
    Locale(identifier: "th_TH"),
    Locale(identifier: "id_ID"),
    // CJK
    Locale(identifier: "ja_JP"),
    Locale(identifier: "zh_Hans_CN"),
    Locale(identifier: "zh_Hant_TW"),
    Locale(identifier: "ko_KR"),
    // Other
    Locale(identifier: "tr_TR"),
    Locale(identifier: "ka_GE"),
]
