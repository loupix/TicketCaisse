import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/saved_tickets_provider.dart';
import '../models/ticket_data.dart';
import 'ticket_detail_screen.dart';

class TicketsListScreen extends ConsumerWidget {
  const TicketsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(savedTicketsProvider);
    final notifier = ref.read(savedTicketsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tickets sauvegardés'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => notifier.load(),
        child: Builder(
          builder: (_) {
            if (state.isLoading && state.tickets.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.error != null) {
              return Center(child: Text(state.error!));
            }
            if (state.tickets.isEmpty) {
              return const Center(child: Text('Aucun ticket sauvegardé'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: state.tickets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final t = state.tickets[index];
                return Dismissible(
                  key: ValueKey(t.id ?? index),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    if (t.id != null) notifier.delete(t.id!);
                  },
                  child: _TicketTile(ticket: t),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  final TicketData ticket;
  const _TicketTile({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
      title: Text(ticket.storeName ?? 'Ticket sans magasin'),
      subtitle: Text(_buildSubtitle()),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TicketDetailScreen(),
            settings: RouteSettings(arguments: ticket),
          ),
        );
      },
    );
  }

  String _buildSubtitle() {
    final date = ticket.createdAt ?? ticket.date;
    final total = ticket.total != null ? '${ticket.total!.toStringAsFixed(2)}${ticket.currency ?? '€'}' : 'Total inconnu';
    final when = date != null ? '${date.day}/${date.month}/${date.year}' : 'Date inconnue';
    return '$when • $total • ${ticket.items.length} article(s)';
  }
}

