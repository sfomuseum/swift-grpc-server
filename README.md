# swift-grpc-server

Opinionated Swift package for running simple gRPC servers with optional TLS support.

## Example

```
import Logging
import GRPCServer
import GRPC

// This is your own code. This is the package that will be created when you
// run protoc on your protobuffer definition.
var provider: CallHandlerProvider

let logger = Logger(label: "org.sfomuseum.example")

let server_opts = GRPCServerOptions(
	host: "localhost",			// default: localhost
        port: 8080,				// default: 8080
        threads: 1,				// default: 1
        logger: logger,
        tls_certificate: "/path/to/tls.cert",	// optional
        tls_key: "/path/to/tls.key",		// optional
        verbose: false				// default: false
)
      
let server = GRPCServer(server_opts)
try await server.Run([provider])
```