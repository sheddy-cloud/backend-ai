#!/usr/bin/env python3
"""
Simple test script for the AI Safari ML Prediction Engine
Run this to verify the service is working correctly
"""

import asyncio
import aiohttp
import json
from datetime import datetime

# Service configuration
BASE_URL = "http://localhost:8000"

async def test_health_check():
    """Test the health check endpoint"""
    print("🏥 Testing health check...")
    
    async with aiohttp.ClientSession() as session:
        try:
            async with session.get(f"{BASE_URL}/health") as response:
                if response.status == 200:
                    data = await response.json()
                    print(f"✅ Health check passed: {data['status']}")
                    return True
                else:
                    print(f"❌ Health check failed: {response.status}")
                    return False
        except Exception as e:
            print(f"❌ Health check error: {e}")
            return False

async def test_wildlife_prediction():
    """Test the wildlife prediction endpoint"""
    print("\n🦁 Testing wildlife prediction...")
    
    prediction_request = {
        "park_id": "serengeti",
        "time_of_day": "early_morning",
        "season": "dry",
        "user_preferences": {
            "wildlife_photography": True,
            "budget_level": "Mid-Range"
        },
        "include_weather": True
    }
    
    async with aiohttp.ClientSession() as session:
        try:
            async with session.post(
                f"{BASE_URL}/predict/wildlife",
                json=prediction_request
            ) as response:
                if response.status == 200:
                    data = await response.json()
                    print(f"✅ Prediction successful for {data['park_id']}")
                    print(f"   Confidence score: {data['confidence_score']:.3f}")
                    print(f"   Animals predicted: {len(data['predictions'])}")
                    print(f"   Weather: {data['weather_data']['condition']} at {data['weather_data']['temperature']}°C")
                    return True
                else:
                    error_text = await response.text()
                    print(f"❌ Prediction failed: {response.status} - {error_text}")
                    return False
        except Exception as e:
            print(f"❌ Prediction error: {e}")
            return False

async def test_realtime_predictions():
    """Test the real-time predictions endpoint"""
    print("\n📡 Testing real-time predictions...")
    
    async with aiohttp.ClientSession() as session:
        try:
            async with session.get(f"{BASE_URL}/predictions/serengeti/realtime") as response:
                if response.status == 200:
                    data = await response.json()
                    print(f"✅ Real-time predictions retrieved for {data['park_id']}")
                    print(f"   Last updated: {data['last_updated']}")
                    return True
                else:
                    error_text = await response.text()
                    print(f"❌ Real-time predictions failed: {response.status} - {error_text}")
                    return False
        except Exception as e:
            print(f"❌ Real-time predictions error: {e}")
            return False

async def test_weather_sync():
    """Test the weather sync endpoint"""
    print("\n🌤️ Testing weather sync...")
    
    async with aiohttp.ClientSession() as session:
        try:
            async with session.post(f"{BASE_URL}/sync/weather") as response:
                if response.status == 200:
                    data = await response.json()
                    print(f"✅ Weather sync started: {data['message']}")
                    return True
                else:
                    error_text = await response.text()
                    print(f"❌ Weather sync failed: {response.status} - {error_text}")
                    return False
        except Exception as e:
            print(f"❌ Weather sync error: {e}")
            return False

async def test_predictions_sync():
    """Test the predictions sync endpoint"""
    print("\n🔄 Testing predictions sync...")
    
    async with aiohttp.ClientSession() as session:
        try:
            async with session.post(f"{BASE_URL}/sync/predictions") as response:
                if response.status == 200:
                    data = await response.json()
                    print(f"✅ Predictions sync started: {data['message']}")
                    return True
                else:
                    error_text = await response.text()
                    print(f"❌ Predictions sync failed: {response.status} - {error_text}")
                    return False
        except Exception as e:
            print(f"❌ Predictions sync error: {e}")
            return False

async def run_all_tests():
    """Run all tests and provide summary"""
    print("🚀 Starting AI Safari ML Service Tests...")
    print("=" * 50)
    
    tests = [
        ("Health Check", test_health_check),
        ("Wildlife Prediction", test_wildlife_prediction),
        ("Real-time Predictions", test_realtime_predictions),
        ("Weather Sync", test_weather_sync),
        ("Predictions Sync", test_predictions_sync)
    ]
    
    results = []
    
    for test_name, test_func in tests:
        try:
            result = await test_func()
            results.append((test_name, result))
        except Exception as e:
            print(f"❌ {test_name} test crashed: {e}")
            results.append((test_name, False))
    
    # Print summary
    print("\n" + "=" * 50)
    print("📊 Test Results Summary:")
    print("=" * 50)
    
    passed = 0
    total = len(results)
    
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status} - {test_name}")
        if result:
            passed += 1
    
    print(f"\n🎯 Overall: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed! ML Service is working correctly.")
    else:
        print("⚠️  Some tests failed. Check the service logs for details.")
    
    return passed == total

def main():
    """Main function to run tests"""
    try:
        # Run async tests
        success = asyncio.run(run_all_tests())
        
        if success:
            print("\n🚀 ML Service is ready for production!")
        else:
            print("\n🔧 Please fix the failing tests before proceeding.")
            
    except KeyboardInterrupt:
        print("\n⏹️  Tests interrupted by user")
    except Exception as e:
        print(f"\n💥 Test runner crashed: {e}")

if __name__ == "__main__":
    main()
