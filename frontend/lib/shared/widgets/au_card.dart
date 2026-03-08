import 'package:flutter/material.dart';

/// Reusable Series Card widget used across Home, Search, Library screens.
class SeriesCard extends StatelessWidget {
  final String title;
  final String author;
  final String coverUrl;
  final List<String> genres;
  final VoidCallback? onTap;
  final VoidCallback? onReadTap;

  const SeriesCard({
    super.key,
    required this.title,
    required this.author,
    this.coverUrl = '',
    this.genres = const [],
    this.onTap,
    this.onReadTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 220,
                width: 160,
                color: theme.primaryColor.withAlpha(20),
                child: coverUrl.isNotEmpty
                    ? Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _placeholder(theme),
                      )
                    : _placeholder(theme),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 6),
            if (genres.isNotEmpty)
              Wrap(
                spacing: 4,
                children: genres
                    .take(2)
                    .map(
                      (g) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          g,
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme) {
    return Center(
      child: Icon(
        Icons.auto_stories_rounded,
        size: 48,
        color: theme.primaryColor.withAlpha(80),
      ),
    );
  }
}

/// Horizontal list Series card used for FYP sections.
class SeriesListCard extends StatelessWidget {
  final String title;
  final String author;
  final String coverUrl;
  final List<String> genres;
  final String? subtitle;
  final VoidCallback? onTap;

  const SeriesListCard({
    super.key,
    required this.title,
    required this.author,
    this.coverUrl = '',
    this.genres = const [],
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 80,
                width: 60,
                color: theme.primaryColor.withAlpha(20),
                child: coverUrl.isNotEmpty
                    ? Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.auto_stories,
                          color: theme.primaryColor.withAlpha(80),
                        ),
                      )
                    : Icon(
                        Icons.auto_stories,
                        color: theme.primaryColor.withAlpha(80),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    author,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                  if (genres.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      children: genres
                          .take(3)
                          .map(
                            (g) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                g,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
