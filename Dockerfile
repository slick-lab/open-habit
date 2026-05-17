FROM alpine:3.19

WORKDIR /app

# Install Ruby and dependencies

RUN apk add --no-cache \
    ruby \
    ruby-bundler \
    postgresql-client \
    libc6-compat

# Install Ruby gems
RUN gem install telegem httparty

# Copy your pre-built Crystal binary
COPY server /app/server

# Copy Ruby bot code
COPY bot/ /app/bot/

# Make binary executable
RUN chmod +x /app/server

# Create start script
RUN echo '#!/bin/sh' > /app/start.sh && \
    echo '# Start Crystal server' >> /app/start.sh && \
    echo '/app/server &' >> /app/start.sh && \
    echo 'SERVER_PID=$!' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Wait for server to be ready' >> /app/start.sh && \
    echo 'sleep 3' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start Ruby bot' >> /app/start.sh && \
    echo 'ruby /app/bot/bot.rb' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Wait for both processes' >> /app/start.sh && \
    echo 'wait $SERVER_PID' >> /app/start.sh && \
    chmod +x /app/start.sh

EXPOSE 3000

CMD ["/app/start.sh"]
