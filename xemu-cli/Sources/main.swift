import Network

let cli: XemuCLI = .init()

cli.run("""
    file /Users/xehos/Downloads/dk.nes
    context
""")

cli.run()
