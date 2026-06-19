import 'package:flutter/material.dart';
import '../services/app_review_service.dart';

/// Modal dialog where the user rates the app.
/// Pass [initialRating] / [initialComment] to pre-fill when editing.
class RateAppDialog extends StatefulWidget {
  final int? initialRating;
  final String? initialComment;

  const RateAppDialog({super.key, this.initialRating, this.initialComment});

  /// Returns true if the user submitted a review, false if cancelled.
  static Future<bool> show(
    BuildContext context, {
    int? initialRating,
    String? initialComment,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RateAppDialog(
        initialRating: initialRating,
        initialComment: initialComment,
      ),
    );
    return result == true;
  }

  @override
  State<RateAppDialog> createState() => _RateAppDialogState();
}

class _RateAppDialogState extends State<RateAppDialog> {
  late int _rating;
  late TextEditingController _commentController;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating ?? 0;
    _commentController = TextEditingController(text: widget.initialComment ?? '');
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1) {
      setState(() => _error = 'Please pick a star rating');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final ok = await AppReviewService().submit(
      rating: _rating,
      comment: _commentController.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks for your feedback!')),
      );
    } else {
      setState(() {
        _submitting = false;
        _error = 'Could not submit. Try again in a moment.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite, color: Colors.pink, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.initialRating != null ? 'Update your review' : 'Enjoying the app?',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Your feedback helps us make it better.',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 18),

            // Star picker
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final filled = i < _rating;
                  return IconButton(
                    icon: Icon(
                      filled ? Icons.star_rounded : Icons.star_border_rounded,
                      color: filled ? Colors.amber : Colors.grey.shade400,
                      size: 38,
                    ),
                    onPressed: _submitting ? null : () => setState(() => _rating = i + 1),
                  );
                }),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                _ratingLabel(_rating),
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 16),

            // Comment
            TextField(
              controller: _commentController,
              enabled: !_submitting,
              maxLength: 1000,
              maxLines: 3,
              minLines: 3,
              decoration: InputDecoration(
                hintText: 'Tell us more (optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(12),
                counterText: '',
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
              ),
            ],

            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
                  child: const Text('Not now'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(widget.initialRating != null ? 'Update' : 'Submit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1: return 'Hated it';
      case 2: return 'Disliked it';
      case 3: return 'It was okay';
      case 4: return 'Liked it';
      case 5: return 'Loved it!';
      default: return 'Tap a star';
    }
  }
}
