import 'package:flutter/material.dart';

class AuthorTierBadge extends StatelessWidget {
  final String tier;
  final double size;

  const AuthorTierBadge({
    super.key,
    required this.tier,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final t = tier.toLowerCase();
    final theme = Theme.of(context);
    final color = theme.iconTheme.color ?? theme.textTheme.bodyMedium?.color;
    
    if (t == 'popular' || t == 'top') {
      return Icon(Icons.verified, size: size, color: Colors.blue[500]);
    }
    
    if (t == 'diamond') {
      return Icon(Icons.diamond_outlined, size: size, color: color);
    }
    
    if (t == 'gold') {
      return Icon(Icons.auto_awesome, size: size, color: color);
    }
    
    if (t == 'silver') {
      return Icon(Icons.bolt_outlined, size: size, color: color);
    }
    
    // Bronze
    return Icon(Icons.local_fire_department_outlined, size: size, color: color);
  }
}
