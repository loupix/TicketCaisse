import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ticket_data.dart';
import '../services/ticket_repository.dart';

class SavedTicketsState {
  final List<TicketData> tickets;
  final bool isLoading;
  final String? error;

  SavedTicketsState({
    this.tickets = const [],
    this.isLoading = false,
    this.error,
  });

  SavedTicketsState copyWith({
    List<TicketData>? tickets,
    bool? isLoading,
    String? error,
  }) {
    return SavedTicketsState(
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class SavedTicketsNotifier extends StateNotifier<SavedTicketsState> {
  SavedTicketsNotifier() : super(SavedTicketsState());

  final TicketRepository _repo = TicketRepository();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repo.loadTickets();
      state = state.copyWith(isLoading: false, tickets: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erreur chargement tickets: $e');
    }
  }

  Future<void> add(TicketData ticket) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final saved = await _repo.addTicket(ticket);
      final updated = [...state.tickets, saved];
      state = state.copyWith(isLoading: false, tickets: updated);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erreur enregistrement ticket: $e');
    }
  }

  Future<void> delete(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.deleteTicket(id);
      final updated = state.tickets.where((t) => t.id != id).toList();
      state = state.copyWith(isLoading: false, tickets: updated);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erreur suppression ticket: $e');
    }
  }
}

final savedTicketsProvider = StateNotifierProvider<SavedTicketsNotifier, SavedTicketsState>((ref) {
  final notifier = SavedTicketsNotifier();
  // Chargement initial paresseux côté UI via notifier.load()
  return notifier;
});

