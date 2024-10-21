import Darwin.net

class NetworkLocalAddress {
    static func get() -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        
        guard getifaddrs(&ifaddr) == 0, let ifaddr else {
            return nil
        }
        
        freeifaddrs(ifaddr)
        
        return parseIfaddrs(ifaddr)
    }
    
    private static func parseIfaddrs(_ interface: UnsafeMutablePointer<ifaddrs>) -> String? {
        let addrFamily = interface.pointee.ifa_addr.pointee.sa_family
        let name = String(cString: interface.pointee.ifa_name)
        
        guard addrFamily == UInt8(AF_INET), name == "en0" || name == "en1" else {
            guard let next = interface.pointee.ifa_next else {
                return nil
            }
            
            return parseIfaddrs(next)
        }
        
        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        
        getnameinfo(
            interface.pointee.ifa_addr,
            socklen_t(interface.pointee.ifa_addr.pointee.sa_len),
            &hostname,
            socklen_t(hostname.count),
            nil,
            socklen_t(0),
            NI_NUMERICHOST
        )

        return String(cString: hostname)
    }
}
