import Logging
import Foundation

import GRPCCore
import GRPCNIOTransportHTTP2
import GRPCProtobuf

@available(macOS 15.0, *)
public class GRPCServer {
    
    internal var options: GRPCServerOptions
    
    public init(_ opts: GRPCServerOptions) {
        self.options = opts
    }
    
    public func Run(_ services: [GRPCCore.RegistrableRPCService ]) async throws {
                        
        let transport = HTTP2ServerTransport.Posix(
            address: .ipv4(host: self.options.host, port: self.options.port),
            transportSecurity: .plaintext,
        )
        
        let server = GRPCCore.GRPCServer(transport: transport, services: services)
                
        try await withThrowingDiscardingTaskGroup { group in
            // Why does this time out?
            // let address = try await transport.listeningAddress
            self.options.logger.info("listening for requests on \(self.options.host):\(self.options.port)")
            group.addTask { try await server.serve() }
        }
    }
    
}
