class PhraseEntry {
  final String en;
  final String es;
  final String fr;
  final String de;
  final String zh;
  final String ja;
  final String ar;
  final String hi;
  final String pt;
  final String ru;
  final String? ta;

  const PhraseEntry({
    required this.en,
    required this.es,
    required this.fr,
    required this.de,
    required this.zh,
    required this.ja,
    required this.ar,
    required this.hi,
    required this.pt,
    required this.ru,
    this.ta,
  });

  String? getForLanguage(String lang) {
    switch (lang.toLowerCase()) {
      case 'en':
        return en;
      case 'es':
        return es;
      case 'fr':
        return fr;
      case 'de':
        return de;
      case 'zh':
        return zh;
      case 'ja':
        return ja;
      case 'ar':
        return ar;
      case 'hi':
        return hi;
      case 'pt':
        return pt;
      case 'ru':
        return ru;
      case 'ta':
        return ta;
      default:
        return null;
    }
  }
}

const List<PhraseEntry> offlinePhrasebook = [
  PhraseEntry(
    en: 'hello',
    es: 'hola',
    fr: 'bonjour',
    de: 'hallo',
    zh: '你好',
    ja: 'こんにちは',
    ar: 'مرحبا',
    hi: 'नमस्ते',
    pt: 'olá',
    ru: 'здравствуйте',
    ta: 'வணக்கம்',
  ),
  PhraseEntry(
    en: 'how are you?',
    es: '¿cómo estás?',
    fr: 'comment allez-vous?',
    de: 'wie geht es ihnen?',
    zh: '你好吗？',
    ja: 'お元気ですか？',
    ar: 'كيف حالك؟',
    hi: 'आप कैसे हैं?',
    pt: 'como você está?',
    ru: 'как ваши дела?',
    ta: 'நீங்கள் எப்படி இருக்கிறீர்கள்?',
  ),
  PhraseEntry(
    en: 'thank you very much',
    es: 'muchas gracias',
    fr: 'merci beaucoup',
    de: 'vielen dank',
    zh: '非常感谢',
    ja: 'どうもありがとうございます',
    ar: 'شكرا جزيلا',
    hi: 'बहुत-बहुत धन्यवाद',
    pt: 'muito obrigado',
    ru: 'большое спасибо',
    ta: 'மிக்க நன்றி',
  ),
  PhraseEntry(
    en: 'thank you',
    es: 'gracias',
    fr: 'merci',
    de: 'danke',
    zh: '谢谢',
    ja: 'ありがとう',
    ar: 'شكرا',
    hi: 'धन्यवाद',
    pt: 'obrigado',
    ru: 'спасибо',
    ta: 'நன்றி',
  ),
  PhraseEntry(
    en: 'you are welcome',
    es: 'de nada',
    fr: 'de rien',
    de: 'gern geschehen',
    zh: '不客气',
    ja: 'どういたしまして',
    ar: 'عفوا',
    hi: 'आपका स्वागत है',
    pt: 'de nada',
    ru: 'пожалуйста',
    ta: 'வரவேற்கிறேன்',
  ),
  PhraseEntry(
    en: 'goodbye',
    es: 'adiós',
    fr: 'au revoir',
    de: 'auf wiedersehen',
    zh: '再见',
    ja: 'さようなら',
    ar: 'مع السلامة',
    hi: 'अलविदा',
    pt: 'adeus',
    ru: 'до свидания',
    ta: 'போய் வருகிறேன்',
  ),
  PhraseEntry(
    en: 'nice to meet you',
    es: 'encantado de conocerte',
    fr: 'ravi de vous rencontrer',
    de: 'schön, sie kennenzulernen',
    zh: '很高兴认识你',
    ja: 'はじめまして',
    ar: 'تشرفت بمعرفتك',
    hi: 'आपसे मिलकर अच्छा लगा',
    pt: 'prazer em conhecê-lo',
    ru: 'приятно познакомиться',
    ta: 'உங்களை சந்தித்ததில் மகிழ்ச்சி',
  ),
  PhraseEntry(
    en: 'system architecture',
    es: 'arquitectura del sistema',
    fr: 'architecture du système',
    de: 'systemarchitektur',
    zh: '系统架构',
    ja: 'システムアーキテクチャ',
    ar: 'هندسة النظام',
    hi: 'सिस्टम वास्तुकला',
    pt: 'arquitetura de sistema',
    ru: 'архитектура системы',
    ta: 'கணினி கட்டமைப்பு',
  ),
  PhraseEntry(
    en: 'action item',
    es: 'tarea pendiente',
    fr: 'élément daction',
    de: 'handlungsschritt',
    zh: '行动项',
    ja: 'アクションアイテム',
    ar: 'بند العمل',
    hi: 'कार्य मद',
    pt: 'item de ação',
    ru: 'пункт действия',
    ta: 'நடவடிக்கை உருப்படி',
  ),
  PhraseEntry(
    en: 'where is the railway station?',
    es: '¿dónde está la estación de ferrocarril?',
    fr: 'où est la gare?',
    de: 'wo ist der bahnhof?',
    zh: '火车站建在哪里？',
    ja: '駅はどこですか？',
    ar: 'أين محطة القطار؟',
    hi: 'रेलवे स्टेशन कहाँ है?',
    pt: 'onde fica a estação ferroviária?',
    ru: 'где находится вокзал?',
    ta: 'ரயில் நிலையம் எங்கே உள்ளது?',
  ),
  PhraseEntry(
    en: 'where is the train station?',
    es: '¿dónde está la estación de tren?',
    fr: 'où est la gare?',
    de: 'wo ist der bahnhof?',
    zh: '火车站建在哪里？',
    ja: '駅はどこですか？',
    ar: 'أين محطة القطار؟',
    hi: 'ट्रेन स्टेशन कहाँ है?',
    pt: 'onde fica a estação de trem?',
    ru: 'где станция поезда?',
    ta: 'ரயில் நிலையம் எங்கே உள்ளது?',
  ),
  PhraseEntry(
    en: 'what is zoology?',
    es: '¿qué es la zoología?',
    fr: 'qu\'est-ce que la zoologie?',
    de: 'was ist zoologie?',
    zh: '什么是动物学？',
    ja: '動物学とは何ですか？',
    ar: 'ما هو علم الحيوان؟',
    hi: 'प्राणी विज्ञान क्या है?',
    pt: 'o que é zoologia?',
    ru: 'что такое зоология?',
    ta: 'விலங்கியல் என்றால் என்ன?',
  ),
];

const Map<String, Map<String, String>> offlineLexicon = {
  'zoology': {
    'es': 'zoología',
    'fr': 'zoologie',
    'de': 'Zoologie',
    'zh': '动物学',
    'ja': '動物学',
    'ar': 'علم الحيوان',
    'hi': 'प्राणी विज्ञान',
    'pt': 'zoologia',
    'ru': 'зоология',
    'ta': 'விலங்கியல்',
  },
  'station': {
    'es': 'estación',
    'fr': 'gare',
    'de': 'Bahnhof',
    'zh': '站',
    'ja': '駅',
    'ar': 'محطة',
    'hi': 'स्टेशन',
    'pt': 'estação',
    'ru': 'станция',
    'ta': 'நிலையம்',
  },
  'railway': {
    'es': 'ferrocarril',
    'fr': 'chemin de fer',
    'de': 'Eisenbahn',
    'zh': '铁路',
    'ja': '鉄道',
    'ar': 'سكة حديدية',
    'hi': 'रेलवे',
    'pt': 'ferrovia',
    'ru': 'железная дорога',
    'ta': 'ரயில்',
  },
  'hello': {
    'es': 'hola',
    'fr': 'bonjour',
    'de': 'hallo',
    'zh': '你好',
    'ja': 'こんにちは',
    'ar': 'مرحبا',
    'hi': 'नमस्ते',
    'pt': 'olá',
    'ru': 'здравствуйте',
    'ta': 'வணக்கம்'
  },
  'world': {
    'es': 'mundo',
    'fr': 'monde',
    'de': 'welt',
    'zh': '世界',
    'ja': '世界',
    'ar': 'عالم',
    'hi': 'दुनिया',
    'pt': 'mundo',
    'ru': 'мир',
    'ta': 'உலகம்'
  },
  'welcome': {
    'es': 'bienvenido',
    'fr': 'bienvenue',
    'de': 'willkommen',
    'zh': '欢迎',
    'ja': '歓迎',
    'ar': 'أهلا بك',
    'hi': 'स्वागत',
    'pt': 'bem-vindo',
    'ru': 'добро пожаловать',
    'ta': 'நல்வரவு'
  },
  'yes': {
    'es': 'sí',
    'fr': 'oui',
    'de': 'ja',
    'zh': '是',
    'ja': 'はい',
    'ar': 'نعم',
    'hi': 'हाँ',
    'pt': 'sim',
    'ru': 'да',
    'ta': 'ஆம்'
  },
  'no': {
    'es': 'no',
    'fr': 'non',
    'de': 'nein',
    'zh': '不',
    'ja': 'いいえ',
    'ar': 'لا',
    'hi': 'नहीं',
    'pt': 'não',
    'ru': 'нет',
    'ta': 'இல்லை'
  },
  'please': {
    'es': 'por favor',
    'fr': 'sil vous plaît',
    'de': 'bitte',
    'zh': '请',
    'ja': 'お願いします',
    'ar': 'من فضلك',
    'hi': 'कृपया',
    'pt': 'por favor',
    'ru': 'пожалуйста',
    'ta': 'தயவுசெய்து'
  },
  'good': {
    'es': 'bueno',
    'fr': 'bon',
    'de': 'gut',
    'zh': '好',
    'ja': '良い',
    'ar': 'جيد',
    'hi': 'अच्छा',
    'pt': 'bom',
    'ru': 'хороший',
    'ta': 'நல்லது'
  },
  'morning': {
    'es': 'mañana',
    'fr': 'matin',
    'de': 'morgen',
    'zh': '早晨',
    'ja': '朝',
    'ar': 'صباح',
    'hi': 'सुबह',
    'pt': 'manhã',
    'ru': 'உட்ரோ',
    'ta': 'காலை'
  },
  'meeting': {
    'es': 'reunión',
    'fr': 'réunion',
    'de': 'besprechung',
    'zh': '会议',
    'ja': '会議',
    'ar': 'اجتماع',
    'hi': 'बैठक',
    'pt': 'reunião',
    'ru': 'встреча',
    'ta': 'கூட்டம்'
  },
  'interview': {
    'es': 'entrevista',
    'fr': 'entretien',
    'de': 'vorstellungsgespräch',
    'zh': '面试',
    'ja': '面接',
    'ar': 'مقابلة',
    'hi': 'साक्षात्कार',
    'pt': 'entrevista',
    'ru': 'интервью',
    'ta': 'நேர்காணல்'
  },
  'question': {
    'es': 'pregunta',
    'fr': 'question',
    'de': 'frage',
    'zh': '问题',
    'ja': '質問',
    'ar': 'سؤال',
    'hi': 'सवाल',
    'pt': 'pergunta',
    'ru': 'вопрос',
    'ta': 'கேள்வி'
  },
  'answer': {
    'es': 'respuesta',
    'fr': 'réponse',
    'de': 'antwort',
    'zh': '答案',
    'ja': '回答',
    'ar': 'إجابة',
    'hi': 'उत्तर',
    'pt': 'resposta',
    'ru': 'ответ',
    'ta': 'பதில்'
  },
  'project': {
    'es': 'proyecto',
    'fr': 'projet',
    'de': 'projekt',
    'zh': '项目',
    'ja': 'プロジェクト',
    'ar': 'مشروع',
    'hi': 'परियोजना',
    'pt': 'projeto',
    'ru': 'проект',
    'ta': 'திட்டம்'
  },
  'team': {
    'es': 'equipo',
    'fr': 'équipe',
    'de': 'team',
    'zh': '团队',
    'ja': 'チーム',
    'ar': 'فريق',
    'hi': 'टीम',
    'pt': 'equipe',
    'ru': 'команда',
    'ta': 'குழு'
  },
  'goal': {
    'es': 'meta',
    'fr': 'objectif',
    'de': 'ziel',
    'zh': '目标',
    'ja': '目標',
    'ar': 'هدف',
    'hi': 'लक्ष्य',
    'pt': 'meta',
    'ru': 'цель',
    'ta': 'இலக்கு'
  },
  'decision': {
    'es': 'decisión',
    'fr': 'décision',
    'de': 'entscheidung',
    'zh': '决定',
    'ja': '決定',
    'ar': 'قرار',
    'hi': 'निर्णय',
    'pt': 'decisão',
    'ru': 'решение',
    'ta': 'முடிவு'
  },
  'today': {
    'es': 'hoy',
    'fr': 'aujourdhui',
    'de': 'heute',
    'zh': '今天',
    'ja': '今日',
    'ar': 'اليوم',
    'hi': 'आज',
    'pt': 'hoje',
    'ru': 'сегодня',
    'ta': 'இன்று'
  },
  'important': {
    'es': 'importante',
    'fr': 'important',
    'de': 'wichtig',
    'zh': '重要',
    'ja': '重要',
    'ar': 'مهم',
    'hi': 'महत्वपूर्ण',
    'pt': 'importante',
    'ru': 'важный',
    'ta': 'முக்கியமானது'
  },
  'system': {
    'es': 'sistema',
    'fr': 'système',
    'de': 'system',
    'zh': '系统',
    'ja': 'システム',
    'ar': 'نظام',
    'hi': 'प्रणाली',
    'pt': 'sistema',
    'ru': 'система',
    'ta': 'அமைப்பு'
  },
  'data': {
    'es': 'datos',
    'fr': 'données',
    'de': 'daten',
    'zh': '数据',
    'ja': 'データ',
    'ar': 'بيانات',
    'hi': 'डेटा',
    'pt': 'dados',
    'ru': 'данные',
    'ta': 'தரவு'
  },
  'security': {
    'es': 'seguridad',
    'fr': 'sécurité',
    'de': 'sicherheit',
    'zh': '安全',
    'ja': 'セキュリティ',
    'ar': 'أمن',
    'hi': 'सुरक्षा',
    'pt': 'segurança',
    'ru': 'безопасность',
    'ta': 'பாதுகாப்பு'
  },
  'network': {
    'es': 'red',
    'fr': 'réseau',
    'de': 'netzwerk',
    'zh': '网络',
    'ja': 'ネットワーク',
    'ar': 'شبكة',
    'hi': 'नेटवर्क',
    'pt': 'rede',
    'ru': 'сеть',
    'ta': 'பிணையம்'
  },
  'science': {
    'es': 'ciencia',
    'fr': 'science',
    'de': 'wissenschaft',
    'zh': '科学',
    'ja': '科学',
    'ar': 'علم',
    'hi': 'विज्ञान',
    'pt': 'ciência',
    'ru': 'наука',
    'ta': 'அறிவியல்'
  },
  'mathematics': {
    'es': 'matemáticas',
    'fr': 'mathématiques',
    'de': 'mathematik',
    'zh': '数学',
    'ja': '数学',
    'ar': 'رياضيات',
    'hi': 'गणित',
    'pt': 'matemática',
    'ru': 'математика',
    'ta': 'கணிதம்'
  },
  'language': {
    'es': 'idioma',
    'fr': 'langue',
    'de': 'sprache',
    'zh': '语言',
    'ja': '言語',
    'ar': 'لغة',
    'hi': 'भाषा',
    'pt': 'língua',
    'ru': 'язык',
    'ta': 'மொழி'
  },
  'time': {
    'es': 'tiempo',
    'fr': 'temps',
    'de': 'zeit',
    'zh': '时间',
    'ja': '時間',
    'ar': 'وقت',
    'hi': 'समय',
    'pt': 'tempo',
    'ru': 'время',
    'ta': 'நேரம்'
  },
};
