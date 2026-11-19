
import 'package:flutter/material.dart';

class DocumentPreview extends StatelessWidget {
  final String documentUrl;
  final String title;
  final VoidCallback? onTap;

  const DocumentPreview({
    super.key,
    required this.documentUrl,
    required this.title,
    this.onTap,
  });

  bool get _isImage {
    final url = documentUrl.toLowerCase();
    return url.endsWith('.png') ||
        url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.webp');
  }

  @override
  Widget build(BuildContext context) {
    if (documentUrl.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('No document attached'),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.teal.shade100),
        ),
        child: Row(
          children: [
            if (_isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  documentUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                       const Icon(Icons.broken_image, size: 48),
                ),
              )
            else
              const Icon(
                Icons.picture_as_pdf,
                size: 48,
                color: Colors.red,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.open_in_new, color: Colors.teal),
          ],
        ),
      ),
    );
  }
}
