import Benchmark
import Foundation
import SwiftMoney

let benchmarks: @Sendable () -> Void = {
    let defaultMetrics: [BenchmarkMetric] = [
        .wallClock,
        .mallocCountTotal,
        .instructions,
    ]

    let defaultConfiguration = Benchmark.Configuration(
        metrics: defaultMetrics,
        scalingFactor: .mega
    )

    // MARK: - Money Arithmetic

    Benchmark("Money addition", configuration: defaultConfiguration) { benchmark in
        var accumulated = Money<GBP>(minorUnits: 0)
        let delta = Money<GBP>(minorUnits: 1)

        for _ in benchmark.scaledIterations {
            blackHole(accumulated)
            accumulated = accumulated + delta
        }
    }

    Benchmark("Foundation Decimal addition", configuration: defaultConfiguration) { benchmark in
        var accumulated = Foundation.Decimal.zero
        let delta = Foundation.Decimal(string: "0.01")!

        for _ in benchmark.scaledIterations {
            blackHole(accumulated)
            accumulated = accumulated + delta
        }
    }

    Benchmark("Money subtraction", configuration: defaultConfiguration) { benchmark in
        var accumulated = Money<GBP>(minorUnits: 999_999_999)
        let delta = Money<GBP>(minorUnits: 1)

        for _ in benchmark.scaledIterations {
            blackHole(accumulated)
            accumulated = accumulated - delta
        }
    }

    Benchmark("Foundation Decimal subtraction", configuration: defaultConfiguration) { benchmark in
        var accumulated = Foundation.Decimal(string: "9999999.99")!
        let delta = Foundation.Decimal(string: "0.01")!

        for _ in benchmark.scaledIterations {
            blackHole(accumulated)
            accumulated = accumulated - delta
        }
    }

    Benchmark("Money multiplication (Int64)", configuration: defaultConfiguration) { benchmark in
        let price = Money<GBP>(minorUnits: 1250)
        let quantities: [Int64] = [1, 2, 3, 5, 7, 10, 13, 17, 19, 23]
        var i = 0

        for _ in benchmark.scaledIterations {
            blackHole(price * quantities[i % quantities.count])
            i &+= 1
        }
    }

    Benchmark("Foundation Decimal multiplication", configuration: defaultConfiguration) { benchmark in
        let price = Foundation.Decimal(string: "12.50")!
        let quantities: [Foundation.Decimal] = [1, 2, 3, 5, 7, 10, 13, 17, 19, 23]
        var i = 0

        for _ in benchmark.scaledIterations {
            blackHole(price * quantities[i % quantities.count])
            i &+= 1
        }
    }

    Benchmark("Money comparison", configuration: defaultConfiguration) { benchmark in
        let a = Money<GBP>(minorUnits: 1000)
        let b = Money<GBP>(minorUnits: 2000)
        var count: Int = 0

        for _ in benchmark.scaledIterations {
            if a < b { count &+= 1 }
        }
        blackHole(count)
    }

    Benchmark("Foundation Decimal comparison", configuration: defaultConfiguration) { benchmark in
        let a = Foundation.Decimal(string: "10.00")!
        let b = Foundation.Decimal(string: "20.00")!
        var count: Int = 0

        for _ in benchmark.scaledIterations {
            if a < b { count &+= 1 }
        }
        blackHole(count)
    }

    Benchmark("Money isNaN check", configuration: defaultConfiguration) { benchmark in
        let value = Money<GBP>(minorUnits: 1250)
        var count: Int = 0

        for _ in benchmark.scaledIterations {
            if !value.isNaN { count &+= 1 }
        }
        blackHole(count)
    }

    // MARK: - FormatStyle

    Benchmark("Money formatted()", configuration: defaultConfiguration) { benchmark in
        let price = Money<GBP>(minorUnits: 12550)
        var lengthAccumulator: Int = 0

        for _ in benchmark.scaledIterations {
            lengthAccumulator &+= price.formatted().count
        }
        blackHole(lengthAccumulator)
    }

    Benchmark("Foundation Decimal formatted(.currency)", configuration: defaultConfiguration) { benchmark in
        let price = Foundation.Decimal(string: "125.50")!
        let style = Foundation.Decimal.FormatStyle.Currency(code: "GBP")
        var lengthAccumulator: Int = 0

        for _ in benchmark.scaledIterations {
            lengthAccumulator &+= price.formatted(style).count
        }
        blackHole(lengthAccumulator)
    }

    Benchmark("Money formatted(.grouping(.never))", configuration: defaultConfiguration) { benchmark in
        let price = Money<GBP>(minorUnits: 12550)
        let style = Money<GBP>.FormatStyle().grouping(.never)
        var lengthAccumulator: Int = 0

        for _ in benchmark.scaledIterations {
            lengthAccumulator &+= price.formatted(style).count
        }
        blackHole(lengthAccumulator)
    }

    // MARK: - Codable

    Benchmark("Money JSON encode (.minorUnits)", configuration: defaultConfiguration) { benchmark in
        let price = Money<GBP>(minorUnits: 12550)
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .minorUnits
        var byteCount: Int = 0

        for _ in benchmark.scaledIterations {
            byteCount &+= (try? encoder.encode(price))?.count ?? 0
        }
        blackHole(byteCount)
    }

    Benchmark("Foundation Decimal JSON encode", configuration: defaultConfiguration) { benchmark in
        let decimal = Foundation.Decimal(string: "125.50")!
        let encoder = JSONEncoder()
        var byteCount: Int = 0

        for _ in benchmark.scaledIterations {
            byteCount &+= (try? encoder.encode(decimal))?.count ?? 0
        }
        blackHole(byteCount)
    }

    Benchmark("Money JSON decode (.minorUnits)", configuration: defaultConfiguration) { benchmark in
        let data = "12550".data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.moneyDecodingStrategy = .minorUnits
        var count: Int = 0

        for _ in benchmark.scaledIterations {
            let value = try? decoder.decode(Money<GBP>.self, from: data)
            blackHole(value)
            count &+= 1
        }
        blackHole(count)
    }

    Benchmark("Foundation Decimal JSON decode", configuration: defaultConfiguration) { benchmark in
        let data = "125.50".data(using: .utf8)!
        let decoder = JSONDecoder()
        var count: Int = 0

        for _ in benchmark.scaledIterations {
            let value = try? decoder.decode(Foundation.Decimal.self, from: data)
            blackHole(value)
            count &+= 1
        }
        blackHole(count)
    }

    // MARK: - Distribution

    Benchmark("Money distributed(into: 3)", configuration: defaultConfiguration) { benchmark in
        let amount = Money<GBP>(minorUnits: 1000)

        for _ in benchmark.scaledIterations {
            blackHole(amount.distributed(into: 3))
        }
    }

    // MARK: - ExchangeRate

    Benchmark("ExchangeRate convert", configuration: defaultConfiguration) { benchmark in
        let rate = ExchangeRate<GBP, USD>(from: 100, to: 135)!
        let gbp = Money<GBP>(minorUnits: 1000)

        for _ in benchmark.scaledIterations {
            blackHole(rate.convert(gbp))
        }
    }

    // MARK: - MoneyBag

    Benchmark("MoneyBag add 10 entries", configuration: defaultConfiguration) { benchmark in
        let amounts: [Money<GBP>] = (1...10).map { Money<GBP>(minorUnits: Int64($0) * 100) }

        for _ in benchmark.scaledIterations {
            var bag = MoneyBag()
            for amount in amounts {
                bag.add(amount)
            }
            blackHole(bag)
        }
    }
}
