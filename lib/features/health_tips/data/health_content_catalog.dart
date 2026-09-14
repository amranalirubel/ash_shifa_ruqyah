class HealthSource {
  const HealthSource({
    required this.id,
    required this.organization,
    required this.title,
    required this.url,
    required this.reviewedOn,
  });

  final String id;
  final String organization;
  final String title;
  final String url;
  final String reviewedOn;
}

class HealthBanner {
  const HealthBanner({
    required this.id,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.iconKey,
    required this.sourceIds,
  });

  final String id;
  final String eyebrow;
  final String title;
  final String body;
  final String iconKey;
  final List<String> sourceIds;
}

class DailyHealthTip {
  const DailyHealthTip({
    required this.id,
    required this.title,
    required this.details,
    required this.iconKey,
    required this.sourceIds,
  });

  final String id;
  final String title;
  final String details;
  final String iconKey;
  final List<String> sourceIds;
}

enum HealthGuideCategory {
  dailyMovement,
  kneeCare,
  backCare,
  handCare,
  mindfulness,
}

extension HealthGuideCategoryLabel on HealthGuideCategory {
  String get label => switch (this) {
    HealthGuideCategory.dailyMovement => 'দৈনিক নড়াচড়া',
    HealthGuideCategory.kneeCare => 'হাঁটু',
    HealthGuideCategory.backCare => 'কোমর',
    HealthGuideCategory.handCare => 'হাত ও কব্জি',
    HealthGuideCategory.mindfulness => 'মনন ও শ্বাস',
  };
}

class MovementGuide {
  const MovementGuide({
    required this.id,
    required this.title,
    required this.summary,
    required this.duration,
    required this.level,
    required this.category,
    required this.iconKey,
    required this.steps,
    required this.dosage,
    required this.stopAndSeekHelp,
    required this.sourceIds,
    this.hasGuidedSession = false,
  });

  final String id;
  final String title;
  final String summary;
  final String duration;
  final String level;
  final HealthGuideCategory category;
  final String iconKey;
  final List<String> steps;
  final String dosage;
  final List<String> stopAndSeekHelp;
  final List<String> sourceIds;
  final bool hasGuidedSession;
}

class DietGuide {
  const DietGuide({
    required this.id,
    required this.title,
    required this.summary,
    required this.iconKey,
    required this.chooseMoreOften,
    required this.limitMoreOften,
    required this.clinicalNote,
    required this.sourceIds,
  });

  final String id;
  final String title;
  final String summary;
  final String iconKey;
  final List<String> chooseMoreOften;
  final List<String> limitMoreOften;
  final String clinicalNote;
  final List<String> sourceIds;
}

/// Editorially curated, version-controlled health information.
///
/// This catalogue is intentionally bundled with the app. Medical content must
/// not be replaced by unreviewed remote text. A future remote publishing flow
/// should require schema validation, named clinical review, an audit trail, and
/// an explicit published status before the app accepts an update.
class HealthContentCatalog {
  const HealthContentCatalog._();

  static const int schemaVersion = 2;
  static const String editorialReviewDate = '2026-09-14';

  static const Map<String, HealthSource> sources = {
    'who_activity': HealthSource(
      id: 'who_activity',
      organization: 'World Health Organization (WHO)',
      title: 'Physical activity',
      url: 'https://www.who.int/news-room/fact-sheets/detail/physical-activity',
      reviewedOn: editorialReviewDate,
    ),
    'who_healthy_diet': HealthSource(
      id: 'who_healthy_diet',
      organization: 'World Health Organization (WHO)',
      title: 'Healthy diet',
      url: 'https://www.who.int/news-room/fact-sheets/detail/healthy-diet',
      reviewedOn: editorialReviewDate,
    ),
    'cdc_sleep': HealthSource(
      id: 'cdc_sleep',
      organization: 'Centers for Disease Control and Prevention (CDC)',
      title: 'About Sleep',
      url: 'https://www.cdc.gov/sleep/about/index.html',
      reviewedOn: editorialReviewDate,
    ),
    'cdc_bmi': HealthSource(
      id: 'cdc_bmi',
      organization: 'Centers for Disease Control and Prevention (CDC)',
      title: 'Adult BMI Categories',
      url: 'https://www.cdc.gov/bmi/adult-calculator/bmi-categories.html',
      reviewedOn: editorialReviewDate,
    ),
    'cdc_diabetes': HealthSource(
      id: 'cdc_diabetes',
      organization: 'Centers for Disease Control and Prevention (CDC)',
      title: 'Healthy Eating With Diabetes',
      url: 'https://www.cdc.gov/diabetes/healthy-eating/index.html',
      reviewedOn: editorialReviewDate,
    ),
    'nih_dash': HealthSource(
      id: 'nih_dash',
      organization: 'NHLBI, National Institutes of Health',
      title: 'DASH Eating Plan',
      url: 'https://www.nhlbi.nih.gov/health/dash-eating-plan',
      reviewedOn: editorialReviewDate,
    ),
    'nhs_cholesterol': HealthSource(
      id: 'nhs_cholesterol',
      organization: 'National Health Service (NHS)',
      title: 'How to lower your cholesterol',
      url:
          'https://www.nhs.uk/conditions/high-cholesterol/how-to-lower-your-cholesterol/',
      reviewedOn: editorialReviewDate,
    ),
    'nhs_knee': HealthSource(
      id: 'nhs_knee',
      organization: 'East of England Community Health and Care NHS Trust',
      title: 'Knee pain: advice and beginner exercises',
      url: 'https://www.dynamichealth.nhs.uk/help-and-advice/knee-pain/',
      reviewedOn: editorialReviewDate,
    ),
    'nhs_back': HealthSource(
      id: 'nhs_back',
      organization: 'East of England Community Health and Care NHS Trust',
      title: 'Lower back pain: advice and exercises',
      url:
          'https://www.dynamichealth.nhs.uk/help-and-advice/lower-back-pain/',
      reviewedOn: editorialReviewDate,
    ),
    'nhs_wrist': HealthSource(
      id: 'nhs_wrist',
      organization: 'East of England Community Health and Care NHS Trust',
      title: 'Wrist, hand and thumb pain',
      url:
          'https://www.dynamichealth.nhs.uk/help-and-advice/wrist-hand-and-thumb-pain/',
      reviewedOn: editorialReviewDate,
    ),
    'nhs_breathing': HealthSource(
      id: 'nhs_breathing',
      organization: 'National Health Service (NHS)',
      title: 'Breathing exercises for stress',
      url:
          'https://www.nhs.uk/mental-health/self-help/guides-tools-and-activities/breathing-exercises-for-stress/',
      reviewedOn: editorialReviewDate,
    ),
    'nih_mindfulness': HealthSource(
      id: 'nih_mindfulness',
      organization: 'NCCIH, National Institutes of Health',
      title: 'Meditation and Mindfulness: Effectiveness and Safety',
      url:
          'https://www.nccih.nih.gov/health/meditation-and-mindfulness-effectiveness-and-safety',
      reviewedOn: editorialReviewDate,
    ),
  };

  static const List<HealthBanner> banners = [
    HealthBanner(
      id: 'movement_counts',
      eyebrow: 'আজকের Evidence Note',
      title: 'অল্প নড়াচড়াও শূন্যের চেয়ে ভালো',
      body:
          'ধীরে শুরু করুন। প্রাপ্তবয়স্কদের লক্ষ্য সপ্তাহে অন্তত ১৫০ মিনিট মাঝারি মাত্রার শারীরিক কার্যকলাপ।',
      iconKey: 'walk',
      sourceIds: ['who_activity'],
    ),
    HealthBanner(
      id: 'sleep_matters',
      eyebrow: 'ঘুম ও সুস্থতা',
      title: 'ঘুম শুধু বিশ্রাম নয়',
      body:
          '১৮–৬০ বছর বয়সী অধিকাংশ প্রাপ্তবয়স্কের প্রতিদিন ৭ বা তার বেশি ঘণ্টা ঘুম প্রয়োজন।',
      iconKey: 'sleep',
      sourceIds: ['cdc_sleep'],
    ),
    HealthBanner(
      id: 'balanced_diet',
      eyebrow: 'খাবারের ভিত্তি',
      title: 'বৈচিত্র্য, ভারসাম্য ও পরিমিতি',
      body:
          'একটি স্বাস্থ্যকর খাদ্যতালিকা বয়স, কাজ ও স্বাস্থ্য অনুযায়ী বদলায়; তবে বৈচিত্র্য ও কম প্রক্রিয়াজাত খাবার সবার ভিত্তি।',
      iconKey: 'nutrition',
      sourceIds: ['who_healthy_diet'],
    ),
    HealthBanner(
      id: 'calm_breath',
      eyebrow: 'মানসিক বিরতি',
      title: 'পাঁচ মিনিট ধীর শ্বাস',
      body:
          'আরাম করে নাক দিয়ে শ্বাস নিন, মুখ দিয়ে ছাড়ুন; জোর করবেন না এবং নিয়মিত অনুশীলন করুন।',
      iconKey: 'breathing',
      sourceIds: ['nhs_breathing'],
    ),
  ];

  static const List<DailyHealthTip> dailyTips = [
    DailyHealthTip(
      id: 'move_today',
      title: 'আজ কিছুটা নড়াচড়া করুন',
      details:
          'স্বাচ্ছন্দ্য অনুযায়ী হাঁটা দিয়ে শুরু করুন। সময়কে ছোট কয়েকটি ভাগেও সম্পন্ন করা যায়।',
      iconKey: 'walk',
      sourceIds: ['who_activity'],
    ),
    DailyHealthTip(
      id: 'break_sitting',
      title: 'দীর্ঘক্ষণ একভাবে বসে থাকবেন না',
      details:
          'কাজের ফাঁকে নিয়মিত উঠে দাঁড়ান বা অল্প হাঁটুন। দৈনন্দিন সব ধরনের নড়াচড়া হিসাবের মধ্যে পড়ে।',
      iconKey: 'movement',
      sourceIds: ['who_activity'],
    ),
    DailyHealthTip(
      id: 'sleep_schedule',
      title: 'ঘুম ও জাগার সময় নিয়মিত রাখুন',
      details:
          'শোবার অন্তত ৩০ মিনিট আগে electronic device বন্ধ করার চেষ্টা করুন।',
      iconKey: 'sleep',
      sourceIds: ['cdc_sleep'],
    ),
    DailyHealthTip(
      id: 'food_variety',
      title: 'খাবারে বৈচিত্র্য রাখুন',
      details:
          'শাকসবজি, ফল, ডাল, পূর্ণশস্য এবং উপযুক্ত protein source মিলিয়ে খান।',
      iconKey: 'nutrition',
      sourceIds: ['who_healthy_diet'],
    ),
    DailyHealthTip(
      id: 'less_sugary_drinks',
      title: 'চিনিযুক্ত পানীয় কমান',
      details:
          'পানি বা চিনি ছাড়া পানীয় বেছে নিন। বিশেষ রোগে তরলের সীমা থাকলে চিকিৎসকের নির্দেশ মানুন।',
      iconKey: 'water',
      sourceIds: ['who_healthy_diet', 'cdc_diabetes'],
    ),
    DailyHealthTip(
      id: 'calm_breathing',
      title: 'পাঁচ মিনিট শান্ত শ্বাস নিন',
      details:
          'নাক দিয়ে স্বাভাবিকভাবে শ্বাস নিন এবং মুখ দিয়ে ধীরে ছাড়ুন; মাথা ঘুরলে থামুন।',
      iconKey: 'breathing',
      sourceIds: ['nhs_breathing'],
    ),
    DailyHealthTip(
      id: 'listen_to_pain',
      title: 'ব্যথাকে উপেক্ষা করে ব্যায়াম নয়',
      details:
          'ব্যায়ামে ব্যথা স্পষ্টভাবে বেড়ে গেলে range বা repetition কমান এবং প্রয়োজন হলে clinician-এর পরামর্শ নিন।',
      iconKey: 'safety',
      sourceIds: ['nhs_knee', 'nhs_back', 'nhs_wrist'],
    ),
  ];

  static const List<MovementGuide> movementGuides = [
    MovementGuide(
      id: 'comfortable_walk',
      title: 'স্বাচ্ছন্দ্যের হাঁটা',
      summary:
          'দৈনিক নড়াচড়া বাড়ানোর সহজ উপায়; গতি এমন রাখুন যাতে কথা বলা যায়।',
      duration: '১০–২০ মিনিট',
      level: 'শুরুর স্তর',
      category: HealthGuideCategory.dailyMovement,
      iconKey: 'walk',
      steps: [
        'আরামদায়ক জুতা পরে সমতল ও নিরাপদ জায়গা বেছে নিন।',
        'প্রথম ২ মিনিট ধীরে হাঁটুন।',
        'তারপর স্বাচ্ছন্দ্য অনুযায়ী গতি সামান্য বাড়ান।',
        'শেষ ২ মিনিট আবার ধীরে হাঁটুন।',
      ],
      dosage:
          'প্রথমে ১০ মিনিট দিয়ে শুরু করুন। সহ্য হলে ধীরে সময় বাড়ান; সপ্তাহের মোট লক্ষ্য ১৫০ মিনিটের দিকে নিন।',
      stopAndSeekHelp: [
        'বুকে ব্যথা, অস্বাভাবিক শ্বাসকষ্ট, মাথা ঘোরা বা অজ্ঞান লাগলে সঙ্গে সঙ্গে থামুন।',
        'নতুন আঘাত বা তীব্র ব্যথা থাকলে আগে স্বাস্থ্যকর্মীর পরামর্শ নিন।',
      ],
      sourceIds: ['who_activity'],
    ),
    MovementGuide(
      id: 'seated_knee_extension',
      title: 'বসে হাঁটু সোজা করা',
      summary:
          'উরুর সামনের পেশি সক্রিয় করার নিয়ন্ত্রিত beginner movement।',
      duration: '৩–৫ মিনিট',
      level: 'হালকা',
      category: HealthGuideCategory.kneeCare,
      iconKey: 'knee',
      steps: [
        'মজবুত চেয়ারে সোজা হয়ে বসুন; দুই পা মেঝেতে রাখুন।',
        'এক পায়ের আঙুল নিজের দিকে টেনে হাঁটু ধীরে সোজা করুন।',
        'স্বাচ্ছন্দ্যের সীমায় এক মুহূর্ত থাকুন।',
        'ধীরে পা নামিয়ে অন্য পায়ে পুনরাবৃত্তি করুন।',
      ],
      dosage:
          'প্রথমে প্রতি পায়ে ৫ বার, ১ সেট। আরাম থাকলে ধীরে ৮–১০ বার পর্যন্ত বাড়ান।',
      stopAndSeekHelp: [
        'আঘাতের পর ব্যথা, পায়ে ভর দিতে না পারা, বা হাঁটু খুব ফুলে/বিকৃত হলে exercise করবেন না।',
        'হাঁটু গরম-লাল এবং জ্বর বা কাঁপুনি থাকলে দ্রুত চিকিৎসা নিন।',
      ],
      sourceIds: ['nhs_knee'],
    ),
    MovementGuide(
      id: 'supported_sit_to_stand',
      title: 'চেয়ার থেকে ওঠা-বসা',
      summary:
          'পা ও নিতম্বের দৈনন্দিন শক্তি তৈরির functional movement।',
      duration: '৩–৬ মিনিট',
      level: 'শুরুর স্তর',
      category: HealthGuideCategory.kneeCare,
      iconKey: 'chair',
      steps: [
        'দেয়ালের পাশে একটি মজবুত চেয়ার রাখুন।',
        'পা ও হাঁটু কোমরের সমান দূরত্বে রেখে সোজা বসুন।',
        'গোড়ালিতে ভর দিয়ে নিয়ন্ত্রিতভাবে দাঁড়ান।',
        'নিতম্ব পেছনে নিয়ে ধীরে আবার বসুন; পড়ে বসবেন না।',
      ],
      dosage:
          '৩–৫ বার দিয়ে শুরু করুন। ভারসাম্যের সমস্যা থাকলে পাশে সহায়তাকারী রাখুন।',
      stopAndSeekHelp: [
        'হাঁটু lock/give way করলে বা ব্যথা দ্রুত বাড়লে থামুন।',
        'সাম্প্রতিক পড়ে যাওয়া বা আঘাত থাকলে আগে assessment নিন।',
      ],
      sourceIds: ['nhs_knee', 'nhs_back'],
    ),
    MovementGuide(
      id: 'posterior_pelvic_tilt',
      title: 'কোমরের Pelvic Tilt',
      summary:
          'কোমরের আরামদায়ক range of movement-এর জন্য ধীর, নিয়ন্ত্রিত অনুশীলন।',
      duration: '৩–৫ মিনিট',
      level: 'হালকা',
      category: HealthGuideCategory.backCare,
      iconKey: 'back',
      steps: [
        'বিছানা বা mat-এ চিৎ হয়ে হাঁটু ভাঁজ করে শুয়ে পড়ুন।',
        'পা মেঝেতে রেখে পেট হালকা ভেতরে নিন ও নিতম্বের পেশি টানুন।',
        'কোমরের নিচের অংশ বিছানা বা mat-এর দিকে আলতো চাপুন।',
        'স্বাভাবিক শ্বাস রেখে ছেড়ে দিন।',
      ],
      dosage:
          '৫ বার দিয়ে শুরু করুন। আরাম থাকলে ৭–১০ বার পর্যন্ত ধীরে বাড়াতে পারেন।',
      stopAndSeekHelp: [
        'দুই পায়ে নতুন দুর্বলতা/অসাড়তা, যৌনাঙ্গ বা পায়ুপথে অসাড়তা, কিংবা প্রস্রাব-পায়খানার নিয়ন্ত্রণ বদলালে জরুরি চিকিৎসা নিন।',
        'গুরুতর দুর্ঘটনার পর ব্যথা বা সঙ্গে বুকব্যথা থাকলে exercise নয়—জরুরি মূল্যায়ন দরকার।',
      ],
      sourceIds: ['nhs_back'],
    ),
    MovementGuide(
      id: 'gentle_knee_rolls',
      title: 'কোমরের Gentle Knee Rolls',
      summary:
          'কাঁধ স্থির রেখে কোমরকে স্বাচ্ছন্দ্যের সীমায় পাশে নড়ানোর exercise।',
      duration: '৩–৫ মিনিট',
      level: 'হালকা',
      category: HealthGuideCategory.backCare,
      iconKey: 'back',
      steps: [
        'চিৎ হয়ে দুই হাঁটু ভাঁজ করুন এবং হাঁটু পাশাপাশি রাখুন।',
        'উপরের পিঠ ও কাঁধ বিছানা বা mat-এ স্থির রাখুন।',
        'হাঁটু দুটো ধীরে এক পাশে নিন—শুধু আরামদায়ক সীমা পর্যন্ত।',
        'মাঝে ফিরে অন্য পাশে একইভাবে নিন।',
      ],
      dosage: 'প্রতি পাশে ৩–৫ বার দিয়ে শুরু করুন; দ্রুত বা ঝাঁকুনি দিয়ে নয়।',
      stopAndSeekHelp: [
        'ব্যথা পায়ে ছড়িয়ে নতুন অসাড়তা বা দুর্বলতা হলে থামুন।',
        'ব্যথা দ্রুত খারাপ হলে বা red-flag উপসর্গ থাকলে জরুরি মূল্যায়ন নিন।',
      ],
      sourceIds: ['nhs_back'],
    ),
    MovementGuide(
      id: 'wrist_side_to_side',
      title: 'কব্জি পাশে নড়ানো',
      summary:
          'কব্জির আরামদায়ক range ফিরিয়ে আনার gentle mobility exercise।',
      duration: '২–৪ মিনিট',
      level: 'হালকা',
      category: HealthGuideCategory.handCare,
      iconKey: 'hand',
      steps: [
        'বাহু টেবিলে রেখে আঙুল ও কব্জি সোজা রাখুন।',
        'কব্জি ধীরে কনিষ্ঠ আঙুলের দিকে নিন।',
        'মাঝে ফিরে ধীরে বৃদ্ধাঙ্গুলের দিকে নিন।',
        'নড়াচড়া ছোট রাখুন; জোর করে শেষ সীমায় যাবেন না।',
      ],
      dosage: 'প্রতি দিকে ৫ বার দিয়ে শুরু করুন; আরাম থাকলে ধীরে বাড়ান।',
      stopAndSeekHelp: [
        'পড়ে যাওয়া বা আঘাতের পর ব্যথা, fracture সন্দেহ, বা হাত অসাড়/দুর্বল হলে assessment নিন।',
        'আঙুল খুব ফুলে বা শক্ত হয়ে গেলে চিকিৎসকের পরামর্শ নিন।',
      ],
      sourceIds: ['nhs_wrist'],
    ),
    MovementGuide(
      id: 'wrist_prayer_stretch',
      title: 'হাতের তালু মিলিয়ে কব্জি স্ট্রেচ',
      summary:
          'দুই তালু মিলিয়ে কব্জিকে অল্প range-এ নমনীয় করার অনুশীলন।',
      duration: '২–৩ মিনিট',
      level: 'হালকা',
      category: HealthGuideCategory.handCare,
      iconKey: 'hand',
      steps: [
        'বুকের সামনে দুই হাতের তালু আলতো করে মিলিয়ে নিন।',
        'তালু একসঙ্গে রেখে হাত ধীরে নিচের দিকে নামান।',
        'কব্জিতে হালকা stretch অনুভব হলে এক মুহূর্ত থাকুন।',
        'চাপ ছেড়ে স্বাভাবিক অবস্থায় ফিরুন।',
      ],
      dosage: '৩–৫টি gentle repetition; ব্যথার মধ্যে চাপ দেবেন না।',
      stopAndSeekHelp: [
        'তীক্ষ্ণ ব্যথা, ঝিনঝিনি বা অসাড়তা বাড়লে সঙ্গে সঙ্গে থামুন।',
        'সাম্প্রতিক trauma বা fracture সন্দেহে এই exercise করবেন না।',
      ],
      sourceIds: ['nhs_wrist'],
    ),
    MovementGuide(
      id: 'calm_breathing_5',
      title: '৫ মিনিট Guided Breathing',
      summary:
          'Stress বা অস্থিরতায় শরীরকে থামিয়ে স্বাভাবিক, জোরহীন শ্বাসে মন দেওয়ার অনুশীলন।',
      duration: '৫ মিনিট',
      level: 'সবার জন্য',
      category: HealthGuideCategory.mindfulness,
      iconKey: 'breathing',
      steps: [
        'সমর্থনযুক্ত চেয়ারে বসুন বা আরাম করে শুয়ে পড়ুন।',
        'পা মেঝেতে রাখুন এবং আঁটসাঁট পোশাক ঢিলা করুন।',
        'নাক দিয়ে আরামদায়কভাবে শ্বাস নিন; জোর করবেন না।',
        'মুখ দিয়ে ধীরে শ্বাস ছাড়ুন; চাইলে ১ থেকে ৫ গুনুন।',
      ],
      dosage: 'নিয়মিত ৫ মিনিট অনুশীলন করুন; app session যেকোনো সময় pause করা যাবে।',
      stopAndSeekHelp: [
        'মাথা ঘোরা, শ্বাসকষ্ট বা আতঙ্ক বাড়লে থামুন এবং স্বাভাবিক শ্বাসে ফিরুন।',
        'এটি anxiety বা panic disorder-এর চিকিৎসার বিকল্প নয়।',
      ],
      sourceIds: ['nhs_breathing'],
      hasGuidedSession: true,
    ),
    MovementGuide(
      id: 'mindful_body_scan',
      title: 'সংক্ষিপ্ত Body Scan',
      summary:
          'শরীরের অনুভূতি বিচার না করে লক্ষ্য করার mindfulness practice।',
      duration: '৩–৫ মিনিট',
      level: 'শুরুর স্তর',
      category: HealthGuideCategory.mindfulness,
      iconKey: 'mindfulness',
      steps: [
        'আরামদায়ক অবস্থায় বসুন; চোখ বন্ধ করা বাধ্যতামূলক নয়।',
        'কয়েকটি স্বাভাবিক শ্বাস লক্ষ্য করুন।',
        'পা থেকে মাথা পর্যন্ত একেক অংশের চাপ, উষ্ণতা বা আরাম লক্ষ্য করুন।',
        'মন অন্যদিকে গেলে নিজেকে দোষ না দিয়ে আবার শরীরের অনুভূতিতে ফিরুন।',
      ],
      dosage: '৩ মিনিট দিয়ে শুরু করুন; স্বাচ্ছন্দ্য থাকলে ৫ মিনিট করুন।',
      stopAndSeekHelp: [
        'চর্চায় anxiety, depression বা distress বাড়লে থামুন।',
        'গুরুতর মানসিক উপসর্গে trained mental-health professional-এর সহায়তা নিন।',
      ],
      sourceIds: ['nih_mindfulness'],
    ),
    MovementGuide(
      id: 'mindful_walk',
      title: 'Mindful Walking',
      summary:
          'হাঁটার সময় পদক্ষেপ, শ্বাস ও চারপাশের নিরাপদ সংকেতে মন ফেরানোর practice।',
      duration: '৫–১০ মিনিট',
      level: 'শুরুর স্তর',
      category: HealthGuideCategory.mindfulness,
      iconKey: 'mindfulness',
      steps: [
        'নিরাপদ, পরিচিত এবং বাধামুক্ত পথ বেছে নিন।',
        'স্বাভাবিক গতিতে হাঁটুন এবং পায়ের মাটিতে পড়া অনুভব করুন।',
        'শ্বাস বদলানোর চেষ্টা না করে তার ছন্দ লক্ষ্য করুন।',
        'মন অন্যদিকে গেলে পথের নিরাপত্তা দেখে আবার পদক্ষেপে মন ফেরান।',
      ],
      dosage: '৫ মিনিট দিয়ে শুরু করুন; রাস্তা পার হওয়া বা গাড়ির কাছে practice নয়।',
      stopAndSeekHelp: [
        'মাথা ঘোরা, ভারসাম্য হারানো বা ব্যথা হলে থামুন।',
        'Mindfulness চিকিৎসার বিকল্প নয়; distress বাড়লে পেশাদার সহায়তা নিন।',
      ],
      sourceIds: ['who_activity', 'nih_mindfulness'],
    ),
  ];

  static const List<DietGuide> dietGuides = [
    DietGuide(
      id: 'balanced_eating',
      title: 'সুষম খাবারের ভিত্তি',
      summary:
          'একটি নির্দিষ্ট “সবার জন্য একই” diet নয়—বৈচিত্র্য, ভারসাম্য, পরিমিতি ও স্থানীয় স্বাস্থ্যকর খাবারকে গুরুত্ব দিন।',
      iconKey: 'nutrition',
      chooseMoreOften: [
        'বিভিন্ন রঙের শাকসবজি ও সম্পূর্ণ ফল',
        'ডাল, ছোলা, মসুর এবং অন্যান্য legumes',
        'পূর্ণশস্য; যেমন ওটস, আটার রুটি বা ব্রাউন রাইস',
        'মাছ, ডিম বা ব্যক্তির জন্য উপযুক্ত protein source',
        'বাদাম-বীজ ও unsaturated fat পরিমিত পরিমাণে',
      ],
      limitMoreOften: [
        'অতিরিক্ত লবণ বা sodium-সমৃদ্ধ processed food',
        'চিনিযুক্ত পানীয় ও অতিরিক্ত free sugar',
        'অতিরিক্ত saturated/trans fat',
        'অতিরিক্ত ultra-processed খাবার',
      ],
      clinicalNote:
          'গর্ভাবস্থা, কিডনি/লিভার রোগ, food allergy বা ওষুধের সঙ্গে diet restriction থাকলে ব্যক্তিগত পরামর্শ নিন।',
      sourceIds: ['who_healthy_diet'],
    ),
    DietGuide(
      id: 'type_2_diabetes',
      title: 'টাইপ–২ ডায়াবেটিস',
      summary:
          'খাবারের পরিমাণ, carbohydrate-এর ধরন এবং meal timing—সবই blood glucose management-এ গুরুত্বপূর্ণ।',
      iconKey: 'glucose',
      chooseMoreOften: [
        'Plate method: অর্ধেক non-starchy সবজি',
        'এক-চতুর্থাংশ lean protein',
        'এক-চতুর্থাংশ high-fibre carbohydrate',
        'সম্পূর্ণ ফল—juice-এর বদলে',
        'নিজের treatment plan অনুযায়ী নিয়মিত meal timing',
      ],
      limitMoreOften: [
        'চিনিযুক্ত soft drink, energy drink ও অতিরিক্ত মিষ্টি',
        'বড় portion-এর refined carbohydrate',
        'অতিরিক্ত processed snack',
        'নিজে থেকে meal বা prescribed medicine বাদ দেওয়া',
      ],
      clinicalNote:
          'Insulin/medicine ব্যবহার, kidney disease, pregnancy বা recurrent low glucose থাকলে dietitian/doctor-এর individual plan জরুরি।',
      sourceIds: ['cdc_diabetes', 'who_healthy_diet'],
    ),
    DietGuide(
      id: 'high_blood_pressure',
      title: 'উচ্চ রক্তচাপ',
      summary:
          'DASH হলো flexible, balanced এবং heart-healthy eating pattern; কোনো special food কিনতে হয় না।',
      iconKey: 'heart',
      chooseMoreOften: [
        'শাকসবজি, ফল ও পূর্ণশস্য',
        'ডাল, বাদাম ও বীজ',
        'মাছ, poultry এবং ব্যক্তির জন্য উপযুক্ত lean protein',
        'কম-চর্বিযুক্ত dairy, যদি সহ্য হয়',
        'বাড়িতে কম লবণে রান্না করা খাবার',
      ],
      limitMoreOften: [
        'অতিরিক্ত লবণ, stock cube ও salty sauce',
        'চিপস, instant noodles এবং processed meat',
        'চিনিযুক্ত পানীয় ও অতিরিক্ত মিষ্টি',
        'অতিরিক্ত saturated fat',
      ],
      clinicalNote:
          'রক্তচাপের ওষুধ নিজে থেকে বন্ধ করবেন না। Kidney disease বা potassium restriction থাকলে DASH পরিবর্তন প্রয়োজন হতে পারে।',
      sourceIds: ['nih_dash'],
    ),
    DietGuide(
      id: 'high_cholesterol',
      title: 'উচ্চ কোলেস্টেরল',
      summary:
          'Saturated fat কমিয়ে unsaturated fat, wholegrain, ফল-সবজি ও বাদাম বাড়ানো সহায়ক হতে পারে।',
      iconKey: 'heart',
      chooseMoreOften: [
        'Oily fish, যদি ব্যক্তির জন্য উপযুক্ত হয়',
        'Olive/rapeseed বা স্থানীয় unsaturated vegetable oil পরিমিতভাবে',
        'পূর্ণশস্য, ফল ও শাকসবজি',
        'বাদাম ও বীজ পরিমিত পরিমাণে',
        'হাঁটা, সাঁতার বা cycling-এর মতো নিয়মিত activity',
      ],
      limitMoreOften: [
        'Fatty meat ও processed meat',
        'Butter, ghee, cream এবং অতিরিক্ত full-fat cheese',
        'Cake, biscuit ও saturated-fat বেশি snack',
        'Coconut/palm oil বেশি থাকা খাবার',
      ],
      clinicalNote:
          'Cholesterol report, diabetes, blood pressure ও সামগ্রিক cardiovascular risk একসঙ্গে দেখে clinician treatment ঠিক করেন।',
      sourceIds: ['nhs_cholesterol', 'who_activity'],
    ),
  ];

  static List<HealthSource> resolveSources(Iterable<String> ids) {
    return ids.map((id) => sources[id]).whereType<HealthSource>().toList();
  }
}
