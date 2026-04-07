#!/bin/bash
# =============================================================================
# Vowel Stack Build Script
# =============================================================================
# Builds client and core UI locally, then copies compiled assets to dist/
# for Docker deployment.
#
# Usage:
#   ./scripts/build.sh              # Full build
#   ./scripts/build.sh --skip-client # Skip client build (use existing)
#   ./scripts/build.sh --skip-ui     # Skip UI build (use existing)
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
SKIP_CLIENT=false
SKIP_UI=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --skip-client)
      SKIP_CLIENT=true
      shift
      ;;
    --skip-ui)
      SKIP_UI=true
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --skip-client    Skip client build (use existing dist)"
      echo "  --skip-ui       Skip UI build (use existing dist)"
      echo "  --help, -h      Show this help message"
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      exit 1
      ;;
  esac
done

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Vowel Stack Build Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${BLUE}Project root: $PROJECT_ROOT${NC}"
echo ""

# Create dist directory
DIST_DIR="$PROJECT_ROOT/dist"
mkdir -p "$DIST_DIR"

# =============================================================================
# Step 1: Build Client Library
# =============================================================================
if [ "$SKIP_CLIENT" = false ]; then
  echo -e "${YELLOW}→ Building client library...${NC}"
  cd "$PROJECT_ROOT/client"

  # Check if node_modules exists, if not install
  if [ ! -d "node_modules" ]; then
    echo -e "${BLUE}  Installing client dependencies...${NC}"
    bun install
  fi

  # Build the client library
  echo -e "${BLUE}  Running client build...${NC}"
  bun run build

  echo -e "${GREEN}✓ Client build complete${NC}"
else
  echo -e "${YELLOW}→ Skipping client build (using existing)${NC}"
fi

# Copy client dist to main dist folder
echo -e "${BLUE}  Copying client/dist to dist/client...${NC}"
rm -rf "$DIST_DIR/client"
cp -r "$PROJECT_ROOT/client/dist" "$DIST_DIR/client"
echo -e "${GREEN}✓ Client assets copied${NC}"
echo ""

# =============================================================================
# Step 2: Build Core UI
# =============================================================================
if [ "$SKIP_UI" = false ]; then
  echo -e "${YELLOW}→ Building core UI...${NC}"

  # First ensure client is linked/built since UI depends on it
  cd "$PROJECT_ROOT/core/ui"

  # Check if node_modules exists, if not install
  if [ ! -d "node_modules" ]; then
    echo -e "${BLUE}  Installing UI dependencies...${NC}"
    bun install
  fi

  # Build the UI
  echo -e "${BLUE}  Running UI build...${NC}"
  bun run build

  echo -e "${GREEN}✓ Core UI build complete${NC}"
else
  echo -e "${YELLOW}→ Skipping UI build (using existing)${NC}"
fi

# Copy UI dist to main dist folder
echo -e "${BLUE}  Copying core/ui/dist to dist/ui...${NC}"
rm -rf "$DIST_DIR/ui"
cp -r "$PROJECT_ROOT/core/ui/dist" "$DIST_DIR/ui"
echo -e "${GREEN}✓ UI assets copied${NC}"
echo ""

# =============================================================================
# Step 3: Copy Core Server Files
# =============================================================================
echo -e "${YELLOW}→ Copying core server files...${NC}"

# Copy core source files
echo -e "${BLUE}  Copying core/src to dist/src...${NC}"
rm -rf "$DIST_DIR/src"
cp -r "$PROJECT_ROOT/core/src" "$DIST_DIR/src"

# Copy core package files for production install
echo -e "${BLUE}  Copying package files...${NC}"
cp "$PROJECT_ROOT/core/package.json" "$DIST_DIR/"
if [ -f "$PROJECT_ROOT/core/bun.lock" ]; then
  cp "$PROJECT_ROOT/core/bun.lock" "$DIST_DIR/"
fi

echo -e "${GREEN}✓ Server files copied${NC}"
echo ""

# =============================================================================
# Build Summary
# =============================================================================
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Build Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Dist folder contents:${NC}"
echo "  dist/client/    - Client library assets"
echo "  dist/ui/        - Core UI assets"
echo "  dist/src/       - Server source code"
echo "  dist/package.json - Server package configuration"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Run 'docker compose build' to build the container"
echo "  2. Run 'docker compose up' to start the stack"
