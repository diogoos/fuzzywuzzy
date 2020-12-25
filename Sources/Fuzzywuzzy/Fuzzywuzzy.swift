import Levenshtein
import Foundation

public extension String {
    /// Calculates the String's similarity to another
    /// - Parameter to: the string that this one should be compared to
    /// - Parameter fullProcess: whether the whole string should be processed
    /// - Returns: a measure of the sequences' similarity (Int in [0, 100])
    /// where the higher the value, the closer the strigs are.
    func ratio(to another: String, fullProcess: Bool = true) -> Int {
        // Process the strings if necessary
        let s1 = fullProcess ? fullyProcessed() : self
        let s2 = fullProcess ? another.fullyProcessed() : another

        if s1.isEmpty && s2.isEmpty { return 100 }

        // Create string matcher
        let m = StringMatcher(compare: s1, to: s2)
        return m.ratio().percentRound()
    }

    /// The ratio of the most similar substring in
    /// this string and the other as a number between 0 and 100
    /// - Parameter to: the string that this one should be
    /// compared to
    /// - Parameter fullProcess: whether the string should be processed
    /// for a more accurate search
    /// - Returns: an integer between 0 and 100 describing the similarity
    func partialRatio(to another: String, fullProcess: Bool = true) -> Int {
        // assign by sizes
        let isSmaller = length <= another.length
        let shorter = isSmaller ? self    : another
        let longer  = isSmaller ? another : self

        if self == another { return 100 }

        let m = StringMatcher(compare: shorter, to: longer)
        let blocks = m.matchingBlocks()

        /*
         * Each block represents a string of matching characters
         * in a string of the form (idx_1, idx_2, len). The best
         * partial match will block align with at least one
         * of those blocks.
         * e.g. shorter = "abcd", longer "XXXbcdeEEE"
         * block = (1, 3, 3)
         * best score == ratio("abcd", "Xbcd")
         */
        var scores = [Double]()
        for block in blocks {
            let longStart = max(0, block.b - block.a)
            let longEnd = longStart + shorter.count
            let longSubstring = String(longer[longer.range(start: longStart, end: longEnd)])

            let m2 = StringMatcher(compare: shorter, to: longSubstring)
            let r = m2.ratio()

            if r > 0.995 { return 100 }
            else { scores.append(r) }
        }

        if scores.isEmpty { return 0 }
        if scores.count == 1 && scores.max()!.isNaN { return 0 }
        if scores.max()!.isNaN { scores = scores.filter { !$0.isNaN } }

        return scores.max()!.percentRound()
    }

    /// Return a measure of the sequences' similarity between 0 and 100, using different algorithms.
    ///
    /// **Steps in the order they occur**
    /// 1. Run full_process from utils on both strings
    /// 2. Short circuit if this makes either string empty
    /// 3. Take the ratio of the two processed strings (fuzz.ratio)
    /// 4. Run checks to compare the length of the strings
    ///    * If one of the strings is more than 1.5 times as long as the other
    ///      use partial_ratio comparisons - scale partial results by 0.9
    ///      (this makes sure only full results can return 100)
    ///    * If one of the strings is over 8 times as long as the other
    ///      instead scale by 0.6
    /// 5. Run the other ratio functions
    ///    * if using partial ratio functions call partial_ratio,
    ///      partial_token_sort_ratio and partial_token_set_ratio
    ///      scale all of these by the ratio based on length
    ///    * otherwise call token_sort_ratio and token_set_ratio
    ///    * all token based comparisons are scaled by 0.95
    ///      (on top of any partial scalars)
    /// 6. Take the highest value from these results
    ///    * round it and return it as an integer.
    /// - Parameter to: The string that this should be compared to
    func weightedRatio(to another: String, forceAscii: Bool = true) -> Int {
        let p1 = self.fullyProcessed(stripNonAscii: forceAscii)
        let p2 = another.fullyProcessed(stripNonAscii: forceAscii)

        var tryPartials = true
        let unbaseScale = 0.95
        var partialScale = 0.9

        let base = Double(p1.ratio(to: p2, fullProcess: false))
        let lenRatio = Double(max(p1.count, p2.count)) / Double(min(p1.count, p2.count))

        // if strings are similar lengths, don't use partials
        if lenRatio < 1.5 { tryPartials = false }
        // if one string is much shorter than another change scale
        if lenRatio > 8 { partialScale = 0.6 }

        if tryPartials {
            let partial = Double(p1.partialRatio(to: p2)) * partialScale

            let pstor = TokenFunctions.partialTokenSortRatio(p1, p2, fullProcess: false) * unbaseScale * partialScale
            let pster = TokenFunctions.partialTokenSetRatio (p1, p2, fullProcess: false) * unbaseScale * partialScale

            return Int(Swift.max(base, partial, pstor, pster).rounded())
        } else {
            let tsor = TokenFunctions.tokenSortRatio(p1, p2, fullProcess: false) * unbaseScale
            let tser = TokenFunctions.tokenSetRatio (p1, p2, fullProcess: false) * unbaseScale

            return Int(Swift.max(base, tsor, tser).rounded())
        }
    }
}

