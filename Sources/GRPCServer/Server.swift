import Logging
import GRPC
import NIOCore
import NIOPosix
import NIOSSL
import Logging
import Foundation
import Puppy

@available(macOS 14.0, iOS 17.0, tvOS 17.0, *)
public class GRPCServer {
    
    internal var options: GRPCServerOptions
    
    public init(_ opts: GRPCServerOptions) {
        self.options = opts
    }
    
    public func Run(_ providers: [CallHandlerProvider]) async throws {
        
        let group = MultiThreadedEventLoopGroup(numberOfThreads: self.options.threads)
        
        defer {
            try! group.syncShutdownGracefully()
        }
        
        var builder: Server.Builder
        
        if self.options.tls_certificate != nil && self.options.tls_key != nil {
            
            let cert = try NIOSSLCertificate(file: self.options.tls_certificate!, format: .pem)
            let key = try NIOSSLPrivateKey(file: self.options.tls_key!, format: .pem)
            
            // 'secure(group:certificateChain:privateKey:)' is deprecated: Use one of 'usingTLSBackedByNIOSSL(on:certificateChain:privateKey:)', 'usingTLSBackedByNetworkFramework(on:with:)' or 'usingTLS(with:on:)'
            
            builder = Server.secure(group: group, certificateChain:[cert], privateKey: key)
        } else {
            
            builder = Server.insecure(group: group)
        }
        
        let server = try await builder
            .withServiceProviders(providers)
            .withLogger(self.options.logger)
            .bind(host: self.options.host, port: self.options.port)
            .get()
        
        self.options.logger.info("server started on port \(server.channel.localAddress!.port!)")
        
        // Wait on the server's `onClose` future to stop the program from exiting.
        try await server.onClose.get()
    }
    
}
