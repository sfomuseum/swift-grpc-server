import Logging
import GRPC
import NIOCore
import NIOPosix
import NIOSSL
import Logging
import Foundation
import Puppy

public struct GRPCServerOptions {
    public var host: String = "localhost"
    public var port: Int = 8080
    public var threads: Int = 1
    public var logger: Logger?
    public var log_label: String = "org.sfomuseum.grpc.server"
    public var log_file: String?
    public var tls_certificate: String?
    public var tls_key: String?
    public var verbose: Bool = false
}

internal struct logFormatter: LogFormattable {
    private let dateFormat = DateFormatter()

    init() {
        dateFormat.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    }

    func formatMessage(_ level: LogLevel, message: String, tag: String, function: String,
                       file: String, line: UInt, swiftLogInfo: [String : String],
                       label: String, date: Date, threadID: UInt64) -> String {
        let date = dateFormatter(date, withFormatter: dateFormat)
        let fileName = fileName(file)
        let moduleName = moduleName(file)
        return "\(date) \(threadID) [\(level)] \(swiftLogInfo) \(moduleName)/\(fileName)#L.\(line) \(function) \(message)"
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, *)
public class GRPCServer {
    
    internal var options: GRPCServerOptions
    
    public init(_ opts: GRPCServerOptions) {
        self.options = opts
        
        if self.options.logger == nil {
            
            self.options.logger = defaultLogger(log_label: self.options.log_label, log_file: self.options.log_file, verbose: self.options.verbose)
        }
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
            .withLogger(self.options.logger!)
            .bind(host: self.options.host, port: self.options.port)
        .get()

        self.options.logger!.info("server started on port \(server.channel.localAddress!.port!)")

      // Wait on the server's `onClose` future to stop the program from exiting.
      try await server.onClose.get()
    }
    
    internal func defaultLogger(log_label: String, log_file: String?, verbose: Bool) -> Logger {
        
        let log_format = logFormatter()
          
          // This does not work (yet) as advertised. Specifically only
          // the first handler added to puppy ever gets invoked. Dunno...
          
          var puppy = Puppy()

        /*
        if log_file != nil {
              
            let log_url = URL(fileURLWithPath: log_file!).absoluteURL
              
              let rotationConfig = RotationConfig(suffixExtension: .numbering,
                                                  maxFileSize: 30 * 1024 * 1024,
                                                  maxArchivedFilesCount: 5)
              
              let fileRotation = try FileRotationLogger(log_label,
                                                        logFormat: log_format,
                                                        fileURL: log_url,
                                                        rotationConfig: rotationConfig
              )
              
              puppy.add(fileRotation)
          }
          */
        
          // See notes above
          
          let console = ConsoleLogger(log_label, logFormat: log_format)
          puppy.add(console)
          
          LoggingSystem.bootstrap {
              
              var handler = PuppyLogHandler(label: $0, puppy: puppy)
              handler.logLevel = .info
              
              if verbose {
                  handler.logLevel = .trace
              }
              
              return handler
          }
          
          return Logger(label: log_label)
    }
}
