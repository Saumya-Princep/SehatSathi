import 'package:flutter/material.dart';
import '../models/vitals.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../l10n/app_localizations.dart';

class VitalsSummaryWidget extends StatelessWidget {
  final List<Vitals> vitalsList;

  const VitalsSummaryWidget({Key? key, required this.vitalsList}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (vitalsList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('No vitals recorded yet.', style: TextStyle(color: Colors.grey))),
      );
    }

    final latest = vitalsList.last;
    final isHighBP = latest.bloodPressureSystolic > 120 || latest.bloodPressureDiastolic > 80;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildVitalCard(context, AppLocalizations.of(context)!.bp, '${latest.bloodPressureSystolic}/${latest.bloodPressureDiastolic}', isHighBP ? Colors.red : Colors.green, Icons.favorite)),
            const SizedBox(width: 8),
            Expanded(child: _buildVitalCard(context, AppLocalizations.of(context)!.heartRate, '${latest.heartRate}', Colors.blue, Icons.monitor_heart)),
            const SizedBox(width: 8),
            Expanded(child: _buildVitalCard(context, AppLocalizations.of(context)!.weight, '${latest.weight}', Colors.purple, Icons.scale)),
          ],
        ),
        const SizedBox(height: 16),
        Text(AppLocalizations.of(context)!.recentTrends, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: vitalsList.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.bloodPressureSystolic.toDouble())).toList(),
                  isCurved: true,
                  color: Colors.red,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                ),
                LineChartBarData(
                  spots: vitalsList.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.heartRate.toDouble())).toList(),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                ),
              ],
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true, 
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey));
                    },
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withOpacity(0.2))),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('BP (Systolic)', Colors.red),
            const SizedBox(width: 16),
            _buildLegendItem('Heart Rate', Colors.blue),
          ],
        ),
      ],
    );
  }

  Widget _buildVitalCard(BuildContext context, String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
