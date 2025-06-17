import 'package:flutter/material.dart';
import '../widgets/game_selector.dart';
import '../widgets/chat_area.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GamesHomePage extends StatefulWidget {
  const GamesHomePage({Key? key}) : super(key: key); // ✅ add key

  @override
  _GamesHomePageState createState() => _GamesHomePageState();
}

class _GamesHomePageState extends State<GamesHomePage> {
  int selectedGameIndex = -1;
  List<String> games = [];
  final List<Map<String, String>> messages = [];
  final TextEditingController _chatController = TextEditingController();

  bool isGameSelectorVisible = false;
  final GlobalKey _dropdownIconKey = GlobalKey();
  Offset dropdownOffset = Offset.zero;
  bool useLLM = false;

  @override
  void initState() {
    super.initState();
    fetchGames();
  }

  Future<void> fetchGames() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:5000/games'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          games = List<String>.from(data);
        });
      } else {
        // Handle error
      }
    } catch (e) {
      // Handle error
    }
  }

  void sendMessage() async {
    final userMessage = _chatController.text.trim();
    if (userMessage.isEmpty || selectedGameIndex == -1) return;

    final selectedGame = games[selectedGameIndex];

    setState(() {
      messages.add({'sender': 'user', 'text': userMessage});
      _chatController.clear();
    });

    try {
      final response = await http.post(
        Uri.parse(
          'http://localhost:5000/ask',
        ), // Replace with actual backend URL in production
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'game': selectedGame,
          'query': userMessage,
          'use_llm': useLLM,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiMessage = data['answer'] ?? "No answer provided.";

        setState(() {
          messages.add({'sender': 'ai', 'text': 'AI: $aiMessage'});
        });
      } else {
        setState(() {
          messages.add({
            'sender': 'ai',
            'text':
                'AI: Error ${response.statusCode}: ${response.reasonPhrase}',
          });
        });
      }
    } catch (e) {
      setState(() {
        messages.add({
          'sender': 'ai',
          'text': 'AI: Failed to connect to server.',
        });
      });
    }
  }



  void toggleGameSelector() {
    final renderBox =
        _dropdownIconKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final offset = renderBox.localToGlobal(Offset.zero);
      setState(() {
        dropdownOffset = offset;
        isGameSelectorVisible = !isGameSelectorVisible;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 36, 36, 36),
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Games', style: TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              key: _dropdownIconKey,
              icon: Icon(Icons.arrow_drop_down_circle_rounded),
              onPressed: toggleGameSelector,
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 17, 115, 196),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(2.0),
            child: Column(
              children: [
                Expanded(child: ChatArea(messages: messages)),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatController,
                        style: TextStyle(color: Colors.black, fontSize: 14),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[200],
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      width: 48,
                      child: Material(
                        color: const Color.fromARGB(255, 17, 115, 196),
                        borderRadius: BorderRadius.circular(50),
                        child: InkWell(
                          onTap: sendMessage,
                          borderRadius: BorderRadius.circular(50),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.send,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Floating dropdown
          if (isGameSelectorVisible)
            Positioned(
              top: 0,
              left: 0, // Adjust as needed
              child: Material(
                elevation: 8,
                child: GameSelector(
                  games: games,
                  selectedIndex: selectedGameIndex,
                  onSelected: (index) {
                    setState(() {
                      selectedGameIndex = index;
                      isGameSelectorVisible = false;
                    });
                  },
                ),
              ),
            ),

          // Floating LLM Button
          Positioned(
            bottom: 60, // Place above the send button
            right: 8,
            child: Material(
              color:
                  useLLM
                      ? const Color.fromARGB(
                        255,
                        17,
                        115,
                        196,
                      ) // AppBar color when selected
                      : Colors
                          .blue[50]!, // Light blue background when not selected
              borderRadius: BorderRadius.circular(50),
              child: InkWell(
                onTap: () {
                  setState(() {
                    useLLM = !useLLM; // Toggle LLM usage
                  });
                },
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          useLLM
                              ? const Color.fromARGB(
                                255,
                                17,
                                115,
                                196,
                              ) // Highlight border if selected
                              : Colors.grey[300]!, // Default border color
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    'LLM',
                    style: TextStyle(
                      color:
                          useLLM
                              ? Colors
                                  .white // White text when selected
                              : Colors.black, // Black text when not selected
                      fontSize: 12, // Smaller text size
                      fontWeight: FontWeight.normal, // Normal font weight
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
