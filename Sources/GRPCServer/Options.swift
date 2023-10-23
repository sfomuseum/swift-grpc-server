import Logging

public struct GRPCServerOptions {
    public var host: String = "localhost"
    public var port: Int = 8080
    public var threads: Int = 1
    public var logger: Logger
    public var tls_certificate: String?
    public var tls_key: String?
    public var verbose: Bool = false
    
    public init(host: String, port: Int, threads: Int, logger: Logger, tls_certificate: String? = nil, tls_key: String? = nil, verbose: Bool) {
        self.host = host
        self.port = port
        self.threads = threads
        self.logger = logger
        self.tls_certificate = tls_certificate
        self.tls_key = tls_key
        self.verbose = verbose
    }
}
