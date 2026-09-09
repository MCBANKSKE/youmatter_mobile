import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:youmatter_mobile/core/networking/api_service.dart';
// import 'package:youmatter_mobile/core/services/local_notification_service.dart';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  final _api = ApiService();
  List<dynamic> _offers = [];
  bool _loading = true;
  final Set<String> _busy = {};
  // final Set<String> _notifiedOfferIds = {};

  @override
  void initState() {
    super.initState();
    _goAvailable();
  }

  @override
  void dispose() {
    // Fire-and-forget: return to idle when leaving the listener screen.
    _api.updateActivity('idle').catchError((_) {});
    super.dispose();
  }

  /// The backend only matches users whose activity is
  /// `available_to_listen`, so set it before polling for offers.
  Future<void> _goAvailable() async {
    try {
      await _api.updateActivity('available_to_listen');
    } catch (_) {}
    _load();
  }

  Future<void> _load() async {
    try {
      final offers = await _api.getOffers();
      if (!mounted) return;
      setState(() {
        _offers = offers;
        _loading = false;
      });

      // NOTE: local notifications are temporarily disabled (see main.dart).
      // Fire a "someone needs to talk" notification for newly-seen offers.
      // for (final offer in offers) {
      //   final map = offer as Map<String, dynamic>?;
      //   if (map == null) continue;
      //   final id = map['id']?.toString();
      //   if (id == null || _notifiedOfferIds.contains(id)) continue;
      //   _notifiedOfferIds.add(id);
      //   final request = map['talk_request'] as Map<String, dynamic>?;
      //   final topic = request?['topic']?.toString() ?? '';
      //   LocalNotificationService.instance.showSomeoneNeedsTalk(topic);
      // }

      await Future.delayed(const Duration(seconds: 5));
      if (mounted) _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _respond(Map<String, dynamic> offer, bool accept) async {
    final id = offer['id'].toString();
    setState(() => _busy.add(id));
    try {
      if (accept) {
        await _api.acceptOffer(id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Offer accepted! Opening conversations…')),
        );
        context.go('/conversations');
        return;
      } else {
        await _api.declineOffer(id);
        if (!mounted) return;
        setState(() {
          _offers.removeWhere((o) => o['id'].toString() == id);
          _busy.remove(id);
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy.remove(id));
      String message = 'Could not respond to this offer. It may have expired.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('I want to listen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _offers.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.hourglass_empty, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'No requests right now.\nWhen someone needs a listener, their request will appear here.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _offers.length,
                                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final offer = _offers[index] as Map<String, dynamic>;
                      final request =
                          offer['talk_request'] as Map<String, dynamic>?;
                      final id = offer['id'].toString();
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color:
                                Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request?['topic'] ?? 'Someone wants to talk',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if (request?['description'] != null &&
                                  (request?['description'] as String)
                                      .isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(request!['description']),
                              ],
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: _busy.contains(id)
                                          ? null
                                          : () => _respond(offer, true),
                                      child: const Text('Be there for them'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _busy.contains(id)
                                          ? null
                                          : () => _respond(offer, false),
                                      child: const Text('Pass'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}