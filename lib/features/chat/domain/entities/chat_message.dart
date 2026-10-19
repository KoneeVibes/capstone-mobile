import 'package:equatable/equatable.dart';

/// One line in a case conversation.
///
/// Mock for now; the real transport fills the same shape.
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.authorName,
    required this.text,
    required this.isMine,
  });

  final String id;

  /// Shown above the text; also the source of the avatar initial.
  final String authorName;

  final String text;

  /// Whether the signed-in member sent it, which sides and colours the row.
  final bool isMine;

  @override
  List<Object?> get props => [id, authorName, text, isMine];
}
