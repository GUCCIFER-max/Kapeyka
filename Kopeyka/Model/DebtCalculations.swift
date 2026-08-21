import Foundation

extension Income {
    var totalRepaid: Decimal {
        (repayments as? Set<Expense> ?? [])
            .reduce(Decimal(0)) { $0 + $1.amount }
    }

    var remainingDebt: Decimal {
        max(0, amount - totalRepaid)
    }

    var isSettled: Bool {
        remainingDebt <= 0
    }

    var repaymentProgress: Double {
        guard amount > 0 else { return 1 }
        return min(1, NSDecimalNumber(decimal: totalRepaid / amount).doubleValue)
    }
}
