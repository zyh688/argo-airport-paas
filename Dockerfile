FROM alpine:latest
EXPOSE 3000
WORKDIR /app
# COPY . .
COPY web.js /app/web.js
COPY server.js /app/server.js
COPY package.json /app/package.json
COPY entrypoint.sh /app/entrypoint.sh

ENV TZ="Asia/Shanghai"
ENV NODE_ENV="production"

RUN apk update && \
    apk upgrade && \
    # Set timezone
    apk add --no-cache tzdata && \
    ln -sf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone &&\
    # Install dependencies
    apk add iproute2 coreutils curl unzip wget sudo supervisor openssh-server bash &&\
    # Install nodejs
    apk add nodejs npm &&\
    npm install -r package.json &&\
    npm install -g pm2 &&\
    # Clean up
    rm -rf /var/cache/apk/* &&\
    # Install cloudflared
    wget -nv -O cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 &&\
    mv cloudflared /usr/local/bin &&\
    # Install XrayR
    wget -nv -O /tmp/apps.zip https://github.com/XrayR-project/XrayR/releases/latest/download/XrayR-linux-64.zip && \
    mkdir /app/apps && \
    unzip -d /app/apps /tmp/apps.zip && \
    mv /app/apps/XrayR /app/apps/myapps && \
    rm -rf /app/apps/README.md && \
    rm -rf /app/apps/LICENSE && \
    rm -rf /app/apps/config.yml && \
    rm -f /tmp/apps.zip && \
    # Install Nezha agent
    wget -t 2 -T 10 -N https://github.com/nezhahq/agent/releases/latest/download/nezha-agent_linux_amd64.zip &&\
    unzip -qod ./ nezha-agent_linux_amd64.zip &&\
    rm -f nezha-agent_linux_amd64.zip &&\
    # Set permissions
    chmod +x /usr/local/bin/cloudflared &&\
    chmod +x /app/apps/myapps &&\
    chmod +x /app/nezha-agent &&\
    chmod +x /app/entrypoint.sh &&\
    chmod +x web.js &&\
    # Set root password and enable password login  
    echo 'root:password' | chpasswd &&\
    sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config &&\
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 启用 systemd init 系统
ENV init /lib/systemd/systemd
# 以 init 方式启动
ENTRYPOINT ["node", "server.js"]
