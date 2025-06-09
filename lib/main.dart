import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:torch_light/torch_light.dart';
import 'package:vibration/vibration.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'भूकम्प जानकारी',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'NotoSansDevanagari',
      ),
      home: const QuakeReadyApp(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class QuakeReadyApp extends StatefulWidget {
  const QuakeReadyApp({super.key});

  @override
  _QuakeReadyAppState createState() => _QuakeReadyAppState();
}

class _QuakeReadyAppState extends State<QuakeReadyApp> {
  String _currentScreen = 'splash';
  int _selectedMenuIndex = 0;
  bool _isFlashlightOn = false;
  bool _isSirenPlaying = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInfoAudioPlaying = false;
  bool _isDosDontsAudioPlaying = false;
  bool _isRetrofittingAudioPlaying = false;
  int _quizCurrentQuestionIndex = 0;
  int _quizCorrectAnswers = 0;
  List<int?> _quizUserAnswers = [];
  bool _quizShowResults = false;
  String? _quizFeedbackMessage;
  bool _quizIsFeedbackShowing = false;
  int _gameCurrentIndex = 0;
  List<bool> _gameSelectedItems = List.filled(11, false);
  int _gameCorrectCount = 0;
  bool _gameOver = false;

  // Splash Screen Logic
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _currentScreen = 'home';
        });
      }
    });
    _quizQuestions.shuffle(Random());
    _quizSelectedQuestions = _quizQuestions.take(10).toList();
    for (var question in _quizSelectedQuestions) {
      List<String> options = List.from(question['options']);
      int correctIndex = question['correct'];
      String correctAnswer = options[correctIndex];
      options.shuffle(Random());
      question['options'] = options;
      question['correct'] = options.indexOf(correctAnswer);
    }
    _quizUserAnswers = List<int?>.filled(10, null);
    _gameItems.shuffle(Random());
  }

  // Audio Playback
  Future<void> _playAudio(String assetPath, {bool loop = false}) async {
    await _audioPlayer.stop();
    try {
      await _audioPlayer.setAsset(assetPath);
      if (loop) {
        await _audioPlayer.setLoopMode(LoopMode.all);
      } else {
        await _audioPlayer.setLoopMode(LoopMode.off);
      }
      await _audioPlayer.play();
      setState(() {
        if (assetPath == 'assets/siren.mp3') {
          _isSirenPlaying = true;
        } else if (assetPath == 'assets/audio/info_content.mp3') {
          _isInfoAudioPlaying = true;
        } else if (assetPath == 'assets/audio/dos_donts_content.mp3') {
          _isDosDontsAudioPlaying = true;
        } else if (assetPath == 'assets/audio/retrofitting_content.mp3') {
          _isRetrofittingAudioPlaying = true;
        }
      });
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed && !loop) {
          setState(() {
            if (assetPath == 'assets/audio/info_content.mp3') {
              _isInfoAudioPlaying = false;
            } else if (assetPath == 'assets/audio/dos_donts_content.mp3') {
              _isDosDontsAudioPlaying = false;
            } else if (assetPath == 'assets/audio/retrofitting_content.mp3') {
              _isRetrofittingAudioPlaying = false;
            }
          });
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('अडियो प्ले गर्न सकिएन: $e')),
      );
    }
    Vibration.vibrate(duration: 50);
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
    setState(() {
      _isInfoAudioPlaying = false;
      _isDosDontsAudioPlaying = false;
      _isRetrofittingAudioPlaying = false;
      _isSirenPlaying = false;
    });
    Vibration.vibrate(duration: 50);
  }

  // Flashlight Toggle
  Future<void> _toggleFlashlight() async {
    try {
      if (_isFlashlightOn) {
        await TorchLight.disableTorch();
      } else {
        await TorchLight.enableTorch();
      }
      setState(() {
        _isFlashlightOn = !_isFlashlightOn;
      });
      Vibration.vibrate(duration: 50);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('फ्ल्याशलाइट उपलब्ध छैन।'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Siren Toggle
  Future<void> _toggleSiren() async {
    try {
      if (_isSirenPlaying) {
        await _stopAudio();
      } else {
        await _playAudio('assets/siren.mp3', loop: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('सायरन आपतकालीन अवस्थामा प्रयोग गरिन्छ जब तपाईं बोल्न सक्नुहुन्न वा फस्नुभएको छ।'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('कृपया डिभाइसको भोल्युम १००% मा सेट गर्नुहोस्।'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('सायरन बजाउन सकिएन।'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Audio Toggles for Content Screens
  Future<void> _toggleInfoAudio() async {
    if (_isInfoAudioPlaying) {
      await _stopAudio();
    } else {
      await _playAudio('assets/audio/info_content.mp3');
    }
  }

  Future<void> _toggleDosDontsAudio() async {
    if (_isDosDontsAudioPlaying) {
      await _stopAudio();
    } else {
      await _playAudio('assets/audio/dos_donts_content.mp3');
    }
  }

  Future<void> _toggleRetrofittingAudio() async {
    if (_isRetrofittingAudioPlaying) {
      await _stopAudio();
    } else {
      await _playAudio('assets/audio/retrofitting_content.mp3');
    }
  }

  // Phone Call
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('फोन कल गर्न सकिएन।'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
    Vibration.vibrate(duration: 50);
  }

  // Menu Audio
  final List<String> _menuAudioFiles = [
    'assets/audio/samanya_jankari.mp3',
    'assets/audio/apatkalin_sampark.mp3',
    'assets/audio/garnuparne_nagarnuparne.mp3',
    'assets/audio/retrofit.mp3',
    'assets/audio/khelharu.mp3',
    '', // Placeholder for Credits (no audio)
  ];

  // Content from InfoScreen
  final String _infoContent = '''
के हो भूकम्प?

भूकम्प पृथ्वीको भित्री सतहमा हुने हलचलको परिणाम हो, जुन प्रायः टेक्टोनिक प्लेटहरूको आपसी टक्कर वा चापले उत्पन्न हुन्छ। जब यी प्लेटहरू चलायमान हुन्छन्, ऊर्जा सतहमा पहुँच्दछ, जसले जमिन हल्लिन्छ। यो हलचलले भवन, सडक, र अन्य संरचनाहरूलाई क्षति पुर्‍याउन सक्छ, र कहिलेकाहीँ मानवीय जीवनका लागि पनि खतरा सिर्जना गर्छ। भूकम्पको तीव्रता र प्रभाव मुख्य रूपमा म्याग्निच्युड र गहिराइमा निर्भर गर्छ।

नेपालको भूकम्पीय जोखिम

नेपाल हिमालय क्षेत्रमा अवस्थित छ, जुन विश्वकै सबैभन्दा सक्रिय भूकम्पीय क्षेत्रमध्ये एक हो। यो देश भारतीय र युरेसियन टेक्टोनिक प्लेटको सङ्कुचन क्षेत्रमा पर्छ, जसले गर्दा यहाँ वार्षिक रूपमा साना-ठूला भूकम्पहरू हुने गर्छन्। नेपालमा हरेक वर्ष औसतमा ५० भन्दा बढी भूकम्प महसुस हुन्छन्, र मध्येमा केहीले ठूलो क्षति पुर्‍याउँछन्। सजगता, सतर्कता, र पूर्व तयारीले मात्र हामी यी प्राकृतिक विपद्को जोखिम कम गर्न सक्छौं। रेट्रोफिटिंग जस्ता विधिहरूले पुराना भवनहरूलाई भूकम्प प्रतिरोधी बनाउन सकिन्छ, जसले जीवन र सम्पत्तिको क्षति न्यूनीकरण गर्छ।

नेपालका प्रमुख भूकम्पहरू

नेपालको इतिहासमा धेरै विनाशकारी भूकम्पहरू भएका छन्, जसले देशको संरचना र जनजीवनमा गहिरो प्रभाव पारेका छन्। यहाँ केही उल्लेखनीय घटनाहरू छन्:

वि.सं. १९९० (सन् १९३४): बिहार-नेपाल भूकम्प
म्याग्निच्युड ८.० को यो भूकम्पले काठमाडौं उपत्यका र पूर्वी नेपालमा ठूलो विनाश मच्चायो। करिब १०,००० मानिसको मृत्यु भयो, र सयौं गाउँहरू पूर्ण रूपमा ध्वस्त भए। आर्थिक क्षति र बस्तीको पुनर्निर्माणमा दशकौँ लाग्यो।
वि.सं. २०१५ (सन् १९५४): डोटी भूकम्प
म्याग्निच्युड ६.५ को यो भूकम्पले सुदूरपश्चिम नेपालमा करिब १५० जनाको जyan लियो र धेरै घरहरू भत्काए। यो घटनाले पहाडी क्षेत्रमा भूकम्पको जोखिमलाई पुनः उजागर गर्‍यो।
वि.सं. २०४५ (सन् १९८८): उत्तरी धनकुटा भूकम्प
म्याग्निच्युड ६.९ को यो भूकम्पले पूर्वी नेपालमा १,००० भन्दा बढीको मृत्यु र हजारौंको विस्थापन गरायो। सडक र पुलहरूमा ठूलो क्षति भयो, जसले उद्धार कार्यमा बाधा पुर्‍यायो।
वि.सं. २०७२ (सन् २०१५): गोरखा भूकम्प
म्याग्निच्युड ७.८ को यो विनाशकारी भूकम्पले नेपालको इतिहासमा हालसम्मकै ठूलो क्षति पुर्‍यायो। ९,००० भन्दा बढीको मृत्यु भयो, २२,००० भन्दा बढी घाइते भए, र ६ लाखभन्दा बढी घरहरू पूर्ण वा आंशिक रूपमा ध्वस्त भए। आर्थिक नोक्सानी करिब ७ अर्ब अमेरिकी डलर अनुमान गरिएको छ।
वि.सं. २०८० (सन् २०२३): पश्चिम नेपाल भूकम्प
म्याग्निच्युड ६.४ को यो भूकम्पले जाजरकोट र रुकुम क्षेत्रमा ठूलो प्रभाव पार्यो। १५७ जनाको मृत्यु भयो, र २५६ भन्दा बढी घाइते भए। पहाडी भूभागमा पहिरोको जोखिमले उद्धार कार्यमा थप चुनौती थपिएको थियो।
भूकम्प तयारीको महत्त्व

यी घटनाहरूले नेपालमा भूकम्प तयारी र बलियो संरचनाको आवश्यकतालाई प्रस्ट रूपमा देखाउँछन्। भूकम्पबाट बच्नको लागि परिवारसँग आपतकालीन योजना बनाउनुहोस्, सुरक्षित ठाउँ पहिचान गर्नुहोस्, र रेट्रोफिटिंग विशेषज्ञसँग परामर्श लिनुहोस्। यो जानकारीले मात्र नभई, यो एपको अन्य खण्डहरू (जस्तै: आपतकालीन सम्पर्क, गर्नुपर्ने/नगर्ने कुराहरू, र खेलहरू) प्रयोग गरेर आफ्नो र आफ्नो परिवारको सुरक्षाको लागि तयार रहन सिक्नुहोस्।
  ''';

  // Content from EmergencyContactsScreen
  final List<Map<String, String>> _emergencyContacts = const [
    {'name': 'राष्ट्रिय आपतकालीन नम्बर (नेपाल प्रहरी)', 'number': '100'},
    {'name': 'अग्नि नियन्त्रण (Fire Brigade / Dhamkal Service)', 'number': '101'},
    {'name': 'एम्बुलेन्स सेवा (National Ambulance)', 'number': '102'},
    {'name': 'राष्ट्रिय भूकम्प मापन केन्द्र', 'number': '01-5522322'},
    {'name': 'नेपाल रेडक्रस सोसाइटी', 'number': '01-4270650'},
    {'name': 'राष्ट्रिय आत्महत्या रोकथाम हटलाइन', 'number': '1166'},
    {'name': 'मानसिक अस्पताल, ललितपुर (Mental Hospital, Lagankhel)', 'number': '01-5521333'},
    {'name': 'कान्ति बाल अस्पताल (Child and Adolescent Psychiatry Unit)', 'number': '01-4225311'},
    {'name': 'टियु शिक्षण अस्पताल (TU Teaching Hospital - Mental Health Support)', 'number': '01-4502011'},
    {'name': 'प्रदेश नं. १ प्रहरी कार्यालय (Province 1 Police)', 'number': '021-521212'},
    {'name': 'प्रदेश नं. २ प्रहरी कार्यालय (Province 2 Police)', 'number': '041-521212'},
    {'name': 'बागमती प्रदेश प्रहरी कार्यालय (Bagmati Province Police)', 'number': '01-4261111'},
    {'name': 'गण्डकी प्रदेश प्रहरी कार्यालय (Gandaki Province Police)', 'number': '061-521212'},
    {'name': 'लुम्बिनी प्रदेश प्रहरी कार्यालय (Lumbini Province Police)', 'number': '081-521212'},
    {'name': 'कर्णाली प्रदेश प्रहरी कार्यालय (Karnali Province Police)', 'number': '083-521212'},
    {'name': 'सुदूरपश्चिम प्रदेश प्रहरी कार्यालय (Sudurpashchim Province Police)', 'number': '091-521212'},
    {'name': 'काठमाडौं अग्नि नियन्त्रण (Kathmandu Fire Brigade)', 'number': '01-4221111'},
    {'name': 'ललितपुर अग्नि नियन्त्रण (Lalitpur Fire Brigade)', 'number': '01-5521111'},
    {'name': 'राष्ट्रिय विपद् प्रतिकार्य हटलाइन (National Disaster Response)', 'number': '1149'},
    {'name': 'हेलिकप्टर उद्धार सेवा (Helicopter Rescue Service)', 'number': '01-4256909'},
    {'name': 'पर्यटक प्रहरी (Tourist Police Hotline)', 'number': '1144'},
    {'name': 'पर्यटक प्रहरी, भृकुटीमण्डप (Tourist Police, Bhrikuti Mandap)', 'number': '01-4247041'},
    {'name': 'नेपाल पर्यटन बोर्ड (Nepal Tourism Board)', 'number': '01-4256909'},
    {'name': 'काठमाडौं मोडेल अस्पताल एम्बुलेन्स (Kathmandu Model Hospital)', 'number': '01-4240805'},
    {'name': 'ललितपुर नगरपालिका एम्बुलेन्स (Lalitpur Municipality)', 'number': '01-5527003'},
    {'name': 'परोपकार एम्बुलेन्स (Paropakar Ambulance)', 'number': '01-4251614'},
    {'name': 'ट्राफिक प्रहरी (Traffic Police)', 'number': '103'},
    {'name': 'बाल हेल्पलाइन (Child Helpline)', 'number': '104'},
    {'name': 'हराइरहेका बालबालिका प्रतिक्रिया (Missing Child Response)', 'number': '1098'},
    {'name': 'हेल्पलाइन (Nepal Telecom Helpline)', 'number': '197'},
  ];

  // Content from DosDontsScreen
  final List<String> _dos = const [
    '🧘 शान्त रहनुहोस् – डराउनु भएन, होसियार हुनुहोस्',
    '🧎‍♂️ Drop, 🛏 Cover, ✋ Hold अपनाउनुहोस् (Drop: घुँडामा बस्नुहोस्, Cover: टेबुलमुनि लुक्नुहोस्, Hold: टेबुल समात्नुहोस्)',
    '🌳 खुला ठाउँ नजिक हुनुहुन्छ भने त्यता जानुहोस् (बिजुलीको पोल वा भवनबाट टाढा)',
    '🛑 ग्यास र बिजुली बन्द गर्नुहोस् यदि सुरक्षित रुपमा गर्न सकिन्छ भने',
    '🎒 आपतकालीन किट तयार राख्नुहोस् – टर्च, औषधि, पानी, साना खाद्यपदार्थ',
    '📻 रेडियो वा मोबाइलबाट सूचना सुन्नुहोस् – आधिकारिक स्रोतमा भरपर्नुहोस्',
  ];

  final List<String> _donts = const [
    'खुला ठाउँमा नभाग्नुहोस् जबसम्म सुरक्षित छैन',
    'सिँढी प्रयोग नगर्नुहोस्',
    'खतरनाक ठाउँमा नजानुहोस्',
    'रेट्रोफिटिंग बिना पुरानो भवनमा नबस्नुहोस्',
  ];

  // Content from RetrofittingScreen
  final String _retrofittingContent = '''
रेट्रोफिटिंग भनेको के हो?
रेट्रोफिटिंग भनेको पुराना भवनहरूलाई भूकम्प प्रतिरोधी बनाउन संरचनात्मक सुधार गर्ने प्रक्रिया हो। यसमा भित्ता, पिलर, र जगलाई बलियो बनाउने, स्टिल ब्रेसिंग थप्ने, वा अन्य प्राविधिक विधिहरू प्रयोग गरिन्छ।

रेट्रोफिटिंग किन महत्त्वपूर्ण छ?
- सुरक्षा: रेट्रोफिटिंगले भूकम्पको समयमा भवन ढल्ने जोखिम कम गर्छ, जसले मानवीय क्षति घटाउँछ।
- लागत प्रभावी: नयाँ भवन बनाउनुभन्दा रेट्रोफिटिंग सस्तो हुन्छ।
- संरक्षण: ऐतिहासिक वा सांस्कृतिक महत्त्वका भवनहरूलाई जोगाउन रेट्रोफिटिंग उपयोगी छ।
- पर्यावरणीय फाइदा: नयाँ निर्माणको तुलनामा रेट्रोफिटिंगले कम स्रोत प्रयोग गर्छ।

कहिले रेट्रोफिटिंग गर्ने, नयाँ बनाउने होइन?
- भवनको अवस्था: यदि भवनको आधारभूत संरचना बलियो छ र केवल सुदृढीकरण आवश्यक छ भने रेट्रोफिटिंग उपयुक्त हुन्छ।
- बजेट: नयाँ भवन बनाउन आर्थिक स्रोत नभएमा रेट्रोफिटिंग राम्रो विकल्प हो।
- समय: रेट्रोफिटिंग छिटो हुन्छ, जबकि नयाँ निर्माणमा समय लाग्छ।
- सांस्कृतिक मूल्य: यदि भवन ऐतिहासिक वा सांस्कृतिक रूपमा महत्त्वपूर्ण छ भने रेट्रोफिटिंग प्राथमिकता हुन्छ।
- ठूलो क्षति: यदि भवन पूर्ण रूपमा कमजोर वा ध्वस्त छ भने नयाँ निर्माण उपयुक्त हुन्छ।

रेट्रोफिटिंग विशेषज्ञसँग परामर्श लिनुहोस् र आफ्नो घरको मूल्याङ्कन गर्नुहोस्।
  ''';

  // Content from QuizScreen
  final List<Map<String, dynamic>> _quizQuestions = [
    {
      'question': 'भूकम्पको समयमा सबैभन्दा सुरक्षित कुन हो?',
      'options': ['टेबल मुनि बस्ने', 'सिँढीमा भाग्ने', 'खुला ठाउँमा उभिने', 'लिफ्ट प्रयोग गर्ने'],
      'correct': 0,
      'explanation': 'टेबल मुनि बस्दा झर्ने वस्तुबाट जोगिन सकिन्छ।'
    },
    {
      'question': 'आपतकालीन झोलामा के राख्नुपर्छ?',
      'options': ['पानी', 'खेलौना', 'लक्जरी गहना', 'टेलिभिजन'],
      'correct': 0,
      'explanation': 'पानी आपतकालीन अवस्थामा जीवन रक्षाको लागि आवश्यक छ।'
    },
    {
      'question': 'रेट्रोफिटिंगको मुख्य उद्देश्य के हो?',
      'options': ['भवन बलियो बनाउने', 'भवन सजाउने', 'भवन ठूलो बनाउने', 'भवन सस्तो बनाउने'],
      'correct': 0,
      'explanation': 'रेट्रोफिटिंगले भवनलाई भूकम्प प्रतिरोधी बनाउँछ।'
    },
    {
      'question': 'भूकम्प अभ्यासको नाम के हो?',
      'options': ['Drop, Cover, Hold', 'Run, Hide, Seek', 'Jump, Duck, Roll', 'Stand, Watch, Wait'],
      'correct': 0,
      'explanation': 'Drop, Cover, Hold भूकम्पको समयमा सुरक्षित रहने अभ्यास हो।'
    },
    {
      'question': 'भूकम्पको समयमा सिँढी प्रयोग गर्नु...',
      'options': ['खतरनाक हो', 'सुरक्षित हो', 'आवश्यक हो', 'रमाइलो हो'],
      'correct': 0,
      'explanation': 'सिँढी प्रयोग गर्दा चोटपटक लाग्ने जोखिम हुन्छ।'
    },
    {
      'question': 'आपतकालीन सम्पर्क योजना किन महत्त्वपूर्ण छ?',
      'options': ['परिवारलाई जोड्न', 'खाना पकाउन', 'टिभी हेर्न', 'खेल खेल्न'],
      'correct': 0,
      'explanation': 'सम्पर्क योजनाले आपतकालमा परिवारलाई एकजुट गर्न मद्दत गर्छ।'
    },
    {
      'question': 'रेट्रोफिटिंगले के कम गर्छ?',
      'options': ['भूकम्पको क्षति', 'घरको मूल्य', 'घरको साइज', 'बिजुली खपत'],
      'correct': 0,
      'explanation': 'रेट्रोफिटिंगले भूकम्पको समयमा भवनको क्षति कम गर्छ।'
    },
    {
      'question': 'भूकम्पको समयमा टाउको कसरी जोगाउने?',
      'options': ['हातले ढाक्ने', 'कपडाले ढाक्ने', 'कुनै ढाक्नु नपर्ने', 'प्लास्टिकले ढाक्ने'],
      'correct': 0,
      'explanation': 'हातले टाउको ढाक्दा झर्ने वस्तुबाट जोगिन सकिन्छ।'
    },
    {
      'question': 'आपतकालीन झोलामा खाना कति दिनको राख्ने?',
      'options': ['३ दिन', '१ दिन', '१ हप्ता', '१ महिना'],
      'correct': 0,
      'explanation': '३ दिनको खाना आपतकालीन अवस्थाको लागि पर्याप्त हुन्छ।'
    },
    {
      'question': 'भूकम्पको जोखिम कम गर्न के गर्नुपर्छ?',
      'options': ['पूर्व तयारी', 'टिभी हेर्ने', 'खेल्ने', 'सुत्ने'],
      'correct': 0,
      'explanation': 'पूर्व तयारीले भूकम्पको जोखिम कम गर्न सकिन्छ।'
    },
    {
      'question': 'भूकम्पको समयमा लिफ्ट प्रयोग गर्नु...',
      'options': ['खतरनाक हो', 'सुरक्षित हो', 'आवश्यक हो', 'सजिलो हो'],
      'correct': 0,
      'explanation': 'लिफ्टमा फस्ने जोखिम हुन्छ, त्यसैले प्रयोग गर्नु हुँदैन।'
    },
    {
      'question': 'रेट्रोफिटिंग कसले गर्नुपर्छ?',
      'options': ['विशेषज्ञ', 'सबैले', 'कसैले पनि', 'बच्चाहरूले'],
      'correct': 0,
      'explanation': 'विशेषज्ञले रेट्रोफिटिंग गर्दा सुरक्षित र प्रभावकारी हुन्छ।'
    },
    {
      'question': 'आपतकालीन झोलामा फ्ल्याशलाइट किन राख्ने?',
      'options': ['उज्यालोको लागि', 'खेल्नको लागि', 'सजाउनको लागि', 'बेच्नको लागि'],
      'correct': 0,
      'explanation': 'फ्ल्याशलाइटले अँध्यारोमा उज्यालो प्रदान गर्छ।'
    },
    {
      'question': 'भूकम्पको समयमा शान्त रहनु...',
      'options': ['महत्त्वपूर्ण हो', 'अनावश्यक हो', 'खतरनाक हो', 'रमाइलो हो'],
      'correct': 0,
      'explanation': 'शान्त रहँदा सही निर्णय लिन सकिन्छ।'
    },
    {
      'question': 'रेट्रोफिटिंग बिना पुरानो भवन...',
      'options': ['खतरनाक हुन्छ', 'सुरक्षित हुन्छ', 'सुन्दर हुन्छ', 'सस्तो हुन्छ'],
      'correct': 0,
      'explanation': 'रेट्रोफिटिंग बिना पुरानो भवन भूकम्पमा जोखिमपूर्ण हुन्छ।'
    },
    {
      'question': 'आपतकालीन झोलामा रेडियो किन राख्ने?',
      'options': ['सूचना सुन्न', 'गाना सुन्न', 'खेल्न', 'सजाउन'],
      'correct': 0,
      'explanation': 'रेडियोले आपतकालीन सूचना प्राप्त गर्न मद्दत गर्छ।'
    },
    {
      'question': 'भूकम्पको समयमा खुला ठाउँमा कहिले जाने?',
      'options': ['सुरक्षित भएपछि', 'तुरुन्तै', 'कहिल्यै नजाने', 'राति मात्र'],
      'correct': 0,
      'explanation': 'सुरक्षित भएपछि मात्र खुला ठाउँमा जानु उचित हुन्छ।'
    },
    {
      'question': 'रेट्रोफिटिंगले भवनको आयु...',
      'options': ['बढाउँछ', 'घटाउँछ', 'परिवर्तन गर्दैन', 'शून्य बनाउँछ'],
      'correct': 0,
      'explanation': 'रेट्रोफिटिंगले भवनको बलियोपन र आयु बढाउँछ।'
    },
    {
      'question': 'आपतकालीन झोलामा प्राथमिक उपचार किट...',
      'options': ['आवश्यक छ', 'अनावश्यक छ', 'खतरनाक छ', 'सजावटी छ'],
      'correct': 0,
      'explanation': 'प्राथमिक उपचार किटले सानोतिनो चोटपटकको उपचारमा सहयोग गर्छ।'
    },
    {
      'question': 'भूकम्पको तयारीले के गर्छ?',
      'options': ['जोखिम कम गर्छ', 'जोखिम बढाउँछ', 'कुनै प्रभाव पार्दैन', 'मनोरञ्जन दिन्छ'],
      'correct': 0,
      'explanation': 'तयारीले भूकम्पको जोखिम र क्षति कम गर्छ।'
    },
  ];
  List<Map<String, dynamic>> _quizSelectedQuestions = [];

  // Content from EmergencyKitGameScreen
  final List<Map<String, dynamic>> _gameItems = [
    {'name': 'पानी', 'isCorrect': true},
    {'name': 'खाना', 'isCorrect': true},
    {'name': 'प्राथमिक उपचार किट', 'isCorrect': true},
    {'name': 'फ्ल्याशलाइट', 'isCorrect': true},
    {'name': 'रेडियो', 'isCorrect': true},
    {'name': 'कपडा', 'isCorrect': true},
    {'name': 'कागजातको प्रतिलिपि', 'isCorrect': true},
    {'name': 'टेलिभिजन', 'isCorrect': false},
    {'name': 'खेलौना', 'isCorrect': false},
    {'name': 'लक्जरी गहना', 'isCorrect': false},
    {'name': 'ल्यापटप', 'isCorrect': false},
  ];

  // Quiz Logic
  void _answerQuestion(int selectedIndex) {
    setState(() {
      _quizUserAnswers[_quizCurrentQuestionIndex] = selectedIndex;
      _quizIsFeedbackShowing = true;
      if (selectedIndex == _quizSelectedQuestions[_quizCurrentQuestionIndex]['correct']) {
        _quizCorrectAnswers++;
        _quizFeedbackMessage = 'तपाईं भूकम्प सुरक्षाको बाटोमा हुनुहुन्छ!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_quizFeedbackMessage!),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        _quizFeedbackMessage =
        'गलत! सही जवाफ: ${_quizSelectedQuestions[_quizCurrentQuestionIndex]['options'][_quizSelectedQuestions[_quizCurrentQuestionIndex]['correct']]}\nविवरण: ${_quizSelectedQuestions[_quizCurrentQuestionIndex]['explanation']}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_quizFeedbackMessage!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && !_quizShowResults) {
          setState(() {
            _quizIsFeedbackShowing = false;
            _nextQuestion();
          });
        }
      });
    });
  }

  void _nextQuestion() {
    if (_quizCurrentQuestionIndex < 9) {
      _quizCurrentQuestionIndex++;
      _quizFeedbackMessage = null;
    } else {
      _quizShowResults = true;
    }
  }

  void _resetQuiz() {
    setState(() {
      _quizCurrentQuestionIndex = 0;
      _quizCorrectAnswers = 0;
      _quizUserAnswers = List<int?>.filled(10, null);
      _quizShowResults = false;
      _quizFeedbackMessage = null;
      _quizIsFeedbackShowing = false;
      _quizQuestions.shuffle(Random());
      _quizSelectedQuestions = _quizQuestions.take(10).toList();
      for (var question in _quizSelectedQuestions) {
        List<String> options = List.from(question['options']);
        int correctIndex = question['correct'];
        String correctAnswer = options[correctIndex];
        options.shuffle(Random());
        question['options'] = options;
        question['correct'] = options.indexOf(correctAnswer);
      }
    });
    Vibration.vibrate(duration: 50);
  }

  // Emergency Kit Game Logic
  void _selectGameItem(bool include) {
    if (_gameCurrentIndex >= _gameItems.length || _gameOver) return;
    setState(() {
      if (include && _gameItems[_gameCurrentIndex]['isCorrect']) {
        _gameCorrectCount++;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('सही छ! यो आपतकालीन किटको लागि आवश्यक छ!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (!include && !_gameItems[_gameCurrentIndex]['isCorrect']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('सही निर्णय! यो आवश्यक छैन।'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (include && !_gameItems[_gameCurrentIndex]['isCorrect']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('गलत! यो आवश्यक छैन।'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (!include && _gameItems[_gameCurrentIndex]['isCorrect']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ओहो! यो आवश्यक थियो।'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      _gameSelectedItems[_gameCurrentIndex] = include;
      if (_gameCurrentIndex < _gameItems.length - 1) {
        _gameCurrentIndex++;
      } else {
        _gameOver = true;
      }
    });
    Vibration.vibrate(duration: 50);
  }

  void _resetGame() {
    setState(() {
      _gameCurrentIndex = 0;
      _gameCorrectCount = 0;
      _gameOver = false;
      _gameSelectedItems = List.filled(11, false);
      _gameItems.shuffle(Random());
    });
    Vibration.vibrate(duration: 50);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    if (_isFlashlightOn) {
      TorchLight.disableTorch();
    }
    super.dispose();
  }

  // Single build method
  @override
  Widget build(BuildContext context) {
    if (_currentScreen == 'quiz') {
      return _buildQuizScreen();
    } else if (_currentScreen == 'game') {
      return WillPopScope(
        onWillPop: () async {
          setState(() {
            _currentScreen = 'home';
            _selectedMenuIndex = 4;
          });
          return false;
        },
        child: _buildGameScreen(),
      );
    } else if (_currentScreen == 'splash') {
      return Scaffold(
        backgroundColor: const Color(0xFF932A31),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/quakeready_logo.png',
                height: 150,
                width: 150,
              ),
              const SizedBox(height: 20),
              const Text(
                'QuakeReady नेपाल',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              Image.asset(
                'assets/yfgn_logo.png',
                height: 100,
                width: 100,
              ),
              const SizedBox(height: 20),
              const Text(
                'Developed by Youth for Good Nepal',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_currentScreen == 'home') {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'QuakeReady नेपाल',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF932A31),
        ),
        body: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 150,
                    color: const Color(0xFFE0E0E0),
                    child: Column(
                      children: [
                        _buildMenuItem(0, 'सामान्य जानकारी'),
                        _buildMenuItem(1, 'आपतकालीन सम्पर्क'),
                        _buildMenuItem(2, 'गर्नुपर्ने/नगर्ने'),
                        _buildMenuItem(3, 'रेट्रोफिटिंग'),
                        _buildMenuItem(4, 'खेलहरू'),
                        _buildMenuItem(5, 'क्रेडिट'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _buildContentScreen(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFlashlightOn ? Colors.grey : Colors.white,
                      padding: const EdgeInsets.all(20),
                      shape: const CircleBorder(),
                    ),
                    onPressed: _toggleFlashlight,
                    child: const Text(
                      '🔦',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 40),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSirenPlaying ? Colors.grey : Colors.white,
                      padding: const EdgeInsets.all(20),
                      shape: const CircleBorder(),
                    ),
                    onPressed: _toggleSiren,
                    child: const Text(
                      '🚨',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.all(8.0),
              child: const Text(
                'Developed by Youth for Good Nepal',
                style: TextStyle(fontSize: 14, color: Colors.black),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildMenuItem(int index, String title) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMenuIndex = index;
          _currentScreen = 'home';
        });
        if (_menuAudioFiles[index].isNotEmpty) {
          _playAudio(_menuAudioFiles[index]);
        }
      },
      child: Container(
        height: 60,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: _selectedMenuIndex == index ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey, width: 1),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: const Color(0xFF932A31),
              fontWeight: _selectedMenuIndex == index ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildContentScreen() {
    switch (_selectedMenuIndex) {
      case 0: // Info Screen
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _toggleInfoAudio,
                      icon: Text(
                        '🔊',
                        style: TextStyle(
                          fontSize: 24,
                          color: _isInfoAudioPlaying ? Colors.blue : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _infoContent,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        );

      case 1: // Emergency Contacts Screen
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: _emergencyContacts.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: const Icon(Icons.phone, color: Colors.blue),
              title: Text(_emergencyContacts[index]['name']!),
              subtitle: GestureDetector(
                onTap: () => _makePhoneCall(_emergencyContacts[index]['number']!),
                child: Text(
                  _emergencyContacts[index]['number']!,
                  style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                ),
              ),
            );
          },
        );

      case 2: // Do's and Don'ts Screen
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _toggleDosDontsAudio,
                      icon: Text(
                        '🔊',
                        style: TextStyle(
                          fontSize: 24,
                          color: _isDosDontsAudioPlaying ? Colors.blue : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  '✅ गर्नुपर्ने कुराहरू:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._dos.map((e) => ListTile(
                  leading: const Icon(Icons.check, color: Colors.green),
                  title: Text(e),
                )),
                const SizedBox(height: 16),
                const Text(
                  '❌ नगर्नुपर्ने कुराहरू:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._donts.map((e) => ListTile(
                  leading: const Icon(Icons.close, color: Colors.red),
                  title: Text(e),
                )),
              ],
            ),
          ),
        );

      case 3: // Retrofitting Screen
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _toggleRetrofittingAudio,
                      icon: Text(
                        '🔊',
                        style: TextStyle(
                          fontSize: 24,
                          color: _isRetrofittingAudioPlaying ? Colors.blue : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _retrofittingContent,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        );

      case 4: // Games Selection Screen
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'खेलहरू छान्नुहोस्',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                ),
                onPressed: () {
                  setState(() {
                    _currentScreen = 'quiz';
                  });
                  Vibration.vibrate(duration: 50);
                },
                child: const Text(
                  'क्विज',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                ),
                onPressed: () {
                  setState(() {
                    _currentScreen = 'game';
                  });
                  Vibration.vibrate(duration: 50);
                },
                child: const Text(
                  'आपतकालीन किट खेल',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        );

      case 5: // Credits Screen
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'क्रेडिट',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Text(
                  'डेभलपर:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'प्रमेश भट्टराई',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                const Text(
                  'आइडिया र इनपुट:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'अमन कोइराला\nअञ्जिला भट्टराई\nसेसन पौडेल\nश्री कृष्ण ढकाल\nमिलन कोइराला',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildQuizScreen() {
    double safetyScore = _quizCorrectAnswers / 10;
    return Scaffold(
      appBar: AppBar(
        title: const Text('क्विज'),
        backgroundColor: Colors.teal,
      ),
      body: _quizShowResults
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'तपाईंको स्कोर: $_quizCorrectAnswers/10',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _resetQuiz();
                setState(() {
                  _currentScreen = 'quiz';
                });
              },
              child: const Text('फेरि खेल्नुहोस्'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentScreen = 'home';
                  _selectedMenuIndex = 4;
                });
              },
              child: const Text('फर्कनुहोस्'),
            ),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: safetyScore,
              backgroundColor: Colors.red,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 10,
            ),
            const SizedBox(height: 16),
            Text(
              'प्रश्न ${_quizCurrentQuestionIndex + 1}/10',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _quizSelectedQuestions[_quizCurrentQuestionIndex]['question'],
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ...List.generate(
              _quizSelectedQuestions[_quizCurrentQuestionIndex]['options'].length,
                  (index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _quizUserAnswers[_quizCurrentQuestionIndex] == null
                        ? Colors.blue
                        : index == _quizSelectedQuestions[_quizCurrentQuestionIndex]['correct']
                        ? Colors.green
                        : _quizUserAnswers[_quizCurrentQuestionIndex] == index
                        ? Colors.red
                        : Colors.blue,
                  ),
                  onPressed: _quizUserAnswers[_quizCurrentQuestionIndex] == null
                      ? () {
                    _answerQuestion(index);
                    Vibration.vibrate(duration: 50);
                  }
                      : null,
                  child: Text(
                    _quizSelectedQuestions[_quizCurrentQuestionIndex]['options'][index],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('आपतकालीन किट खेल'),
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _currentScreen = 'home';
              _selectedMenuIndex = 4;
            });
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.yellow, Colors.green],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: _gameOver
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'खेल समाप्त! स्कोर: $_gameCorrectCount/7',
                style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: () {
                  _resetGame();
                  setState(() {
                    _currentScreen = 'game';
                  });
                },
                child: const Text(
                  'फेरि खेल्नुहोस्',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentScreen = 'home';
                    _selectedMenuIndex = 4;
                  });
                },
                child: const Text('फर्कनुहोस्'),
              ),
            ],
          )
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _gameItems[_gameCurrentIndex]['name'],
                style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                    onPressed: () => _selectGameItem(true),
                    child: const Text(
                      'राख्नुहोस्',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                    onPressed: () => _selectGameItem(false),
                    child: const Text(
                      'हटाउनुहोस्',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}