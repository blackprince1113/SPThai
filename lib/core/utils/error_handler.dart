import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class ErrorHandler {
  static String getMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-credential':
          return 'Invalid email or password.';
        case 'email-already-in-use':
          return 'This email is already in use by another account.';
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'weak-password':
          return 'Password is too weak. It must be at least 6 characters.';
        case 'operation-not-allowed':
          return 'This login method is currently disabled.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'requires-recent-login':
          return 'Please log in again to perform this action.';
        case 'channel-error':
          return 'Please fill in all required fields.';
        default:
          return 'Authentication failed (${error.code}).';
      }
    } else if (error is PlatformException) {
      return 'System error: ${error.message}';
    } else if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Permission denied. You do not have permission to perform this action.';
        case 'not-found':
          return 'The requested user or resource was not found.';
        case 'already-exists':
          return 'The resource already exists.';
        case 'unavailable':
          return 'Database service is temporarily unavailable. Please try again later.';
        default:
          return 'Database error (${error.code}). Please try again later.';
      }
    } else if (error is String) {
      return error;
    }

    return 'An unexpected error occurred. Please try again.';
  }
}
