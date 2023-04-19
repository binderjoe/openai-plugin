#!/bin/sh
set -e

./hostconfig.sh

# Heroku uses PORT, Azure App Services uses WEBSITES_PORT, Fly.io uses 8080 by default
exec uvicorn server.main:app --host 0.0.0.0 --port "${PORT:-${WEBSITES_PORT:-8080}}"
#/bin/sh