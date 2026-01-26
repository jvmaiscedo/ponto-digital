FROM hexpm/elixir:1.17.3-erlang-27.1.2-alpine-3.20.3 AS builder

RUN apk add --no-cache build-base git python3 curl

WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

COPY config/ config/
COPY lib/ lib/
COPY priv/ priv/
COPY assets/ assets/

RUN mix compile
RUN mix assets.deploy
RUN mix release

FROM alpine:3.20.3 AS runner

RUN apk add --no-cache libstdc++ openssl ncurses-libs curl tar xz

WORKDIR /app

RUN curl -fL -o typst.tar.xz https://github.com/typst/typst/releases/download/v0.11.0/typst-x86_64-unknown-linux-musl.tar.xz \
    && tar -xf typst.tar.xz \
    && mv typst-x86_64-unknown-linux-musl/typst /usr/local/bin/ \
    && chmod +x /usr/local/bin/typst \
    && rm -rf typst.tar.xz typst-x86_64-unknown-linux-musl

COPY --from=builder /app/_build/prod/rel/pontodigital ./

ENV HOME=/app
ENV MIX_ENV=prod

EXPOSE 4000

CMD ["bin/pontodigital", "start"]