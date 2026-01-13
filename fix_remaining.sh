#!/bin/bash
cd /Users/engammar/Apps/Mizan

# Fix taskNotifications.first to taskNotifications.notifications.first
sed -i '' 's/taskNotifications\.first/taskNotifications.notifications.first/g' MizanApp/Core/Services/NotificationManager.swift

# Fix NotificationManager init
sed -i '' 's/private init() {/override private init() {/g' MizanApp/Core/Services/NotificationManager.swift

# Fix PrayerTimeService Predicate issues by using computed properties
# These need manual fixes - marking for now

echo "Batch fixes applied"
