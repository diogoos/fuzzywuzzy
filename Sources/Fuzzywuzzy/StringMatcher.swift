//
//  StringMatcher.swift
//
//  Created by Diogo Silva on 12/24/20.
//

import Levenshtein

/// SequenceMatcher is a flexible class for comparing pairs of sequences of
/// strings. The basic idea is to find the longest contiguous matching subsequence
/// The same idea is then applied recursively to the pieces of the sequences to
/// the left and to the right of the matching subsequence. This does not yield minimal
/// edit sequences, but does tend to yield matches that "look right" to people.
public class StringMatcher {
    // MARK: - Variables & Initalizers
    /// The first string being compared
    var s1: String { didSet { clearCache() } }
    /// The second sequence being compared (second sequence; differences
    /// are computed as "what do we need to do to 's1' to change it into 's2'?")
    var s2: String { didSet { clearCache() } }

    /// A C-compatible pointer to the utf8 value of the first string
    private var p1: UnsafePointer<UInt8>? { s1.toPointer() }
    /// A C-compatible pointer to the utf8 value of the second string
    private var p2: UnsafePointer<UInt8>? { s2.toPointer() }

    /// Construct a SequenceMatcher.
    /// - Parameter compare: is the first of two sequences to be compared.
    /// - Parameter to: is the second of two sequences to be compared;
    /// differences are computed as "what do we need to do to 's1' to change
    /// it into 's2'?
    init(compare s1: String, to s2: String) {
        self.s1 = s1
        self.s2 = s2
    }

    // MARK: - Cache
    // As many of the functions are computationally expensive,
    // we should cache the results to speed up the functions.
    // However, it must always be cleared when sequences are
    // changed.

    /// Cached ratio of s1 to s2
    private var cachedRatio: Double? = nil
    /// Cached distance between s1 and s2
    private var cachedDistance: Double? = nil
    /// Cached matching blocks in s1 and s2
    private var cachedMatchingBlocks: [MatchingBlock]? = nil
    /// Cached operation codes to transform s1 into s2
    private var cachedOpCodes: [Operation]? = nil

    /// Remove all items of the cache
    /// Automatically called when the sequences change
    private func clearCache() {
        cachedRatio = nil
        cachedDistance = nil
        cachedMatchingBlocks = nil
        cachedOpCodes = nil
    }

    // MARK: - Structures
    // These structures describe the results of each operation
    // performed by the user. They should be Swifty translations
    // of their original C-based counterparts.


    /// An operation that can be applied to a string,
    /// such as inserting, removing, adding, or replacing
    /// characters
    ///
    /// Each operation is contains a type, and four indexes of strings.
    /// The first two (`sbeg` and `send`) pertain to the first string,
    /// while the second two (`dbeg` and `dend`) pertain to the second.
    ///
    /// These parts can be interpreted as the following:
    /// ```
    /// replace:  s1[sbeg:send] should be replaced by s2[dbeg:dend]
    /// delete:   s2[sbeg:send] should be deleted.
    /// insert:   s2[dbeg:dend] should be inserted at s1[sbeg:send].
    /// equal:    s1[sbeg:send] == b[dbeg:dend]
    /// ```
    ///
    struct Operation {
        /// The type of the operation
        var type: EditType

        /// Start index of the operation in the first sequence
        var sbeg: Int
        /// End index of the operation in the first sequence
        var send: Int

        /// Start index of the operation in the second sequence
        var dbeg: Int

        /// End index of the operation in the second sequence
        var dend: Int

        /// Construct a new operation given each individual member
        init(type: EditType, sbeg: Int, send: Int, dbeg: Int, dend: Int) {
            self.type = type
            self.sbeg = sbeg
            self.send = send
            self.dbeg = dbeg
            self.dend = dend
        }

        /// Construct a new operation from a type
        /// and a tuple of indicies in the format
        /// (sbeg, send, dbeg, dend)
        init(type: EditType, indicies: (Int, Int, Int, Int)) {
            self.type = type

            sbeg = indicies.0
            send = indicies.1
            dbeg = indicies.2
            dend = indicies.3
        }

        /// Construct a new operation from a C LevOpCode
        init(from levcode: LevOpCode) {
            type = EditType(rawValue: Int(levcode.type.rawValue))!
            sbeg = levcode.sbeg
            send = levcode.send
            dbeg = levcode.dbeg
            dend = levcode.dend
        }

        /// Convert to a C LevOpCode
        func cCompatible() -> LevOpCode {
            let cEditType = LevEditType(rawValue: UInt32(type.rawValue))
            return LevOpCode(type: cEditType, sbeg: sbeg, send: send, dbeg: dbeg, dend: dend)
        }
    }

    /// A type of edit performed on a string
    enum EditType: Int {
        case keep, replace, insert, delete
    }


    /// A Matching Block describes matching subsequences in each string.
    /// The triple is in the form (i, j, n), and means that a[i:i+n] == b[j:j+n].
    typealias MatchingBlock = (a: Int, b: Int, size: Int)


    // MARK: - String operations
    // Operations normally called by the user to compute
    // relationships between the strings.


    /// Calculates the sequences' similarity
    ///
    /// Where T is the total number of elements in both sequences, and
    /// M is the number of matches, this is 2.0*M / T.
    /// Note that this is 1 if the sequences are identical, and 0 if
    /// they have nothing in common.
    ///
    /// - Note: ratio() is expensive to compute if you haven't already
    /// computed matchingBlcoks() or opCodes(), in which case you may
    /// want to try quickRatio() or veryQuickRatio() first to get an
    /// upper bound.
    ///
    /// - Returns: a measure of the sequences' similarity (Double in [0, 1])
    /// where the higher the value, the closer the strigs are.
    func ratio() -> Double {
        if let ratio = cachedRatio { return ratio } // Attempt to use cache

        // Get lengths
        let len1 = s1.length
        let len2 = s2.length
        let lensum = len1 + len2

        // get ratio
        let edit_dist = lev_edit_distance(len1, p1, len2, p2, 1)
        let ratio = Double(lensum - edit_dist) / Double(lensum)

        // cache result
        cachedRatio = ratio

        return ratio
    }

    /// Find the operations that must be applied to s1 to turn it into s2.
    /// - Returns: an array of operations to be applied to s1
    func opcodes() -> [Operation] {
        if let operations = cachedOpCodes { return operations } // Attempt to use cache

        var size = 0
        var opcodes = [LevOpCode]()

        let len1 = s1.length
        let len2 = s2.length

        if let ops = lev_editops_find(len1, p1, len2, p2, &size) {
            var opSize: Int = 0
            if let bops = lev_editops_to_opcodes(size, ops, &opSize, len1, len2) {
                opcodes = bops.elements(count: opSize)
                free(bops)
            }
            free(ops)
        }

        let operations = opcodes.map({ Operation(from: $0) })
        cachedOpCodes = operations
        return operations
    }

    /// Return list of triples describing matching subsequences.
    ///
    /// Each triple is of the form (i, j, n), and means that
    /// a[i:i+n] == b[j:j+n].  The triples are monotonically increasing
    /// in i and in j.  It is also guaranteed that if (i, j, n) and
    /// (i', j', n') are adjacent triples in the list, and the second
    /// is not the last triple in the list, then i+n != i' or j+n != j'.
    /// The last triple is a dummy, (len(a), len(b), 0), and is the only
    /// triple with n==0.
    func matchingBlocks() -> [MatchingBlock] {
        if let matchingBlocks = cachedMatchingBlocks { return matchingBlocks } // attempt to use cache
        var operations = opcodes().map({ $0.cCompatible() }) // get operation codes (cached or not)

        var blocks = [LevMatchingBlock]()

        var size = 0
        if let mblocks = lev_opcodes_matching_blocks(s1.length, s2.length, operations.count, &operations, &size) {
            blocks = mblocks.elements(count: size)
            free(mblocks)
        }

        // required by https://github.com/miohtama/python-Levenshtein/blob/f050e3ca537a057f63a87791b5f5325ca1e198f8/Levenshtein.c#L1517
        // and diffLib SequenceMatcher
        // but not by https://github.com/tmplt/fuzzywuzzy/blob/a4f8b717b3f30208436f82054413660a8d2f7613/src/wrapper.cpp#L101
        // for better compatibility, we should use the former, not the latter
        blocks.append(LevMatchingBlock(spos: s1.length, dpos: s2.length, len: 0))

        return blocks.map { ($0.spos, $0.dpos, $0.len) }
    }
    
}
