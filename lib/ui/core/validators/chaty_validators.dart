class ChatyValidators {
  // Reserved usernames that cannot be registered
  static const Set<String> reservedUsernames = {
    'admin',
    'administrator',
    'root',
    'support',
    'security',
    'chaty',
    'official',
    'moderator',
    'system',
    'help',
    'bot',
    'service',
    'guest',
    'null',
    'undefined',
    'anonymous',
    'channel',
    'community',
    'group',
    'saved',
    'updates',
  };

  /// Normalizes a username: lowercase, stripped of leading @ and whitespace
  static String normalizeUsername(String username) {
    return username.trim().toLowerCase().replaceAll(RegExp(r'^@+'), '');
  }

  /// Validates a username format
  /// Rules: 4-32 characters, alphanumeric and underscore only, cannot be reserved
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }

    final normalized = normalizeUsername(value);

    if (normalized.length < 4) {
      return 'Username must be at least 4 characters';
    }

    if (normalized.length > 32) {
      return 'Username must not exceed 32 characters';
    }

    final validPattern = RegExp(r'^[a-z0-9_]+$');
    if (!validPattern.hasMatch(normalized)) {
      return 'Only letters, numbers, and underscores are allowed';
    }

    if (reservedUsernames.contains(normalized)) {
      return 'This username is reserved and cannot be registered';
    }

    return null;
  }

  /// Validates an email address
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }

    final email = value.trim();
    final emailPattern = RegExp(
      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
    );

    if (!emailPattern.hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validates a password
  /// Rules: minimum 6 characters for practical usability
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    if (value.length > 128) {
      return 'Password cannot exceed 128 characters';
    }

    return null;
  }

  /// Validates a phone number using E.164-like practical rules
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    final phonePattern = RegExp(r'^\+?[0-9]{7,15}$');

    if (!phonePattern.hasMatch(cleaned)) {
      return 'Please enter a valid international phone number';
    }

    return null;
  }

  /// Validates display name
  static String? validateDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Display name is required';
    }

    if (value.trim().length > 50) {
      return 'Display name must not exceed 50 characters';
    }

    return null;
  }

  /// Validates group/channel title
  static String? validateGroupTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Title is required';
    }

    if (value.trim().length > 64) {
      return 'Title must not exceed 64 characters';
    }

    return null;
  }

  /// Validates bio / about text
  static String? validateBio(String? value) {
    if (value != null && value.length > 256) {
      return 'Bio must not exceed 256 characters';
    }
    return null;
  }
}
