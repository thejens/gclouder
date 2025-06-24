#!/bin/bash

echo "🔍 GClouder Authentication Debug Test"
echo "======================================"

# Check if gcloud is installed
echo ""
echo "1. Checking if gcloud is installed..."
if ! command -v gcloud &> /dev/null; then
    echo "❌ ERROR: gcloud command not found!"
    echo "   Please install Google Cloud SDK first:"
    echo "   brew install google-cloud-sdk"
    exit 1
else
    echo "✅ gcloud found at: $(which gcloud)"
    echo "   Version: $(gcloud version --format='value(Google Cloud SDK)' 2>/dev/null || echo 'Unable to get version')"
fi

# Check current auth status
echo ""
echo "2. Checking current authentication status..."
echo "Running: gcloud auth application-default print-access-token"
if gcloud auth application-default print-access-token &>/dev/null; then
    echo "✅ Already authenticated - access token available"
    echo "   Account: $(gcloud config get-value account 2>/dev/null || echo 'Unknown')"
else
    echo "❌ Not authenticated - no valid access token"
fi

# Build the debug version
echo ""
echo "3. Building debug version of GClouder..."
if make dev > /dev/null 2>&1; then
    echo "✅ Debug build successful"
else
    echo "❌ Failed to build debug version"
    exit 1
fi

# Test the Swift app's authentication flow
echo ""
echo "4. Testing Swift app authentication flow..."
echo "Running GClouder authentication test..."
echo ""
echo "ℹ️  This will trigger the app's authentication flow directly."
echo "   Watch the console output below for debug information."
echo "   The browser should open automatically for authentication."
echo ""
echo "📊 Debug output:"
echo "---------------"

# Run the debug version with test flag - this will trigger authentication directly
.build/debug/gclouder --test-auth

echo ""
echo "🔍 Debug test complete!"

# Check final auth status
echo ""
echo "5. Checking final authentication status..."
if gcloud auth application-default print-access-token &>/dev/null; then
    echo "✅ Authentication successful - access token is now available"
    echo "   Account: $(gcloud config get-value account 2>/dev/null || echo 'Unknown')"
else
    echo "❌ Still not authenticated - authentication may have failed"
fi 