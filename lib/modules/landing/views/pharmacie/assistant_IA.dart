import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../utilitaires/apps_colors.dart';

class AssistantIAPage extends StatefulWidget {
  const AssistantIAPage({super.key});

  @override
  State<AssistantIAPage> createState() => _AssistantIAPageState();
}

class _AssistantIAPageState extends State<AssistantIAPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _errorMessage;

  // Configuration pour l'API Gemini
  final String _apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  final String _apiKey =
      'AIzaSyCPEOAAbNBeq12Ob6-hCvwif5Sj9Dh8e48'; // ⚠️ Mets ta propre clé API

  @override
  void initState() {
    super.initState();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _errorMessage = 'Utilisateur non connecté');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final userMessage = {
      'text': message,
      'sender': 'user',
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('conversations')
        .add(userMessage);

    try {
      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': message}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          },
        }),
      );

      print("Réponse brute Gemini: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final assistantResponse = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
            'Réponse non disponible';

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('conversations')
            .add({
          'text': assistantResponse,
          'sender': 'assistant',
          'timestamp': FieldValue.serverTimestamp(),
        });

        setState(() => _messageController.clear());
        _scrollToBottom();
      } else {
        setState(() =>
        _errorMessage = 'Erreur API: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Stream<List<Map<String, dynamic>>> _getConversation() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('conversations')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildChatArea()),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.psychology_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assistant IA',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Posez vos questions pour gérer votre pharmacie',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getConversation(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          );
        }
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }
        final messages = snapshot.data ?? [];
        if (messages.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isUser = message['sender'] == 'user';
            return Align(
              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUser ? AppColors.primary : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUser ? AppColors.primary : Colors.grey.shade200,
                  ),
                ),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                child: Text(
                  message['text'] ?? '',
                  style: TextStyle(
                    color: isUser ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Posez une question...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _sendMessage(_messageController.text),
            ),
          ),
          if (_isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.send_rounded, color: AppColors.primary),
              onPressed: () => _sendMessage(_messageController.text),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune conversation',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez à poser vos questions !',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur lors du chargement',
            style: TextStyle(
              color: Colors.red.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
