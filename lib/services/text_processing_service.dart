import 'package:flutter/foundation.dart';

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
          .replaceAll(''', "'")
          .replaceAll(''', "'")
          .replaceAll('"', '"')
          .replaceAll('"', '"')
          .replaceAll('–', '-')
          .replaceAll('—', '-')
          // Fix specific encoding issues we've observed
          .replaceAll('ä', "'")   // Fix incorrect 'ä' that appears instead of apostrophes
          .replaceAll('â', "'")   // Fix incorrect 'â' that appears instead of apostrophes
          .replaceAll('ås', "'s") // Fix incorrect 'ås' pattern
          .replaceAll('äs', "'s") // Fix incorrect 'äs' pattern
          .replaceAll('âs', "'s") // Fix incorrect 'âs' pattern
          .replaceAll('eä', "e'") // Fix common pattern
          .replaceAll('eâ', "e'") // Fix common pattern
          .replaceAll('äre', "'re") // Fix common pattern
          .replaceAll('âre', "'re") // Fix common pattern
          .replaceAll('äve', "'ve") // Fix common pattern
          .replaceAll('âve', "'ve") // Fix common pattern
          .replaceAll('äll', "'ll") // Fix common pattern
          .replaceAll('âll', "'ll") // Fix common pattern
          .replaceAll('äd', "'d") // Fix common pattern
          .replaceAll('âd', "'d") // Fix common pattern
          .replaceAll('ät', "'t") // Fix common pattern
          .replaceAll('ât', "'t") // Fix common pattern
          .replaceAll('än', "'n") // Fix common pattern
          .replaceAll('ân', "'n") // Fix common pattern
          // Fix cases where 'ä' or 'â' appears instead of a space
          .replaceAll('äwhether', ' whether')
          .replaceAll('âwhether', ' whether')
          .replaceAll('äjust', ' just')
          .replaceAll('âjust', ' just')
          .replaceAll('äand', ' and')
          .replaceAll('âand', ' and')
          .replaceAll('äor', ' or')
          .replaceAll('âor', ' or')
          .replaceAll('äbut', ' but')
          .replaceAll('âbut', ' but')
          .replaceAll('äso', ' so')
          .replaceAll('âso', ' so')
          .replaceAll('äthen', ' then')
          .replaceAll('âthen', ' then')
          .replaceAll('äthe', ' the')
          .replaceAll('âthe', ' the')
          .replaceAll('äin', ' in')
          .replaceAll('âin', ' in')
          .replaceAll('äon', ' on')
          .replaceAll('âon', ' on')
          .replaceAll('äat', ' at')
          .replaceAll('âat', ' at')
          .replaceAll('äfor', ' for')
          .replaceAll('âfor', ' for')
          .replaceAll('äwith', ' with')
          .replaceAll('âwith', ' with')
          .replaceAll('äby', ' by')
          .replaceAll('âby', ' by')
          .replaceAll('äabout', ' about')
          .replaceAll('âabout', ' about')
          .replaceAll('äif', ' if')
          .replaceAll('âif', ' if')
          .replaceAll('äof', ' of')
          .replaceAll('âof', ' of')
          .replaceAll('ähow', ' how')
          .replaceAll('âhow', ' how')
          .replaceAll('âd like', "'d like");
      
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
      
      debugPrint('TextProcessingService: Removed control characters, now normalizing whitespace');
      
      // Normalize whitespace (replace multiple spaces with a single space)
      final normalizedWhitespace = cleanedText.replaceAll(RegExp(r'\s+'), ' ').trim();
      
      debugPrint('TextProcessingService: Normalization complete, returning processed text of length ${normalizedWhitespace.length}');
      return normalizedWhitespace;
    } catch (e) {
      // Log the error but return a best-effort cleaned string
      // This avoids throwing exceptions for text processing issues
      debugPrint('TextProcessingService: Error normalizing text: $e');
      
      debugPrint('TextProcessingService: Using fallback normalization');
      
      // More aggressive fallback that handles the specific issue we're seeing
      final fallbackResult = text
          .replaceAll('ä', "'")  // Replace problematic character with apostrophe as fallback
          .replaceAll('â', "'")  // Replace problematic character with apostrophe as fallback
          .replaceAll(RegExp(r'[^\x20-\x7E]'), '') // Remove non-ASCII
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
      debugPrint('TextProcessingService: Error sanitizing text: $e');
      
      final fallbackResult = text.replaceAll(RegExp(r'[^\x20-\x7E]'), '').trim();
      
      debugPrint('TextProcessingService: Fallback sanitization complete, returning text of length ${fallbackResult.length}');
      return fallbackResult;
    }
  }
} 