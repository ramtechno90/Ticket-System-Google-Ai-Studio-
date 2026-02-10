import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cross_file/cross_file.dart';
import 'package:url_launcher/url_launcher.dart'; // Added
import '../models/user_model.dart';
import '../models/ticket_model.dart';
import '../models/comment_model.dart';
import '../models/enums.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'image_viewer_screen.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _commentController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _commentFocusNode = FocusNode();
  bool _isSending = false;

  // State for pagination
  final List<Comment> _comments = [];
  DocumentSnapshot? _lastDoc;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final _scrollController = ScrollController();
  StreamSubscription<List<Comment>>? _newCommentsSubscription;
  DateTime? _initialFetchTime;
  late Stream<Ticket?> _ticketStream;
  final List<PlatformFile> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    _ticketStream = _firestoreService.getTicketStream(widget.ticketId);
    _initialFetchTime = DateTime.now();
    _fetchInitialComments();
    _listenForNewComments();

    _scrollController.addListener(() {
      // In wide layout, the main scroll controller is used by the SingleChildScrollView
      // Pagination logic might need to check the scroll position differently or rely on manual loading.
      // For simplicity, we keep manual loading button visible when needed.
      if (!mounted) return;
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    _scrollController.dispose();
    _newCommentsSubscription?.cancel();
    super.dispose();
  }

  String _lookupMimeType(String name) {
    final extension = name.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _fetchInitialComments() async {
    setState(() => _isLoading = true);
    try {
      final result = await _firestoreService.getComments(widget.ticketId);
      final fetchedComments = result['comments'] as List<Comment>;
      final lastDoc = result['lastDoc'] as DocumentSnapshot?;

      if (mounted) {
        setState(() {
          _comments.clear();
          _comments.addAll(fetchedComments);
          _lastDoc = lastDoc;
          _hasMore = fetchedComments.length == 10; // Page size
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching comments: $e')),
        );
      }
    }
  }

  Future<void> _fetchMoreComments() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final result = await _firestoreService.getComments(widget.ticketId, lastDoc: _lastDoc);
      final fetchedComments = result['comments'] as List<Comment>;
      final lastDoc = result['lastDoc'] as DocumentSnapshot?;

      if (mounted) {
        setState(() {
          _comments.addAll(fetchedComments);
          _lastDoc = lastDoc;
          _hasMore = fetchedComments.isNotEmpty;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _listenForNewComments() {
    // Fetches comments created after the screen was opened
    _newCommentsSubscription = _firestoreService
        .getNewComments(widget.ticketId, _initialFetchTime!)
        .listen((newComments) {
      if (mounted) {
        setState(() {
          for (final newComment in newComments) { // Insert in correct order for reverse list
            if (!_comments.any((c) => c.id == newComment.id)) {
              _comments.insert(0, newComment); // Add to index 0 (Bottom in reverse list)
            }
          }
        });
      }
    });
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );

    if (result != null) {
      setState(() {
        _selectedFiles.addAll(result.files);
      });
    }
  }

  void _removeFile(PlatformFile file) {
    setState(() {
      _selectedFiles.remove(file);
    });
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty && _selectedFiles.isEmpty) return;
    setState(() => _isSending = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser!;
      final storageService = StorageService();

      final commentId = DateTime.now().millisecondsSinceEpoch.toString();
      List<String> attachmentUrls = [];

      for (var file in _selectedFiles) {
        String path = 'tickets/${widget.ticketId}/comments/$commentId/${file.name}';
        XFile xFile;
        String mimeType = _lookupMimeType(file.name);
        if (file.bytes != null) {
           xFile = XFile.fromData(file.bytes!, name: file.name, mimeType: mimeType);
        } else if (file.path != null && !kIsWeb) {
           xFile = XFile(file.path!, name: file.name, mimeType: mimeType);
        } else {
           continue;
        }
        String url = await storageService.uploadFile(file: xFile, path: path);
        attachmentUrls.add(url);
      }

      final comment = Comment(
        id: commentId,
        ticketId: widget.ticketId,
        userId: user.uid,
        userName: user.name,
        userRole: user.role,
        text: _commentController.text.trim(),
        timestamp: DateTime.now(),
        clientId: user.clientId,
        attachments: attachmentUrls,
      );

      await _firestoreService.addComment(widget.ticketId, comment);
      _commentController.clear();
      setState(() {
        _selectedFiles.clear();
      });
      // New comment will be added via the real-time listener
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding comment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _updateStatus(TicketStatus status) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser!;

      final systemComment = Comment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        ticketId: widget.ticketId,
        userId: user.uid,
        userName: user.name,
        userRole: user.role,
        text: 'Status changed to ${status.value}',
        timestamp: DateTime.now(),
        isSystemMessage: true,
        clientId: user.clientId,
      );

      await _firestoreService.updateTicketStatus(
        widget.ticketId,
        status,
        systemComment: systemComment
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ticket status updated to ${status.value}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  Future<void> _deleteTicket(String ticketId, UserRole role) async {
    try {
      await _firestoreService.deleteTicket(ticketId, role);
      if (mounted) {
        Navigator.of(context).pop(); // Return to dashboard
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket deleted from view')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting ticket: $e')),
        );
      }
    }
  }

  void _openImage(String url) {
    if (kIsWeb) {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ImageViewerScreen(imageUrl: url),
        ),
      );
    }
  }

  Widget _buildActionButtons(Ticket ticket, UserModel user) {
    bool isManufacturer = [UserRole.support_agent, UserRole.supervisor, UserRole.admin].contains(user.role);
    List<Widget> buttons = [];

    if (isManufacturer) {
      if (ticket.status == TicketStatus.newTicket) {
        buttons.add(_buildActionButton('Acknowledge', () => _updateStatus(TicketStatus.acknowledged), Colors.white, Colors.black, outline: true));
        buttons.add(const SizedBox(height: 8));
        buttons.add(_buildActionButton('Hold for Info', () => _updateStatus(TicketStatus.holdForInfo), Colors.white, Colors.black, outline: true));
      } else if (ticket.status == TicketStatus.acknowledged) {
        buttons.add(_buildActionButton('Progress Work', () => _updateStatus(TicketStatus.inProgress), Colors.white, Colors.black, outline: true));
      } else if (ticket.status == TicketStatus.inProgress) {
        buttons.add(_buildActionButton('Resolve Ticket', () => _updateStatus(TicketStatus.resolved), Colors.green, Colors.white));
        buttons.add(const SizedBox(height: 8));
        buttons.add(_buildActionButton('Hold for Info', () => _updateStatus(TicketStatus.holdForInfo), Colors.white, Colors.black, outline: true));
      } else if (ticket.status == TicketStatus.holdForInfo) {
        buttons.add(_buildActionButton('Reactivate', () => _updateStatus(TicketStatus.acknowledged), Colors.white, Colors.black, outline: true));
      } else if (ticket.status == TicketStatus.resolved) {
        buttons.add(_buildActionButton('Close Ticket', () => _updateStatus(TicketStatus.closed), Colors.white, Colors.black, outline: true));
      }
    } else {
      // Client
      if (ticket.status == TicketStatus.resolved) {
        buttons.add(_buildActionButton('Reopen Ticket', () => _updateStatus(TicketStatus.acknowledged), Colors.green, Colors.white));
      }
    }

    if (ticket.status == TicketStatus.closed) {
      if (buttons.isNotEmpty) buttons.add(const SizedBox(height: 8));
      buttons.add(_buildActionButton(
        'Delete Ticket',
        () => _deleteTicket(ticket.id, user.role),
        Colors.red,
        Colors.white,
      ));
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('MANAGEMENT ACTIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          ...buttons,
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed, Color bgColor, Color textColor, {bool outline = false}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: outline ? 0 : 2,
        side: outline ? BorderSide(color: Colors.grey.shade300) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildFilePreviews() {
    if (_selectedFiles.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _selectedFiles.map((file) {
          return Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: file.bytes != null
                      ? Image.memory(file.bytes!, fit: BoxFit.cover)
                      : const Icon(Icons.image, color: Colors.grey),
                ),
              ),
              GestureDetector(
                onTap: () => _removeFile(file),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCommentItem(Comment comment) {
    if (comment.isSystemMessage) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            comment.text,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
          ),
        ),
      );
    }

    bool isClient = comment.userRole == UserRole.client_user;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isClient ? Colors.white : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isClient ? Colors.grey.shade200 : Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(comment.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(DateFormat('h:mm a').format(comment.timestamp), style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          if (comment.text.isNotEmpty) Text(comment.text),
          if (comment.attachments.isNotEmpty) ...[
            if (comment.text.isNotEmpty) const SizedBox(height: 8),
            Wrap(
               spacing: 8,
               runSpacing: 8,
               children: comment.attachments.map((url) =>
                  GestureDetector(
                    onTap: () => _openImage(url),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ClipRRect(
                         borderRadius: BorderRadius.circular(8),
                         child: Image.network(
                            url,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                               return GestureDetector(
                                 onTap: () => _openImage(url),
                                 child: Container(
                                   width: 100,
                                   height: 100,
                                   color: Colors.grey.shade200,
                                   child: const Column(
                                     mainAxisAlignment: MainAxisAlignment.center,
                                     children: [
                                       Icon(Icons.broken_image, color: Colors.grey),
                                       SizedBox(height: 4),
                                       Text('Tap to view', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                     ],
                                   ),
                                 ),
                               );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                               if (loadingProgress == null) return child;
                               return Container(
                                 width: 100,
                                 height: 100,
                                 color: Colors.grey.shade200,
                                 child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                               );
                            },
                         ),
                      ),
                    ),
                  )
               ).toList(),
            ),
          ]
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Row(children: [Text('Ticket #${widget.ticketId}', style: const TextStyle(fontSize: 16))]),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<Ticket?>(
        stream: _ticketStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Ticket not found'));
          }

          final ticket = snapshot.data!;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              final isShort = constraints.maxHeight < 600;

              Widget buildStatus() => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        const Text('TICKET LIFECYCLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: ticket.status.color,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: ticket.status.color.withOpacity(0.5)),
                          ),
                          child: Text(ticket.status.value, style: TextStyle(color: ticket.status.textColor, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );

              Widget buildDescriptionCard() => Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    WidgetSpan(
                                      child: const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                                      alignment: PlaceholderAlignment.middle,
                                    ),
                                    const WidgetSpan(child: SizedBox(width: 4)),
                                    TextSpan(text: ticket.userName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                                    const TextSpan(text: ' reported in ', style: TextStyle(color: Colors.grey)),
                                    TextSpan(text: ticket.category.value, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(DateFormat('MMM d, h:mm a').format(ticket.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(ticket.subject, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Text(ticket.description, style: const TextStyle(fontSize: 15, height: 1.5)),
                         if (ticket.attachments.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text('Attachments:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ticket.attachments.map((url) =>
                            GestureDetector(
                              onTap: () => _openImage(url),
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                  image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                                ),
                              ),
                            )
                          ).toList(),
                        ),
                      ]
                      ],
                    ),
                  );

              Widget buildCommentInput() => ticket.status != TicketStatus.closed
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            key: const ValueKey('commentInput'),
                            focusNode: _commentFocusNode,
                            controller: _commentController,
                            decoration: const InputDecoration(hintText: 'Write your reply...', border: InputBorder.none),
                            maxLines: 3,
                          ),
                          _buildFilePreviews(),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.attach_file, color: Colors.grey),
                                onPressed: _pickFiles,
                                tooltip: 'Attach photos',
                              ),
                              ElevatedButton.icon(
                                onPressed: _isSending ? null : _submitComment,
                                icon: const Icon(Icons.send, size: 16),
                                label: const Text('Reply'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink();
              
              Widget buildTimeline({bool shrinkWrap = false, ScrollPhysics? physics}) {
                if (_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  reverse: true,
                  controller: shrinkWrap ? null : _scrollController,
                  shrinkWrap: shrinkWrap,
                  physics: physics,
                  itemCount: _comments.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _comments.length) {
                      if (_hasMore) {
                        if (_isLoadingMore) {
                          return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
                        } else {
                          return Center(
                            child: TextButton(
                              onPressed: _fetchMoreComments,
                              child: const Text('Load older comments'),
                            ),
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    }
                    return _buildCommentItem(_comments[index]);
                  },
                );
              }

              Widget buildMainContent() {
                // In wide mode (inside SingleChildScrollView), we use shrinkWrap and no physics
                // In mobile mode (inside SingleChildScrollView), we also use shrinkWrap and no physics
                final timeline = buildTimeline(shrinkWrap: true, physics: const NeverScrollableScrollPhysics());

                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Communication Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      timeline,
                      const SizedBox(height: 16),
                      buildCommentInput(),
                    ],
                  );
              }

              if (isWide) {
                return SingleChildScrollView(
                  controller: _scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: buildMainContent()),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              buildDescriptionCard(),
                              const SizedBox(height: 16),
                              buildStatus(),
                              const SizedBox(height: 16),
                              _buildActionButtons(ticket, user),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                // Mobile Layout: Single Scroll View
                return SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      buildStatus(),
                      const SizedBox(height: 16),
                      _buildActionButtons(ticket, user),
                      if ([UserRole.support_agent, UserRole.supervisor, UserRole.admin].contains(user.role)) const SizedBox(height: 16),
                      buildDescriptionCard(),
                      const SizedBox(height: 24),
                      const Text('Communication Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      buildTimeline(shrinkWrap: true, physics: const NeverScrollableScrollPhysics()),
                      const SizedBox(height: 16),
                      buildCommentInput(),
                      const SizedBox(height: 32), // Bottom padding
                    ],
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
