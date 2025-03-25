import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/error_utils.dart';

/// Service for consistent text processing throughout the app
class TextProcessingService {
  /// Normalizes text from API responses
  /// 
  /// - Replaces fancy quotes with standard quotes
  /// - Removes non-printable and control characters
  /// - Normalizes whitespace
  /// - Preserves emojis and other Unicode characters when possible
  static String normalizeText(String text) {
    debugPrint('TextProcessingService: normalizeText() called for text of length ${text.length}');
    
    if (text.isEmpty) {
      debugPrint('TextProcessingService: Input text is empty, returning as is');
      return text;
    }
    
    try {
      debugPrint('TextProcessingService: Applying text normalization rules');
      
      // Replace fancy quotes, apostrophes and problematic characters
      final replacedQuotes = text
          // Fix the U+0080 U+0099 sequence that appears in contractions
          .replaceAll('\u0080\u0099', "'")
          .replaceAll(''', "'")
          .replaceAll(''', "'")
          .replaceAll('"', '"')
          .replaceAll('"', '"')
          .replaceAll('–', '-')
          .replaceAll('—', '-')
          .replaceAll('Here\u2019s', "Here's")
          .replaceAll('There\u2019s', "There's")
          .replaceAll('It\u2019s', "It's")
          .replaceAll('What\u2019s', "What's")
          .replaceAll('That\u2019s', "That's")
          // Fix specific encoding issues we've observed
          .replaceAll('ä', "'")   // Fix incorrect 'ä' that appears instead of apostrophes
          .replaceAll('â', "'");  // Fix incorrect 'â' that appears instead of apostrophes
      
      debugPrint('TextProcessingService: Applied character replacements, now fixing spacing issues');
      
      // Fix spacing issues by replacing problematic characters when they appear as space replacements
      String fixSpacing(String input) {
        // Replace standalone 'ä' or 'â' that should be spaces (between words)
        var result = input.replaceAllMapped(RegExp(r'(\w)ä(\w)'), (match) {
          return '${match.group(1)} ${match.group(2)}';
        });
        
        result = result.replaceAllMapped(RegExp(r'(\w)â(\w)'), (match) {
          return '${match.group(1)} ${match.group(2)}';
        });
        
        return result;
      }
      
      final spacingFixed = fixSpacing(replacedQuotes);
      
      debugPrint('TextProcessingService: Fixed spacing issues, now removing control characters');
      
      // Remove control characters while preserving other Unicode
      // This is better than removing all non-ASCII as it preserves useful characters
      final cleanedText = spacingFixed.replaceAll(
        RegExp(r'[\p{C}]', unicode: true), 
        ''
      );
      
      // Replace any remaining instances of the right single quotation mark in contractions
      final contractionFixed = cleanedText.replaceAllMapped(
        RegExp(r'(\w+)\u2019(s|t|ve|re|ll|d|m)'),
        (match) => '${match.group(1)}\'${match.group(2)}'
      );
      
      debugPrint('TextProcessingService: Removed control characters, now normalizing whitespace');
      
      // Normalize whitespace (replace multiple spaces with a single space)
      final normalizedWhitespace = contractionFixed.replaceAll(RegExp(r'\s+'), ' ').trim();
      
      debugPrint('TextProcessingService: Normalization complete, returning processed text of length ${normalizedWhitespace.length}');
      return normalizedWhitespace;
    } catch (e) {
      // Log the error but return a best-effort cleaned string
      // This avoids throwing exceptions for text processing issues
      ErrorUtils.logError('TextProcessingService.normalizeText', e);
      
      debugPrint('TextProcessingService: Using fallback normalization');
      
      // More aggressive fallback that handles the specific issue we're seeing
      final fallbackResult = text
          .replaceAll('ä', "'")  // Replace problematic character with apostrophe as fallback
          .replaceAll('â', "'")  // Replace problematic character with apostrophe as fallback
          .replaceAll('\u2019', "'") // Replace right single quotation mark
          // Modified regex to preserve emojis and other useful Unicode characters
          .replaceAll(RegExp(r'[\p{C}]', unicode: true), '') // Only remove control characters, keep emojis
          .replaceAll(RegExp(r'\s+'), ' ') // Normalize spaces
          .trim();
          
      debugPrint('TextProcessingService: Fallback normalization complete, returning text of length ${fallbackResult.length}');
      return fallbackResult;
    }
  }
  
  /// Creates a safe display version of potentially problematic text
  /// Use this for user-generated content that will be displayed in the UI
  static String sanitizeForDisplay(String text) {
    debugPrint('TextProcessingService: sanitizeForDisplay() called for text of length ${text.length}');
    
    if (text.isEmpty) {
      debugPrint('TextProcessingService: Input text is empty, returning as is');
      return text;
    }
    
    try {
      debugPrint('TextProcessingService: Removing HTML tags');
      
      // Remove HTML tags that could cause rendering issues
      final noHtml = text.replaceAll(RegExp(r'<[^>]*>'), '');
      
      debugPrint('TextProcessingService: HTML tags removed, now applying general normalization');
      
      // Apply general normalization
      final result = normalizeText(noHtml);
      
      debugPrint('TextProcessingService: Sanitization complete, returning processed text of length ${result.length}');
      return result;
    } catch (e) {
      ErrorUtils.logError('TextProcessingService.sanitizeForDisplay', e);
      
      final fallbackResult = text
          // Modified regex to preserve emojis and other useful Unicode characters
          .replaceAll(RegExp(r'[\p{C}]', unicode: true), '') // Only remove control characters, keep emojis
          .trim();
      
      debugPrint('TextProcessingService: Fallback sanitization complete, returning text of length ${fallbackResult.length}');
      return fallbackResult;
    }
  }

  /// Normalizes text from API responses while preserving HTML and markdown formatting
  /// 
  /// - Replaces fancy quotes with standard quotes
  /// - Fixes encoding issues with apostrophes
  /// - Preserves HTML tags and markdown formatting
  static String normalizeTextPreserveMarkup(String text) {
    debugPrint('TextProcessingService: normalizeTextPreserveMarkup() called for text of length ${text.length}');
    
    if (text.isEmpty) {
      debugPrint('TextProcessingService: Input text is empty, returning as is');
      return text;
    }
    
    try {
      debugPrint('TextProcessingService: Applying text normalization rules while preserving markup');
      
      // Normalize all apostrophe sequences to a single standard apostrophe
      var result = text;
      result = result.replaceAll('\u0080\u0099', "'");
      result = result.replaceAll(''', "'");
      result = result.replaceAll(''', "'");
      result = result.replaceAll('\u2019', "'");
      result = result.replaceAll('ä', "'");
      result = result.replaceAll('â', "'");
      
      // Fix any double apostrophes that might have been created
      result = result.replaceAll("''", "'");
      
      // Handle quotes and dashes
      result = result
          .replaceAll('"', '"')
          .replaceAll('"', '"')
          .replaceAll('–', '-')
          .replaceAll('—', '-');
      
      debugPrint('TextProcessingService: Normalization complete, returning processed text of length ${result.length}');
      return result;
    } catch (e) {
      ErrorUtils.logError('TextProcessingService.normalizeTextPreserveMarkup', e);
      return text; // Return original text if normalization fails
    }
  }
} 