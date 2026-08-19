import 'package:flutter/material.dart';
import '../../ui/core/theme/theme_controller.dart';
import '../../injection/locator.dart';
import '../auth/widgets/auth_components.dart';

class ProPricingScreen extends StatefulWidget {
  const ProPricingScreen({super.key});

  @override
  State<ProPricingScreen> createState() => _ProPricingScreenState();
}

class _ProPricingScreenState extends State<ProPricingScreen> {
  bool _isYearly = true;

  @override
  Widget build(BuildContext context) {
    final theme = locator<ThemeController>().globalTheme;
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark ? const Color(0xFF141416) : Colors.white;
    final borderCol = isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top circular back button & title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AuthBackButton(),
                  Text(
                    'Pricing Plan',
                    style: TextStyle(
                      color: theme.primaryTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert_rounded, color: theme.secondaryTextColor),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Title and Subtitle matching mockup
              Center(
                child: Column(
                  children: [
                    Text(
                      'Easily Build Better Chats\nwith Chaty Pro',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.primaryTextColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Turn ideas into conversations instantly with AI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.secondaryTextColor,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Segmented Switch (Monthly | Yearly [Save 50%])
              Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F1F23) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: borderCol, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Monthly button
                      GestureDetector(
                        onTap: () => setState(() => _isYearly = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isYearly
                                ? (isDark ? Colors.white : const Color(0xFF09090B))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            'Monthly',
                            style: TextStyle(
                              color: !_isYearly
                                  ? (isDark ? Colors.black : Colors.white)
                                  : theme.secondaryTextColor,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      // Yearly button
                      GestureDetector(
                        onTap: () => setState(() => _isYearly = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: _isYearly
                                ? (isDark ? Colors.white : const Color(0xFF09090B))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Yearly',
                                style: TextStyle(
                                  color: _isYearly
                                      ? (isDark ? Colors.black : Colors.white)
                                      : theme.secondaryTextColor,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Save 50%',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Plus Plan Card matching the mockup
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: borderCol, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.4) : const Color(0x0C000000),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plus',
                      style: TextStyle(
                        color: theme.primaryTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _isYearly ? '\$10.25' : '\$20.50',
                          style: TextStyle(
                            color: theme.primaryTextColor,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isYearly ? 'Per Month billed annually' : 'Per Month billed monthly',
                          style: TextStyle(
                            color: theme.secondaryTextColor,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Solid Pill Get Started Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Chaty Pro Plus Plan Activated! 🎉',
                                style: TextStyle(color: theme.onAccentColor, fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: theme.accentColor,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.white : const Color(0xFF09090B),
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          'Get Started',
                          style: TextStyle(
                            color: isDark ? Colors.black : Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Pricing plan',
                      style: TextStyle(
                        color: theme.secondaryTextColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),

                    _buildCheckItem(theme, 'Smart AI messaging assistance'),
                    _buildCheckItem(theme, 'Access to Chaty Pro Theme Library'),
                    _buildCheckItem(theme, 'Early access to new features'),
                    _buildCheckItem(theme, 'Next-generation privacy & encryption tools'),
                    _buildCheckItem(theme, 'Unlimited task and backup synchronization'),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckItem(dynamic theme, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 14,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: theme.primaryTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
