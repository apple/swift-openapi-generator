FROM swift:5.9 AS builder
COPY ../Sources/ /code/Sources/
COPY ../Package.swift /code/Package.swift
WORKDIR /code
RUN swift build -c release

FROM swift:5.9-slim AS runtime
COPY --from=builder /code/.build/release/HelloWorldVaporServer /HelloWorldVaporServer
ENV HOST=0.0.0.0
ENV PORT=8080
ENTRYPOINT [ "/HelloWorldVaporServer" ]
