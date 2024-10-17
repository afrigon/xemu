extension String {
    var sanitizedFilename: String {
        self
            .replacing(/\(.*\)/, with: "")
            .replacing(/\[.*\]/, with: "")
            .replacing(/-\d+$/, with: "")
            .replacing(/'s/, with: "")
            .replacing(/,/, with: "")
            .replacing(/\ \d+\ /, with: " ")
            .replacing(/-/, with: "")
            .replacing(/\s+/, with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
