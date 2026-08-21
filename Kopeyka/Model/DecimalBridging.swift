import CoreData

/// Core Data's `Decimal` attribute type has no scalar Swift representation —
/// generated properties are always `NSDecimalNumber?`. These wrappers give
/// the rest of the app a plain, non-optional `Decimal` to work with under
/// the original property names, without every call site handling bridging.
extension Expense {
    var amount: Decimal {
        get { (amountRaw as Decimal?) ?? 0 }
        set { amountRaw = newValue as NSDecimalNumber }
    }
}

extension Template {
    var amount: Decimal {
        get { (amountRaw as Decimal?) ?? 0 }
        set { amountRaw = newValue as NSDecimalNumber }
    }
}

extension Income {
    var amount: Decimal {
        get { (amountRaw as Decimal?) ?? 0 }
        set { amountRaw = newValue as NSDecimalNumber }
    }
}
