FROM node:14

# Create app directory
WORKDIR /usr/src/app

# Copy app source
COPY . .

# Bind to port 3000
EXPOSE 3000

# Command to run the application
CMD [ "node", "app.js" ]
