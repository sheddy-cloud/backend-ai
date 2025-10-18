# 🚀 AI Safari Backend

A production-ready Node.js backend for your AI-powered Safari Assistant app, featuring wildlife predictions, route recommendations, and accommodation suggestions.

## 🎯 Features

- **🦁 Wildlife Predictions API** - Real-time animal sighting probabilities
- **🗺️ Route Recommendations API** - Personalized safari itineraries
- **🏨 Accommodation API** - Smart lodging suggestions with filters
- **🧠 AI Recommendations Engine** - Personalized insights based on user preferences
- **🗄️ PostgreSQL Database** - Robust data storage with JSONB support
- **⚡ Redis Caching** - High-performance data caching
- **🔒 Security Features** - Helmet, CORS, rate limiting
- **🐳 Docker Ready** - Easy deployment with Docker Compose

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │    │   Backend API   │    │   PostgreSQL    │
│                 │◄──►│   (Node.js)     │◄──►│   Database      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │     Redis       │
                       │    Cache        │
                       └─────────────────┘
```

## 🚀 Quick Start

### Option 1: Docker (Recommended)

1. **Clone and navigate to backend directory**
   ```bash
   cd backend
   ```

2. **Start all services**
   ```bash
   docker-compose up -d
   ```

3. **Setup database**
   ```bash
   docker-compose exec backend npm run db:setup
   docker-compose exec backend npm run db:seed
   ```

4. **Test the API**
   ```bash
   curl http://localhost:3000/health
   ```

### Option 2: Local Development

1. **Install dependencies**
   ```bash
   npm install
   ```

2. **Setup PostgreSQL database**
   - Install PostgreSQL
   - Create database: `ai_safari_db`
   - Copy `env.example` to `.env` and update credentials

3. **Setup database tables**
   ```bash
   npm run db:setup
   npm run db:seed
   ```

4. **Start development server**
   ```bash
   npm run dev
   ```
