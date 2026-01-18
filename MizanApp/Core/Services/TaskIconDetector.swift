//
//  TaskIconDetector.swift
//  Mizan
//
//  Intelligent icon detection from task title using keyword matching
//

import Foundation

/// Detects appropriate SF Symbol icons based on task title keywords
final class TaskIconDetector {

    static let shared = TaskIconDetector()

    private init() {}

    // MARK: - Icon Mapping Structure

    private struct IconMapping {
        let icon: String
        let keywords: Set<String>
        let substrings: Set<String> // For contains-based matching
    }

    // MARK: - Icon Mappings

    private let mappings: [IconMapping] = [
        // Study / Reading / Learning
        IconMapping(
            icon: "book.fill",
            keywords: [
                // English
                "study", "read", "book", "learn", "homework", "revision", "exam",
                "test", "lecture", "class", "course", "lesson", "tutorial",
                "research", "library", "essay", "paper", "thesis", "assignment",
                // Arabic full words
                "مذاكرة", "مذاكره", "دراسة", "دراسه", "قراءة", "قراءه", "حفظ",
                "كتاب", "تعلم", "درس", "محاضرة", "امتحان", "اختبار", "مراجعة",
                "واجب", "فصل", "ورد", "قرآن", "بحث", "مكتبة"
            ],
            substrings: [
                "مذاكر", "دراس", "قرا", "حفظ", "تعل", "درس", "كتاب",
                "study", "read", "learn", "book", "exam"
            ]
        ),

        // Exercise / Walking / Sports
        IconMapping(
            icon: "figure.walk",
            keywords: [
                "walk", "run", "jog", "exercise", "workout", "gym", "fitness",
                "sport", "training", "cardio", "hiking", "swimming", "cycling",
                "yoga", "stretch", "marathon", "steps",
                "مشي", "جري", "رياضة", "تمارين", "نادي", "لياقة", "تدريب",
                "سباحة", "دراجة", "يوغا", "تمدد", "خطوات"
            ],
            substrings: [
                "مشي", "جري", "رياض", "تمار", "نادي", "تدريب",
                "walk", "run", "jog", "gym", "workout", "exercise"
            ]
        ),

        // Sleep / Rest
        IconMapping(
            icon: "moon.fill",
            keywords: [
                "sleep", "nap", "rest", "bed", "night", "slumber", "snooze",
                "نوم", "نومة", "راحة", "سرير", "قيلولة", "استرخاء", "ليل"
            ],
            substrings: [
                "نوم", "راح", "سرير", "قيلول",
                "sleep", "nap", "rest", "bed"
            ]
        ),

        // Prayer / Worship / Dhikr
        IconMapping(
            icon: "heart.fill",
            keywords: [
                "prayer", "salah", "salat", "dhikr", "worship", "dua", "quran",
                "mosque", "masjid", "pray", "tasbih", "istighfar",
                "صلاة", "صلاه", "ذكر", "أذكار", "دعاء", "تسبيح", "استغفار",
                "سنة", "نافلة", "ضحى", "وتر", "قيام", "تهجد", "فجر",
                "ظهر", "عصر", "مغرب", "عشاء", "جمعة", "مسجد", "جامع"
            ],
            substrings: [
                "صلا", "صلو", "ذكر", "دعا", "تسبيح", "استغفار", "مسجد",
                "pray", "salah", "dhikr", "worship", "mosque"
            ]
        ),

        // Work / Office / Business
        IconMapping(
            icon: "briefcase.fill",
            keywords: [
                "work", "job", "office", "meeting", "call", "email", "task",
                "project", "deadline", "report", "presentation", "client",
                "interview", "conference", "business", "corporate",
                "عمل", "شغل", "مكتب", "اجتماع", "مشروع", "تقرير",
                "عرض", "عميل", "مقابلة", "مؤتمر", "وظيفة"
            ],
            substrings: [
                "عمل", "شغل", "مكتب", "اجتماع", "مشروع", "وظيف",
                "work", "job", "office", "meeting", "project"
            ]
        ),

        // Food / Eating / Cooking
        IconMapping(
            icon: "fork.knife",
            keywords: [
                "eat", "food", "meal", "lunch", "dinner", "breakfast", "snack",
                "cook", "restaurant", "cafe", "kitchen", "recipe", "grocery",
                "أكل", "طعام", "وجبة", "غداء", "عشاء", "فطور", "طبخ",
                "مطعم", "كافيه", "مطبخ", "وصفة", "بقالة", "سحور", "افطار"
            ],
            substrings: [
                "أكل", "طعام", "وجب", "طبخ", "مطعم", "فطور", "غداء", "عشاء",
                "eat", "food", "meal", "lunch", "dinner", "cook"
            ]
        ),

        // Social / Family / Friends
        IconMapping(
            icon: "person.2.fill",
            keywords: [
                "family", "friends", "party", "gathering", "visit", "birthday",
                "wedding", "celebration", "hangout", "meet", "date",
                "عائلة", "أصدقاء", "حفلة", "تجمع", "زيارة", "عيد ميلاد",
                "زفاف", "احتفال", "موعد", "لقاء"
            ],
            substrings: [
                "عائل", "صديق", "حفل", "زيار", "لقاء", "تجمع",
                "family", "friend", "party", "visit", "meet"
            ]
        ),

        // Health / Medical / Doctor
        IconMapping(
            icon: "cross.case.fill",
            keywords: [
                "doctor", "hospital", "clinic", "medicine", "pharmacy", "health",
                "checkup", "appointment", "dentist", "therapy", "medical",
                "طبيب", "دكتور", "مستشفى", "عيادة", "دواء", "صيدلية",
                "فحص", "موعد طبي", "أسنان", "علاج", "صحة"
            ],
            substrings: [
                "طبيب", "دكتور", "مستشفى", "عياد", "دواء", "صيدل", "صح",
                "doctor", "hospital", "clinic", "medicine", "health"
            ]
        ),

        // Shopping / Errands
        IconMapping(
            icon: "cart.fill",
            keywords: [
                "shop", "shopping", "buy", "store", "mall", "grocery", "market",
                "purchase", "errand",
                "تسوق", "شراء", "متجر", "سوق", "مول", "بقالة"
            ],
            substrings: [
                "تسوق", "شراء", "متجر", "سوق", "بقال",
                "shop", "buy", "store", "mall", "market"
            ]
        ),

        // Cleaning / Chores / Home
        IconMapping(
            icon: "house.fill",
            keywords: [
                "clean", "cleaning", "laundry", "dishes", "vacuum", "organize",
                "tidy", "chore", "home", "housework",
                "تنظيف", "غسيل", "كنس", "ترتيب", "منزل", "بيت", "أعمال منزلية"
            ],
            substrings: [
                "تنظيف", "غسيل", "ترتيب", "منزل", "بيت",
                "clean", "laundry", "tidy", "home", "chore"
            ]
        ),

        // Travel / Transport
        IconMapping(
            icon: "car.fill",
            keywords: [
                "drive", "car", "travel", "trip", "airport", "flight", "train",
                "commute", "uber", "taxi",
                "سيارة", "قيادة", "سفر", "رحلة", "مطار", "طيران", "قطار"
            ],
            substrings: [
                "سيار", "سفر", "رحل", "مطار", "قياد",
                "drive", "car", "travel", "trip", "flight"
            ]
        ),

        // Entertainment / Fun / Relaxation
        IconMapping(
            icon: "play.fill",
            keywords: [
                "movie", "film", "show", "tv", "game", "play", "fun", "entertainment",
                "netflix", "youtube", "music", "concert",
                "فيلم", "مسلسل", "لعبة", "ترفيه", "موسيقى", "حفلة موسيقية"
            ],
            substrings: [
                "فيلم", "مسلسل", "لعب", "ترفيه", "موسيق",
                "movie", "film", "show", "game", "play", "music"
            ]
        ),

        // Creative / Art / Design
        IconMapping(
            icon: "paintbrush.fill",
            keywords: [
                "art", "draw", "paint", "design", "create", "craft", "photo",
                "photography", "sketch", "illustration",
                "رسم", "تصميم", "فن", "إبداع", "تصوير", "فوتو"
            ],
            substrings: [
                "رسم", "تصميم", "فن", "تصوير",
                "art", "draw", "paint", "design", "photo"
            ]
        ),

        // Writing / Notes / Journal
        IconMapping(
            icon: "pencil.line",
            keywords: [
                "write", "writing", "journal", "diary", "notes", "blog", "letter",
                "كتابة", "يوميات", "مذكرات", "ملاحظات", "رسالة"
            ],
            substrings: [
                "كتاب", "يوميات", "مذكرات", "ملاحظ",
                "write", "journal", "diary", "notes"
            ]
        ),

        // Call / Phone / Contact
        IconMapping(
            icon: "phone.fill",
            keywords: [
                "call", "phone", "contact", "ring", "telephone",
                "اتصال", "مكالمة", "هاتف", "تليفون"
            ],
            substrings: [
                "اتصال", "مكالم", "هاتف",
                "call", "phone", "contact"
            ]
        ),

        // Email / Message
        IconMapping(
            icon: "envelope.fill",
            keywords: [
                "email", "mail", "message", "reply", "inbox",
                "بريد", "إيميل", "رسالة", "رد"
            ],
            substrings: [
                "بريد", "ايميل", "إيميل", "رسال",
                "email", "mail", "message"
            ]
        ),

        // Money / Finance / Bills
        IconMapping(
            icon: "dollarsign.circle.fill",
            keywords: [
                "pay", "payment", "bill", "money", "bank", "transfer", "budget",
                "invoice", "salary", "expense",
                "دفع", "فاتورة", "مال", "بنك", "تحويل", "ميزانية", "راتب"
            ],
            substrings: [
                "دفع", "فاتور", "مال", "بنك", "راتب",
                "pay", "bill", "money", "bank", "budget"
            ]
        )
    ]

    // MARK: - Detection

    /// Detects the most appropriate icon for a task title
    /// - Parameter title: The task title to analyze
    /// - Returns: SF Symbol name for the detected icon
    func detectIcon(from title: String) -> String {
        let lowercasedTitle = title.lowercased()

        // First pass: Check substrings (more flexible matching)
        for mapping in mappings {
            for substring in mapping.substrings {
                if lowercasedTitle.contains(substring.lowercased()) {
                    return mapping.icon
                }
            }
        }

        // Second pass: Check full keywords (exact word matching)
        let words = Set(lowercasedTitle.components(separatedBy: .whitespacesAndNewlines))
        for mapping in mappings {
            for keyword in mapping.keywords {
                if words.contains(keyword.lowercased()) {
                    return mapping.icon
                }
            }
        }

        // Default icon when no match found
        return "circle.fill"
    }

    /// Returns all available icons for the icon picker
    var allIcons: [String] {
        mappings.map { $0.icon } + ["circle.fill"]
    }
}
