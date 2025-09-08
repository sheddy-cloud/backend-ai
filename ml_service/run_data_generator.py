#!/usr/bin/env python3
"""
Simple script to run the synthetic data generator
"""

import sys
from pathlib import Path

# Add the scripts directory to the path
sys.path.append(str(Path(__file__).parent / "scripts"))

try:
    from generate_synthetic_data import SyntheticDataGenerator
    
    print("🚀 AI Safari ML Service - Synthetic Data Generator")
    print("=" * 50)
    
    # Create generator and run
    generator = SyntheticDataGenerator()
    generator.generate_all_data()
    
    print("\n🎯 Next steps:")
    print("1. The ML service will use this synthetic data for training")
    print("2. Replace with real datasets in production")
    print("3. Run the ML service to test predictions")
    
except ImportError as e:
    print(f"❌ Import error: {e}")
    print("Make sure you're running this from the ml_service directory")
except Exception as e:
    print(f"❌ Error: {e}")
    sys.exit(1)
