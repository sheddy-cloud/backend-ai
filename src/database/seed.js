const { query } = require('./config');

const seedData = async () => {
  try {
    console.log('🌱 Seeding database with initial data...');

    // Insert parks
    const parks = [
      {
        park_id: 'serengeti',
        name: 'Serengeti National Park',
        description: 'Famous for the annual migration of over 1.5 million wildebeest and 250,000 zebras',
        location_lat: -2.3333,
        location_lng: 34.8333,
        image_url: 'assets/zebramorn.jpg'
      },
      {
        park_id: 'manyara',
        name: 'Lake Manyara National Park',
        description: 'Known for tree-climbing lions and diverse birdlife',
        location_lat: -3.5000,
        location_lng: 35.8333,
        image_url: 'assets/lionontree.jpg'
      },
      {
        park_id: 'mikumi',
        name: 'Mikumi National Park',
        description: 'Fourth largest national park in Tanzania with diverse wildlife',
        location_lat: -7.1167,
        location_lng: 37.0833,
        image_url: 'assets/chetahcool.jpg'
      },
      {
        park_id: 'gombe',
        name: 'Gombe Stream National Park',
        description: 'Famous for chimpanzee research and forest wildlife',
        location_lat: -4.6667,
        location_lng: 29.6333,
        image_url: 'assets/apesfamily.jpg'
      }
    ];

    for (const park of parks) {
      await query(`
        INSERT INTO parks (park_id, name, description, location_lat, location_lng, image_url)
        VALUES ($1, $2, $3, $4, $5, $6)
        ON CONFLICT (park_id) DO UPDATE SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        location_lat = EXCLUDED.location_lat,
        location_lng = EXCLUDED.location_lng,
        image_url = EXCLUDED.image_url
      `, [park.park_id, park.name, park.description, park.location_lat, park.location_lng, park.image_url]);
    }

    console.log('✅ Parks data seeded successfully!');

    // Insert wildlife predictions
    const wildlifeData = [
      // Serengeti
      { park_id: 'serengeti', animal_type: 'lions', probability: 0.85, optimal_time: '06:00 - 09:00', best_location: 'Central Serengeti Plains', confidence: 0.92, tips: 'Best viewed during early morning game drives' },
      { park_id: 'serengeti', animal_type: 'elephants', probability: 0.78, optimal_time: '15:00 - 18:00', best_location: 'Seronera River Valley', confidence: 0.88, tips: 'Look near water sources in the afternoon' },
      { park_id: 'serengeti', animal_type: 'wildebeest', probability: 0.95, optimal_time: 'All day', best_location: 'Migration routes (seasonal)', confidence: 0.98, tips: 'Migration peaks from July to October' },
      { park_id: 'serengeti', animal_type: 'cheetahs', probability: 0.65, optimal_time: '08:00 - 11:00', best_location: 'Eastern Plains', confidence: 0.75, tips: 'Active during cooler morning hours' },
      
      // Manyara
      { park_id: 'manyara', animal_type: 'tree_lions', probability: 0.70, optimal_time: '14:00 - 17:00', best_location: 'Lake Manyara shores', confidence: 0.80, tips: 'Unique tree-climbing behavior in this park' },
      { park_id: 'manyara', animal_type: 'elephants', probability: 0.90, optimal_time: '06:00 - 09:00', best_location: 'Lake Manyara shores', confidence: 0.95, tips: 'Excellent elephant viewing year-round' },
      { park_id: 'manyara', animal_type: 'flamingos', probability: 0.85, optimal_time: 'All day', best_location: 'Lake Manyara', confidence: 0.90, tips: 'Best during dry season (June-October)' },
      
      // Mikumi
      { park_id: 'mikumi', animal_type: 'elephants', probability: 0.88, optimal_time: '06:00 - 09:00', best_location: 'Mkata Plains', confidence: 0.92, tips: 'Large herds frequently seen on the plains' },
      { park_id: 'mikumi', animal_type: 'zebras', probability: 0.95, optimal_time: 'All day', best_location: 'Mkata Plains', confidence: 0.98, tips: 'Abundant throughout the park' },
      { park_id: 'mikumi', animal_type: 'wildebeest', probability: 0.82, optimal_time: 'All day', best_location: 'Mkata Plains', confidence: 0.88, tips: 'Often seen grazing with zebras' },
      
      // Gombe
      { park_id: 'gombe', animal_type: 'chimpanzees', probability: 0.75, optimal_time: '06:00 - 10:00', best_location: 'Forest trails', confidence: 0.85, tips: 'Requires guided forest walks' },
      { park_id: 'gombe', animal_type: 'monkeys', probability: 0.90, optimal_time: 'All day', best_location: 'Forest canopy', confidence: 0.95, tips: 'Multiple species visible throughout the day' },
      { park_id: 'gombe', animal_type: 'birds', probability: 0.85, optimal_time: '06:00 - 09:00', best_location: 'Forest edges', confidence: 0.90, tips: 'Over 200 bird species recorded' }
    ];

    for (const wildlife of wildlifeData) {
      await query(`
        INSERT INTO wildlife_predictions (park_id, animal_type, probability, optimal_time, best_location, confidence, tips)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        ON CONFLICT DO NOTHING
      `, [wildlife.park_id, wildlife.animal_type, wildlife.probability, wildlife.optimal_time, wildlife.best_location, wildlife.confidence, wildlife.tips]);
    }

    console.log('✅ Wildlife predictions data seeded successfully!');

    // Insert safari routes
    const routesData = [
      {
        route_id: 'route_1',
        name: 'Classic Northern Circuit',
        description: 'Experience the best of Tanzania\'s northern parks including the Great Migration',
        duration: '7 days',
        difficulty: 'Easy',
        best_time: 'June - October',
        estimated_cost: '$2,500 - $4,000',
        transportation: '4x4 Safari Vehicle',
        accommodation_type: 'Luxury Lodges & Tented Camps',
        score: 9.2,
        highlights: ['Great Migration viewing', 'Tree-climbing lions', 'Elephant herds', 'Bird watching'],
        parks_included: ['serengeti', 'manyara', 'tarangire']
      },
      {
        route_id: 'route_2',
        name: 'Wildlife Photography Special',
        description: 'Perfect for photographers seeking the best wildlife shots',
        duration: '10 days',
        difficulty: 'Moderate',
        best_time: 'Year-round',
        estimated_cost: '$3,000 - $5,000',
        transportation: 'Private 4x4 with Photography Setup',
        accommodation_type: 'Photography-focused Lodges',
        score: 9.5,
        highlights: ['Professional photography opportunities', 'Diverse wildlife species', 'Scenic landscapes', 'Cultural experiences'],
        parks_included: ['serengeti', 'manyara', 'mikumi']
      },
      {
        route_id: 'route_3',
        name: 'Chimpanzee & Wildlife Adventure',
        description: 'Combine primate tracking with traditional safari experiences',
        duration: '8 days',
        difficulty: 'Moderate',
        best_time: 'May - October',
        estimated_cost: '$2,800 - $4,200',
        transportation: '4x4 Vehicle & Boat',
        accommodation_type: 'Forest Lodges & Lake View Hotels',
        score: 8.8,
        highlights: ['Chimpanzee tracking', 'Forest exploration', 'Lake Manyara wildlife', 'Bird watching'],
        parks_included: ['gombe', 'mikumi', 'manyara']
      }
    ];

    for (const route of routesData) {
      await query(`
        INSERT INTO safari_routes (route_id, name, description, duration, difficulty, best_time, estimated_cost, transportation, accommodation_type, score, highlights, parks_included)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
        ON CONFLICT (route_id) DO UPDATE SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        duration = EXCLUDED.duration,
        difficulty = EXCLUDED.difficulty,
        best_time = EXCLUDED.best_time,
        estimated_cost = EXCLUDED.estimated_cost,
        transportation = EXCLUDED.transportation,
        accommodation_type = EXCLUDED.accommodation_type,
        score = EXCLUDED.score,
        highlights = EXCLUDED.highlights,
        parks_included = EXCLUDED.parks_included
      `, [route.route_id, route.name, route.description, route.duration, route.difficulty, route.best_time, route.estimated_cost, route.transportation, route.accommodation_type, route.score, JSON.stringify(route.highlights), JSON.stringify(route.parks_included)]);
    }

    console.log('✅ Safari routes data seeded successfully!');

    // Insert accommodations
    const accommodationsData = [
      {
        accommodation_id: 'serengeti_1',
        park_id: 'serengeti',
        name: 'Serengeti Serena Safari Lodge',
        type: 'Luxury Lodge',
        rating: 4.8,
        price: '$450/night',
        amenities: ['Pool', 'Spa', 'Restaurant', 'WiFi', 'Game Drives'],
        location: 'Central Serengeti',
        wildlife_viewing: 'Excellent',
        photography_rating: 'Outstanding',
        family_friendly: true,
        score: 9.3,
        image_url: 'assets/refresh/coolbed.jpg'
      },
      {
        accommodation_id: 'serengeti_2',
        park_id: 'serengeti',
        name: 'Four Seasons Safari Lodge',
        type: 'Ultra Luxury',
        rating: 4.9,
        price: '$800/night',
        amenities: ['Infinity Pool', 'Spa', 'Fine Dining', 'Private Game Drives', 'Helicopter Tours'],
        location: 'Central Serengeti',
        wildlife_viewing: 'Exceptional',
        photography_rating: 'Exceptional',
        family_friendly: true,
        score: 9.7,
        image_url: 'assets/refresh/room.jpg'
      },
      {
        accommodation_id: 'manyara_1',
        park_id: 'manyara',
        name: 'Lake Manyara Tree Lodge',
        type: 'Tree House Lodge',
        rating: 4.6,
        price: '$350/night',
        amenities: ['Tree House Views', 'Restaurant', 'Game Drives', 'Bird Watching'],
        location: 'Lake Manyara Shore',
        wildlife_viewing: 'Very Good',
        photography_rating: 'Excellent',
        family_friendly: true,
        score: 8.9,
        image_url: 'assets/refresh/coolbed.jpg'
      },
      {
        accommodation_id: 'mikumi_1',
        park_id: 'mikumi',
        name: 'Mikumi Wildlife Camp',
        type: 'Mid-Range Camp',
        rating: 4.4,
        price: '$200/night',
        amenities: ['Tented Camp', 'Restaurant', 'Game Drives', 'Campfire'],
        location: 'Mkata Plains',
        wildlife_viewing: 'Good',
        photography_rating: 'Good',
        family_friendly: true,
        score: 8.2,
        image_url: 'assets/refresh/tourlook.jpg'
      },
      {
        accommodation_id: 'gombe_1',
        park_id: 'gombe',
        name: 'Gombe Forest Lodge',
        type: 'Forest Lodge',
        rating: 4.5,
        price: '$280/night',
        amenities: ['Forest Views', 'Chimpanzee Tracking', 'Forest Walks', 'Restaurant'],
        location: 'Gombe Forest',
        wildlife_viewing: 'Excellent for Primates',
        photography_rating: 'Very Good',
        family_friendly: false,
        score: 8.7,
        image_url: 'assets/refresh/coolbed.jpg'
      }
    ];

    for (const accommodation of accommodationsData) {
      await query(`
        INSERT INTO accommodations (accommodation_id, park_id, name, type, rating, price, amenities, location, wildlife_viewing, photography_rating, family_friendly, score, image_url)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
        ON CONFLICT (accommodation_id) DO UPDATE SET
        name = EXCLUDED.name,
        type = EXCLUDED.type,
        rating = EXCLUDED.rating,
        price = EXCLUDED.price,
        amenities = EXCLUDED.amenities,
        location = EXCLUDED.location,
        wildlife_viewing = EXCLUDED.wildlife_viewing,
        photography_rating = EXCLUDED.photography_rating,
        family_friendly = EXCLUDED.family_friendly,
        score = EXCLUDED.score,
        image_url = EXCLUDED.image_url
      `, [accommodation.accommodation_id, accommodation.park_id, accommodation.name, accommodation.type, accommodation.rating, accommodation.price, JSON.stringify(accommodation.amenities), accommodation.location, accommodation.wildlife_viewing, accommodation.photography_rating, accommodation.family_friendly, accommodation.score, accommodation.image_url]);
    }

    console.log('✅ Accommodations data seeded successfully!');

    console.log('🎉 Database seeding completed successfully!');

  } catch (error) {
    console.error('❌ Error seeding database:', error);
    throw error;
  }
};

// Run seeding if this file is executed directly
if (require.main === module) {
  seedData()
    .then(() => {
      console.log('🎉 Database seeding completed successfully!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('💥 Database seeding failed:', error);
      process.exit(1);
    });
}

module.exports = {
  seedData
};

