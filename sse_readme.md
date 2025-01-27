[Server-Sent Events](https://www.w3.org/TR/eventsource/) server/client for Crystal.

## Usage

### Client

```crystal
require "sse"

sse = HTTP::ServerSentEvents::EventSource.new("http://127.0.0.1:8080")

sse.on_message do |message|
  # Receiving messages from server
  p message.data
end

sse.run
```

### Server

```crystal
require "sse"

server = HTTP::Server.new [
  HTTP::ServerSentEvents::Handler.new { |es, _|
    es.source {
      # Delivering event data every 1 second.
      sleep 1
      HTTP::ServerSentEvents::EventMessage.new(
        data: ["foo", "bar"],
      )
    }
  },
]

server.bind_tcp "127.0.0.1", 8080
server.listen
```

Running server and you can get then:

```
$ curl 127.0.0.1:8080 -H "Accept: text/event-stream"

data: foo
data: bar

data: foo
data: bar

...

```