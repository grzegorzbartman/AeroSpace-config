// Prints the Data volume's used-space percentage (integer) the way Finder
// counts it: volumeAvailableCapacityForImportantUsage treats purgeable space
// (e.g. Time Machine local snapshots) as free, unlike df's Avail column.
// Compiled binary avoids the ~1s `swift -e` cold start on every poll.
import Foundation

let url = URL(fileURLWithPath: "/System/Volumes/Data")
guard let v = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey,
                                                .volumeTotalCapacityKey]),
      let total = v.volumeTotalCapacity, total > 0,
      let avail = v.volumeAvailableCapacityForImportantUsage, avail > 0 else {
    exit(1)
}
let used = 100.0 * (1.0 - Double(avail) / Double(total))
print(Int(used.rounded()))
