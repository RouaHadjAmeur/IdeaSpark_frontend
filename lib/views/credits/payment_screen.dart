import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ideaspark/core/app_theme.dart';
import 'package:ideaspark/core/app_localizations.dart';
import 'package:ideaspark/view_models/payment_view_model.dart';

class PaymentScreen extends StatefulWidget {
  final String? packName;
  final String? credits;
  final String? price;

  const PaymentScreen({
    super.key,
    this.packName,
    this.credits,
    this.price,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _cardNumber = TextEditingController();
  final _cardName = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();

  @override
  void dispose() {
    _cardNumber.dispose();
    _cardName.dispose();
    _expiry.dispose();
    _cvv.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final packName = widget.packName ?? 'Pack Pro';
    final credits = widget.credits ?? '500 crédits';
    final price = widget.price ?? '14,99€';
    final colorScheme = Theme.of(context).colorScheme;

    return ChangeNotifierProvider(
      create: (_) => PaymentViewModel(
        packName: packName,
        credits: credits,
        totalPrice: price,
      ),
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Consumer<PaymentViewModel>(
              builder: (context, vm, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            context.tr('payment'),
                            style: GoogleFonts.syne(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr('secure_encrypted'),
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Column(
                        children: [
                          _SummaryRow(
                            label: context.tr('selected_pack'),
                            value: vm.packName,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 12),
                          _SummaryRow(
                            label: context.tr('credits'),
                            value: vm.credits,
                            colorScheme: colorScheme,
                          ),
                          Divider(
                            height: 24,
                            color: colorScheme.outlineVariant,
                          ),
                          _SummaryRow(
                            label: context.tr('total'),
                            value: vm.totalPrice,
                            isTotal: true,
                            colorScheme: colorScheme,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      context.tr('payment_method'),
                      style: GoogleFonts.syne(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PaymentMethod(
                      icon: '💳',
                      title: context.tr('card'),
                      subtitle: context.tr('card_subtitle'),
                      selected: vm.selectedMethod == 0,
                      onTap: () => vm.setPaymentMethod(0),
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 12),
                    _PaymentMethod(
                      icon: '📱',
                      title: context.tr('apple_google_pay'),
                      subtitle: context.tr('fast_payment'),
                      selected: vm.selectedMethod == 1,
                      onTap: () => vm.setPaymentMethod(1),
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 12),
                    _PaymentMethod(
                      icon: '🅿️',
                      title: context.tr('paypal'),
                      subtitle: context.tr('paypal_subtitle'),
                      selected: vm.selectedMethod == 2,
                      onTap: () => vm.setPaymentMethod(2),
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 24),
                    if (vm.selectedMethod == 0) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _cardNumber,
                              decoration: InputDecoration(
                                labelText: context.tr('card_number'),
                                hintText: context.tr('card_number_hint'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _cardName,
                              decoration: InputDecoration(
                                labelText: context.tr('name_on_card'),
                                hintText: context.tr('name_hint'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _expiry,
                                    decoration: InputDecoration(
                                      labelText: context.tr('expiry'),
                                      hintText: context.tr('expiry_hint'),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _cvv,
                                    decoration: InputDecoration(
                                      labelText: context.tr('cvv'),
                                      hintText: context.tr('cvv_hint'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final success = await vm.confirmPayment();
                          if (!context.mounted) return;
                          if (success) {
                            context.pop();
                            context.pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.successColor,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: Text(context.tr('confirm_payment')),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.tr('secure_ssl'),
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final ColorScheme colorScheme;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.colorScheme,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isTotal
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.syne(
            fontSize: isTotal ? 20 : 16,
            fontWeight: FontWeight.w600,
            color:
                isTotal ? colorScheme.primary : colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _PaymentMethod extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _PaymentMethod({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? colorScheme.primary : colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.15)
                : null,
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  color: colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
