import SwiftUI

/// Big serif amount entry with live thousands-grouping ("500 000") and a
/// clear button, so a mistyped amount is one tap to fix. `rawValue` stays
/// plain digits (plus an optional ".") for downstream `Decimal` parsing —
/// only the displayed text is grouped.
struct AmountField: View {
    @Binding var rawValue: String
    var fontSize: CGFloat = 56

    var body: some View {
        TextField(
            "0",
            text: Binding(
                get: { Self.grouped(rawValue) },
                set: { rawValue = Self.digitsOnly($0) }
            )
        )
        .keyboardType(.decimalPad)
        .font(.sum(fontSize))
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .trailing) {
            if !rawValue.isEmpty {
                Button {
                    rawValue = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .padding(.trailing, 4)
            }
        }
    }

    private static func digitsOnly(_ input: String) -> String {
        var result = ""
        var hasSeparator = false
        for char in input {
            if char.isNumber {
                result.append(char)
            } else if (char == "," || char == ".") && !hasSeparator {
                result.append(".")
                hasSeparator = true
            }
        }
        return result
    }

    private static func grouped(_ raw: String) -> String {
        guard !raw.isEmpty else { return "" }
        let parts = raw.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let integerDigits = Array(String(parts[0]))

        var groupedReversed = ""
        for (index, char) in integerDigits.reversed().enumerated() {
            if index > 0 && index % 3 == 0 {
                groupedReversed.append(" ")
            }
            groupedReversed.append(char)
        }
        var result = String(groupedReversed.reversed())

        if parts.count > 1 {
            result += "," + parts[1]
        }
        return result
    }
}

private struct AmountFieldPreview: View {
    @State private var value = "500000"

    var body: some View {
        AmountField(rawValue: $value)
            .padding()
            .preferredColorScheme(.dark)
    }
}

#Preview {
    AmountFieldPreview()
}
