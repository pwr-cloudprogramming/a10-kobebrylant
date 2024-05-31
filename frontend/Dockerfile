FROM node:lts

WORKDIR /app

COPY ./source/package*.json ./

RUN npm install

COPY ./source .

EXPOSE 8081

CMD ["npm", "run", "serve", "--host"]

