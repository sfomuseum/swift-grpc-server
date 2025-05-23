# swift-grpc-server

Opinionated Swift package for running simple gRPC servers with optional TLS support.

## Important

This package targets version `1.x` of the [grpc/grpc-swift](https://github.com/grpc/grpc-swift) libraries which have been updated to a backwards-incompatible version 2.x.

I have not decided if it's worth updating this package (to `grpc-swift` v2.x) yet.

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

## Logging "remote address"

For reasons I don't understand by the time user-defined code get invoked by `grpc-swift` it is no longer guaranteed that the client remote address will be in the message headers.

This can be addressed through the use an ["Interceptor"](https://github.com/grpc/grpc-swift/blob/main/docs/interceptors-tutorial.md) to capture the remote address from the `ServerInterceptorContext` and assigning that value to a `Logger` metadata. For example, something like this:

```
final class TextEmbosserServerInterceptorFactory: EmbosserServerInterceptorFactoryProtocol {
    
    func makeEmbossTextInterceptors() -> [GRPC.ServerInterceptor<EmbossTextRequest, EmbossTextResponse>] {
        return [TextEmbosserServerInterceptor()]
    }
}

final class TextEmbosserServerInterceptor: ServerInterceptor<EmbossTextRequest, EmbossTextResponse> {
    
    override func receive(
      _ part: GRPCServerRequestPart<EmbossTextRequest>,
      context: ServerInterceptorContext<EmbossTextRequest, EmbossTextResponse>
    ) {
        
        switch part {
        case .metadata(var m):
            if context.remoteAddress != nil {
                m.add(name: "remoteAddress", value: context.remoteAddress!.description)
            }
            context.receive(.metadata(m))
        default:
            context.receive(part)
        }
    }
}
```

And then:

```
public func setRemoteAddress(context: GRPC.GRPCAsyncServerCallContext, logger: Logger) {
        
    var remote_addr = "unknown"
        
    let headers = context.request.headers
        
    if headers.first(name: "remoteAddress") != nil {
        remote_addr = headers.first(name: "remoteAddress")!
    }
        
    logger[metadataKey: "remote-address"] = "\(remote_addr)"
}
```

However, the problem is that this means `Logger` needs to be mutable but Swift gRPC provider classes need to be "final" so that they can conform to the `Sendable` protocol.

To address this a `GRPCServerLogger` class is available that wraps an user-defined `Logging` instance, conforms to the `Logging` protocol and is marked as `@unchecked Sendable` to silence compiler errors.

_I thought I read that `swift-log` was made to play nice with Sendable but I can't get it to work so all of this may be a misunderstanding on my part. I would love to remove the `GRPCServerLogger` class entirely if possible._
 
Here's how you might use `GRPCServerLogger` in your code:

```
final class TextEmbosser: EmbosserAsyncProvider {
    let interceptors: EmbosserServerInterceptorFactoryProtocol?
    let logger: GRPCServerLogger
    
    init(logger: Logger) {
        self.logger = GRPCServerLogger(logger:logger)
        self.interceptors = TextEmbosserServerInterceptorFactory()
    }
    
    func embossText(request: EmbossTextRequest, context: GRPC.GRPCAsyncServerCallContext) async throws -> EmbossTextResponse {
        
        self.logger.setRemoteAddress(context: context)
        
        // The rest of your code here...
    }
}
```


    
## See also

* https://github.com/grpc/grpc-swift
* https://github.com/apple/swift-log
