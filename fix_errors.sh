#!/bin/bash
# Fix all Task.sleep references
sed -i '' 's/Task\.sleep/_Concurrency.Task.sleep/g' /Users/engammar/Apps/Mizan/MizanApp/Core/Services/PrayerTimeService.swift

# Fix HapticManager trigger calls
find /Users/engammar/Apps/Mizan/MizanApp -name "*.swift" -type f -exec sed -i '' 's/HapticManager\.shared\.trigger(\.light)/HapticManager.shared.trigger(.impact(.light))/g' {} \;
find /Users/engammar/Apps/Mizan/MizanApp -name "*.swift" -type f -exec sed -i '' 's/HapticManager\.shared\.trigger(\.medium)/HapticManager.shared.trigger(.impact(.medium))/g' {} \;
find /Users/engammar/Apps/Mizan/MizanApp -name "*.swift" -type f -exec sed -i '' 's/HapticManager\.shared\.trigger(\.heavy)/HapticManager.shared.trigger(.impact(.heavy))/g' {} \;
find /Users/engammar/Apps/Mizan/MizanApp -name "*.swift" -type f -exec sed -i '' 's/HapticManager\.shared\.trigger(\.success)/HapticManager.shared.trigger(.notification(.success))/g' {} \;
find /Users/engammar/Apps/Mizan/MizanApp -name "*.swift" -type f -exec sed -i '' 's/HapticManager\.shared\.trigger(\.warning)/HapticManager.shared.trigger(.notification(.warning))/g' {} \;
find /Users/engammar/Apps/Mizan/MizanApp -name "*.swift" -type f -exec sed -i '' 's/HapticManager\.shared\.trigger(\.error)/HapticManager.shared.trigger(.notification(.error))/g' {} \;

echo "Done"
