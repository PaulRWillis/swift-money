// Generated from ISO 4217's list-one.xml, published 2026-01-01. Do not edit by hand:
// run `python3 ISO4217/generate.py` instead.
//
// Codes the list gives no minor unit for are absent, because a scale of at least one would
// assert a subdivision the standard declines to state. That is the metals XAU, XAG, XPT and
// XPD, the bond market units XBA to XBD, XDR, XSU, XUA, and the reserved XTS and XXX. Java's
// `Currency.getDefaultFractionDigits()` reports -1 for the same set rather than invent one.

public extension Currency {
    /// UAE Dirham.
    static let aed = Currency(unchecked: "AED", unitScale: 100)

    /// Afghani.
    static let afn = Currency(unchecked: "AFN", unitScale: 100)

    /// Lek.
    static let all = Currency(unchecked: "ALL", unitScale: 100)

    /// Armenian Dram.
    static let amd = Currency(unchecked: "AMD", unitScale: 100)

    /// Kwanza.
    static let aoa = Currency(unchecked: "AOA", unitScale: 100)

    /// Argentine Peso.
    static let ars = Currency(unchecked: "ARS", unitScale: 100)

    /// Australian Dollar.
    static let aud = Currency(unchecked: "AUD", unitScale: 100)

    /// Aruban Florin.
    static let awg = Currency(unchecked: "AWG", unitScale: 100)

    /// Azerbaijan Manat.
    static let azn = Currency(unchecked: "AZN", unitScale: 100)

    /// Convertible Mark.
    static let bam = Currency(unchecked: "BAM", unitScale: 100)

    /// Barbados Dollar.
    static let bbd = Currency(unchecked: "BBD", unitScale: 100)

    /// Taka.
    static let bdt = Currency(unchecked: "BDT", unitScale: 100)

    /// Bahraini Dinar.
    static let bhd = Currency(unchecked: "BHD", unitScale: 1_000)

    /// Burundi Franc.
    static let bif = Currency(unchecked: "BIF", unitScale: 1)

    /// Bermudian Dollar.
    static let bmd = Currency(unchecked: "BMD", unitScale: 100)

    /// Brunei Dollar.
    static let bnd = Currency(unchecked: "BND", unitScale: 100)

    /// Boliviano.
    static let bob = Currency(unchecked: "BOB", unitScale: 100)

    /// Mvdol.
    static let bov = Currency(unchecked: "BOV", unitScale: 100)

    /// Brazilian Real.
    static let brl = Currency(unchecked: "BRL", unitScale: 100)

    /// Bahamian Dollar.
    static let bsd = Currency(unchecked: "BSD", unitScale: 100)

    /// Ngultrum.
    static let btn = Currency(unchecked: "BTN", unitScale: 100)

    /// Pula.
    static let bwp = Currency(unchecked: "BWP", unitScale: 100)

    /// Belarusian Ruble.
    static let byn = Currency(unchecked: "BYN", unitScale: 100)

    /// Belize Dollar.
    static let bzd = Currency(unchecked: "BZD", unitScale: 100)

    /// Canadian Dollar.
    static let cad = Currency(unchecked: "CAD", unitScale: 100)

    /// Congolese Franc.
    static let cdf = Currency(unchecked: "CDF", unitScale: 100)

    /// WIR Euro.
    static let che = Currency(unchecked: "CHE", unitScale: 100)

    /// Swiss Franc.
    static let chf = Currency(unchecked: "CHF", unitScale: 100)

    /// WIR Franc.
    static let chw = Currency(unchecked: "CHW", unitScale: 100)

    /// Unidad de Fomento.
    static let clf = Currency(unchecked: "CLF", unitScale: 10_000)

    /// Chilean Peso.
    static let clp = Currency(unchecked: "CLP", unitScale: 1)

    /// Yuan Renminbi.
    static let cny = Currency(unchecked: "CNY", unitScale: 100)

    /// Colombian Peso.
    static let cop = Currency(unchecked: "COP", unitScale: 100)

    /// Unidad de Valor Real.
    static let cou = Currency(unchecked: "COU", unitScale: 100)

    /// Costa Rican Colon.
    static let crc = Currency(unchecked: "CRC", unitScale: 100)

    /// Cuban Peso.
    static let cup = Currency(unchecked: "CUP", unitScale: 100)

    /// Cabo Verde Escudo.
    static let cve = Currency(unchecked: "CVE", unitScale: 100)

    /// Czech Koruna.
    static let czk = Currency(unchecked: "CZK", unitScale: 100)

    /// Djibouti Franc.
    static let djf = Currency(unchecked: "DJF", unitScale: 1)

    /// Danish Krone.
    static let dkk = Currency(unchecked: "DKK", unitScale: 100)

    /// Dominican Peso.
    static let dop = Currency(unchecked: "DOP", unitScale: 100)

    /// Algerian Dinar.
    static let dzd = Currency(unchecked: "DZD", unitScale: 100)

    /// Egyptian Pound.
    static let egp = Currency(unchecked: "EGP", unitScale: 100)

    /// Nakfa.
    static let ern = Currency(unchecked: "ERN", unitScale: 100)

    /// Ethiopian Birr.
    static let etb = Currency(unchecked: "ETB", unitScale: 100)

    /// Euro.
    static let eur = Currency(unchecked: "EUR", unitScale: 100)

    /// Fiji Dollar.
    static let fjd = Currency(unchecked: "FJD", unitScale: 100)

    /// Falkland Islands Pound.
    static let fkp = Currency(unchecked: "FKP", unitScale: 100)

    /// Pound Sterling.
    static let gbp = Currency(unchecked: "GBP", unitScale: 100)

    /// Lari.
    static let gel = Currency(unchecked: "GEL", unitScale: 100)

    /// Ghana Cedi.
    static let ghs = Currency(unchecked: "GHS", unitScale: 100)

    /// Gibraltar Pound.
    static let gip = Currency(unchecked: "GIP", unitScale: 100)

    /// Dalasi.
    static let gmd = Currency(unchecked: "GMD", unitScale: 100)

    /// Guinean Franc.
    static let gnf = Currency(unchecked: "GNF", unitScale: 1)

    /// Quetzal.
    static let gtq = Currency(unchecked: "GTQ", unitScale: 100)

    /// Guyana Dollar.
    static let gyd = Currency(unchecked: "GYD", unitScale: 100)

    /// Hong Kong Dollar.
    static let hkd = Currency(unchecked: "HKD", unitScale: 100)

    /// Lempira.
    static let hnl = Currency(unchecked: "HNL", unitScale: 100)

    /// Gourde.
    static let htg = Currency(unchecked: "HTG", unitScale: 100)

    /// Forint.
    static let huf = Currency(unchecked: "HUF", unitScale: 100)

    /// Rupiah.
    static let idr = Currency(unchecked: "IDR", unitScale: 100)

    /// New Israeli Sheqel.
    static let ils = Currency(unchecked: "ILS", unitScale: 100)

    /// Indian Rupee.
    static let inr = Currency(unchecked: "INR", unitScale: 100)

    /// Iraqi Dinar.
    static let iqd = Currency(unchecked: "IQD", unitScale: 1_000)

    /// Iranian Rial.
    static let irr = Currency(unchecked: "IRR", unitScale: 100)

    /// Iceland Krona.
    static let isk = Currency(unchecked: "ISK", unitScale: 1)

    /// Jamaican Dollar.
    static let jmd = Currency(unchecked: "JMD", unitScale: 100)

    /// Jordanian Dinar.
    static let jod = Currency(unchecked: "JOD", unitScale: 1_000)

    /// Yen.
    static let jpy = Currency(unchecked: "JPY", unitScale: 1)

    /// Kenyan Shilling.
    static let kes = Currency(unchecked: "KES", unitScale: 100)

    /// Som.
    static let kgs = Currency(unchecked: "KGS", unitScale: 100)

    /// Riel.
    static let khr = Currency(unchecked: "KHR", unitScale: 100)

    /// Comorian Franc.
    static let kmf = Currency(unchecked: "KMF", unitScale: 1)

    /// North Korean Won.
    static let kpw = Currency(unchecked: "KPW", unitScale: 100)

    /// Won.
    static let krw = Currency(unchecked: "KRW", unitScale: 1)

    /// Kuwaiti Dinar.
    static let kwd = Currency(unchecked: "KWD", unitScale: 1_000)

    /// Cayman Islands Dollar.
    static let kyd = Currency(unchecked: "KYD", unitScale: 100)

    /// Tenge.
    static let kzt = Currency(unchecked: "KZT", unitScale: 100)

    /// Lao Kip.
    static let lak = Currency(unchecked: "LAK", unitScale: 100)

    /// Lebanese Pound.
    static let lbp = Currency(unchecked: "LBP", unitScale: 100)

    /// Sri Lanka Rupee.
    static let lkr = Currency(unchecked: "LKR", unitScale: 100)

    /// Liberian Dollar.
    static let lrd = Currency(unchecked: "LRD", unitScale: 100)

    /// Loti.
    static let lsl = Currency(unchecked: "LSL", unitScale: 100)

    /// Libyan Dinar.
    static let lyd = Currency(unchecked: "LYD", unitScale: 1_000)

    /// Moroccan Dirham.
    static let mad = Currency(unchecked: "MAD", unitScale: 100)

    /// Moldovan Leu.
    static let mdl = Currency(unchecked: "MDL", unitScale: 100)

    /// Malagasy Ariary.
    ///
    /// Divides into five iraimbilanja, which ISO 4217 cannot express: its
    /// exponent field holds a power of ten, so it records 2 and footnotes the currency
    /// `divby5`. The scale here follows ISO, because that is what payment systems assume.
    static let mga = Currency(unchecked: "MGA", unitScale: 100)

    /// Denar.
    static let mkd = Currency(unchecked: "MKD", unitScale: 100)

    /// Kyat.
    static let mmk = Currency(unchecked: "MMK", unitScale: 100)

    /// Tugrik.
    static let mnt = Currency(unchecked: "MNT", unitScale: 100)

    /// Pataca.
    static let mop = Currency(unchecked: "MOP", unitScale: 100)

    /// Ouguiya.
    ///
    /// Divides into five khoums, which ISO 4217 cannot express: its
    /// exponent field holds a power of ten, so it records 2 and footnotes the currency
    /// `divby5`. The scale here follows ISO, because that is what payment systems assume.
    static let mru = Currency(unchecked: "MRU", unitScale: 100)

    /// Mauritius Rupee.
    static let mur = Currency(unchecked: "MUR", unitScale: 100)

    /// Rufiyaa.
    static let mvr = Currency(unchecked: "MVR", unitScale: 100)

    /// Malawi Kwacha.
    static let mwk = Currency(unchecked: "MWK", unitScale: 100)

    /// Mexican Peso.
    static let mxn = Currency(unchecked: "MXN", unitScale: 100)

    /// Mexican Unidad de Inversion (UDI).
    static let mxv = Currency(unchecked: "MXV", unitScale: 100)

    /// Malaysian Ringgit.
    static let myr = Currency(unchecked: "MYR", unitScale: 100)

    /// Mozambique Metical.
    static let mzn = Currency(unchecked: "MZN", unitScale: 100)

    /// Namibia Dollar.
    static let nad = Currency(unchecked: "NAD", unitScale: 100)

    /// Naira.
    static let ngn = Currency(unchecked: "NGN", unitScale: 100)

    /// Cordoba Oro.
    static let nio = Currency(unchecked: "NIO", unitScale: 100)

    /// Norwegian Krone.
    static let nok = Currency(unchecked: "NOK", unitScale: 100)

    /// Nepalese Rupee.
    static let npr = Currency(unchecked: "NPR", unitScale: 100)

    /// New Zealand Dollar.
    static let nzd = Currency(unchecked: "NZD", unitScale: 100)

    /// Rial Omani.
    static let omr = Currency(unchecked: "OMR", unitScale: 1_000)

    /// Balboa.
    static let pab = Currency(unchecked: "PAB", unitScale: 100)

    /// Sol.
    static let pen = Currency(unchecked: "PEN", unitScale: 100)

    /// Kina.
    static let pgk = Currency(unchecked: "PGK", unitScale: 100)

    /// Philippine Peso.
    static let php = Currency(unchecked: "PHP", unitScale: 100)

    /// Pakistan Rupee.
    static let pkr = Currency(unchecked: "PKR", unitScale: 100)

    /// Zloty.
    static let pln = Currency(unchecked: "PLN", unitScale: 100)

    /// Guarani.
    static let pyg = Currency(unchecked: "PYG", unitScale: 1)

    /// Qatari Rial.
    static let qar = Currency(unchecked: "QAR", unitScale: 100)

    /// Romanian Leu.
    static let ron = Currency(unchecked: "RON", unitScale: 100)

    /// Serbian Dinar.
    static let rsd = Currency(unchecked: "RSD", unitScale: 100)

    /// Russian Ruble.
    static let rub = Currency(unchecked: "RUB", unitScale: 100)

    /// Rwanda Franc.
    static let rwf = Currency(unchecked: "RWF", unitScale: 1)

    /// Saudi Riyal.
    static let sar = Currency(unchecked: "SAR", unitScale: 100)

    /// Solomon Islands Dollar.
    static let sbd = Currency(unchecked: "SBD", unitScale: 100)

    /// Seychelles Rupee.
    static let scr = Currency(unchecked: "SCR", unitScale: 100)

    /// Sudanese Pound.
    static let sdg = Currency(unchecked: "SDG", unitScale: 100)

    /// Swedish Krona.
    static let sek = Currency(unchecked: "SEK", unitScale: 100)

    /// Singapore Dollar.
    static let sgd = Currency(unchecked: "SGD", unitScale: 100)

    /// Saint Helena Pound.
    static let shp = Currency(unchecked: "SHP", unitScale: 100)

    /// Leone.
    static let sle = Currency(unchecked: "SLE", unitScale: 100)

    /// Somali Shilling.
    static let sos = Currency(unchecked: "SOS", unitScale: 100)

    /// Surinam Dollar.
    static let srd = Currency(unchecked: "SRD", unitScale: 100)

    /// South Sudanese Pound.
    static let ssp = Currency(unchecked: "SSP", unitScale: 100)

    /// Dobra.
    static let stn = Currency(unchecked: "STN", unitScale: 100)

    /// El Salvador Colon.
    static let svc = Currency(unchecked: "SVC", unitScale: 100)

    /// Syrian Pound.
    static let syp = Currency(unchecked: "SYP", unitScale: 100)

    /// Lilangeni.
    static let szl = Currency(unchecked: "SZL", unitScale: 100)

    /// Baht.
    static let thb = Currency(unchecked: "THB", unitScale: 100)

    /// Somoni.
    static let tjs = Currency(unchecked: "TJS", unitScale: 100)

    /// Turkmenistan New Manat.
    static let tmt = Currency(unchecked: "TMT", unitScale: 100)

    /// Tunisian Dinar.
    static let tnd = Currency(unchecked: "TND", unitScale: 1_000)

    /// Pa’anga.
    static let top = Currency(unchecked: "TOP", unitScale: 100)

    /// Turkish Lira.
    static let `try` = Currency(unchecked: "TRY", unitScale: 100)

    /// Trinidad and Tobago Dollar.
    static let ttd = Currency(unchecked: "TTD", unitScale: 100)

    /// New Taiwan Dollar.
    static let twd = Currency(unchecked: "TWD", unitScale: 100)

    /// Tanzanian Shilling.
    static let tzs = Currency(unchecked: "TZS", unitScale: 100)

    /// Hryvnia.
    static let uah = Currency(unchecked: "UAH", unitScale: 100)

    /// Uganda Shilling.
    static let ugx = Currency(unchecked: "UGX", unitScale: 1)

    /// US Dollar.
    static let usd = Currency(unchecked: "USD", unitScale: 100)

    /// US Dollar (Next day).
    static let usn = Currency(unchecked: "USN", unitScale: 100)

    /// Uruguay Peso en Unidades Indexadas (UI).
    static let uyi = Currency(unchecked: "UYI", unitScale: 1)

    /// Peso Uruguayo.
    static let uyu = Currency(unchecked: "UYU", unitScale: 100)

    /// Unidad Previsional.
    static let uyw = Currency(unchecked: "UYW", unitScale: 10_000)

    /// Uzbekistan Sum.
    static let uzs = Currency(unchecked: "UZS", unitScale: 100)

    /// Bolívar Soberano.
    static let ved = Currency(unchecked: "VED", unitScale: 100)

    /// Bolívar Soberano.
    static let ves = Currency(unchecked: "VES", unitScale: 100)

    /// Dong.
    static let vnd = Currency(unchecked: "VND", unitScale: 1)

    /// Vatu.
    static let vuv = Currency(unchecked: "VUV", unitScale: 1)

    /// Tala.
    static let wst = Currency(unchecked: "WST", unitScale: 100)

    /// Arab Accounting Dinar.
    static let xad = Currency(unchecked: "XAD", unitScale: 100)

    /// CFA Franc BEAC.
    static let xaf = Currency(unchecked: "XAF", unitScale: 1)

    /// East Caribbean Dollar.
    static let xcd = Currency(unchecked: "XCD", unitScale: 100)

    /// Caribbean Guilder.
    static let xcg = Currency(unchecked: "XCG", unitScale: 100)

    /// CFA Franc BCEAO.
    static let xof = Currency(unchecked: "XOF", unitScale: 1)

    /// CFP Franc.
    static let xpf = Currency(unchecked: "XPF", unitScale: 1)

    /// Yemeni Rial.
    static let yer = Currency(unchecked: "YER", unitScale: 100)

    /// Rand.
    static let zar = Currency(unchecked: "ZAR", unitScale: 100)

    /// Zambian Kwacha.
    static let zmw = Currency(unchecked: "ZMW", unitScale: 100)

    /// Zimbabwe Gold.
    static let zwg = Currency(unchecked: "ZWG", unitScale: 100)
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


public extension Currency {
    /// The ISO 4217 currency a code names.
    ///
    /// ```swift
    /// Currency(iso: "GBP")   // GBP, 100 subunits
    /// Currency(iso: "LTY")   // nil
    /// ```
    init?(iso code: CurrencyCode) {
        // Switched on the packed word rather than the code, so the compiler can build a
        // search over integers. Every case is checked by the tests, which look up all of
        // these by their spelling.
        switch code.packedValue {
        case 0x4145440000000000: self = .aed   // AED
        case 0x41464E0000000000: self = .afn   // AFN
        case 0x414C4C0000000000: self = .all   // ALL
        case 0x414D440000000000: self = .amd   // AMD
        case 0x414F410000000000: self = .aoa   // AOA
        case 0x4152530000000000: self = .ars   // ARS
        case 0x4155440000000000: self = .aud   // AUD
        case 0x4157470000000000: self = .awg   // AWG
        case 0x415A4E0000000000: self = .azn   // AZN
        case 0x42414D0000000000: self = .bam   // BAM
        case 0x4242440000000000: self = .bbd   // BBD
        case 0x4244540000000000: self = .bdt   // BDT
        case 0x4248440000000000: self = .bhd   // BHD
        case 0x4249460000000000: self = .bif   // BIF
        case 0x424D440000000000: self = .bmd   // BMD
        case 0x424E440000000000: self = .bnd   // BND
        case 0x424F420000000000: self = .bob   // BOB
        case 0x424F560000000000: self = .bov   // BOV
        case 0x42524C0000000000: self = .brl   // BRL
        case 0x4253440000000000: self = .bsd   // BSD
        case 0x42544E0000000000: self = .btn   // BTN
        case 0x4257500000000000: self = .bwp   // BWP
        case 0x42594E0000000000: self = .byn   // BYN
        case 0x425A440000000000: self = .bzd   // BZD
        case 0x4341440000000000: self = .cad   // CAD
        case 0x4344460000000000: self = .cdf   // CDF
        case 0x4348450000000000: self = .che   // CHE
        case 0x4348460000000000: self = .chf   // CHF
        case 0x4348570000000000: self = .chw   // CHW
        case 0x434C460000000000: self = .clf   // CLF
        case 0x434C500000000000: self = .clp   // CLP
        case 0x434E590000000000: self = .cny   // CNY
        case 0x434F500000000000: self = .cop   // COP
        case 0x434F550000000000: self = .cou   // COU
        case 0x4352430000000000: self = .crc   // CRC
        case 0x4355500000000000: self = .cup   // CUP
        case 0x4356450000000000: self = .cve   // CVE
        case 0x435A4B0000000000: self = .czk   // CZK
        case 0x444A460000000000: self = .djf   // DJF
        case 0x444B4B0000000000: self = .dkk   // DKK
        case 0x444F500000000000: self = .dop   // DOP
        case 0x445A440000000000: self = .dzd   // DZD
        case 0x4547500000000000: self = .egp   // EGP
        case 0x45524E0000000000: self = .ern   // ERN
        case 0x4554420000000000: self = .etb   // ETB
        case 0x4555520000000000: self = .eur   // EUR
        case 0x464A440000000000: self = .fjd   // FJD
        case 0x464B500000000000: self = .fkp   // FKP
        case 0x4742500000000000: self = .gbp   // GBP
        case 0x47454C0000000000: self = .gel   // GEL
        case 0x4748530000000000: self = .ghs   // GHS
        case 0x4749500000000000: self = .gip   // GIP
        case 0x474D440000000000: self = .gmd   // GMD
        case 0x474E460000000000: self = .gnf   // GNF
        case 0x4754510000000000: self = .gtq   // GTQ
        case 0x4759440000000000: self = .gyd   // GYD
        case 0x484B440000000000: self = .hkd   // HKD
        case 0x484E4C0000000000: self = .hnl   // HNL
        case 0x4854470000000000: self = .htg   // HTG
        case 0x4855460000000000: self = .huf   // HUF
        case 0x4944520000000000: self = .idr   // IDR
        case 0x494C530000000000: self = .ils   // ILS
        case 0x494E520000000000: self = .inr   // INR
        case 0x4951440000000000: self = .iqd   // IQD
        case 0x4952520000000000: self = .irr   // IRR
        case 0x49534B0000000000: self = .isk   // ISK
        case 0x4A4D440000000000: self = .jmd   // JMD
        case 0x4A4F440000000000: self = .jod   // JOD
        case 0x4A50590000000000: self = .jpy   // JPY
        case 0x4B45530000000000: self = .kes   // KES
        case 0x4B47530000000000: self = .kgs   // KGS
        case 0x4B48520000000000: self = .khr   // KHR
        case 0x4B4D460000000000: self = .kmf   // KMF
        case 0x4B50570000000000: self = .kpw   // KPW
        case 0x4B52570000000000: self = .krw   // KRW
        case 0x4B57440000000000: self = .kwd   // KWD
        case 0x4B59440000000000: self = .kyd   // KYD
        case 0x4B5A540000000000: self = .kzt   // KZT
        case 0x4C414B0000000000: self = .lak   // LAK
        case 0x4C42500000000000: self = .lbp   // LBP
        case 0x4C4B520000000000: self = .lkr   // LKR
        case 0x4C52440000000000: self = .lrd   // LRD
        case 0x4C534C0000000000: self = .lsl   // LSL
        case 0x4C59440000000000: self = .lyd   // LYD
        case 0x4D41440000000000: self = .mad   // MAD
        case 0x4D444C0000000000: self = .mdl   // MDL
        case 0x4D47410000000000: self = .mga   // MGA
        case 0x4D4B440000000000: self = .mkd   // MKD
        case 0x4D4D4B0000000000: self = .mmk   // MMK
        case 0x4D4E540000000000: self = .mnt   // MNT
        case 0x4D4F500000000000: self = .mop   // MOP
        case 0x4D52550000000000: self = .mru   // MRU
        case 0x4D55520000000000: self = .mur   // MUR
        case 0x4D56520000000000: self = .mvr   // MVR
        case 0x4D574B0000000000: self = .mwk   // MWK
        case 0x4D584E0000000000: self = .mxn   // MXN
        case 0x4D58560000000000: self = .mxv   // MXV
        case 0x4D59520000000000: self = .myr   // MYR
        case 0x4D5A4E0000000000: self = .mzn   // MZN
        case 0x4E41440000000000: self = .nad   // NAD
        case 0x4E474E0000000000: self = .ngn   // NGN
        case 0x4E494F0000000000: self = .nio   // NIO
        case 0x4E4F4B0000000000: self = .nok   // NOK
        case 0x4E50520000000000: self = .npr   // NPR
        case 0x4E5A440000000000: self = .nzd   // NZD
        case 0x4F4D520000000000: self = .omr   // OMR
        case 0x5041420000000000: self = .pab   // PAB
        case 0x50454E0000000000: self = .pen   // PEN
        case 0x50474B0000000000: self = .pgk   // PGK
        case 0x5048500000000000: self = .php   // PHP
        case 0x504B520000000000: self = .pkr   // PKR
        case 0x504C4E0000000000: self = .pln   // PLN
        case 0x5059470000000000: self = .pyg   // PYG
        case 0x5141520000000000: self = .qar   // QAR
        case 0x524F4E0000000000: self = .ron   // RON
        case 0x5253440000000000: self = .rsd   // RSD
        case 0x5255420000000000: self = .rub   // RUB
        case 0x5257460000000000: self = .rwf   // RWF
        case 0x5341520000000000: self = .sar   // SAR
        case 0x5342440000000000: self = .sbd   // SBD
        case 0x5343520000000000: self = .scr   // SCR
        case 0x5344470000000000: self = .sdg   // SDG
        case 0x53454B0000000000: self = .sek   // SEK
        case 0x5347440000000000: self = .sgd   // SGD
        case 0x5348500000000000: self = .shp   // SHP
        case 0x534C450000000000: self = .sle   // SLE
        case 0x534F530000000000: self = .sos   // SOS
        case 0x5352440000000000: self = .srd   // SRD
        case 0x5353500000000000: self = .ssp   // SSP
        case 0x53544E0000000000: self = .stn   // STN
        case 0x5356430000000000: self = .svc   // SVC
        case 0x5359500000000000: self = .syp   // SYP
        case 0x535A4C0000000000: self = .szl   // SZL
        case 0x5448420000000000: self = .thb   // THB
        case 0x544A530000000000: self = .tjs   // TJS
        case 0x544D540000000000: self = .tmt   // TMT
        case 0x544E440000000000: self = .tnd   // TND
        case 0x544F500000000000: self = .top   // TOP
        case 0x5452590000000000: self = .`try`   // TRY
        case 0x5454440000000000: self = .ttd   // TTD
        case 0x5457440000000000: self = .twd   // TWD
        case 0x545A530000000000: self = .tzs   // TZS
        case 0x5541480000000000: self = .uah   // UAH
        case 0x5547580000000000: self = .ugx   // UGX
        case 0x5553440000000000: self = .usd   // USD
        case 0x55534E0000000000: self = .usn   // USN
        case 0x5559490000000000: self = .uyi   // UYI
        case 0x5559550000000000: self = .uyu   // UYU
        case 0x5559570000000000: self = .uyw   // UYW
        case 0x555A530000000000: self = .uzs   // UZS
        case 0x5645440000000000: self = .ved   // VED
        case 0x5645530000000000: self = .ves   // VES
        case 0x564E440000000000: self = .vnd   // VND
        case 0x5655560000000000: self = .vuv   // VUV
        case 0x5753540000000000: self = .wst   // WST
        case 0x5841440000000000: self = .xad   // XAD
        case 0x5841460000000000: self = .xaf   // XAF
        case 0x5843440000000000: self = .xcd   // XCD
        case 0x5843470000000000: self = .xcg   // XCG
        case 0x584F460000000000: self = .xof   // XOF
        case 0x5850460000000000: self = .xpf   // XPF
        case 0x5945520000000000: self = .yer   // YER
        case 0x5A41520000000000: self = .zar   // ZAR
        case 0x5A4D570000000000: self = .zmw   // ZMW
        case 0x5A57470000000000: self = .zwg   // ZWG
        default: return nil
        }
    }
}
