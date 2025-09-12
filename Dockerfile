FROM node:18-alpine

#? Set working directory
WORKDIR /app 

#? COPY package files to get the lib
COPY 2048-in-react/package*.json ./

#? Install all dependencies needed
RUN npm install

#? Copy the rest of the app into the contianer
COPY 2048-in-react/ ./

RUN npm run build 
EXPOSE 3000 
ENTRYPOINT ["npm", "run", "dev"]
