import 'dart:async';
import 'dart:js' as js;
import 'package:flutter/material.dart';

void main() {
  runApp(const RuralLinkLogisticsApp());
}

class RuralLinkLogisticsApp extends StatelessWidget {
  const RuralLinkLogisticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RURAL Link AI - Rural Logistics & Transit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFFE65100),
          surface: Colors.white,
        ),
      ),
      home: const RuralLinkChatScreen(),
    );
  }
}

class RuralLinkChatScreen extends StatefulWidget {
  const RuralLinkChatScreen({super.key});

  @override
  State<RuralLinkChatScreen> createState() => _RuralLinkChatScreenState();
}

class _RuralLinkChatScreenState extends State<RuralLinkChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAiTyping = false;
  String _selectedLanguage = 'मराठी';

  late AnimationController _pulseController;
  late List<Map<String, dynamic>> _messages;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _initAdvancedVoiceEngine();
    _messages = [
      {
        'isUser': false,
        'text': _getWelcomeMessage(),
        'type': 'welcome',
        'time': 'Just now',
      }
    ];
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _initAdvancedVoiceEngine() {
    try {
      js.context.callMethod('eval', [r'''
        window.getBestIndianVoice = function(lang) {
          var voices = window.speechSynthesis.getVoices();
          if (!voices || voices.length === 0) return null;
          var target = lang === 'मराठी' ? 'mr' : (lang === 'हिन्दी' ? 'hi' : 'en');
          
          for (var i = 0; i < voices.length; i++) {
            var v = voices[i];
            if (v.lang && v.lang.toLowerCase().indexOf(target) !== -1) {
              return v;
            }
          }
          for (var j = 0; j < voices.length; j++) {
            if (voices[j].lang && voices[j].lang.indexOf('IN') !== -1) {
              return voices[j];
            }
          }
          return voices[0];
        };

        if ('speechSynthesis' in window) {
          window.speechSynthesis.onvoiceschanged = function() {
            window.getBestIndianVoice('मराठी');
          };
        }

        window.speakRuralLink = function(text, lang) {
          try {
            if (!('speechSynthesis' in window)) return;
            window.speechSynthesis.cancel();
            var utterance = new SpeechSynthesisUtterance(text);
            var voice = window.getBestIndianVoice(lang);
            if (voice) utterance.voice = voice;
            utterance.lang = lang === 'मराठी' ? 'mr-IN' : (lang === 'हिन्दी' ? 'hi-IN' : 'en-IN');
            utterance.rate = 0.92;
            utterance.pitch = 1.0;
            window.speechSynthesis.speak(utterance);
          } catch(e) {}
        };

        window.startHardwareMicRecognition = function(langCode, onSpeechResult, onSpeechEnd, onStatusUpdate, onError) {
          try {
            var Speech = window.webkitSpeechRecognition || window.SpeechRecognition;
            if (!Speech) {
              if (onError) onError('Web Speech API is not supported in this browser.');
              return false;
            }

            if (window._ruralLinkSpeechRec) {
              try { window._ruralLinkSpeechRec.abort(); } catch(e) {}
            }

            var rec = new Speech();
            rec.continuous = true;
            rec.interimResults = true;
            rec.lang = langCode;

            rec.onstart = function() {
              if (onStatusUpdate) onStatusUpdate('Microphone active. Listening to speech...');
            };

            rec.onspeechstart = function() {
              if (onStatusUpdate) onStatusUpdate('Sound detected! Transcribing...');
            };

            rec.onresult = function(event) {
              var fullStr = '';
              for (var i = 0; i < event.results.length; i++) {
                fullStr += event.results[i][0].transcript;
              }
              if (fullStr && onSpeechResult) {
                onSpeechResult(fullStr);
              }
            };

            rec.onend = function() {
              if (onSpeechEnd) onSpeechEnd();
            };

            rec.onerror = function(err) {
              var errMsg = err ? (err.error || err.message || 'Unknown') : 'error';
              if (onError) onError(errMsg);
            };

            rec.start();
            window._ruralLinkSpeechRec = rec;
            return true;
          } catch(e) {
            if (onError) onError(e.toString());
            return false;
          }
        };

        window.stopHardwareMicRecognition = function() {
          if (window._ruralLinkSpeechRec) {
            try { window._ruralLinkSpeechRec.stop(); } catch(e) {}
          }
        };
      ''']);
    } catch (_) {}
  }

  void _speakAloud(String text) {
    String clean = text.replaceAll(RegExp(r'[*_#`■▲▼•🚜💰🤝🛣️📈📍]'), '');
    try {
      js.context.callMethod('speakRuralLink', [clean, _selectedLanguage]);
    } catch (_) {}
  }

  String _getWelcomeMessage() {
    if (_selectedLanguage == 'मराठी') {
      return '🌾 **नमस्कार! RURAL Link AI मध्ये आपले स्वागत आहे.**\n\nआपण **माईक 🎙️** वर बोलू शकता किंवा खालील १ ते ५ क्रमांकांचा पर्याय निवडून विचारू शकता:\n1. 🚜 **वाहन बुकिंग (Truck/Tractor)**\n2. 💰 **वाहतूक भाडे अंदाज**\n3. 🤝 **शेतकरी गट वाहतूक (Pooling)**\n4. 🛣️ **रस्ता व हवामान स्थिती**\n5. 📈 **आजचे बाजारभाव (Mandi Rates)**';
    } else if (_selectedLanguage == 'हिन्दी') {
      return '🌾 **नमस्ते! RURAL Link AI में आपका स्वागत है।**\n\nआप **माइक 🎙️** से बोल सकते हैं या 1 से 5 नंबर लिखकर पूछ सकते हैं:\n1. 🚜 **गाड़ी बुकिंग (Truck/Tractor)**\n2. 💰 **भाड़ा अनुमान (Cost Estimate)**\n3. 🤝 **किसान ग्रुप पूलिंग (Pooling)**\n4. 🛣️ **सड़क व मौसम स्थिति**\n5. 📈 **आज का मंडी भाव (Mandi Rates)**';
    } else {
      return '🌾 **Namaste & Welcome to RURAL Link AI!**\n\nYou can speak via the **Mic 🎙️** or type options 1 to 5:\n1. 🚜 **Vehicle Booking (Truck/Tractor)**\n2. 💰 **Freight Cost Estimate**\n3. 🤝 **Shared Group Pooling**\n4. 🛣️ **Road & Weather Status**\n5. 📈 **Live Mandi Rates**';
    }
  }

  void _switchLanguage(String newLang) {
    setState(() {
      _selectedLanguage = newLang;
      if (_messages.isNotEmpty && _messages[0]['type'] == 'welcome') {
        _messages[0]['text'] = _getWelcomeMessage();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('भाषा बदलली: $newLang / Language switched to $newLang'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF2E7D32),
      ),
    );
  }

  List<String> _getQuickSuggestions() {
    if (_selectedLanguage == 'मराठी') {
      return [
        '🌾 १. वाहन बुकिंग (Transport)',
        '💰 २. वाहतूक खर्च (Cost)',
        '🚚 ३. शेतकरी गट (Pooling)',
        '🛣️ ४. रस्ता स्थिती (Road)',
        '📈 ५. आजचे बाजारभाव (Mandi)',
        '📍 थेट ट्रॅकिंग (Tracking)',
      ];
    } else if (_selectedLanguage == 'हिन्दी') {
      return [
        '🌾 1. गाड़ी बुकिंग (Transport)',
        '💰 2. भाड़ा अनुमान (Cost)',
        '🚚 3. किसान ग्रुप (Pooling)',
        '🛣️ 4. सड़क स्थिति (Road)',
        '📈 5. मंडी भाव (Mandi)',
        '📍 लाइव ट्रैकिंग (Tracking)',
      ];
    } else {
      return [
        '🌾 1. Book Transport',
        '💰 2. Estimate Cost',
        '🚚 3. Freight Pooling',
        '🛣️ 4. Road Status',
        '📈 5. Mandi Rates',
        '📍 Live Tracking',
      ];
    }
  }

  void _openLiveVoiceAssistant() {
    String liveSpoken = '';
    String statusInfo = 'माईक चालू आहे... बोला!';
    bool isRecording = true;

    String langCode = _selectedLanguage == 'मराठी'
        ? 'mr-IN'
        : (_selectedLanguage == 'हिन्दी' ? 'hi-IN' : 'en-IN');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (isRecording) {
              try {
                js.context.callMethod('startHardwareMicRecognition', [
                  langCode,
                  js.allowInterop((dynamic text) {
                    setModalState(() {
                      liveSpoken = text.toString();
                      statusInfo = 'Transcription received!';
                    });
                  }),
                  js.allowInterop(() {}),
                  js.allowInterop((dynamic status) {
                    setModalState(() {
                      statusInfo = status.toString();
                    });
                  }),
                  js.allowInterop((dynamic err) {
                    setModalState(() {
                      statusInfo = 'Status: $err (Click query chip below for instant voice demo)';
                    });
                  }),
                ]);
              } catch (_) {}
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.mic, color: Color(0xFF2E7D32), size: 24),
                      const SizedBox(width: 8),
                      Text(
                        _selectedLanguage == 'मराठी'
                            ? 'RURAL Link व्हॉईस असिस्टंट (मराठी)'
                            : (_selectedLanguage == 'हिन्दी'
                                ? 'RURAL Link वॉइस असिस्टेंट (हिंदी)'
                                : 'RURAL Link Voice Assistant (English)'),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Language selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: ['मराठी', 'हिन्दी', 'English'].map((lang) {
                      final isSelected = _selectedLanguage == lang;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(
                            lang,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFF2E7D32),
                          onSelected: (bool selected) {
                            if (selected) {
                              _switchLanguage(lang);
                              langCode = lang == 'मराठी' ? 'mr-IN' : (lang == 'हिन्दी' ? 'hi-IN' : 'en-IN');
                              setModalState(() {});
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Big Glowing Mic Button
                  GestureDetector(
                    onTap: () {
                      setModalState(() {
                        isRecording = !isRecording;
                        if (!isRecording) {
                          js.context.callMethod('stopHardwareMicRecognition');
                          statusInfo = 'माईक थांबवला आहे';
                        }
                      });
                    },
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: isRecording ? const Color(0xFFE8F5E9) : Colors.grey.shade200,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isRecording ? const Color(0xFF2E7D32) : Colors.grey,
                          width: 3,
                        ),
                        boxShadow: isRecording
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF2E7D32).withOpacity(0.3),
                                  blurRadius: 16,
                                  spreadRadius: 4,
                                )
                              ]
                            : [],
                      ),
                      child: Icon(
                        isRecording ? Icons.mic : Icons.mic_off,
                        color: isRecording ? const Color(0xFF2E7D32) : Colors.grey,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    statusInfo,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isRecording ? const Color(0xFF2E7D32) : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Live Transcription Display Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAF9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFC8E6C9), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('तुम्ही काय बोललात / Transcribed:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45)),
                        const SizedBox(height: 6),
                        Text(
                          liveSpoken.isNotEmpty
                              ? '"$liveSpoken"'
                              : (_selectedLanguage == 'मराठी'
                                  ? '(माईकमध्ये बोला किंवा खालीलपैकी एका बटनावर टॅप करा)'
                                  : '(Speak now or tap any quick prompt below)'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: liveSpoken.isNotEmpty ? const Color(0xFF1B5E20) : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Submit Spoken Query Button
                  if (liveSpoken.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: Text(_selectedLanguage == 'मराठी' ? 'हा प्रश्न विचारा (Send Voice Query)' : 'Send Voice Query'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          js.context.callMethod('stopHardwareMicRecognition');
                          Navigator.pop(modalContext);
                          _sendMessage(liveSpoken);
                        },
                      ),
                    ),

                  const Divider(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _selectedLanguage == 'मराठी' ? '🌟 थेट १-टॅप व्हॉईस प्रश्न (100% Guaranteed Voice Demo):' : '🌟 Spoken Voice Queries (100% Reliable Demo):',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _getQuickVoiceChips(modalContext),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      try {
        js.context.callMethod('stopHardwareMicRecognition');
      } catch (_) {}
    });
  }

  List<Widget> _getQuickVoiceChips(BuildContext modalCtx) {
    final prompts = _selectedLanguage == 'मराठी'
        ? [
            '🌾 कांद्यासाठी बोलेरो पिकअप गाडी बुक करा (Option 1)',
            '💰 ३० किमीसाठी किती भाडे लागेल? (Option 2)',
            '🚚 शेतकरी गट पूलिंग शोधा (Option 3)',
            '🛣️ गावातील रस्ता पावसाने सुरू आहे का? (Option 4)',
            '📈 आजचा पुणे व नाशिक बाजारभाव दाखवा (Option 5)',
          ]
        : (_selectedLanguage == 'हिन्दी'
            ? [
                '🌾 प्याज के लिए बोलेरो पिकअप गाड़ी बुक करें (Option 1)',
                '💰 35 किमी दूरी के लिए कितना भाड़ा लगेगा? (Option 2)',
                '🚚 किसान ग्रुप पूलिंग ढूंढें (Option 3)',
                '🛣️ बारिश के बाद गांव की सड़क कैसी है? (Option 4)',
                '📈 आज का मंडी भाव क्या है? (Option 5)',
              ]
            : [
                '🌾 Book 2 ton Bolero pickup truck (Option 1)',
                '💰 Calculate freight cost for 35 km (Option 2)',
                '🚚 Find shared freight pooling (Option 3)',
                '🛣️ Check village road condition (Option 4)',
                '📈 Show today live APMC Mandi rates (Option 5)',
              ]);

    return prompts.map((phrase) {
      return ActionChip(
        avatar: const Icon(Icons.volume_up, size: 14, color: Color(0xFF2E7D32)),
        label: Text(phrase, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        backgroundColor: const Color(0xFFF1F8E9),
        side: const BorderSide(color: Color(0xFFC5E1A5)),
        onPressed: () {
          try {
            js.context.callMethod('stopHardwareMicRecognition');
          } catch (_) {}
          Navigator.pop(modalCtx);
          setState(() {
            _textController.text = phrase;
          });
          _sendMessage(phrase);
        },
      );
    }).toList();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? customText]) {
    final text = (customText ?? _textController.text).trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'isUser': true,
        'text': text,
        'type': 'text',
        'time': _getCurrentTime(),
      });
      _textController.clear();
      _isAiTyping = true;
    });
    _scrollToBottom();

    Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final aiResponse = _generateLogisticsAiResponse(text);
      setState(() {
        _isAiTyping = false;
        _messages.add(aiResponse);
      });
      _scrollToBottom();
      _speakAloud(aiResponse['text'] as String? ?? '');
    });
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  Widget _rowDetail(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              color: isHighlight ? Colors.green.shade800 : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _generateLogisticsAiResponse(String query) {
    final q = query.toLowerCase().trim();
    final isMr = _selectedLanguage == 'मराठी' ||
        q.contains('करा') ||
        q.contains('आहे') ||
        q.contains('कांदा') ||
        q.contains('भाडे') ||
        q.contains('रस्ता');
    final isHi = _selectedLanguage == 'हिन्दी' ||
        q.contains('करें') ||
        q.contains('किराया') ||
        q.contains('गाड़ी') ||
        q.contains('सड़क');

    // 0. NUMBER SHORTCUTS (1, 2, 3, 4, 5 / १, २, ३, ४, ५)
    if (q == '1' || q == '१' || q == 'एक' || q == 'one' || q.contains('option 1') || q.contains('१.')) {
      return _getBookingResponse(isMr, isHi);
    }
    if (q == '2' || q == '२' || q == 'दोन' || q == 'two' || q.contains('option 2') || q.contains('२.')) {
      return _getCostResponse(isMr, isHi);
    }
    if (q == '3' || q == '३' || q == 'तीन' || q == 'three' || q.contains('option 3') || q.contains('३.')) {
      return _getPoolResponse(isMr, isHi);
    }
    if (q == '4' || q == '४' || q == 'चार' || q == 'four' || q.contains('option 4') || q.contains('४.')) {
      return _getRoadResponse(isMr, isHi);
    }
    if (q == '5' || q == '५' || q == 'पाच' || q == 'five' || q.contains('option 5') || q.contains('५.')) {
      return _getMandiResponse(isMr, isHi);
    }

    // 1. TRACKING
    if (q.contains('track') ||
        q.contains('location') ||
        q.contains('where') ||
        q.contains('gps') ||
        q.contains('dispatch') ||
        q.contains('ट्रॅक') ||
        q.contains('ट्रैक') ||
        q.contains('कुठे')) {
      return {
        'isUser': false,
        'text': isMr
            ? '📍 **थेट GPS व प्रवास ट्रॅकर (Live Transit)**'
            : (isHi
                ? '📍 **लाइव GPS व वाहन ट्रैकिंग (Live Transit)**'
                : '📍 **Live GPS Telemetry & Transit Tracker**'),
        'type': 'track_card',
        'time': _getCurrentTime(),
        'data': {
          'vehicle': 'Mahindra Bolero Maxi (MH-14-GH-8291)',
          'driver': 'संभाजी शिंदे (+91 98224-54120)',
          'speed': '38 km/h (Rural Link Road)',
          'eta': isMr ? '१८ मिनिटांत शेतात पोहोचेल' : '18 mins to Farm Gate',
          'currentPoint': isMr
              ? 'नीरा नदी पूल सेक्टर पार करत आहे'
              : 'Passing Nira River Bridge Sector',
          'destination': isMr
              ? 'मुख्य APMC मार्केट यार्ड'
              : 'APMC Regional Mandi, Yard #3',
          'steps': [
            {
              'title': isMr ? 'चालकाने बुकिंग स्वीकारले' : 'Driver Accepted',
              'time': '18:10',
              'done': true
            },
            {
              'title': isMr ? 'शेताकडे मार्गस्थ' : 'En Route to Farm',
              'time': '18:18 (Current)',
              'active': true
            },
            {
              'title': isMr
                  ? 'माल भरणे व OTP पडताळणी'
                  : 'Loading & OTP Verification',
              'time': 'Est. 18:30',
              'done': false
            },
            {
              'title': isMr ? 'महामार्ग प्रवास' : 'Highway Transit',
              'time': 'Est. 19:00',
              'done': false
            },
            {
              'title': isMr ? 'मंडी अनलोडिंग गेट' : 'APMC Mandi Unloading',
              'time': 'Est. 19:35',
              'done': false
            },
          ]
        }
      };
    }

    // 2. CONFIRMATION
    if (q.contains('confirm') ||
        q.contains('book now') ||
        q.startsWith('confirm booking') ||
        q.contains('निश्चित करा') ||
        q.contains('पक्की करें')) {
      String vName = 'Mahindra Bolero Maxi Truck';
      if (q.contains('tata') ||
          q.contains('छोटा हाथी') ||
          q.contains('छोटा हत्ती')) vName = 'Tata Ace Gold';
      if (q.contains('tractor') || q.contains('ट्रॅक्टर')) {
        vName = 'Mahindra 45HP Tractor-Trolley';
      }

      return {
        'isUser': false,
        'text': isMr
            ? '🎉 **बुकिंग निश्चित झाली! चालक नियुक्त केला आहे.**'
            : (isHi
                ? '🎉 **बुकिंग पक्की हो गई! ड्राइवर असाइन हुआ।**'
                : '🎉 **Trip Confirmed! Driver Assigned.**'),
        'type': 'confirmed_card',
        'time': _getCurrentTime(),
        'data': {
          'bookingId': 'RL-BK-${(1000 + DateTime.now().millisecond).toString()}',
          'vehicle': vName,
          'driverName': 'संभाजी शिंदे (Sambhaji Shinde)',
          'driverPhone': '+91 98224-54120',
          'plateNumber': 'MH-14-GH-8291',
          'otp': '4821',
          'eta': isMr ? '१८ मिनिटांत शेतात आगमन' : 'Arriving in 18 mins',
        }
      };
    }

    // 3. MANDI RATES
    if (q.contains('mandi') ||
        q.contains('market') ||
        q.contains('bhav') ||
        q.contains('rate') ||
        q.contains('भाव') ||
        q.contains('बाजारभाव') ||
        q.contains('कांदा') ||
        q.contains('प्याज') ||
        q.contains('टोमॅटो') ||
        q.contains('गहू')) {
      return _getMandiResponse(isMr, isHi);
    }

    // 4. FREIGHT COST
    if (q.contains('cost') ||
        q.contains('estimate') ||
        q.contains('price') ||
        q.contains('fare') ||
        q.contains('भाडे') ||
        q.contains('खर्च') ||
        q.contains('किराया')) {
      return _getCostResponse(isMr, isHi);
    }

    // 5. POOLING
    if (q.contains('pool') ||
        q.contains('share') ||
        q.contains('shared') ||
        q.contains('group') ||
        q.contains('पूलिंग') ||
        q.contains('गट')) {
      return _getPoolResponse(isMr, isHi);
    }

    // 6. ROAD STATUS
    if (q.contains('road') ||
        q.contains('route') ||
        q.contains('weather') ||
        q.contains('status') ||
        q.contains('रस्ता') ||
        q.contains('सड़क')) {
      return _getRoadResponse(isMr, isHi);
    }

    // 7. BOOKING OPTIONS
    if (q.contains('book') ||
        q.contains('produce') ||
        q.contains('transport') ||
        q.contains('truck') ||
        q.contains('tractor') ||
        q.contains('गाडी') ||
        q.contains('वाहन')) {
      return _getBookingResponse(isMr, isHi);
    }

    return {
      'isUser': false,
      'text': isMr
          ? 'मला समजले: "$query".\n\nकृपया खालीलपैकी पर्याय निवडा किंवा माईकवर बोला:\n1. 🚜 **वाहन बुकिंग (Truck/Tractor)**\n2. 💰 **भाडे अंदाज**\n3. 🤝 **शेतकरी गट वाहतूक (Pooling)**\n4. 🛣️ **रस्ता स्थिती**\n5. 📈 **बाजारभाव**'
          : 'I understood: "$query".\n\nPlease select an option or tap the mic:\n1. 🚜 **Vehicle Booking**\n2. 💰 **Freight Cost**\n3. 🤝 **Group Pooling**\n4. 🛣️ **Road Status**\n5. 📈 **Mandi Rates**',
      'type': 'text',
      'time': _getCurrentTime(),
    };
  }

  Map<String, dynamic> _getBookingResponse(bool isMr, bool isHi) {
    return {
      'isUser': false,
      'text': isMr
          ? 'आपल्या परिसरासाठी उपलब्ध शेतमाल वाहतूक वाहने:'
          : 'Here are the best available rural transit options matched for your route:',
      'type': 'booking_card',
      'time': _getCurrentTime(),
      'data': {
        'vehicles': [
          {
            'name': 'Mahindra Bolero Maxi Truck',
            'capacity': '1.5 - 2.0 Tons',
            'eta': '25 mins away (Khadki Hub)',
            'cost': '₹1,200 (Est. 30 km)',
            'rating': '4.8 ★'
          },
          {
            'name': 'Tata Ace Gold (छोटा हत्ती)',
            'capacity': '750 kg - 1.0 Ton',
            'eta': '15 mins away (Village Stand)',
            'cost': '₹750 (Est. 30 km)',
            'rating': '4.9 ★'
          },
          {
            'name': 'Mahindra 45HP Tractor-Trolley',
            'capacity': '4.0 - 5.0 Tons',
            'eta': '40 mins away (Society Stand)',
            'cost': '₹2,100 (Est. 30 km)',
            'rating': '4.7 ★'
          },
        ]
      }
    };
  }

  Map<String, dynamic> _getCostResponse(bool isMr, bool isHi) {
    return {
      'isUser': false,
      'text': isMr
          ? '📊 **AI ग्रामीण वाहतूक खर्च कॅल्क्युलेटर (Option 2)**'
          : '📊 **Dynamic Rural Freight & Cost Engine (Option 2)**',
      'type': 'estimate_card',
      'time': _getCurrentTime(),
      'data': {
        'baseRate': '₹18 / किमी (Bolero / Tata Ace)',
        'mandiDistance': '38.5 किमी (APMC मार्केट यार्ड)',
        'sharedDiscount': isMr ? '-३५% सहकारी पूलिंग बचत' : '-35% via Sahakaari Pooling',
        'totalEstimated': '₹690 - ₹950',
        'recommendation': isMr
            ? '💡 AI सल्ला: २ इतर शेतकऱ्यांसोबत लोड शेअर करून ₹३२० वाचवा.'
            : '💡 AI Tip: Combine harvest with 2 nearby farmers to save ₹320.'
      }
    };
  }

  Map<String, dynamic> _getPoolResponse(bool isMr, bool isHi) {
    return {
      'isUser': false,
      'text': isMr
          ? '🤝 **सहकारी शेतकरी गट वाहतूक (Option 3: Match Found!)**'
          : '🤝 **Sahakaari Freight Pooling (Option 3: Match Found!)**',
      'type': 'pool_card',
      'time': _getCurrentTime(),
      'data': {
        'cluster': isMr ? 'क्लस्टर #R-१०४ (पूर्व शिरोळ व कागल)' : 'Cluster #R-104 (East Shirol & Kagal)',
        'matchedFarmers': [
          {'name': 'रमेश पाटील', 'crop': '१२ क्विंटल टोमॅटो', 'status': 'सकाळी ०७:०० वा. तयार'},
          {'name': 'सुरेश शिंदे', 'crop': '८ क्विंटल मिरची', 'status': 'सकाळी ०७:१५ वा. तयार'},
        ],
        'savings': isMr ? 'प्रत्येक शेतकऱ्याची ३८% भाडे बचत' : '38% saved per farmer compared to solo dispatch',
      }
    };
  }

  Map<String, dynamic> _getRoadResponse(bool isMr, bool isHi) {
    return {
      'isUser': false,
      'text': isMr
          ? '🛣️ **AI ग्रामीण रस्ता व हवामान स्थिती अहवाल (Option 4)**'
          : '🛣️ **AI Village Road Health & Weather Report (Option 4)**',
      'type': 'road_card',
      'time': _getCurrentTime(),
      'data': {
        'route': isMr ? 'गाव रस्ता -> राज्य महामार्ग ११५ -> APMC' : 'Village link road -> State Highway 115 -> APMC',
        'katchaRoad': isMr ? '⚠️ ३.२ किमी कच्चा रस्ता निसरडा; ट्रॅक्टर किंवा बोलेरो वापरावे.' : '⚠️ Unpaved 3.2km soft after rain; high-axle vehicles advised.',
        'bridge': isMr ? '🟢 ओढ्यावरील लहान पूल खुला आहे.' : '🟢 Nala bridge clear & fully passable.',
        'bestTime': isMr ? 'उद्या सकाळी ०६:३० वा. निघणे उत्तम' : '06:30 AM tomorrow morning to avoid APMC queue',
      }
    };
  }

  Map<String, dynamic> _getMandiResponse(bool isMr, bool isHi) {
    return {
      'isUser': false,
      'text': isMr
          ? '📈 **थेट APMC बाजारभाव (Option 5: Live Benchmarks)**'
          : '📈 **Live APMC Mandi Price Intelligence (Option 5)**',
      'type': 'mandi_card',
      'time': _getCurrentTime(),
      'data': {
        'updated': '15 mins ago (Live APMC API)',
        'items': [
          {'crop': isMr ? 'कांदा (Onion)' : 'Onion', 'price': '₹2,450 / क्विंटल', 'trend': '+₹120 ▲', 'demand': 'High demand'},
          {'crop': isMr ? 'टोमॅटो (Tomato)' : 'Tomato', 'price': '₹1,800 / क्विंटल', 'trend': '-₹40 ▼', 'demand': 'Steady'},
          {'crop': isMr ? 'गहू (Wheat)' : 'Wheat', 'price': '₹2,850 / क्विंटल', 'trend': '+₹50 ▲', 'demand': 'High demand'},
          {'crop': isMr ? 'सोयाबीन (Soybean)' : 'Soybean', 'price': '₹4,600 / क्विंटल', 'trend': '+₹80 ▲', 'demand': 'Active Trading'},
        ]
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestions = _getQuickSuggestions();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        elevation: 2,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.local_shipping, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RURAL Link AI',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    _selectedLanguage == 'मराठी'
                        ? 'ग्रामीण लॉजिस्टिक्स व शेतमाल वाहतूक'
                        : (_selectedLanguage == 'हिन्दी'
                            ? 'ग्रामीण लॉजिस्टिक्स व कृषि परिवहन'
                            : 'Rural Logistics & Transit Co-Pilot'),
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLanguage,
              dropdownColor: theme.colorScheme.primary,
              icon: const Icon(Icons.language, color: Colors.white),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              onChanged: (String? val) {
                if (val != null) _switchLanguage(val);
              },
              items: ['मराठी', 'हिन्दी', 'English'].map((lang) => DropdownMenuItem(value: lang, child: Text(lang, style: const TextStyle(color: Colors.white)))).toList(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.mic, color: Colors.white),
            tooltip: 'Live Voice Assistant',
            onPressed: _openLiveVoiceAssistant,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageItem(msg, msg['isUser'] as bool);
              },
            ),
          ),
          if (_isAiTyping)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E7D32))),
                      SizedBox(width: 8),
                      Text('RURAL Link AI गणना करत आहे...', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
              ),
            ),
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                return ActionChip(
                  label: Text(suggestions[i], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  side: const BorderSide(color: Color(0xFFC8E6C9)),
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onPressed: () => _sendMessage(suggestions[i]),
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, -2))]),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _openLiveVoiceAssistant,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF2E7D32), width: 1.5),
                      ),
                      child: const Icon(Icons.mic, color: Color(0xFF2E7D32), size: 22),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F1), borderRadius: BorderRadius.circular(24)),
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: _selectedLanguage == 'मराठी'
                              ? '१ ते ५ टाईप करा किंवा माईकवर टॅप करा...'
                              : (_selectedLanguage == 'हिन्दी'
                                  ? '1 से 5 टाइप करें या माइक पर टैप करें...'
                                  : 'Type 1 to 5 or tap mic...'),
                          hintStyle: const TextStyle(fontSize: 14, color: Colors.black45),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF2E7D32),
                    radius: 22,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> msg, bool isUser) {
    final type = msg['type'] as String? ?? 'text';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * (isUser ? 0.78 : 0.88)),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF2E7D32) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(3),
                  bottomRight: isUser ? const Radius.circular(3) : const Radius.circular(18),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(msg['text'] ?? '', style: TextStyle(color: isUser ? Colors.white : const Color(0xFF1E293B), fontSize: 14.5, height: 1.4)),
                  if (type == 'booking_card') _buildBookingCard(msg['data']),
                  if (type == 'confirmed_card') _buildConfirmedCard(msg['data']),
                  if (type == 'mandi_card') _buildMandiCard(msg['data']),
                  if (type == 'estimate_card') _buildEstimateCard(msg['data']),
                  if (type == 'pool_card') _buildPoolCard(msg['data']),
                  if (type == 'road_card') _buildRoadCard(msg['data']),
                  if (type == 'track_card') _buildTrackCard(msg['data']),
                ],
              ),
            ),
            Padding(padding: const EdgeInsets.only(top: 3, left: 4, right: 4), child: Text(msg['time'] ?? '', style: const TextStyle(fontSize: 10.5, color: Colors.black45))),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> data) {
    final vehicles = data['vehicles'] as List<dynamic>;
    return Column(
      children: vehicles.map((v) {
        return Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFF8FAF8), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE0E0E0))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(v['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(6)), child: Text(v['rating'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.brown))),
                ],
              ),
              const SizedBox(height: 4),
              Text('📦 Capacity: ${v['capacity']} • ⏱️ ${v['eta']}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(v['cost'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32), fontSize: 14)),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, size: 14),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    onPressed: () => _sendMessage("Confirm booking for ${v['name']}"),
                    label: Text(_selectedLanguage == 'मराठी' ? 'बुक करा' : 'Book Now', style: const TextStyle(fontSize: 12)),
                  )
                ],
              )
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConfirmedCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF1F8E9), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFAED581), width: 1.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data['bookingId'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32), fontSize: 14)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(12)), child: const Text('DISPATCHED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
            ],
          ),
          const Divider(height: 16),
          _rowDetail('🚜 Assigned Vehicle:', data['vehicle']),
          _rowDetail('🔢 Number Plate:', data['plateNumber']),
          _rowDetail('👤 Driver Partner:', data['driverName']),
          _rowDetail('📞 Contact:', data['driverPhone']),
          _rowDetail('⏳ Live Arrival:', data['eta'], isHighlight: true),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('🔑 Driver Verification OTP:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text(data['otp'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.call, size: 14, color: Color(0xFF2E7D32)),
                  label: Text(_selectedLanguage == 'मराठी' ? 'चालकाला कॉल' : 'Call Driver', style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32))),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Calling Driver: ${data['driverPhone']}...'))),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.gps_fixed, size: 14),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
                  label: Text(_selectedLanguage == 'मराठी' ? 'थेट ट्रॅकिंग' : 'Track Live', style: const TextStyle(fontSize: 12)),
                  onPressed: () => _sendMessage("Show live GPS tracking for driver"),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTrackCard(Map<String, dynamic> data) {
    final steps = data['steps'] as List<dynamic>;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF3E5F5), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFCE93D8), width: 1.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data['vehicle'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4A148C))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.deepPurple, borderRadius: BorderRadius.circular(12)), child: Text('ETA ${data['eta']}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 6),
          _rowDetail('👤 Driver:', data['driver']),
          _rowDetail('⚡ Live Speed:', data['speed']),
          _rowDetail('📍 Sector:', data['currentPoint'], isHighlight: true),
          _rowDetail('🎯 Destination:', data['destination']),
          const Divider(height: 16),
          const Text('🗺️ Live Transit Journey Milestones:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF4A148C))),
          const SizedBox(height: 8),
          ...steps.map((s) {
            final isDone = s['done'] == true;
            final isActive = s['active'] == true;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Icon(
                    isDone
                        ? Icons.check_circle
                        : (isActive ? Icons.local_shipping : Icons.radio_button_unchecked),
                    size: 16,
                    color: isDone ? Colors.green : (isActive ? Colors.deepPurple : Colors.grey.shade400),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s['title'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive ? Colors.deepPurple.shade900 : Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    s['time'],
                    style: TextStyle(
                      fontSize: 11,
                      color: isActive ? Colors.deepPurple : Colors.black45,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMandiCard(Map<String, dynamic> data) {
    final items = data['items'] as List<dynamic>;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFFE082))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedLanguage == 'मराठी' ? 'APMC बाजार समिती थेट भाव' : 'APMC Regional Mandi Benchmarks',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFE65100)),
              ),
              Text(data['updated'], style: const TextStyle(fontSize: 10, color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) {
            final isUp = (item['trend'] as String).contains('+');
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['crop'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('Demand: ${item['demand']}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(item['price'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2E7D32))),
                      Text(item['trend'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isUp ? Colors.green : Colors.red)),
                    ],
                  )
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEstimateCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFFFFDE7), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFFF59D))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _rowDetail('📏 Distance:', data['mandiDistance']),
          _rowDetail('⚡ Base Tariff:', data['baseRate']),
          _rowDetail('🤝 Subsidy:', data['sharedDiscount'], isHighlight: true),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedLanguage == 'मराठी' ? 'एकूण अंदाजे भाडे:' : 'Est. Total Transit Cost:',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(data['totalEstimated'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2E7D32))),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Text(data['recommendation'], style: const TextStyle(fontSize: 12, color: Color(0xFFE65100), fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildPoolCard(Map<String, dynamic> data) {
    final farmers = data['matchedFarmers'] as List<dynamic>;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFBBDEFB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data['cluster'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1), fontSize: 13)),
          const SizedBox(height: 8),
          ...farmers.map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.person_pin_circle, size: 16, color: Color(0xFF1976D2)),
                    const SizedBox(width: 6),
                    Text('${f['name']}: ${f['crop']} (${f['status']})', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
            child: Row(
              children: [
                const Icon(Icons.savings_outlined, color: Colors.green, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(data['savings'], style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.green))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoadCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBE9E7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCCBC))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data['route'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          Text(data['katchaRoad'], style: const TextStyle(fontSize: 12, color: Color(0xFFBF360C))),
          const SizedBox(height: 4),
          Text(data['bridge'], style: const TextStyle(fontSize: 12, color: Colors.black87)),
          const SizedBox(height: 6),
          Text('⏰ ${data['bestTime']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
        ],
      ),
    );
  }
}