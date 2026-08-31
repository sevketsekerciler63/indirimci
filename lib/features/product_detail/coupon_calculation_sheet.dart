import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../core/models/coupon.dart';
import '../../core/services/coupon_calculator.dart';

class CouponCalculationSheet extends StatefulWidget {
  final double price;
  const CouponCalculationSheet({super.key, required this.price});
  @override
  State<CouponCalculationSheet> createState() => _CouponCalculationSheetState();
}

class _CouponCalculationSheetState extends State<CouponCalculationSheet> {
  final value = TextEditingController();
  final minimum = TextEditingController();
  bool percent = true;
  CouponCalculation? result;
  @override
  void dispose() { value.dispose(); minimum.dispose(); super.dispose(); }
  void calculate() {
    final v = double.tryParse(value.text.replaceAll(',', '.'));
    final m = double.tryParse(minimum.text.replaceAll(',', '.'));
    if (v == null || v <= 0) return;
    final coupon = Coupon(id: 'manual', code: 'MANUEL', platform: 'Manuel', description: 'Manuel hesaplama', discountPercent: percent ? v : null, discountAmount: percent ? null : v, minOrderAmount: m);
    setState(() => result = CouponCalculator.apply(price: widget.price, coupon: coupon));
  }
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: 20, right: 20, top: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Kupon sonrası fiyat', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      const Text('Mağazada doğrulanmadan önce bu yalnızca tahmini hesaplamadır.', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
      const SizedBox(height: 12),
      SegmentedButton<bool>(segments: const [ButtonSegment(value: true, label: Text('%')), ButtonSegment(value: false, label: Text('TL'))], selected: {percent}, onSelectionChanged: (s) => setState(() => percent = s.first)),
      const SizedBox(height: 12),
      TextField(controller: value, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: percent ? 'İndirim yüzdesi' : 'İndirim tutarı (TL)', border: const OutlineInputBorder())),
      const SizedBox(height: 12),
      TextField(controller: minimum, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Minimum sepet (opsiyonel)', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      FilledButton(onPressed: calculate, child: const Text('Hesapla')),
      if (result != null) ...[
        const SizedBox(height: 12),
        Text(result!.applicable ? 'Son fiyat: ${result!.finalPrice.toStringAsFixed(2)} TL' : result!.reason ?? 'Kupon uygulanamadı', style: TextStyle(color: result!.applicable ? AppColors.success : AppColors.warning, fontWeight: FontWeight.bold, fontSize: 17)),
      ],
    ]),
  );
}
