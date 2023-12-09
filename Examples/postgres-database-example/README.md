# Server with Postgres database for persistent storage

In this example we'll integrate persistent state into the server by adding an
integration to a database.

> **Disclaimer:** This example is deliberately simplified and is intended for illustrative purposes only.

## Overview

This example extends the [hello-world-vapor-server-example](../hello-world-vapor-server-example/)
with a trivial API to return the number of messages it has received.

For persistent state, it makes use of a local Postgres database to store the
messages and uses [PostgresNIO](https://github.com/vapor/postgres-nio) for the
database interaction.

The type that provides the API handlers has been converted to an actor and
a database connection is established in the initializer. The Postgres API
requires a logger for all queries so a logger property has also been added.
                
The server uses a table called `messages` to record the messages the server
responds with. This table is created if it does not already exist in the
initializer.

In the `getGreeting` handler, a row is inserted into the `messages` table
containing the message before returning a response.

This example also includes two other API operations: `getCount`, which returns
the number of messages the server has provided; and `reset`, which resets the
database.

## Testing

### Running a local database container

We need a database running locally to use in this exercise. We'll use
[Compose](https://docs.docker.com/compose) to run Postgres locally:

```console
% docker compose start
...
[+] Running 1/1
 ⠿ Container postgresdatabaseserver-postgres-1  Started            0.4s
```

### Testing the server

Run the server locally using the following command:

```console
% swift run
```

Then, in another terminal, make requests and see the database in action.

```console
% curl "localhost:8080/api/greet?name=Jane"
{
  "message" : "Hello, Jane!"
}


% curl "localhost:8080/api/greet?name=Jane"
{
  "message" : "Hello, Jane!"
}


% curl "localhost:8080/api/count"
{
  "count" : 2
}


% curl -X POST "localhost:8080/api/reset"


% curl "localhost:8080/api/count"
{
  "count" : 0
}
```

Try restarting the server after making some requests. The count should
be preserved because the state is persisted in the database.

### Shutting down the local database container

When finished, use this command to stop the database container:

```console
% docker compose stop
...
[+] Running 1/1
 ⠿ Container postgresdatabaseserver-postgres-1  Stopped            0.6s
```
