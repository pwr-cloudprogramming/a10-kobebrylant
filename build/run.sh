#!/bin/bash
echo "This script should start your application"
cd backend/src
python3 app.py

cd ../../frontend/source
vue serve