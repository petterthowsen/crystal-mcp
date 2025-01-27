# Versioning

The Model Context Protocol uses string-based version identifiers following the format `YYYY-MM-DD`, to indicate the last date backwards incompatible changes were made.

The current protocol version is `2024-11-05`.

Important versioning rules:
- The protocol version will not be incremented when the protocol is updated, as long as the changes maintain backwards compatibility.
- Version negotiation happens during initialization.
- Clients and servers MAY support multiple protocol versions simultaneously, but they MUST agree on a single version to use for the session.
- The protocol provides appropriate error handling if version negotiation fails, allowing clients to gracefully terminate connections when they cannot find a version compatible with the server.
