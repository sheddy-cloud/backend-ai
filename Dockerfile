# Use Node.js 18 Alpine for smaller image
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files first
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Ensure logs directory exists
RUN mkdir -p logs

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S napasa -u 1001

# Change ownership of the app directory
RUN chown -R napasa:nodejs /app

# Switch to non-root user
USER napasa

# Expose the port your app listens on
EXPOSE 3000

# Start the app
CMD ["npm", "start"]
