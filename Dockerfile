FROM node:20

WORKDIR /app

RUN apt-get update && \
    apt-get install -y python3 python3-pip && \
    pip3 install boto3 && \
    rm -rf /var/lib/apt/lists/*

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 3000

CMD ["node", "app.js"]