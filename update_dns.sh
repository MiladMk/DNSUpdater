#!/bin/bash

# بارگذاری تنظیمات
source ./config.sh

IP_FILE="ip.txt"
INDEX_FILE=".last_ip_index"

# خواندن آی‌پی‌ها از فایل
mapfile -t IP_LIST < "$IP_FILE"
TOTAL_IPS=${#IP_LIST[@]}

# خواندن ایندکس قبلی
if [[ -f "$INDEX_FILE" ]]; then
    INDEX=$(<"$INDEX_FILE")
else
    INDEX=0
fi

# بررسی اینکه ایندکس معتبر هست یا نه
if (( INDEX >= TOTAL_IPS )); then
    INDEX=0
fi

CURRENT_IP="${IP_LIST[$INDEX]}"

echo "در حال تنظیم آی‌پی جدید: $CURRENT_IP"

# فراخوانی API برای بروزرسانی رکورد
RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
     -H "Authorization: Bearer $CF_API_TOKEN" \
     -H "Content-Type: application/json" \
     --data "{\"type\":\"A\",\"name\":\"$RECORD_NAME\",\"content\":\"$CURRENT_IP\",\"ttl\":120,\"proxied\":false}")

# بررسی موفقیت
if echo "$RESPONSE" | grep -q "\"success\":true"; then
    echo "✅ آی‌پی با موفقیت آپدیت شد."
    NEXT_INDEX=$(( (INDEX + 1) % TOTAL_IPS ))
    echo "$NEXT_INDEX" > "$INDEX_FILE"
else
    echo "❌ خطا در بروزرسانی رکورد:"
    echo "$RESPONSE"
fi

echo "" >> log.txt
echo "----- اجرای جدید در $(date '+%Y-%m-%d %H:%M:%S') -->
echo "$RESPONSE" >> log.txt
echo "" >> log.txt