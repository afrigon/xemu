import SQLite3
import Foundation


class OpenVGDBService {
    static let shared = OpenVGDBService()
    
    private var db: OpaquePointer?
    private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    init?() {
        guard let url = Bundle.main.url(forResource: "openvgdb", withExtension: "sqlite") else {
            return nil
        }
        
        guard sqlite3_open(url.absoluteString, &db) == SQLITE_OK else {
            print("Could not open OpenVGDB database.")
            return nil
        }
    }
    
    deinit {
        sqlite3_close(db)
    }
    
    func getReleases(like name: String, for console: String) -> [OpenVGDBRelease] {
        let selectQuery = """
WITH RankedReleases AS (
    SELECT RELEASES.releaseTitleName AS name, RELEASES.releaseCoverFront AS image, bm25(RELEASES_FTS) AS rank
    FROM RELEASES
    JOIN RELEASES_FTS ON RELEASES.releaseID = RELEASES_FTS.rowid
    WHERE RELEASES_FTS MATCH ?
    AND RELEASES.TEMPsystemShortName = ?
    ORDER BY rank
)

SELECT min(name), image
FROM RankedReleases
GROUP BY image
"""

        var queryStatement: OpaquePointer?
        
        var releases: [OpenVGDBRelease] = []
        
        if sqlite3_prepare_v2(db, selectQuery, -1, &queryStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(queryStatement, 1, "\(name)*", -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(queryStatement, 2, console, -1, SQLITE_TRANSIENT)
            
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let name = String(cString: sqlite3_column_text(queryStatement, 0))
                
                guard let artworkCString = sqlite3_column_text(queryStatement, 1), let artworkURL = URL(string: String(cString: artworkCString)) else {
                    continue
                }
                
                let release = OpenVGDBRelease(name: name, artworkURL: artworkURL)
                releases.append(release)
            }
        } else {
            let err = String(cString: sqlite3_errmsg(db))
            print("Error preparing select: \(err)")
        }

        sqlite3_finalize(queryStatement)
        
        return releases
    }
}
