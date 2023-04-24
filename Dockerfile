FROM node:16-alpine

WORKDIR /app
COPY package*.json ./
RUN npm install --force
COPY . .
RUN npm run build

# Define container health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget -q -O /dev/null http://localhost:80/ || exit 1

EXPOSE 80
CMD ["npm", "run", "start"]
