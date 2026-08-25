// Prints Data volume usage as "used/total unit" (e.g. "1.4/2 TB"), the way
// Finder counts it: volumeAvailableCapacityForImportantUsage treats purgeable
// space (e.g. Time Machine local snapshots) as free, unlike df's Avail column.
// Decimal (SI) units to match Finder's disk sizes. Compiled binary avoids the
// ~1s `swift -e` cold start on every poll.
import Foundation

let url = URL(fileURLWithPath: "/System/Volumes/Data")
guard let v = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey,
                                                .volumeTotalCapacityKey]),
      let total = v.volumeTotalCapacity, total > 0,
      let avail = v.volumeAvailableCapacityForImportantUsage, avail > 0 else {
    exit(1)
}

let usedB = Double(total - Int(avail))
let totalB = Double(total)

func nice(_ v: Double) -> String {
    let s = String(format: "%.1f", v)
    return s.hasSuffix(".0") ? String(Int(v.rounded())) : s
}

if totalB >= 1e12 {
    print("\(nice(usedB / 1e12))/\(nice(totalB / 1e12)) TB")
} else {
    print("\(Int((usedB / 1e9).rounded()))/\(Int((totalB / 1e9).rounded())) GB")
}
