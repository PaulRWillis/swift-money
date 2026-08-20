// Generated from ISO 4217's list-one.xml, published 2026-01-01. Do not edit by hand:
// run `python3 ISO4217/generate.py` instead.
//
// Codes the list gives no minor unit for are absent, because a scale of at least one would
// assert a subdivision the standard declines to state. That is the metals XAU, XAG, XPT and
// XPD, the bond market units XBA to XBD, XDR, XSU, XUA, and the reserved XTS and XXX. Java's
// `Currency.getDefaultFractionDigits()` reports -1 for the same set rather than invent one.

public extension Currency {
    /// UAE Dirham.
    static let aed = Currency(code: "AED", unitScale: 100)

    /// Afghani.
    static let afn = Currency(code: "AFN", unitScale: 100)

    /// Lek.
    static let all = Currency(code: "ALL", unitScale: 100)

    /// Armenian Dram.
    static let amd = Currency(code: "AMD", unitScale: 100)

    /// Kwanza.
    static let aoa = Currency(code: "AOA", unitScale: 100)

    /// Argentine Peso.
    static let ars = Currency(code: "ARS", unitScale: 100)

    /// Australian Dollar.
    static let aud = Currency(code: "AUD", unitScale: 100)

    /// Aruban Florin.
    static let awg = Currency(code: "AWG", unitScale: 100)

    /// Azerbaijan Manat.
    static let azn = Currency(code: "AZN", unitScale: 100)

    /// Convertible Mark.
    static let bam = Currency(code: "BAM", unitScale: 100)

    /// Barbados Dollar.
    static let bbd = Currency(code: "BBD", unitScale: 100)

    /// Taka.
    static let bdt = Currency(code: "BDT", unitScale: 100)

    /// Bahraini Dinar.
    static let bhd = Currency(code: "BHD", unitScale: 1_000)

    /// Burundi Franc.
    static let bif = Currency(code: "BIF", unitScale: 1)

    /// Bermudian Dollar.
    static let bmd = Currency(code: "BMD", unitScale: 100)

    /// Brunei Dollar.
    static let bnd = Currency(code: "BND", unitScale: 100)

    /// Boliviano.
    static let bob = Currency(code: "BOB", unitScale: 100)

    /// Mvdol.
    static let bov = Currency(code: "BOV", unitScale: 100)

    /// Brazilian Real.
    static let brl = Currency(code: "BRL", unitScale: 100)

    /// Bahamian Dollar.
    static let bsd = Currency(code: "BSD", unitScale: 100)

    /// Ngultrum.
    static let btn = Currency(code: "BTN", unitScale: 100)

    /// Pula.
    static let bwp = Currency(code: "BWP", unitScale: 100)

    /// Belarusian Ruble.
    static let byn = Currency(code: "BYN", unitScale: 100)

    /// Belize Dollar.
    static let bzd = Currency(code: "BZD", unitScale: 100)

    /// Canadian Dollar.
    static let cad = Currency(code: "CAD", unitScale: 100)

    /// Congolese Franc.
    static let cdf = Currency(code: "CDF", unitScale: 100)

    /// WIR Euro.
    static let che = Currency(code: "CHE", unitScale: 100)

    /// Swiss Franc.
    static let chf = Currency(code: "CHF", unitScale: 100)

    /// WIR Franc.
    static let chw = Currency(code: "CHW", unitScale: 100)

    /// Unidad de Fomento.
    static let clf = Currency(code: "CLF", unitScale: 10_000)

    /// Chilean Peso.
    static let clp = Currency(code: "CLP", unitScale: 1)

    /// Yuan Renminbi.
    static let cny = Currency(code: "CNY", unitScale: 100)

    /// Colombian Peso.
    static let cop = Currency(code: "COP", unitScale: 100)

    /// Unidad de Valor Real.
    static let cou = Currency(code: "COU", unitScale: 100)

    /// Costa Rican Colon.
    static let crc = Currency(code: "CRC", unitScale: 100)

    /// Cuban Peso.
    static let cup = Currency(code: "CUP", unitScale: 100)

    /// Cabo Verde Escudo.
    static let cve = Currency(code: "CVE", unitScale: 100)

    /// Czech Koruna.
    static let czk = Currency(code: "CZK", unitScale: 100)

    /// Djibouti Franc.
    static let djf = Currency(code: "DJF", unitScale: 1)

    /// Danish Krone.
    static let dkk = Currency(code: "DKK", unitScale: 100)

    /// Dominican Peso.
    static let dop = Currency(code: "DOP", unitScale: 100)

    /// Algerian Dinar.
    static let dzd = Currency(code: "DZD", unitScale: 100)

    /// Egyptian Pound.
    static let egp = Currency(code: "EGP", unitScale: 100)

    /// Nakfa.
    static let ern = Currency(code: "ERN", unitScale: 100)

    /// Ethiopian Birr.
    static let etb = Currency(code: "ETB", unitScale: 100)

    /// Euro.
    static let eur = Currency(code: "EUR", unitScale: 100)

    /// Fiji Dollar.
    static let fjd = Currency(code: "FJD", unitScale: 100)

    /// Falkland Islands Pound.
    static let fkp = Currency(code: "FKP", unitScale: 100)

    /// Pound Sterling.
    static let gbp = Currency(code: "GBP", unitScale: 100)

    /// Lari.
    static let gel = Currency(code: "GEL", unitScale: 100)

    /// Ghana Cedi.
    static let ghs = Currency(code: "GHS", unitScale: 100)

    /// Gibraltar Pound.
    static let gip = Currency(code: "GIP", unitScale: 100)

    /// Dalasi.
    static let gmd = Currency(code: "GMD", unitScale: 100)

    /// Guinean Franc.
    static let gnf = Currency(code: "GNF", unitScale: 1)

    /// Quetzal.
    static let gtq = Currency(code: "GTQ", unitScale: 100)

    /// Guyana Dollar.
    static let gyd = Currency(code: "GYD", unitScale: 100)

    /// Hong Kong Dollar.
    static let hkd = Currency(code: "HKD", unitScale: 100)

    /// Lempira.
    static let hnl = Currency(code: "HNL", unitScale: 100)

    /// Gourde.
    static let htg = Currency(code: "HTG", unitScale: 100)

    /// Forint.
    static let huf = Currency(code: "HUF", unitScale: 100)

    /// Rupiah.
    static let idr = Currency(code: "IDR", unitScale: 100)

    /// New Israeli Sheqel.
    static let ils = Currency(code: "ILS", unitScale: 100)

    /// Indian Rupee.
    static let inr = Currency(code: "INR", unitScale: 100)

    /// Iraqi Dinar.
    static let iqd = Currency(code: "IQD", unitScale: 1_000)

    /// Iranian Rial.
    static let irr = Currency(code: "IRR", unitScale: 100)

    /// Iceland Krona.
    static let isk = Currency(code: "ISK", unitScale: 1)

    /// Jamaican Dollar.
    static let jmd = Currency(code: "JMD", unitScale: 100)

    /// Jordanian Dinar.
    static let jod = Currency(code: "JOD", unitScale: 1_000)

    /// Yen.
    static let jpy = Currency(code: "JPY", unitScale: 1)

    /// Kenyan Shilling.
    static let kes = Currency(code: "KES", unitScale: 100)

    /// Som.
    static let kgs = Currency(code: "KGS", unitScale: 100)

    /// Riel.
    static let khr = Currency(code: "KHR", unitScale: 100)

    /// Comorian Franc.
    static let kmf = Currency(code: "KMF", unitScale: 1)

    /// North Korean Won.
    static let kpw = Currency(code: "KPW", unitScale: 100)

    /// Won.
    static let krw = Currency(code: "KRW", unitScale: 1)

    /// Kuwaiti Dinar.
    static let kwd = Currency(code: "KWD", unitScale: 1_000)

    /// Cayman Islands Dollar.
    static let kyd = Currency(code: "KYD", unitScale: 100)

    /// Tenge.
    static let kzt = Currency(code: "KZT", unitScale: 100)

    /// Lao Kip.
    static let lak = Currency(code: "LAK", unitScale: 100)

    /// Lebanese Pound.
    static let lbp = Currency(code: "LBP", unitScale: 100)

    /// Sri Lanka Rupee.
    static let lkr = Currency(code: "LKR", unitScale: 100)

    /// Liberian Dollar.
    static let lrd = Currency(code: "LRD", unitScale: 100)

    /// Loti.
    static let lsl = Currency(code: "LSL", unitScale: 100)

    /// Libyan Dinar.
    static let lyd = Currency(code: "LYD", unitScale: 1_000)

    /// Moroccan Dirham.
    static let mad = Currency(code: "MAD", unitScale: 100)

    /// Moldovan Leu.
    static let mdl = Currency(code: "MDL", unitScale: 100)

    /// Malagasy Ariary.
    ///
    /// Divides into five iraimbilanja, which ISO 4217 cannot express: its
    /// exponent field holds a power of ten, so it records 2 and footnotes the currency
    /// `divby5`. The scale here follows ISO, because that is what payment systems assume.
    static let mga = Currency(code: "MGA", unitScale: 100)

    /// Denar.
    static let mkd = Currency(code: "MKD", unitScale: 100)

    /// Kyat.
    static let mmk = Currency(code: "MMK", unitScale: 100)

    /// Tugrik.
    static let mnt = Currency(code: "MNT", unitScale: 100)

    /// Pataca.
    static let mop = Currency(code: "MOP", unitScale: 100)

    /// Ouguiya.
    ///
    /// Divides into five khoums, which ISO 4217 cannot express: its
    /// exponent field holds a power of ten, so it records 2 and footnotes the currency
    /// `divby5`. The scale here follows ISO, because that is what payment systems assume.
    static let mru = Currency(code: "MRU", unitScale: 100)

    /// Mauritius Rupee.
    static let mur = Currency(code: "MUR", unitScale: 100)

    /// Rufiyaa.
    static let mvr = Currency(code: "MVR", unitScale: 100)

    /// Malawi Kwacha.
    static let mwk = Currency(code: "MWK", unitScale: 100)

    /// Mexican Peso.
    static let mxn = Currency(code: "MXN", unitScale: 100)

    /// Mexican Unidad de Inversion (UDI).
    static let mxv = Currency(code: "MXV", unitScale: 100)

    /// Malaysian Ringgit.
    static let myr = Currency(code: "MYR", unitScale: 100)

    /// Mozambique Metical.
    static let mzn = Currency(code: "MZN", unitScale: 100)

    /// Namibia Dollar.
    static let nad = Currency(code: "NAD", unitScale: 100)

    /// Naira.
    static let ngn = Currency(code: "NGN", unitScale: 100)

    /// Cordoba Oro.
    static let nio = Currency(code: "NIO", unitScale: 100)

    /// Norwegian Krone.
    static let nok = Currency(code: "NOK", unitScale: 100)

    /// Nepalese Rupee.
    static let npr = Currency(code: "NPR", unitScale: 100)

    /// New Zealand Dollar.
    static let nzd = Currency(code: "NZD", unitScale: 100)

    /// Rial Omani.
    static let omr = Currency(code: "OMR", unitScale: 1_000)

    /// Balboa.
    static let pab = Currency(code: "PAB", unitScale: 100)

    /// Sol.
    static let pen = Currency(code: "PEN", unitScale: 100)

    /// Kina.
    static let pgk = Currency(code: "PGK", unitScale: 100)

    /// Philippine Peso.
    static let php = Currency(code: "PHP", unitScale: 100)

    /// Pakistan Rupee.
    static let pkr = Currency(code: "PKR", unitScale: 100)

    /// Zloty.
    static let pln = Currency(code: "PLN", unitScale: 100)

    /// Guarani.
    static let pyg = Currency(code: "PYG", unitScale: 1)

    /// Qatari Rial.
    static let qar = Currency(code: "QAR", unitScale: 100)

    /// Romanian Leu.
    static let ron = Currency(code: "RON", unitScale: 100)

    /// Serbian Dinar.
    static let rsd = Currency(code: "RSD", unitScale: 100)

    /// Russian Ruble.
    static let rub = Currency(code: "RUB", unitScale: 100)

    /// Rwanda Franc.
    static let rwf = Currency(code: "RWF", unitScale: 1)

    /// Saudi Riyal.
    static let sar = Currency(code: "SAR", unitScale: 100)

    /// Solomon Islands Dollar.
    static let sbd = Currency(code: "SBD", unitScale: 100)

    /// Seychelles Rupee.
    static let scr = Currency(code: "SCR", unitScale: 100)

    /// Sudanese Pound.
    static let sdg = Currency(code: "SDG", unitScale: 100)

    /// Swedish Krona.
    static let sek = Currency(code: "SEK", unitScale: 100)

    /// Singapore Dollar.
    static let sgd = Currency(code: "SGD", unitScale: 100)

    /// Saint Helena Pound.
    static let shp = Currency(code: "SHP", unitScale: 100)

    /// Leone.
    static let sle = Currency(code: "SLE", unitScale: 100)

    /// Somali Shilling.
    static let sos = Currency(code: "SOS", unitScale: 100)

    /// Surinam Dollar.
    static let srd = Currency(code: "SRD", unitScale: 100)

    /// South Sudanese Pound.
    static let ssp = Currency(code: "SSP", unitScale: 100)

    /// Dobra.
    static let stn = Currency(code: "STN", unitScale: 100)

    /// El Salvador Colon.
    static let svc = Currency(code: "SVC", unitScale: 100)

    /// Syrian Pound.
    static let syp = Currency(code: "SYP", unitScale: 100)

    /// Lilangeni.
    static let szl = Currency(code: "SZL", unitScale: 100)

    /// Baht.
    static let thb = Currency(code: "THB", unitScale: 100)

    /// Somoni.
    static let tjs = Currency(code: "TJS", unitScale: 100)

    /// Turkmenistan New Manat.
    static let tmt = Currency(code: "TMT", unitScale: 100)

    /// Tunisian Dinar.
    static let tnd = Currency(code: "TND", unitScale: 1_000)

    /// Pa’anga.
    static let top = Currency(code: "TOP", unitScale: 100)

    /// Turkish Lira.
    static let `try` = Currency(code: "TRY", unitScale: 100)

    /// Trinidad and Tobago Dollar.
    static let ttd = Currency(code: "TTD", unitScale: 100)

    /// New Taiwan Dollar.
    static let twd = Currency(code: "TWD", unitScale: 100)

    /// Tanzanian Shilling.
    static let tzs = Currency(code: "TZS", unitScale: 100)

    /// Hryvnia.
    static let uah = Currency(code: "UAH", unitScale: 100)

    /// Uganda Shilling.
    static let ugx = Currency(code: "UGX", unitScale: 1)

    /// US Dollar.
    static let usd = Currency(code: "USD", unitScale: 100)

    /// US Dollar (Next day).
    static let usn = Currency(code: "USN", unitScale: 100)

    /// Uruguay Peso en Unidades Indexadas (UI).
    static let uyi = Currency(code: "UYI", unitScale: 1)

    /// Peso Uruguayo.
    static let uyu = Currency(code: "UYU", unitScale: 100)

    /// Unidad Previsional.
    static let uyw = Currency(code: "UYW", unitScale: 10_000)

    /// Uzbekistan Sum.
    static let uzs = Currency(code: "UZS", unitScale: 100)

    /// Bolívar Soberano.
    static let ved = Currency(code: "VED", unitScale: 100)

    /// Bolívar Soberano.
    static let ves = Currency(code: "VES", unitScale: 100)

    /// Dong.
    static let vnd = Currency(code: "VND", unitScale: 1)

    /// Vatu.
    static let vuv = Currency(code: "VUV", unitScale: 1)

    /// Tala.
    static let wst = Currency(code: "WST", unitScale: 100)

    /// Arab Accounting Dinar.
    static let xad = Currency(code: "XAD", unitScale: 100)

    /// CFA Franc BEAC.
    static let xaf = Currency(code: "XAF", unitScale: 1)

    /// East Caribbean Dollar.
    static let xcd = Currency(code: "XCD", unitScale: 100)

    /// Caribbean Guilder.
    static let xcg = Currency(code: "XCG", unitScale: 100)

    /// CFA Franc BCEAO.
    static let xof = Currency(code: "XOF", unitScale: 1)

    /// CFP Franc.
    static let xpf = Currency(code: "XPF", unitScale: 1)

    /// Yemeni Rial.
    static let yer = Currency(code: "YER", unitScale: 100)

    /// Rand.
    static let zar = Currency(code: "ZAR", unitScale: 100)

    /// Zambian Kwacha.
    static let zmw = Currency(code: "ZMW", unitScale: 100)

    /// Zimbabwe Gold.
    static let zwg = Currency(code: "ZWG", unitScale: 100)
}


public extension Currencies {
    /// UAE Dirham.
    enum AED: CurrencyType {
        public static let currency: Currency = .aed
    }

    /// Afghani.
    enum AFN: CurrencyType {
        public static let currency: Currency = .afn
    }

    /// Lek.
    enum ALL: CurrencyType {
        public static let currency: Currency = .all
    }

    /// Armenian Dram.
    enum AMD: CurrencyType {
        public static let currency: Currency = .amd
    }

    /// Kwanza.
    enum AOA: CurrencyType {
        public static let currency: Currency = .aoa
    }

    /// Argentine Peso.
    enum ARS: CurrencyType {
        public static let currency: Currency = .ars
    }

    /// Australian Dollar.
    enum AUD: CurrencyType {
        public static let currency: Currency = .aud
    }

    /// Aruban Florin.
    enum AWG: CurrencyType {
        public static let currency: Currency = .awg
    }

    /// Azerbaijan Manat.
    enum AZN: CurrencyType {
        public static let currency: Currency = .azn
    }

    /// Convertible Mark.
    enum BAM: CurrencyType {
        public static let currency: Currency = .bam
    }

    /// Barbados Dollar.
    enum BBD: CurrencyType {
        public static let currency: Currency = .bbd
    }

    /// Taka.
    enum BDT: CurrencyType {
        public static let currency: Currency = .bdt
    }

    /// Bahraini Dinar.
    enum BHD: CurrencyType {
        public static let currency: Currency = .bhd
    }

    /// Burundi Franc.
    enum BIF: CurrencyType {
        public static let currency: Currency = .bif
    }

    /// Bermudian Dollar.
    enum BMD: CurrencyType {
        public static let currency: Currency = .bmd
    }

    /// Brunei Dollar.
    enum BND: CurrencyType {
        public static let currency: Currency = .bnd
    }

    /// Boliviano.
    enum BOB: CurrencyType {
        public static let currency: Currency = .bob
    }

    /// Mvdol.
    enum BOV: CurrencyType {
        public static let currency: Currency = .bov
    }

    /// Brazilian Real.
    enum BRL: CurrencyType {
        public static let currency: Currency = .brl
    }

    /// Bahamian Dollar.
    enum BSD: CurrencyType {
        public static let currency: Currency = .bsd
    }

    /// Ngultrum.
    enum BTN: CurrencyType {
        public static let currency: Currency = .btn
    }

    /// Pula.
    enum BWP: CurrencyType {
        public static let currency: Currency = .bwp
    }

    /// Belarusian Ruble.
    enum BYN: CurrencyType {
        public static let currency: Currency = .byn
    }

    /// Belize Dollar.
    enum BZD: CurrencyType {
        public static let currency: Currency = .bzd
    }

    /// Canadian Dollar.
    enum CAD: CurrencyType {
        public static let currency: Currency = .cad
    }

    /// Congolese Franc.
    enum CDF: CurrencyType {
        public static let currency: Currency = .cdf
    }

    /// WIR Euro.
    enum CHE: CurrencyType {
        public static let currency: Currency = .che
    }

    /// Swiss Franc.
    enum CHF: CurrencyType {
        public static let currency: Currency = .chf
    }

    /// WIR Franc.
    enum CHW: CurrencyType {
        public static let currency: Currency = .chw
    }

    /// Unidad de Fomento.
    enum CLF: CurrencyType {
        public static let currency: Currency = .clf
    }

    /// Chilean Peso.
    enum CLP: CurrencyType {
        public static let currency: Currency = .clp
    }

    /// Yuan Renminbi.
    enum CNY: CurrencyType {
        public static let currency: Currency = .cny
    }

    /// Colombian Peso.
    enum COP: CurrencyType {
        public static let currency: Currency = .cop
    }

    /// Unidad de Valor Real.
    enum COU: CurrencyType {
        public static let currency: Currency = .cou
    }

    /// Costa Rican Colon.
    enum CRC: CurrencyType {
        public static let currency: Currency = .crc
    }

    /// Cuban Peso.
    enum CUP: CurrencyType {
        public static let currency: Currency = .cup
    }

    /// Cabo Verde Escudo.
    enum CVE: CurrencyType {
        public static let currency: Currency = .cve
    }

    /// Czech Koruna.
    enum CZK: CurrencyType {
        public static let currency: Currency = .czk
    }

    /// Djibouti Franc.
    enum DJF: CurrencyType {
        public static let currency: Currency = .djf
    }

    /// Danish Krone.
    enum DKK: CurrencyType {
        public static let currency: Currency = .dkk
    }

    /// Dominican Peso.
    enum DOP: CurrencyType {
        public static let currency: Currency = .dop
    }

    /// Algerian Dinar.
    enum DZD: CurrencyType {
        public static let currency: Currency = .dzd
    }

    /// Egyptian Pound.
    enum EGP: CurrencyType {
        public static let currency: Currency = .egp
    }

    /// Nakfa.
    enum ERN: CurrencyType {
        public static let currency: Currency = .ern
    }

    /// Ethiopian Birr.
    enum ETB: CurrencyType {
        public static let currency: Currency = .etb
    }

    /// Euro.
    enum EUR: CurrencyType {
        public static let currency: Currency = .eur
    }

    /// Fiji Dollar.
    enum FJD: CurrencyType {
        public static let currency: Currency = .fjd
    }

    /// Falkland Islands Pound.
    enum FKP: CurrencyType {
        public static let currency: Currency = .fkp
    }

    /// Pound Sterling.
    enum GBP: CurrencyType {
        public static let currency: Currency = .gbp
    }

    /// Lari.
    enum GEL: CurrencyType {
        public static let currency: Currency = .gel
    }

    /// Ghana Cedi.
    enum GHS: CurrencyType {
        public static let currency: Currency = .ghs
    }

    /// Gibraltar Pound.
    enum GIP: CurrencyType {
        public static let currency: Currency = .gip
    }

    /// Dalasi.
    enum GMD: CurrencyType {
        public static let currency: Currency = .gmd
    }

    /// Guinean Franc.
    enum GNF: CurrencyType {
        public static let currency: Currency = .gnf
    }

    /// Quetzal.
    enum GTQ: CurrencyType {
        public static let currency: Currency = .gtq
    }

    /// Guyana Dollar.
    enum GYD: CurrencyType {
        public static let currency: Currency = .gyd
    }

    /// Hong Kong Dollar.
    enum HKD: CurrencyType {
        public static let currency: Currency = .hkd
    }

    /// Lempira.
    enum HNL: CurrencyType {
        public static let currency: Currency = .hnl
    }

    /// Gourde.
    enum HTG: CurrencyType {
        public static let currency: Currency = .htg
    }

    /// Forint.
    enum HUF: CurrencyType {
        public static let currency: Currency = .huf
    }

    /// Rupiah.
    enum IDR: CurrencyType {
        public static let currency: Currency = .idr
    }

    /// New Israeli Sheqel.
    enum ILS: CurrencyType {
        public static let currency: Currency = .ils
    }

    /// Indian Rupee.
    enum INR: CurrencyType {
        public static let currency: Currency = .inr
    }

    /// Iraqi Dinar.
    enum IQD: CurrencyType {
        public static let currency: Currency = .iqd
    }

    /// Iranian Rial.
    enum IRR: CurrencyType {
        public static let currency: Currency = .irr
    }

    /// Iceland Krona.
    enum ISK: CurrencyType {
        public static let currency: Currency = .isk
    }

    /// Jamaican Dollar.
    enum JMD: CurrencyType {
        public static let currency: Currency = .jmd
    }

    /// Jordanian Dinar.
    enum JOD: CurrencyType {
        public static let currency: Currency = .jod
    }

    /// Yen.
    enum JPY: CurrencyType {
        public static let currency: Currency = .jpy
    }

    /// Kenyan Shilling.
    enum KES: CurrencyType {
        public static let currency: Currency = .kes
    }

    /// Som.
    enum KGS: CurrencyType {
        public static let currency: Currency = .kgs
    }

    /// Riel.
    enum KHR: CurrencyType {
        public static let currency: Currency = .khr
    }

    /// Comorian Franc.
    enum KMF: CurrencyType {
        public static let currency: Currency = .kmf
    }

    /// North Korean Won.
    enum KPW: CurrencyType {
        public static let currency: Currency = .kpw
    }

    /// Won.
    enum KRW: CurrencyType {
        public static let currency: Currency = .krw
    }

    /// Kuwaiti Dinar.
    enum KWD: CurrencyType {
        public static let currency: Currency = .kwd
    }

    /// Cayman Islands Dollar.
    enum KYD: CurrencyType {
        public static let currency: Currency = .kyd
    }

    /// Tenge.
    enum KZT: CurrencyType {
        public static let currency: Currency = .kzt
    }

    /// Lao Kip.
    enum LAK: CurrencyType {
        public static let currency: Currency = .lak
    }

    /// Lebanese Pound.
    enum LBP: CurrencyType {
        public static let currency: Currency = .lbp
    }

    /// Sri Lanka Rupee.
    enum LKR: CurrencyType {
        public static let currency: Currency = .lkr
    }

    /// Liberian Dollar.
    enum LRD: CurrencyType {
        public static let currency: Currency = .lrd
    }

    /// Loti.
    enum LSL: CurrencyType {
        public static let currency: Currency = .lsl
    }

    /// Libyan Dinar.
    enum LYD: CurrencyType {
        public static let currency: Currency = .lyd
    }

    /// Moroccan Dirham.
    enum MAD: CurrencyType {
        public static let currency: Currency = .mad
    }

    /// Moldovan Leu.
    enum MDL: CurrencyType {
        public static let currency: Currency = .mdl
    }

    /// Malagasy Ariary.
    ///
    /// Divides into five iraimbilanja, which ISO 4217 cannot express: its
    /// exponent field holds a power of ten, so it records 2 and footnotes the currency
    /// `divby5`. The scale here follows ISO, because that is what payment systems assume.
    enum MGA: CurrencyType {
        public static let currency: Currency = .mga
    }

    /// Denar.
    enum MKD: CurrencyType {
        public static let currency: Currency = .mkd
    }

    /// Kyat.
    enum MMK: CurrencyType {
        public static let currency: Currency = .mmk
    }

    /// Tugrik.
    enum MNT: CurrencyType {
        public static let currency: Currency = .mnt
    }

    /// Pataca.
    enum MOP: CurrencyType {
        public static let currency: Currency = .mop
    }

    /// Ouguiya.
    ///
    /// Divides into five khoums, which ISO 4217 cannot express: its
    /// exponent field holds a power of ten, so it records 2 and footnotes the currency
    /// `divby5`. The scale here follows ISO, because that is what payment systems assume.
    enum MRU: CurrencyType {
        public static let currency: Currency = .mru
    }

    /// Mauritius Rupee.
    enum MUR: CurrencyType {
        public static let currency: Currency = .mur
    }

    /// Rufiyaa.
    enum MVR: CurrencyType {
        public static let currency: Currency = .mvr
    }

    /// Malawi Kwacha.
    enum MWK: CurrencyType {
        public static let currency: Currency = .mwk
    }

    /// Mexican Peso.
    enum MXN: CurrencyType {
        public static let currency: Currency = .mxn
    }

    /// Mexican Unidad de Inversion (UDI).
    enum MXV: CurrencyType {
        public static let currency: Currency = .mxv
    }

    /// Malaysian Ringgit.
    enum MYR: CurrencyType {
        public static let currency: Currency = .myr
    }

    /// Mozambique Metical.
    enum MZN: CurrencyType {
        public static let currency: Currency = .mzn
    }

    /// Namibia Dollar.
    enum NAD: CurrencyType {
        public static let currency: Currency = .nad
    }

    /// Naira.
    enum NGN: CurrencyType {
        public static let currency: Currency = .ngn
    }

    /// Cordoba Oro.
    enum NIO: CurrencyType {
        public static let currency: Currency = .nio
    }

    /// Norwegian Krone.
    enum NOK: CurrencyType {
        public static let currency: Currency = .nok
    }

    /// Nepalese Rupee.
    enum NPR: CurrencyType {
        public static let currency: Currency = .npr
    }

    /// New Zealand Dollar.
    enum NZD: CurrencyType {
        public static let currency: Currency = .nzd
    }

    /// Rial Omani.
    enum OMR: CurrencyType {
        public static let currency: Currency = .omr
    }

    /// Balboa.
    enum PAB: CurrencyType {
        public static let currency: Currency = .pab
    }

    /// Sol.
    enum PEN: CurrencyType {
        public static let currency: Currency = .pen
    }

    /// Kina.
    enum PGK: CurrencyType {
        public static let currency: Currency = .pgk
    }

    /// Philippine Peso.
    enum PHP: CurrencyType {
        public static let currency: Currency = .php
    }

    /// Pakistan Rupee.
    enum PKR: CurrencyType {
        public static let currency: Currency = .pkr
    }

    /// Zloty.
    enum PLN: CurrencyType {
        public static let currency: Currency = .pln
    }

    /// Guarani.
    enum PYG: CurrencyType {
        public static let currency: Currency = .pyg
    }

    /// Qatari Rial.
    enum QAR: CurrencyType {
        public static let currency: Currency = .qar
    }

    /// Romanian Leu.
    enum RON: CurrencyType {
        public static let currency: Currency = .ron
    }

    /// Serbian Dinar.
    enum RSD: CurrencyType {
        public static let currency: Currency = .rsd
    }

    /// Russian Ruble.
    enum RUB: CurrencyType {
        public static let currency: Currency = .rub
    }

    /// Rwanda Franc.
    enum RWF: CurrencyType {
        public static let currency: Currency = .rwf
    }

    /// Saudi Riyal.
    enum SAR: CurrencyType {
        public static let currency: Currency = .sar
    }

    /// Solomon Islands Dollar.
    enum SBD: CurrencyType {
        public static let currency: Currency = .sbd
    }

    /// Seychelles Rupee.
    enum SCR: CurrencyType {
        public static let currency: Currency = .scr
    }

    /// Sudanese Pound.
    enum SDG: CurrencyType {
        public static let currency: Currency = .sdg
    }

    /// Swedish Krona.
    enum SEK: CurrencyType {
        public static let currency: Currency = .sek
    }

    /// Singapore Dollar.
    enum SGD: CurrencyType {
        public static let currency: Currency = .sgd
    }

    /// Saint Helena Pound.
    enum SHP: CurrencyType {
        public static let currency: Currency = .shp
    }

    /// Leone.
    enum SLE: CurrencyType {
        public static let currency: Currency = .sle
    }

    /// Somali Shilling.
    enum SOS: CurrencyType {
        public static let currency: Currency = .sos
    }

    /// Surinam Dollar.
    enum SRD: CurrencyType {
        public static let currency: Currency = .srd
    }

    /// South Sudanese Pound.
    enum SSP: CurrencyType {
        public static let currency: Currency = .ssp
    }

    /// Dobra.
    enum STN: CurrencyType {
        public static let currency: Currency = .stn
    }

    /// El Salvador Colon.
    enum SVC: CurrencyType {
        public static let currency: Currency = .svc
    }

    /// Syrian Pound.
    enum SYP: CurrencyType {
        public static let currency: Currency = .syp
    }

    /// Lilangeni.
    enum SZL: CurrencyType {
        public static let currency: Currency = .szl
    }

    /// Baht.
    enum THB: CurrencyType {
        public static let currency: Currency = .thb
    }

    /// Somoni.
    enum TJS: CurrencyType {
        public static let currency: Currency = .tjs
    }

    /// Turkmenistan New Manat.
    enum TMT: CurrencyType {
        public static let currency: Currency = .tmt
    }

    /// Tunisian Dinar.
    enum TND: CurrencyType {
        public static let currency: Currency = .tnd
    }

    /// Pa’anga.
    enum TOP: CurrencyType {
        public static let currency: Currency = .top
    }

    /// Turkish Lira.
    enum TRY: CurrencyType {
        public static let currency: Currency = .`try`
    }

    /// Trinidad and Tobago Dollar.
    enum TTD: CurrencyType {
        public static let currency: Currency = .ttd
    }

    /// New Taiwan Dollar.
    enum TWD: CurrencyType {
        public static let currency: Currency = .twd
    }

    /// Tanzanian Shilling.
    enum TZS: CurrencyType {
        public static let currency: Currency = .tzs
    }

    /// Hryvnia.
    enum UAH: CurrencyType {
        public static let currency: Currency = .uah
    }

    /// Uganda Shilling.
    enum UGX: CurrencyType {
        public static let currency: Currency = .ugx
    }

    /// US Dollar.
    enum USD: CurrencyType {
        public static let currency: Currency = .usd
    }

    /// US Dollar (Next day).
    enum USN: CurrencyType {
        public static let currency: Currency = .usn
    }

    /// Uruguay Peso en Unidades Indexadas (UI).
    enum UYI: CurrencyType {
        public static let currency: Currency = .uyi
    }

    /// Peso Uruguayo.
    enum UYU: CurrencyType {
        public static let currency: Currency = .uyu
    }

    /// Unidad Previsional.
    enum UYW: CurrencyType {
        public static let currency: Currency = .uyw
    }

    /// Uzbekistan Sum.
    enum UZS: CurrencyType {
        public static let currency: Currency = .uzs
    }

    /// Bolívar Soberano.
    enum VED: CurrencyType {
        public static let currency: Currency = .ved
    }

    /// Bolívar Soberano.
    enum VES: CurrencyType {
        public static let currency: Currency = .ves
    }

    /// Dong.
    enum VND: CurrencyType {
        public static let currency: Currency = .vnd
    }

    /// Vatu.
    enum VUV: CurrencyType {
        public static let currency: Currency = .vuv
    }

    /// Tala.
    enum WST: CurrencyType {
        public static let currency: Currency = .wst
    }

    /// Arab Accounting Dinar.
    enum XAD: CurrencyType {
        public static let currency: Currency = .xad
    }

    /// CFA Franc BEAC.
    enum XAF: CurrencyType {
        public static let currency: Currency = .xaf
    }

    /// East Caribbean Dollar.
    enum XCD: CurrencyType {
        public static let currency: Currency = .xcd
    }

    /// Caribbean Guilder.
    enum XCG: CurrencyType {
        public static let currency: Currency = .xcg
    }

    /// CFA Franc BCEAO.
    enum XOF: CurrencyType {
        public static let currency: Currency = .xof
    }

    /// CFP Franc.
    enum XPF: CurrencyType {
        public static let currency: Currency = .xpf
    }

    /// Yemeni Rial.
    enum YER: CurrencyType {
        public static let currency: Currency = .yer
    }

    /// Rand.
    enum ZAR: CurrencyType {
        public static let currency: Currency = .zar
    }

    /// Zambian Kwacha.
    enum ZMW: CurrencyType {
        public static let currency: Currency = .zmw
    }

    /// Zimbabwe Gold.
    enum ZWG: CurrencyType {
        public static let currency: Currency = .zwg
    }
}
