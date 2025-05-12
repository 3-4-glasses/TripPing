# Use a Node.js base image
FROM node:16-alpine

# Set working directory
WORKDIR /app

# Copy only package files first for caching
COPY package*.json ./

# Install dependencies
RUN npm install

# Now copy everything (including config/)
COPY . .

# Copy the Firebase service account key into the container
COPY ./config/tripping-51afb-firebase-adminsdk-fbsvc-45136d5a44.json /app/config/tripping-51afb-firebase-adminsdk-fbsvc-45136d5a44.json



# Build TypeScript
RUN npm run build

# Expose port and run the app
EXPOSE 8080
CMD ["npm", "start"]

