import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ParsedCookie {
  final String name;
  final String value;
  final String? domain;
  final String? path;
  final String? expires;
  final bool httpOnly;
  final bool secure;
  final String? sameSite;

  ParsedCookie({
    required this.name,
    required this.value,
    this.domain,
    this.path,
    this.expires,
    this.httpOnly = false,
    this.secure = false,
    this.sameSite,
  });

  static List<ParsedCookie> parseHeaders(Map<String, String> headers) {
    final List<ParsedCookie> cookies = [];

    // Look for set-cookie header (case-insensitive)
    String? setCookieHeader;
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == 'set-cookie') {
        setCookieHeader = entry.value;
        break;
      }
    }

    if (setCookieHeader == null || setCookieHeader.trim().isEmpty) {
      return cookies;
    }

    // Split multiple cookies: commas followed by a cookie pair (name=value)
    // Avoid splitting within Expires dates like "Expires=Wed, 21 Oct 2026 07:28:00 GMT"
    final cookieRegex = RegExp(r',(?=\s*[^;=]+=[^;]+)');
    final rawCookieStrings = setCookieHeader.split(cookieRegex);

    for (final rawCookie in rawCookieStrings) {
      final parts = rawCookie.split(';').map((s) => s.trim()).toList();
      if (parts.isEmpty || !parts[0].contains('=')) continue;

      final firstEquals = parts[0].indexOf('=');
      final name = parts[0].substring(0, firstEquals).trim();
      final value = parts[0].substring(firstEquals + 1).trim();

      String? domain;
      String? path;
      String? expires;
      bool httpOnly = false;
      bool secure = false;
      String? sameSite;

      for (int i = 1; i < parts.length; i++) {
        final attr = parts[i];
        final lower = attr.toLowerCase();

        if (lower == 'httponly') {
          httpOnly = true;
        } else if (lower == 'secure') {
          secure = true;
        } else if (lower.startsWith('domain=')) {
          domain = attr.substring(7).trim();
        } else if (lower.startsWith('path=')) {
          path = attr.substring(5).trim();
        } else if (lower.startsWith('expires=')) {
          expires = attr.substring(8).trim();
        } else if (lower.startsWith('max-age=')) {
          expires ??= 'Max-Age: ${attr.substring(8).trim()}';
        } else if (lower.startsWith('samesite=')) {
          sameSite = attr.substring(9).trim();
        }
      }

      cookies.add(ParsedCookie(
        name: name,
        value: value,
        domain: domain,
        path: path,
        expires: expires,
        httpOnly: httpOnly,
        secure: secure,
        sameSite: sameSite,
      ));
    }

    return cookies;
  }
}

class ResponseCookiesView extends StatelessWidget {
  final Map<String, String> headers;

  const ResponseCookiesView({super.key, required this.headers});

  @override
  Widget build(BuildContext context) {
    final cookies = ParsedCookie.parseHeaders(headers);

    if (cookies.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cookie_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No cookies returned by server',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cookies.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final cookie = cookies[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        cookie.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFCBA6F7),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      tooltip: 'Copy Cookie',
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: '${cookie.name}=${cookie.value}'),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Copied cookie "${cookie.name}"'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SelectableText(
                  cookie.value,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (cookie.httpOnly)
                      _buildBadge('HttpOnly', const Color(0xFF10B981)),
                    if (cookie.secure)
                      _buildBadge('Secure', const Color(0xFF818CF8)),
                    if (cookie.sameSite != null)
                      _buildBadge('SameSite: ${cookie.sameSite}', Colors.amber),
                    if (cookie.domain != null)
                      _buildBadge('Domain: ${cookie.domain}', Colors.blueGrey),
                    if (cookie.path != null)
                      _buildBadge('Path: ${cookie.path}', Colors.grey),
                    if (cookie.expires != null)
                      _buildBadge('Expires: ${cookie.expires}', Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
