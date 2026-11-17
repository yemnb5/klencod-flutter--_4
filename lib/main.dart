import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.init();
  runApp(const RifqApp());
}

// =====================================================
// STORAGE  (SharedPreferences + JSON)
// =====================================================
class Store {
  static late SharedPreferences _p;
  static Future<void> init() async => _p = await SharedPreferences.getInstance();

  static int getCount(String id) => _p.getInt('c_$id') ?? 0;
  static Future<void> setCount(String id, int v) => _p.setInt('c_$id', v);

  static List<String> get favorites => _p.getStringList('fav') ?? [];
  static bool isFav(String id) => favorites.contains(id);
  static Future<void> toggleFav(String id) async {
    final f = [...favorites];
    f.contains(id) ? f.remove(id) : f.add(id);
    await _p.setStringList('fav', f);
  }

  static bool get dark => _p.getBool('dark') ?? false;
  static Future<void> setDark(bool v) => _p.setBool('dark', v);

  static bool get english => _p.getBool('en') ?? false;
  static Future<void> setEnglish(bool v) => _p.setBool('en', v);

  static int get tasbih => _p.getInt('tasbih') ?? 0;
  static Future<void> setTasbih(int v) => _p.setInt('tasbih', v);

  static int get tasbihTarget => _p.getInt('tt') ?? 33;
  static Future<void> setTasbihTarget(int v) => _p.setInt('tt', v);

  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static List<String> habitsOn(String key) {
    final raw = _p.getString('h_$key');
    if (raw == null) return [];
    return List<String>.from(jsonDecode(raw));
  }

  static List<String> get todayHabits => habitsOn(dateKey(DateTime.now()));

  static Future<void> toggleHabit(String id) async {
    final key = dateKey(DateTime.now());
    final list = [...habitsOn(key)];
    list.contains(id) ? list.remove(id) : list.add(id);
    await _p.setString('h_$key', jsonEncode(list));
  }

  static int streak(String id) {
    int s = 0;
    var d = DateTime.now();
    if (!habitsOn(dateKey(d)).contains(id)) {
      d = d.subtract(const Duration(days: 1));
    }
    while (habitsOn(dateKey(d)).contains(id)) {
      s++;
      d = d.subtract(const Duration(days: 1));
    }
    return s;
  }

  static Future<void> resetAll() async {
    await _p.clear();
  }
}

// =====================================================
// MODELS
// =====================================================
class Dhikr {
  final String id;
  final String category;
  final String arabic;
  final String english;
  final String reference;
  final int target;
  const Dhikr({
    required this.id,
    required this.category,
    required this.arabic,
    required this.english,
    required this.reference,
    required this.target,
  });
}

class Habit {
  final String id;
  final String ar;
  final String en;
  final IconData icon;
  final String? adhkarCategory;
  const Habit({
    required this.id,
    required this.ar,
    required this.en,
    required this.icon,
    this.adhkarCategory,
  });
}

// =====================================================
// HABITS
// =====================================================
const List<Habit> allHabits = [
  Habit(id: 'morning', ar: 'أذكار الصباح', en: 'Morning adhkar', icon: Icons.wb_sunny_outlined, adhkarCategory: 'morning'),
  Habit(id: 'evening', ar: 'أذكار المساء', en: 'Evening adhkar', icon: Icons.nights_stay_outlined, adhkarCategory: 'evening'),
  Habit(id: 'quran', ar: 'ورد القرآن', en: 'Quran ward', icon: Icons.menu_book_outlined, adhkarCategory: 'quran'),
  Habit(id: 'duha', ar: 'صلاة الضحى', en: 'Duha prayer', icon: Icons.brightness_7_outlined),
  Habit(id: 'istighfar', ar: 'استغفار ١٠٠ مرة', en: 'Istighfar x100', icon: Icons.autorenew),
  Habit(id: 'salawat', ar: 'الصلاة على النبي ١٠٠', en: 'Salawat x100', icon: Icons.favorite_outline),
  Habit(id: 'sleep', ar: 'أذكار النوم', en: 'Sleep adhkar', icon: Icons.bedtime_outlined, adhkarCategory: 'sleep'),
  Habit(id: 'mulk', ar: 'قراءة سورة الملك', en: 'Surah Al-Mulk', icon: Icons.nightlight_outlined),
];

// =====================================================
// ADHKAR LIBRARY (شامل)
// =====================================================
const List<Dhikr> adhkar = [
  // ---------- القرآن والرقية ----------
  Dhikr(
    id: 'q1',
    category: 'quran',
    arabic: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ۝ الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ ۝ الرَّحْمَٰنِ الرَّحِيمِ ۝ مَالِكِ يَوْمِ الدِّينِ ۝ إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ ۝ اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ ۝ صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ',
    english: 'Surah Al-Fatiha',
    reference: 'سورة الفاتحة',
    target: 1,
  ),
  Dhikr(
    id: 'q2',
    category: 'quran',
    arabic: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ',
    english: 'Ayat al-Kursi',
    reference: 'سورة البقرة: ٢٥٥',
    target: 1,
  ),
  Dhikr(
    id: 'q3',
    category: 'quran',
    arabic: 'آمَنَ الرَّسُولُ بِمَا أُنزِلَ إِلَيْهِ مِن رَّبِّهِ وَالْمُؤْمِنُونَ ۚ كُلٌّ آمَنَ بِاللَّهِ وَمَلَائِكَتِهِ وَكُتُبِهِ وَرُسُلِهِ لَا نُفَرِّقُ بَيْنَ أَحَدٍ مِّن رُّسُلِهِ ۚ وَقَالُوا سَمِعْنَا وَأَطَعْنَا ۖ غُفْرَانَكَ رَبَّنَا وَإِلَيْكَ الْمَصِيرُ ۝ لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا ۚ لَهَا مَا كَسَبَتْ وَعَلَيْهَا مَا اكْتَسَبَتْ ۗ رَبَّنَا لَا تُؤَاخِذْنَا إِن نَّسِينَا أَوْ أَخْطَأْنَا ۚ رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَا إِصْرًا كَمَا حَمَلْتَهُ عَلَى الَّذِينَ مِن قَبْلِنَا ۚ رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِ ۖ وَاعْفُ عَنَّا وَاغْفِرْ لَنَا وَارْحَمْنَا ۚ أَنتَ مَوْلَانَا فَانصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ',
    english: 'Last two verses of Al-Baqarah',
    reference: 'سورة البقرة: ٢٨٥-٢٨٦',
    target: 1,
  ),
  Dhikr(
    id: 'q4',
    category: 'quran',
    arabic: 'قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ',
    english: 'Surah Al-Ikhlas',
    reference: 'سورة الإخلاص',
    target: 3,
  ),
  Dhikr(
    id: 'q5',
    category: 'quran',
    arabic: 'قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ مِن شَرِّ مَا خَلَقَ ۝ وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ ۝ وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ۝ وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ',
    english: 'Surah Al-Falaq',
    reference: 'سورة الفلق',
    target: 3,
  ),
  Dhikr(
    id: 'q6',
    category: 'quran',
    arabic: 'قُلْ أَعُوذُ بِرَبِّ النَّاسِ ۝ مَلِكِ النَّاسِ ۝ إِلَٰهِ النَّاسِ ۝ مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ۝ الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ ۝ مِنَ الْجِنَّةِ وَالنَّاسِ',
    english: 'Surah An-Nas',
    reference: 'سورة الناس',
    target: 3,
  ),

  // ---------- الصباح ----------
  Dhikr(
    id: 'm1',
    category: 'morning',
    arabic: 'اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ',
    english: 'O Allah, by You we enter the morning and the evening...',
    reference: 'رواه الترمذي',
    target: 1,
  ),
  Dhikr(
    id: 'm2',
    category: 'morning',
    arabic: 'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَٰهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
    english: 'Sayyid al-Istighfar',
    reference: 'رواه البخاري',
    target: 1,
  ),
  Dhikr(
    id: 'm3',
    category: 'morning',
    arabic: 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
    english: 'We have entered the morning and the dominion belongs to Allah...',
    reference: 'رواه مسلم',
    target: 1,
  ),
  Dhikr(
    id: 'm4',
    category: 'morning',
    arabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ، اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي دِينِي وَدُنْيَايَ وَأَهْلِي وَمَالِي، اللَّهُمَّ اسْتُرْ عَوْرَاتِي وَآمِنْ رَوْعَاتِي، اللَّهُمَّ احْفَظْنِي مِنْ بَيْنِ يَدَيَّ وَمِنْ خَلْفِي وَعَنْ يَمِينِي وَعَنْ شِمَالِي وَمِنْ فَوْقِي، وَأَعُوذُ بِعَظَمَتِكَ أَنْ أُغْتَالَ مِنْ تَحْتِي',
    english: 'O Allah, I ask You for pardon and well-being...',
    reference: 'رواه أبو داود وابن ماجه',
    target: 1,
  ),
  Dhikr(
    id: 'm5',
    category: 'morning',
    arabic: 'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
    english: 'In the name of Allah, nothing harms with His name...',
    reference: 'رواه أبو داود والترمذي',
    target: 3,
  ),
  Dhikr(
    id: 'm6',
    category: 'morning',
    arabic: 'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا',
    english: 'I am pleased with Allah as Lord, Islam as religion, and Muhammad as Prophet',
    reference: 'رواه أبو داود والترمذي',
    target: 3,
  ),
  Dhikr(
    id: 'm7',
    category: 'morning',
    arabic: 'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ، وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ',
    english: 'O Ever-Living, O Sustainer...',
    reference: 'رواه النسائي في السنن الكبرى',
    target: 1,
  ),
  Dhikr(
    id: 'm8',
    category: 'morning',
    arabic: 'حَسْبِيَ اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ',
    english: 'Allah is sufficient for me, there is no deity but Him...',
    reference: 'رواه أبو داود',
    target: 7,
  ),
  Dhikr(
    id: 'm9',
    category: 'morning',
    arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    english: 'Glory and praise be to Allah',
    reference: 'رواه مسلم',
    target: 100,
  ),
  Dhikr(
    id: 'm10',
    category: 'morning',
    arabic: 'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
    english: 'There is no deity but Allah alone...',
    reference: 'متفق عليه',
    target: 10,
  ),
  Dhikr(
    id: 'm11',
    category: 'morning',
    arabic: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
    english: 'I seek refuge in the perfect words of Allah...',
    reference: 'رواه مسلم',
    target: 3,
  ),
  Dhikr(
    id: 'm12',
    category: 'morning',
    arabic: 'اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لَا إِلَٰهَ إِلَّا أَنْتَ',
    english: 'O Allah, grant me health in my body, hearing, and sight',
    reference: 'رواه أبو داود',
    target: 3,
  ),

  // ---------- المساء ----------
  Dhikr(
    id: 'e1',
    category: 'evening',
    arabic: 'اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ',
    english: 'O Allah, by You we enter the evening...',
    reference: 'رواه الترمذي',
    target: 1,
  ),
  Dhikr(
    id: 'e2',
    category: 'evening',
    arabic: 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
    english: 'We have entered the evening and the dominion belongs to Allah...',
    reference: 'رواه مسلم',
    target: 1,
  ),
  Dhikr(
    id: 'e3',
    category: 'evening',
    arabic: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
    english: 'I seek refuge in the perfect words of Allah...',
    reference: 'رواه مسلم',
    target: 3,
  ),
  Dhikr(
    id: 'e4',
    category: 'evening',
    arabic: 'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
    english: 'In the name of Allah, nothing harms with His name...',
    reference: 'رواه أبو داود والترمذي',
    target: 3,
  ),
  Dhikr(
    id: 'e5',
    category: 'evening',
    arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    english: 'Glory and praise be to Allah',
    reference: 'رواه مسلم',
    target: 100,
  ),
  Dhikr(
    id: 'e6',
    category: 'evening',
    arabic: 'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَٰهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
    english: 'Sayyid al-Istighfar',
    reference: 'رواه البخاري',
    target: 1,
  ),

  // ---------- بعد الصلاة ----------
  Dhikr(
    id: 'p1',
    category: 'afterPrayer',
    arabic: 'أَسْتَغْفِرُ اللَّهَ',
    english: 'I seek forgiveness from Allah',
    reference: 'رواه مسلم',
    target: 3,
  ),
  Dhikr(
    id: 'p2',
    category: 'afterPrayer',
    arabic: 'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
    english: 'O Allah, You are Peace and from You is peace...',
    reference: 'رواه مسلم',
    target: 1,
  ),
  Dhikr(
    id: 'p3',
    category: 'afterPrayer',
    arabic: 'سُبْحَانَ اللَّهِ',
    english: 'Glory be to Allah',
    reference: 'رواه مسلم',
    target: 33,
  ),
  Dhikr(
    id: 'p4',
    category: 'afterPrayer',
    arabic: 'الْحَمْدُ لِلَّهِ',
    english: 'All praise is for Allah',
    reference: 'رواه مسلم',
    target: 33,
  ),
  Dhikr(
    id: 'p5',
    category: 'afterPrayer',
    arabic: 'اللَّهُ أَكْبَرُ',
    english: 'Allah is the Greatest',
    reference: 'رواه مسلم',
    target: 33,
  ),
  Dhikr(
    id: 'p6',
    category: 'afterPrayer',
    arabic: 'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
    english: 'There is no deity but Allah alone...',
    reference: 'رواه مسلم',
    target: 1,
  ),

  // ---------- النوم ----------
  Dhikr(
    id: 's1',
    category: 'sleep',
    arabic: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
    english: 'In Your name, O Allah, I die and I live',
    reference: 'رواه البخاري',
    target: 1,
  ),
  Dhikr(
    id: 's2',
    category: 'sleep',
    arabic: 'اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ',
    english: 'O Allah, save me from Your punishment on the Day You resurrect Your servants',
    reference: 'رواه أبو داود والترمذي',
    target: 3,
  ),
  Dhikr(
    id: 's3',
    category: 'sleep',
    arabic: 'سُبْحَانَ اللَّهِ (٣٣) الْحَمْدُ لِلَّهِ (٣٣) اللَّهُ أَكْبَرُ (٣٤)',
    english: 'Tasbih, Tahmid, Takbir before sleep',
    reference: 'متفق عليه',
    target: 1,
  ),
  Dhikr(
    id: 's4',
    category: 'sleep',
    arabic: 'آيَةُ الْكُرْسِيِّ',
    english: 'Recite Ayat al-Kursi before sleeping',
    reference: 'رواه البخاري',
    target: 1,
  ),

  // ---------- الاستيقاظ ----------
  Dhikr(
    id: 'w1',
    category: 'wake',
    arabic: 'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
    english: 'Praise be to Allah who gave us life after causing us to die',
    reference: 'رواه البخاري',
    target: 1,
  ),
  Dhikr(
    id: 'w2',
    category: 'wake',
    arabic: 'الْحَمْدُ لِلَّهِ الَّذِي رَدَّ عَلَيَّ رُوحِي وَعَافَانِي فِي جَسَدِي وَأَذِنَ لِي بِذِكْرِهِ',
    english: 'Praise be to Allah who returned my soul to me...',
    reference: 'رواه الترمذي',
    target: 1,
  ),

  // ---------- عامة ----------
  Dhikr(
    id: 'g1',
    category: 'general',
    arabic: 'سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَٰهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ',
    english: 'Glory to Allah, praise to Allah, no deity but Allah, Allah is Greatest',
    reference: 'رواه مسلم',
    target: 100,
  ),
  Dhikr(
    id: 'g2',
    category: 'general',
    arabic: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    english: 'There is no power and no strength except with Allah',
    reference: 'متفق عليه',
    target: 100,
  ),
  Dhikr(
    id: 'g3',
    category: 'general',
    arabic: 'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ',
    english: 'I seek Allah\u2019s forgiveness and turn to Him in repentance',
    reference: 'متفق عليه',
    target: 100,
  ),
  Dhikr(
    id: 'g4',
    category: 'general',
    arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
    english: 'Glory and praise be to Allah, glory to Allah the Magnificent',
    reference: 'متفق عليه',
    target: 100,
  ),
  Dhikr(
    id: 'g5',
    category: 'general',
    arabic: 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ',
    english: 'O Allah, send blessings upon Muhammad and his family...',
    reference: 'متفق عليه',
    target: 10,
  ),
  Dhikr(
    id: 'g6',
    category: 'general',
    arabic: 'لَا إِلَٰهَ إِلَّا اللَّهُ',
    english: 'There is no deity except Allah',
    reference: 'متفق عليه',
    target: 100,
  ),

  // ---------- أدعية يومية ----------
  Dhikr(
    id: 'd1',
    category: 'daily',
    arabic: 'بِسْمِ اللَّهِ',
    english: 'In the name of Allah (before eating)',
    reference: 'متفق عليه',
    target: 1,
  ),
  Dhikr(
    id: 'd2',
    category: 'daily',
    arabic: 'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا وَسَقَانَا وَجَعَلَنَا مُسْلِمِينَ',
    english: 'Praise be to Allah who fed us, gave us drink, and made us Muslims',
    reference: 'رواه أبو داود والترمذي',
    target: 1,
  ),
  Dhikr(
    id: 'd3',
    category: 'daily',
    arabic: 'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ وَإِنَّا إِلَى رَبِّنَا لَمُنقَلِبُونَ',
    english: 'Glory to Him who has subjected this to us...',
    reference: 'سورة الزخرف: ١٣-١٤',
    target: 1,
  ),
  Dhikr(
    id: 'd4',
    category: 'daily',
    arabic: 'بِسْمِ اللَّهِ وَلَجْنَا، وَبِسْمِ اللَّهِ خَرَجْنَا، وَعَلَى اللَّهِ رَبِّنَا تَوَكَّلْنَا',
    english: 'In Allah\u2019s name we enter and in His name we leave...',
    reference: 'رواه أبو داود',
    target: 1,
  ),
  Dhikr(
    id: 'd5',
    category: 'daily',
    arabic: 'اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ',
    english: 'O Allah, open for me the gates of Your mercy (entering mosque)',
    reference: 'رواه مسلم',
    target: 1,
  ),
];

// =====================================================
// APP ROOT
// =====================================================
class RifqApp extends StatefulWidget {
  const RifqApp({super.key});
  @override
  State<RifqApp> createState() => _RifqAppState();
}

class _RifqAppState extends State<RifqApp> {
  bool dark = Store.dark;
  bool english = Store.english;

  void toggleTheme() async {
    setState(() => dark = !dark);
    await Store.setDark(dark);
  }

  void toggleLang() async {
    setState(() => english = !english);
    await Store.setEnglish(english);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'رفيق الأذكار',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF7FAF7),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F8B68),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7FAF7),
          centerTitle: true,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF75B58D),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: HomePage(
        dark: dark,
        english: english,
        onThemeToggle: toggleTheme,
        onLangToggle: toggleLang,
      ),
    );
  }
}

// =====================================================
// HOME (BottomNavigation)
// =====================================================
class HomePage extends StatefulWidget {
  final bool dark;
  final bool english;
  final VoidCallback onThemeToggle;
  final VoidCallback onLangToggle;
  const HomePage({
    super.key,
    required this.dark,
    required this.english,
    required this.onThemeToggle,
    required this.onLangToggle,
  });
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int idx = 0;
  String t(String ar, String en) => widget.english ? en : ar;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(english: widget.english),
      LibraryPage(english: widget.english),
      HabitsPage(english: widget.english),
      TasbihPage(english: widget.english),
      SettingsPage(english: widget.english),
    ];
    final titles = [
      'رفيق الأذكار',
      t('الأذكار', 'Adhkar'),
      t('العادات', 'Habits'),
      t('السبحة', 'Tasbih'),
      t('الإعدادات', 'Settings'),
    ];

    return Directionality(
      textDirection: widget.english ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(titles[idx], style: const TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: Icon(widget.dark ? Icons.light_mode : Icons.dark_mode),
              onPressed: widget.onThemeToggle,
            ),
            IconButton(
              icon: const Icon(Icons.translate),
              onPressed: widget.onLangToggle,
            ),
          ],
        ),
        body: IndexedStack(index: idx, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: idx,
          onDestinationSelected: (i) => setState(() => idx = i),
          destinations: [
            NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: t('الرئيسية', 'Home')),
            NavigationDestination(icon: const Icon(Icons.menu_book_outlined), label: t('الأذكار', 'Adhkar')),
            NavigationDestination(icon: const Icon(Icons.checklist_outlined), label: t('العادات', 'Habits')),
            NavigationDestination(icon: const Icon(Icons.radio_button_checked), label: t('السبحة', 'Tasbih')),
            NavigationDestination(icon: const Icon(Icons.settings_outlined), label: t('الإعدادات', 'Settings')),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// DASHBOARD
// =====================================================
class DashboardPage extends StatefulWidget {
  final bool english;
  const DashboardPage({super.key, required this.english});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String t(String ar, String en) => widget.english ? en : ar;

  String get greeting {
    final h = DateTime.now().hour;
    if (h < 12) return t('صباح الخير', 'Good morning');
    if (h < 17) return t('طاب نهارك', 'Good afternoon');
    return t('مساء الخير', 'Good evening');
  }

  Dhikr get dailyDhikr {
    final day = DateTime.now().day;
    return adhkar[day % adhkar.length];
  }

  @override
  Widget build(BuildContext context) {
    final done = Store.todayHabits.length;
    final total = allHabits.length;
    final progress = total == 0 ? 0.0 : done / total;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF3F805C), Color(0xFF8DBB98)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                t('اجعل لسانك رطبًا بذكر الله', 'Keep your tongue moist with the remembrance of Allah'),
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.spa_outlined, color: Colors.white, size: 42),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        t('إنجاز اليوم', 'Today'),
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        '$done / $total',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(t('ابدأ الآن', 'Start now'), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        _quick(context, Icons.wb_sunny_outlined, t('أذكار الصباح', 'Morning adhkar'), 'morning'),
        _quick(context, Icons.nights_stay_outlined, t('أذكار المساء', 'Evening adhkar'), 'evening'),
        _quick(context, Icons.menu_book_outlined, t('القرآن والرقية', 'Quran & Ruqyah'), 'quran'),
        _quick(context, Icons.mosque_outlined, t('بعد الصلاة', 'After prayer'), 'afterPrayer'),
        const SizedBox(height: 20),
        Text(t('ذكر اليوم', 'Dhikr of the day'), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Text(
                  dailyDhikr.arabic,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, height: 1.9, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                Text(dailyDhikr.reference, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _quick(BuildContext context, IconData icon, String title, String category) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE6F2E9),
          child: Icon(icon, color: const Color(0xFF3F805C)),
        ),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryPage(category: category, english: widget.english),
            ),
          );
        },
      ),
    );
  }
}

// =====================================================
// LIBRARY
// =====================================================
class LibraryPage extends StatefulWidget {
  final bool english;
  const LibraryPage({super.key, required this.english});
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  String q = '';
  String cat = 'all';
  bool onlyFav = false;

  String t(String ar, String en) => widget.english ? en : ar;

  @override
  Widget build(BuildContext context) {
    final cats = {
      'all': t('الكل', 'All'),
      'quran': t('القرآن والرقية', 'Quran'),
      'morning': t('الصباح', 'Morning'),
      'evening': t('المساء', 'Evening'),
      'afterPrayer': t('بعد الصلاة', 'After prayer'),
      'sleep': t('النوم', 'Sleep'),
      'wake': t('الاستيقاظ', 'Waking up'),
      'general': t('عامة', 'General'),
      'daily': t('يومية', 'Daily'),
    };

    final results = adhkar.where((d) {
      if (cat != 'all' && d.category != cat) return false;
      if (onlyFav && !Store.isFav(d.id)) return false;
      if (q.isEmpty) return true;
      return d.arabic.contains(q) ||
          d.english.toLowerCase().contains(q.toLowerCase()) ||
          d.reference.contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: t('ابحث...', 'Search...'),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              isDense: true,
            ),
            onChanged: (v) => setState(() => q = v),
          ),
        ),
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: FilterChip(
                avatar: const Icon(Icons.favorite, size: 16, color: Colors.red),
                label: Text(t('المفضلة', 'Favorites')),
                selected: onlyFav,
                onSelected: (v) => setState(() => onlyFav = v),
              ),
            ),
          ],
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: cats.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(e.value),
                  selected: cat == e.key,
                  onSelected: (_) => setState(() => cat = e.key),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: results.isEmpty
              ? Center(child: Text(t('لا توجد نتائج', 'No results')))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: results.length,
                  itemBuilder: (_, i) => DhikrCard(
                    key: ValueKey(results[i].id),
                    dhikr: results[i],
                    english: widget.english,
                  ),
                ),
        ),
      ],
    );
  }
}

// =====================================================
// CATEGORY PAGE
// =====================================================
class CategoryPage extends StatelessWidget {
  final String category;
  final bool english;
  const CategoryPage({super.key, required this.category, required this.english});

  @override
  Widget build(BuildContext context) {
    final items = adhkar.where((d) => d.category == category).toList();
    return Directionality(
      textDirection: english ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(english ? 'Adhkar' : 'الأذكار')),
        body: items.isEmpty
            ? Center(child: Text(english ? 'No adhkar' : 'لا توجد أذكار'))
            : ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: items.length,
                itemBuilder: (_, i) => DhikrCard(
                  key: ValueKey(items[i].id),
                  dhikr: items[i],
                  english: english,
                ),
              ),
      ),
    );
  }
}

// =====================================================
// DHIKR CARD
// =====================================================
class DhikrCard extends StatefulWidget {
  final Dhikr dhikr;
  final bool english;
  const DhikrCard({super.key, required this.dhikr, required this.english});
  @override
  State<DhikrCard> createState() => _DhikrCardState();
}

class _DhikrCardState extends State<DhikrCard> {
  late int count;
  late bool fav;

  @override
  void initState() {
    super.initState();
    count = Store.getCount(widget.dhikr.id);
    fav = Store.isFav(widget.dhikr.id);
  }

  Future<void> inc() async {
    if (count >= widget.dhikr.target) {
      HapticFeedback.lightImpact();
      return;
    }
    setState(() => count++);
    await Store.setCount(widget.dhikr.id, count);
    if (count == widget.dhikr.target) HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.dhikr;
    final en = widget.english;
    final progress = d.target == 0 ? 0.0 : (count / d.target).clamp(0.0, 1.0).toDouble();
    final done = count >= d.target;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    en ? d.english : d.reference,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: fav ? Colors.red : null),
                  onPressed: () async {
                    await Store.toggleFav(d.id);
                    if (mounted) setState(() => fav = !fav);
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              d.arabic,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 21, height: 2.05, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Text(en ? d.reference : 'المصدر: ${d.reference}', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: progress, minHeight: 6),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('${en ? 'Count' : 'العدد'}: $count / ${d.target}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                if (done) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle, color: Colors.green, size: 18),
                ],
                const Spacer(),
                IconButton(
                  tooltip: en ? 'Reset' : 'تصفير',
                  onPressed: () async {
                    setState(() => count = 0);
                    await Store.setCount(d.id, 0);
                  },
                  icon: const Icon(Icons.refresh, size: 20),
                ),
                FilledButton(
                  onPressed: inc,
                  child: Text(en ? '+1' : '+١'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// HABITS PAGE
// =====================================================
class HabitsPage extends StatefulWidget {
  final bool english;
  const HabitsPage({super.key, required this.english});
  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  String t(String ar, String en) => widget.english ? en : ar;

  @override
  Widget build(BuildContext context) {
    final done = Store.todayHabits.length;
    final total = allHabits.length;
    final progress = total == 0 ? 0.0 : done / total;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.today, color: Color(0xFF3F805C)),
                    const SizedBox(width: 8),
                    Text(
                      t('إنجاز اليوم', 'Today'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Spacer(),
                    Text('$done / $total', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: progress, minHeight: 8),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...allHabits.map((h) => _HabitTile(habit: h, english: widget.english, onChanged: () => setState(() {}))),
        const SizedBox(height: 10),
        Text(t('إحصائية آخر ٧ أيام', 'Last 7 days'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: allHabits.map((h) {
                final days = List.generate(7, (i) {
                  final d = DateTime.now().subtract(Duration(days: 6 - i));
                  return Store.habitsOn(Store.dateKey(d)).contains(h.id);
                });
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(widget.english ? h.en : h.ar,
                            style: const TextStyle(fontSize: 13)),
                      ),
                      Expanded(
                        flex: 4,
                        child: Row(
                          children: days.map((on) {
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                                child: Container(
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: on
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _HabitTile extends StatelessWidget {
  final Habit habit;
  final bool english;
  final VoidCallback onChanged;
  const _HabitTile({required this.habit, required this.english, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final done = Store.todayHabits.contains(habit.id);
    final streak = Store.streak(habit.id);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(
                  value: done,
                  onChanged: (_) async {
                    await Store.toggleHabit(habit.id);
                    HapticFeedback.selectionClick();
                    onChanged();
                  },
                ),
                Icon(habit.icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    english ? habit.en : habit.ar,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (streak > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                        const SizedBox(width: 3),
                        Text('$streak',
                            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ),
            if (habit.adhkarCategory != null)
              Align(
                alignment: english ? Alignment.centerLeft : Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6, right: 8, left: 8),
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoryPage(
                            category: habit.adhkarCategory!,
                            english: english,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: Text(english ? 'Open adhkar' : 'افتح الأذكار', style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// TASBIH
// =====================================================
class TasbihPage extends StatefulWidget {
  final bool english;
  const TasbihPage({super.key, required this.english});
  @override
  State<TasbihPage> createState() => _TasbihPageState();
}

class _TasbihPageState extends State<TasbihPage> {
  late int count;
  late int target;
  String t(String ar, String en) => widget.english ? en : ar;

  @override
  void initState() {
    super.initState();
    count = Store.tasbih;
    target = Store.tasbihTarget;
  }

  Future<void> inc() async {
    setState(() => count++);
    await Store.setTasbih(count);
    HapticFeedback.selectionClick();
    if (count % target == 0) HapticFeedback.mediumImpact();
  }

  Future<void> reset() async {
    setState(() => count = 0);
    await Store.setTasbih(0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = target == 0 ? 0.0 : ((count % target) / target).clamp(0.0, 1.0).toDouble();
    final rounds = count ~/ target;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Text(t('السبحة الإلكترونية', 'Digital Tasbih'),
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: inc,
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  border: Border.all(color: Theme.of(context).colorScheme.primary, width: 7),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$count', style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold)),
                    Text(t('عدد التسبيحات', 'Total count')),
                    const SizedBox(height: 6),
                    Text(t('الدورات: $rounds', 'Rounds: $rounds'),
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: progress, minHeight: 8),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              children: [33, 99, 100, 1000].map((v) {
                return ChoiceChip(
                  label: Text('$v'),
                  selected: target == v,
                  onSelected: (_) async {
                    setState(() => target = v);
                    await Store.setTasbihTarget(v);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              height: 62,
              child: FilledButton(
                onPressed: inc,
                child: Text(t('سبّح', 'Count'), style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: reset,
              icon: const Icon(Icons.refresh),
              label: Text(t('تصفير', 'Reset')),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// SETTINGS
// =====================================================
class SettingsPage extends StatelessWidget {
  final bool english;
  const SettingsPage({super.key, required this.english});

  String t(String ar, String en) => english ? en : ar;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(t('رفيق الأذكار', 'Rifq Al-Adhkar')),
            subtitle: Text(t('تطبيق أذكار شامل وتتبع عادات', 'Comprehensive adhkar & habits tracker')),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.menu_book),
            title: Text(t('عدد الأذكار', 'Total adhkar')),
            trailing: Text('${adhkar.length}'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.checklist),
            title: Text(t('عدد العادات', 'Total habits')),
            trailing: Text('${allHabits.length}'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(t('مسح كل البيانات', 'Reset all data'), style: const TextStyle(color: Colors.red)),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(t('تأكيد', 'Confirm')),
                  content: Text(t(
                      'سيتم حذف كل الأعداد والمفضلة وسجل العادات. متابعة؟',
                      'All counts, favorites and habit logs will be deleted. Continue?')),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('إلغاء', 'Cancel'))),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t('حذف', 'Delete'))),
                  ],
                ),
              );
              if (ok == true) {
                await Store.resetAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t('تم الحذف', 'Deleted'))),
                  );
                }
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            t('صُنع بحب لخدمة كتاب الله وسنة نبيه ﷺ', 'Made with ❤ for the Book of Allah and the Sunnah'),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}