# NextBikes XML Scraper

## Quick Setup

1. Configure `.env` file:
```
TARGET_URL=https://iframe.nextbike.net/maps/nextbike-live.xml?&city=532&domains=bo
INTERVAL_SECONDS=10
FILE_NAME=nextbikes_bilbao
```

2. Start Docker:
```bash
docker-compose up -d
```

## Compression Tools

Make executable:
```bash
chmod +x compress.sh scripts/*.sh
```

Usage:
```bash
./compress.sh install    # Set up daily compression (1:00 AM)
./compress.sh compress   # Compress yesterday's folder
./compress.sh compress 15-06-2023  # Compress specific date
```

## Data Structure
```
data/
└── nextbikes-DD-MM-YYYY/
    └── nextbikes_bilbao_TIMESTAMP.xml
```

Logs: `data/compression_log.txt` 