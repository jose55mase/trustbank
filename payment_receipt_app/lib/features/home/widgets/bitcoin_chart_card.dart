import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../design_system/typography/tb_typography.dart';

/// Card that displays a Bitcoin price chart with 7-day history.
/// Uses CoinGecko public API (no API key required).
class BitcoinChartCard extends StatefulWidget {
  const BitcoinChartCard({super.key});

  @override
  State<BitcoinChartCard> createState() => _BitcoinChartCardState();
}

class _BitcoinChartCardState extends State<BitcoinChartCard> {
  List<FlSpot> _spots = [];
  double? _currentPrice;
  double? _priceChange24h;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBitcoinData();
  }

  Future<void> _loadBitcoinData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get 7-day price history
      final historyResponse = await http.get(
        Uri.parse(
          'https://api.coingecko.com/api/v3/coins/bitcoin/market_chart?vs_currency=usd&days=7',
        ),
      );

      if (historyResponse.statusCode == 200) {
        final data = json.decode(historyResponse.body);
        final prices = data['prices'] as List;

        final spots = <FlSpot>[];
        for (int i = 0; i < prices.length; i++) {
          spots.add(FlSpot(i.toDouble(), (prices[i][1] as num).toDouble()));
        }

        // Current price is the last point
        final lastPrice = prices.last[1] as num;
        final firstPrice = prices.first[1] as num;
        final change = ((lastPrice - firstPrice) / firstPrice) * 100;

        if (mounted) {
          setState(() {
            _spots = spots;
            _currentPrice = lastPrice.toDouble();
            _priceChange24h = change;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Error ${historyResponse.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo cargar';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TBSpacing.md),
      decoration: BoxDecoration(
        color: TBColors.surface,
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
        border: Border.all(color: TBColors.grey300.withOpacity(0.5)),
      ),
      child: _isLoading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildLoading() {
    return const SizedBox(
      height: 140,
      child: Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: TBColors.primary),
      ),
    );
  }

  Widget _buildError() {
    return SizedBox(
      height: 140,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, color: TBColors.grey400, size: 28),
            const SizedBox(height: 8),
            Text(_error!, style: TBTypography.bodySmall.copyWith(color: TBColors.grey500)),
            TextButton(
              onPressed: _loadBitcoinData,
              child: const Text('Reintentar', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final isPositive = (_priceChange24h ?? 0) >= 0;
    final changeColor = isPositive ? TBColors.success : TBColors.error;
    final chartColor = isPositive ? TBColors.success : TBColors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('₿', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bitcoin', style: TBTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                Text('BTC/USD · 7 días', style: TBTypography.bodySmall.copyWith(color: TBColors.grey500, fontSize: 11)),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${NumberFormat('#,##0.00').format(_currentPrice ?? 0)}',
                  style: TBTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      size: 14,
                      color: changeColor,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${isPositive ? '+' : ''}${_priceChange24h?.toStringAsFixed(2) ?? '0.00'}%',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: changeColor),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: TBSpacing.md),
        // Chart
        SizedBox(
          height: 80,
          child: _spots.isNotEmpty
              ? LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineTouchData: const LineTouchData(enabled: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _spots,
                        isCurved: true,
                        curveSmoothness: 0.3,
                        color: chartColor,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: chartColor.withOpacity(0.08),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
