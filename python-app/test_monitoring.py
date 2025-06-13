#!/usr/bin/env python3
"""
Test script to verify CPU and memory monitoring functionality
"""
import requests
import time
import sys

def test_endpoints():
    """Test all endpoints to ensure they work correctly"""
    base_url = "http://localhost:5000"
    
    print("Testing dice roller with CPU/Memory monitoring...")
    print("=" * 50)
    
    try:
        # Test health endpoint
        print("1. Testing /health endpoint...")
        response = requests.get(f"{base_url}/health")
        print(f"   Status: {response.status_code}")
        print(f"   Response: {response.json()}")
        
        # Test metrics endpoint
        print("\n2. Testing /metrics endpoint...")
        response = requests.get(f"{base_url}/metrics")
        print(f"   Status: {response.status_code}")
        print(f"   Response: {response.json()}")
        
        # Test dice roll endpoint multiple times
        print("\n3. Testing /rolldice endpoint...")
        for i in range(5):
            response = requests.get(f"{base_url}/rolldice")
            print(f"   Roll {i+1}: {response.text.strip()}")
            time.sleep(1)
        
        # Check metrics again after some activity
        print("\n4. Checking metrics after dice rolls...")
        response = requests.get(f"{base_url}/metrics")
        print(f"   Updated metrics: {response.json()}")
        
        print("\n✅ All tests passed! CPU and memory monitoring is working.")
        
    except requests.exceptions.ConnectionError:
        print("❌ Error: Could not connect to the application.")
        print("   Make sure the Flask app is running on http://localhost:5000")
        return False
    except Exception as e:
        print(f"❌ Error during testing: {e}")
        return False
    
    return True

if __name__ == "__main__":
    print("Make sure to start the Flask application first with:")
    print("python app.py")
    print("\nThen run this test script.")
    input("\nPress Enter to continue with testing...")
    
    if test_endpoints():
        print("\n🎉 All functionality is working correctly!")
    else:
        print("\n❌ Some tests failed. Check the application logs.")
        sys.exit(1)
