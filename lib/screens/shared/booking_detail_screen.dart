import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/booking_provider.dart';
import 'widgets/akrili_image.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  final int id;
  const BookingDetailScreen({super.key, required this.id});

  @override
  ConsumerState<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  bool _isProcessingDecision = false;
  bool _isSubmittingReview = false;
  int _selectedRating = 5;
  final _reviewController = TextEditingController();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'rejected':
      case 'cancelled':
        return AppTheme.secondary;
      case 'completed':
        return const Color(0xFF6366F1);
      default:
        return Colors.blueGrey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'rejected':
      case 'cancelled':
        return Icons.cancel_rounded;
      case 'completed':
        return Icons.verified_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _statusLocalized(String status, AppLocalizations tr) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return tr.statusConfirmed;
      case 'pending':
        return tr.statusPending;
      case 'rejected':
        return tr.statusRejected;
      case 'cancelled':
        return tr.statusCancelled;
      case 'completed':
        return tr.statusCompleted;
      default:
        return status;
    }
  }

  Future<void> _handleAccept() async {
    final tr = context.tr;
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(tr.acceptBtn),
        content: const Text(
          'Confirmer cette réservation ? Le voyageur en sera immédiatement informé par notification.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: Text(tr.acceptBtn),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessingDecision = true);
    try {
      final repo = ref.read(bookingRepositoryProvider);
      await repo.acceptBooking(widget.id);
      ref.invalidate(bookingDetailProvider(widget.id));
      ref.invalidate(hostBookingsProvider);
      ref.invalidate(guestBookingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr.bookingAcceptedSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString().replaceFirst("Exception: ", "")}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingDecision = false);
    }
  }

  Future<void> _handleReject() async {
    final tr = context.tr;
    HapticFeedback.mediumImpact();
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Refuser la réservation ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Veuillez indiquer un motif de refus (optionnel) :',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Motif',
                hintText: 'ex. Logement en travaux ou dates indisponibles',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
              foregroundColor: Colors.white,
            ),
            child: Text(tr.rejectBtn),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessingDecision = true);
    try {
      final repo = ref.read(bookingRepositoryProvider);
      await repo.rejectBooking(widget.id, reason: reasonController.text.trim());
      ref.invalidate(bookingDetailProvider(widget.id));
      ref.invalidate(hostBookingsProvider);
      ref.invalidate(guestBookingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr.bookingRejectedSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString().replaceFirst("Exception: ", "")}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingDecision = false);
    }
  }

  Future<void> _handleSubmitReview() async {
    final comment = _reviewController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez rédiger un commentaire pour votre avis.')),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSubmittingReview = true);
    try {
      final repo = ref.read(bookingRepositoryProvider);
      await repo.submitReview(
        bookingId: widget.id,
        rating: _selectedRating,
        comment: comment,
      );
      ref.invalidate(bookingDetailProvider(widget.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Merci ! Votre avis a été publié avec succès.')),
        );
        _reviewController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la publication : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingReview = false);
    }
  }

  String _formatDisplayDate(String rawDate) {
    try {
      final dt = DateTime.parse(rawDate);
      return DateFormat('EEEE dd MMMM yyyy', 'fr').format(dt);
    } catch (_) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final bookingAsync = ref.watch(bookingDetailProvider(widget.id));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.bookingDetailsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: tr.retry,
            onPressed: () => ref.refresh(bookingDetailProvider(widget.id)),
          ),
        ],
      ),
      body: bookingAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    size: 44,
                    color: AppTheme.secondary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Impossible de charger la réservation',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  err.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  onPressed: () => ref.refresh(bookingDetailProvider(widget.id)),
                  label: Text(tr.retry),
                ),
              ],
            ),
          ),
        ),
        data: (booking) {
          final statusColor = _statusColor(booking.status);
          final property = booking.property;

          // Calculate nights
          DateTime? inDate = DateTime.tryParse(booking.checkIn);
          DateTime? outDate = DateTime.tryParse(booking.checkOut);
          int nights = 1;
          if (inDate != null && outDate != null) {
            nights = outDate.difference(inDate).inDays;
            if (nights <= 0) nights = 1;
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Modern Status Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_statusIcon(booking.status), color: statusColor, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _statusLocalized(booking.status, tr).toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              booking.isPending
                                  ? 'En attente de confirmation de l\'hôte'
                                  : booking.isConfirmed
                                      ? 'Réservation confirmée et active'
                                      : booking.isRejected
                                          ? 'Demande de séjour refusée'
                                          : 'Réservation ${_statusLocalized(booking.status, tr)}',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? Colors.grey[300] : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Booking Reference & Booked Date
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
                    ),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr.referenceLabel,
                            style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            booking.reference.isNotEmpty ? booking.reference : '#${booking.id}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                        ],
                      ),
                      if (booking.createdAt != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              tr.bookedOnLabel,
                              style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd/MM/yyyy').format(booking.createdAt!),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Property Card
                if (property != null) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
                      ),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.push('/properties/${property.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AkriliImage(
                                imageUrl: property.coverUrl,
                                width: 84,
                                height: 84,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      property.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        letterSpacing: -0.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.primary),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            '${property.commune?.name ?? ""}, ${property.wilaya?.name ?? "Algérie"}',
                                            style: TextStyle(
                                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                                              fontSize: 12.5,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          tr.viewListingBtn,
                                          style: const TextStyle(
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.primary),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Dates Timeline & Stay Details
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
                    ),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, color: AppTheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            tr.reservationDetails,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const Divider(height: 22),
                      _detailRow(
                        context,
                        tr.checkInLabel,
                        _formatDisplayDate(booking.checkIn),
                        Icons.login_rounded,
                      ),
                      const SizedBox(height: 12),
                      _detailRow(
                        context,
                        tr.checkOutLabel,
                        _formatDisplayDate(booking.checkOut),
                        Icons.logout_rounded,
                      ),
                      const SizedBox(height: 12),
                      _detailRow(
                        context,
                        tr.durationLabel,
                        '$nights ${tr.nightsUnit}',
                        Icons.nights_stay_outlined,
                      ),
                      const SizedBox(height: 12),
                      _detailRow(
                        context,
                        tr.minGuestsLabel,
                        '${booking.guests} ${tr.guestsUnit}',
                        Icons.group_outlined,
                      ),
                      if (booking.tenant != null) ...[
                        const SizedBox(height: 12),
                        _detailRow(
                          context,
                          tr.tenantField,
                          booking.tenant!.name,
                          Icons.person_outline_rounded,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Total Price Breakdown Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
                    ),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.receipt_long_rounded, color: AppTheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            tr.priceSummary,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const Divider(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tr.totalLabel,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${NumberFormat("#,###").format(booking.totalPrice)} DZD',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Host Decision Actions if canDecide
                if (booking.canDecide && booking.isPending) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.gavel_rounded, color: Colors.amber, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Décision requise de l\'hôte',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Examinez cette réservation et confirmez ou refusez la demande du voyageur.',
                          style: TextStyle(fontSize: 12.5, color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        if (_isProcessingDecision)
                          const Center(
                            child: CircularProgressIndicator(color: AppTheme.primary),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _handleReject,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.secondary,
                                    side: const BorderSide(color: AppTheme.secondary),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(tr.rejectBtn, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _handleAccept,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(tr.acceptBtn, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Review Section if canReview
                if (booking.canReview) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
                      ),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          tr.leaveReviewBtn,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Comment s\'est passé votre séjour ? Votre avis aide grandement la communauté Akrili.',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey),
                        ),
                        const SizedBox(height: 14),
                        // Star Selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final starNum = index + 1;
                            return IconButton(
                              icon: Icon(
                                starNum <= _selectedRating
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: Colors.amber,
                                size: 34,
                              ),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selectedRating = starNum;
                                });
                              },
                            );
                          }),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _reviewController,
                          decoration: const InputDecoration(
                            labelText: 'Votre commentaire',
                            hintText: 'Propreté, accueil, confort...',
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isSubmittingReview ? null : _handleSubmitReview,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isSubmittingReview
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Publier mon avis',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
