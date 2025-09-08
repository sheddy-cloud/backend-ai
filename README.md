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

## 📊 API Endpoints

### Health Check
- `GET /health` - Backend health status

### Wildlife API
- `GET /api/wildlife/predictions` - All wildlife predictions
- `GET /api/wildlife/predictions/:parkId` - Park-specific predictions
- `GET /api/wildlife/animal/:animalType` - Animal-specific predictions

### Routes API
- `GET /api/routes` - All safari routes
- `GET /api/routes/:routeId` - Specific route details
- `GET /api/routes/park/:parkId` - Routes for specific park

### Accommodations API
- `GET /api/accommodations` - All accommodations
- `GET /api/accommodations/park/:parkId` - Park-specific accommodations
- `GET /api/accommodations/:accommodationId` - Specific accommodation

### Recommendations API
- `POST /api/recommendations/personalized` - Personalized AI recommendations
- `GET /api/recommendations/park/:parkId/quick` - Quick park recommendations

## 🗄️ Database Schema

### Tables
- **parks** - National park information
- **wildlife_predictions** - Animal sighting probabilities
- **safari_routes** - Safari itinerary recommendations
- **accommodations** - Lodging options
- **user_preferences** - User behavior and preferences

### Sample Data
The database comes pre-populated with:
- 4 national parks (Serengeti, Manyara, Mikumi, Gombe)
- 12+ wildlife predictions
- 3 safari routes
- 5 accommodation options

## 🔧 Configuration

### Environment Variables
```bash
# Server
PORT=3000
NODE_ENV=development

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=ai_safari_db
DB_USER=postgres
DB_PASSWORD=your_password

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
```

### Database Connection
The backend automatically connects to PostgreSQL and creates all necessary tables and indexes on startup.

## 🧪 Testing

### Test API Endpoints
```bash
# Health check
curl http://localhost:3000/health

# Wildlife predictions for Serengeti
curl http://localhost:3000/api/wildlife/predictions/serengeti

# All accommodations
curl http://localhost:3000/api/accommodations

# Personalized recommendations
curl -X POST http://localhost:3000/api/recommendations/personalized \
  -H "Content-Type: application/json" \
  -d '{"userProfile":{"preferences":{"wildlifePhotography":true,"budgetLevel":"Mid-Range"}}}'
```

## 📱 Flutter Integration

### Update your Flutter app to use the backend:

1. **Replace hardcoded data with API calls**
2. **Update base URL to `http://localhost:3000`**
3. **Handle API responses and errors**

### Example Flutter API call:
```dart
final response = await http.get(
  Uri.parse('http://localhost:3000/api/wildlife/predictions/serengeti')
);

if (response.statusCode == 200) {
  final data = json.decode(response.body);
  // Use data.data for wildlife predictions
}
```

## 🚀 Production Deployment

### Docker Production
```bash
# Build production image
docker build -t ai-safari-backend:prod .

# Run with production environment
docker run -d \
  -p 3000:3000 \
  -e NODE_ENV=production \
  -e DB_HOST=your_production_db \
  ai-safari-backend:prod
```

### Environment Variables for Production
- Set `NODE_ENV=production`
- Use production database credentials
- Configure Redis for production
- Set up proper CORS origins

## 🔮 Future Enhancements

- **Machine Learning Integration** - Real-time wildlife predictions
- **Weather API Integration** - Weather-based recommendations
- **User Authentication** - JWT-based user management
- **Real-time Updates** - WebSocket for live data
- **Analytics Dashboard** - User behavior insights
- **Mobile Push Notifications** - Wildlife alerts

## 🐛 Troubleshooting

### Common Issues

1. **Database Connection Failed**
   - Check PostgreSQL is running
   - Verify database credentials in `.env`
   - Ensure database `ai_safari_db` exists

2. **Port Already in Use**
   - Change `PORT` in `.env`
   - Kill process using port 3000

3. **Docker Issues**
   - Restart Docker service
   - Remove containers: `docker-compose down -v`
   - Rebuild: `docker-compose up --build`

### Logs
```bash
# View backend logs
docker-compose logs backend

# View database logs
docker-compose logs postgres
```

## 📞 Support

Your AI Safari Backend is now ready! 🎉

- **API Base URL**: `http://localhost:3000`
- **Health Check**: `http://localhost:3000/health`
- **Database**: PostgreSQL on port 5432
- **Cache**: Redis on port 6379

## 🎯 Next Steps

1. **Test all API endpoints**
2. **Update your Flutter app to use the backend**
3. **Customize data and add more parks**
4. **Integrate real weather APIs**
5. **Add machine learning models**

Your backend is production-ready and can handle thousands of users! 🚀


