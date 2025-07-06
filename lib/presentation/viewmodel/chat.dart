import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:talk_trip/presentation/bloc/chat/chat_bloc.dart';
import 'package:talk_trip/presentation/widgets/chat_message_widget.dart';
import 'package:talk_trip/presentation/widgets/itinerary_display_widget.dart';
import 'package:talk_trip/presentation/widgets/thinking_bubble_widget.dart';
import 'package:talk_trip/presentation/widgets/saved_itineraries_widget.dart';
import 'package:talk_trip/data/models/message.dart';
import 'package:talk_trip/data/models/itinerary.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isThinking = false;
  Itinerary? _currentItinerary;
  List<Itinerary> _savedItineraries = [];
  bool _isConversationMode = false;
  int? _conversationChatId;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadSavedItineraries();
  }

  void _loadMessages() async {
    final chatBloc = context.read<ChatBloc>();
    final chatId = _isConversationMode && _conversationChatId != null 
        ? _conversationChatId! 
        : chatBloc.currentChatId;
    final messages = await chatBloc.getMessages(chatId);
    setState(() {
      _messages = messages;
    });
  }

  void _loadSavedItineraries() async {
    final chatBloc = context.read<ChatBloc>();
    final itineraries = await chatBloc.getAllItineraries();
    setState(() {
      _savedItineraries = itineraries;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final chatBloc = context.read<ChatBloc>();
    
    if (_isConversationMode && _conversationChatId != null) {
      // In conversation mode, send as a follow-up question
      chatBloc.add(PostDataEvent(
        prompt: text,
        chatId: _conversationChatId!,
        isUser: true,
      ));
    } else {
      // Normal itinerary generation
      chatBloc.add(GenerateItineraryEvent(
        prompt: text,
        chatId: chatBloc.currentChatId,
      ));
    }

    _textController.clear();
  }

  void _saveItinerary() async {
    if (_currentItinerary != null) {
      final chatBloc = context.read<ChatBloc>();
      await chatBloc.saveItinerary(chatBloc.currentChatId, _currentItinerary!);
      _loadSavedItineraries();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Itinerary saved offline!'),
          backgroundColor: Color(0xFF065F46),
        ),
      );
    }
  }

  void _openSavedItinerary(Itinerary itinerary) async {
    final chatBloc = context.read<ChatBloc>();
    final newChatId = await chatBloc.createNewChatSession();
    
    setState(() {
      _currentItinerary = itinerary;
      _messages = [];
      _isConversationMode = true;
      _conversationChatId = newChatId;
    });

    await chatBloc.addSystemMessage(
      newChatId,
      "I'm helping you modify this itinerary: ${itinerary.title} for ${itinerary.destination}. You can ask me to add activities, change restaurants, modify timings, or make any other adjustments."
    );

    _loadMessages();
  }

  void _regenerateResponse() {
    if (_messages.isNotEmpty) {
      final lastUserMessage = _messages.lastWhere((msg) => msg.isUser);
      final chatBloc = context.read<ChatBloc>();
      
      // Remove the last AI response
      setState(() {
        _messages.removeWhere((msg) => !msg.isUser && 
          _messages.indexOf(msg) > _messages.indexOf(lastUserMessage));
      });
      
      // Regenerate response for the last user message
      if (_isConversationMode && _conversationChatId != null) {
        chatBloc.add(PostDataEvent(
          prompt: lastUserMessage.message,
          chatId: _conversationChatId!,
          isUser: true,
        ));
      } else {
        chatBloc.add(GenerateItineraryEvent(
          prompt: lastUserMessage.message,
          chatId: chatBloc.currentChatId,
        ));
      }
    }
  }

  void _copyMessage(String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard'),
        backgroundColor: Color(0xFF065F46),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _exitConversationMode() {
    setState(() {
      _isConversationMode = false;
      _conversationChatId = null;
      _currentItinerary = null;
      _messages = [];
    });
    _loadSavedItineraries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        leading: (_messages.isNotEmpty || _currentItinerary != null || _isConversationMode)
            ? IconButton(
                onPressed: () {
                  if (_isConversationMode) {
                    _exitConversationMode();
                  } else {
                    setState(() {
                      _messages = [];
                      _currentItinerary = null;
                    });
                  }
                },
                icon: Icon(
                  Icons.arrow_back,
                  color: Color(0xFF065F46),
                ),
              )
            : null,
        title: Row(
          children: [
            Expanded(
              child: Text(
                _isConversationMode && _currentItinerary != null
                    ? 'Modifying: ${_currentItinerary!.title}'
                    : _currentItinerary != null 
                        ? 'Itinerary Created 🎉'
                        : _isLoading 
                            ? 'Creating Itinerary...'
                            : _messages.isNotEmpty 
                                ? 'TalkTrip'
                                : 'Hey Shubham 👋',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF065F46),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_messages.isEmpty && _currentItinerary == null && !_isConversationMode)
              IconButton(
                onPressed: () {
                  context.read<ChatBloc>().add(CreateNewChatSessionEvent());
                },
                icon: Icon(
                  Icons.add,
                  color: Color(0xFF065F46),
                ),
              ),
          ],
        ),
      ),
      body: BlocListener<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatSendSuccess) {
            _loadMessages();
            _scrollToBottom();
            setState(() {
              _isThinking = true;
            });
          } else if (state is ChatLoading) {
            setState(() {
              _isLoading = true;
              _isThinking = false;
            });
          } else if (state is ItineraryReceivedSuccess) {
            setState(() {
              _isLoading = false;
              _isThinking = false;
              if (!_isConversationMode) {
                _currentItinerary = state.itinerary;
              } else {
                // Update the current itinerary in conversation mode
                _currentItinerary = state.itinerary;
              }
            });
            _loadMessages();
            _scrollToBottom();
          } else if (state is ChatReciveSuccess) {
            setState(() {
              _isLoading = false;
              _isThinking = false;
            });
            _loadMessages();
            _scrollToBottom();
          } else if (state is ChatFailure) {
            setState(() {
              _isLoading = false;
              _isThinking = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error)),
            );
          } else if (state is NewChatSessionCreated) {
            if (!_isConversationMode) {
              setState(() {
                _messages = [];
                _currentItinerary = null;
              });
            }
          }
        },
        child: Column(
          children: [
            // Loading overlay
            if (_isLoading)
              Container(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 60.w,
                        height: 60.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF065F46),
                          ),
                        ), 
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        _isConversationMode 
                            ? 'Updating your itinerary...'
                            : 'Curating a perfect plan for you...',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            // Show itinerary if created (and not in conversation mode)
            else if (_currentItinerary != null && !_isConversationMode)
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: ItineraryDisplayWidget(
                        itinerary: _currentItinerary!,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final chatBloc = context.read<ChatBloc>();
                                final newChatId = await chatBloc.createNewChatSession();
  
                                setState(() {
                                  _isConversationMode = true;
                                  _conversationChatId = newChatId;
                                  _messages = [];
                                });

                                await chatBloc.addSystemMessage(
                                  newChatId,
                                  "I'm helping you refine this itinerary: ${_currentItinerary!.title} for ${_currentItinerary!.destination}. You can ask me to add activities, change restaurants, modify timings, or make any other adjustments."
                                );

                                _loadMessages();
                              },
                              icon: Icon(Icons.chat_bubble_outline),
                              label: Text('Follow up to refine'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF3BAB8C),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16.r),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _saveItinerary,
                              icon: Icon(Icons.save_outlined),
                              label: Text('Save Offline'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Color(0xFF065F46),
                                padding: EdgeInsets.symmetric(vertical: 16.r),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                side: BorderSide(color: Color(0xFF065F46)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            // Show conversation mode (chat + itinerary side by side or stacked)
            else if (_isConversationMode && _currentItinerary != null)
              Expanded(
                child: Column(
                  children: [
                    // Show current itinerary at the top
                    Container(
                      height: 200.h,
                      child: ItineraryDisplayWidget(
                        itinerary: _currentItinerary!,
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey[300]),
                    // Show chat messages below
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        itemCount: _messages.length + (_isThinking ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length && _isThinking) {
                            return ThinkingBubbleWidget();
                          }
                          final message = _messages[index];
                          final isLastAIMessage = !message.isUser && 
                              index == _messages.length - 1 && 
                              !_isThinking;
                          return ChatMessageWidget(
                            message: message,
                            onCopy: () => _copyMessage(message.message),
                            onRegenerate: isLastAIMessage ? _regenerateResponse : null,
                            isLastMessage: isLastAIMessage,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )
            // Show main chat interface
            else if (_messages.isEmpty) ...[
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    children: [
                      SizedBox(height: 60.h),
                      Text(
                        'What\'s your vision\nfor this trip?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 40.h),
                      // Chat input in the middle
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: Color(0xFF3BAB8C), width: 2.r),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                maxLines: null,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 12.r,
                                    horizontal: 16.r,
                                  ),
                                  border: InputBorder.none,
                                  hintText: 'Describe your ideal trip...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[500],
                                  ),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.all(8.r),
                              child: GestureDetector(
                                onTap: _sendMessage,
                                child: Container(
                                  width: 40.w,
                                  height: 40.h,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF065F46),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.send,
                                    color: Colors.white,
                                    size: 20.sp,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                      // Create My Itinerary button right below
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _sendMessage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2D7D32),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16.r),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Create My Itinerary',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 30.h),
                      // Saved itineraries at the bottom
                      if (_savedItineraries.isNotEmpty)
                        SavedItinerariesWidget(
                          itineraries: _savedItineraries,
                          onItineraryTap: _openSavedItinerary,
                        ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length + (_isThinking ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isThinking) {
                      return ThinkingBubbleWidget();
                    }
                    final message = _messages[index];
                    final isLastAIMessage = !message.isUser && 
                        index == _messages.length - 1 && 
                        !_isThinking;
                    return ChatMessageWidget(
                      message: message,
                      onCopy: () => _copyMessage(message.message),
                      onRegenerate: isLastAIMessage ? _regenerateResponse : null,
                      isLastMessage: isLastAIMessage,
                    );
                  },
                ),
              ),
            ],
            
            // Input area - show for follow-up messages and conversation mode
            if (!_isLoading && _currentItinerary == null && (_messages.isNotEmpty || _isConversationMode))
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: Color(0xFF3BAB8C), width: 2.r),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              maxLines: null,
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: Colors.black,
                              ),
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 12.r,
                                  horizontal: 16.r,
                                ),
                                border: InputBorder.none,
                                hintText: _isConversationMode
                                    ? 'Ask to modify the itinerary...'
                                    : _messages.isEmpty 
                                        ? 'Describe your ideal trip...'
                                        : 'Ask follow-up questions...',
                                hintStyle: TextStyle(
                                  color: Colors.grey[500],
                                ),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.all(8.r),
                            child: GestureDetector(
                              onTap: _sendMessage,
                              child: Container(
                                width: 40.w,
                                height: 40.h,
                                decoration: BoxDecoration(
                                  color: Color(0xFF065F46),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_messages.isEmpty && !_isConversationMode) ...[
                      SizedBox(height: 16.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _sendMessage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2D7D32),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16.r),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Create My Itinerary',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}