//
//  TokenFunctions.swift
//
//  Created by Diogo Silva on 12/24/20.
//

public class TokenFunctions {
    // MARK: - Underlying functions
    /**
     Find all alphanumeric tokens in each string...
     - treat them as a set
     - construct two strings of the form:
     <sorted_intersection><sorted_remainder>
     - take ratios of those two strings
     - controls for unordered partial matches
     */
    internal static func tokenSet(s1: String, s2: String, partial: Bool = true, forceAscii: Bool = true, fullProcess: Bool = true) -> Int {
        if !fullProcess && s1 == s2 { return 100 }

        let p1 = fullProcess ? s1.fullyProcessed(stripNonAscii: forceAscii) : s1
        let p2 = fullProcess ? s2.fullyProcessed(stripNonAscii: forceAscii) : s2

        let tokens1 = Set(p1.split(separator: " "))
        let tokens2 = Set(p2.split(separator: " "))

        let intersection = tokens1.intersection(tokens2)
        let diff1to2 = tokens1.subtracting(tokens2)
        let diff2to1 = tokens2.subtracting(tokens1)

        var sortedSect = intersection.sorted().joined(separator: " ")
        let sorted1to2 = diff1to2.sorted().joined(separator: " ")
        let sorted2to1 = diff2to1.sorted().joined(separator: " ")

        var combined1to2 = sortedSect + " " + sorted1to2
        var combined2to1 = sortedSect + " " + sorted2to1

        // strip whitespace
        sortedSect = sortedSect.trimmingCharacters(in: .whitespaces)
        combined1to2 = combined1to2.trimmingCharacters(in: .whitespaces)
        combined2to1 = combined2to1.trimmingCharacters(in: .whitespaces)

        let ratioFunc = partial ? String.partialRatio : String.ratio
        let pairwise = [
            ratioFunc(sortedSect)(combined1to2, fullProcess),
            ratioFunc(sortedSect)(combined2to1, fullProcess),
            ratioFunc(combined1to2)(combined2to1, fullProcess)
        ]


        return pairwise.max()!
    }

    internal static func tokenSort(s1: String, s2: String, partial: Bool = true, forceAscii: Bool = true, fullProcess: Bool = true) -> Int {
        let sorted1 = s1.sortTokens(forceAscii: forceAscii, fullProcess: fullProcess)
        let sorted2 = s2.sortTokens(forceAscii: forceAscii, fullProcess: fullProcess)

        return partial ? sorted1.partialRatio(to: sorted2) : sorted1.ratio(to: sorted2)
    }

    // MARK: - Public functions
    public static func partialTokenSetRatio(_ s1: String, _ s2: String, force_ascii: Bool = true, fullProcess: Bool = true) -> Double {
        Double(tokenSet(s1: s1, s2: s2, partial: true, forceAscii: force_ascii, fullProcess: fullProcess))
    }

    public static func partialTokenSortRatio(_ s1: String, _ s2: String, forceAscii: Bool = true, fullProcess: Bool = true) -> Double {
        Double(tokenSort(s1: s1, s2: s2, partial: true, forceAscii: forceAscii, fullProcess: fullProcess))
    }

    public static func tokenSortRatio(_ s1: String, _ s2: String, fullProcess: Bool = false) -> Double {
        Double(tokenSort(s1: s1, s2: s2, partial: false, forceAscii: true, fullProcess: fullProcess))
    }

    public static func tokenSetRatio(_ s1: String, _ s2: String, fullProcess: Bool = false) -> Double {
        Double(tokenSet(s1: s1, s2: s2, partial: false, forceAscii: true, fullProcess: fullProcess))
    }
}
