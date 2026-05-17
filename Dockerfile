FROM alpine:3.19

WORKDIR /app


# Copy  pre-built Crystal binary
COPY server /app/server


# Make binary executable
RUN chmod +x /app/server

# Create start script

EXPOSE 3000

CMD ["/app/server"]
