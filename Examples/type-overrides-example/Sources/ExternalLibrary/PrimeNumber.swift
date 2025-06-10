
/// Example struct to be used instead of the default generated type.
/// This illustrates how to introduce a type performing additional validation during Decoding that cannot be expressed with OpenAPI
public struct PrimeNumber: Codable, Hashable, RawRepresentable, Sendable {
    public let rawValue: Int
    public init?(rawValue: Int) {
        if !rawValue.isPrime { return nil }
        self.rawValue = rawValue
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let number = try container.decode(Int.self)
        guard let value = PrimeNumber(rawValue: number) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "The number is not prime.")
        }
        self = value
    }
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }

}

extension Int {
    fileprivate var isPrime: Bool {
        if self <= 1 { return false }
        if self <= 3 { return true }

        var i = 2
        while i * i <= self {
            if self % i == 0 { return false }
            i += 1
        }
        return true
    }
}
