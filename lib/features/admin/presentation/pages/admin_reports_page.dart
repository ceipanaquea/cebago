import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class WorkshopStat {
  final String title;
  final String mode;
  final int occupied;
  final int total;

  WorkshopStat({
    required this.title,
    required this.mode,
    required this.occupied,
    required this.total,
  });
}

class ReportsData {
  final int totalApprovedMatriculas;
  final int totalRequests;
  final int totalCapacity;
  final int totalOccupied;
  final Map<String, int> modeDistribution;
  final List<WorkshopStat> workshopStats;

  ReportsData({
    required this.totalApprovedMatriculas,
    required this.totalRequests,
    required this.totalCapacity,
    required this.totalOccupied,
    required this.modeDistribution,
    required this.workshopStats,
  });
}

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  ReportsData? _data;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = Supabase.instance.client;

      // 1. Obtener datos de matrículas
      final matriculasResponse = await client.from('matriculas').select('estado');
      final requestsList = List<Map<String, dynamic>>.from(matriculasResponse);
      final totalRequests = requestsList.length;
      final totalApproved = requestsList.where((m) => m['estado'] == 'Aprobado').length;

      // 2. Obtener datos de vacantes/talleres
      final vacantesResponse = await client
          .from('vacantes')
          .select('titulo, taller_tecnico, modalidad, cupos_totales, cupos_ocupados');
      final vacantesList = List<Map<String, dynamic>>.from(vacantesResponse);

      int totalCapacity = 0;
      int totalOccupied = 0;
      final Map<String, int> modeDistribution = {
        'Presencial': 0,
        'Semi-presencial': 0,
        'A Distancia': 0,
      };

      final List<WorkshopStat> workshopStats = [];

      for (final vac in vacantesList) {
        final int total = (vac['cupos_totales'] as num?)?.toInt() ?? 0;
        final int occupied = (vac['cupos_ocupados'] as num?)?.toInt() ?? 0;
        final String mode = vac['modalidad'] as String? ?? 'Presencial';
        final String title = vac['titulo'] as String? ?? (vac['taller_tecnico'] as String? ?? 'Taller');

        totalCapacity += total;
        totalOccupied += occupied;

        if (modeDistribution.containsKey(mode)) {
          modeDistribution[mode] = (modeDistribution[mode] ?? 0) + occupied;
        } else {
          modeDistribution[mode] = occupied;
        }

        workshopStats.add(WorkshopStat(
          title: title,
          mode: mode,
          occupied: occupied,
          total: total,
        ));
      }

      setState(() {
        _data = ReportsData(
          totalApprovedMatriculas: totalApproved,
          totalRequests: totalRequests,
          totalCapacity: totalCapacity,
          totalOccupied: totalOccupied,
          modeDistribution: modeDistribution,
          workshopStats: workshopStats,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar reportes: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const SizedBox.shrink(), // Ocultamos el botón de volver si es pestaña
        title: Text(
          'Informes y Reportes',
          style: AppTypography.headlineLg(color: AppColors.onSurface),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _loadData,
          )
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandYellow),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(_errorMessage!, style: AppTypography.bodyMd(color: AppColors.error), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Reintentar'),
              )
            ],
          ),
        ),
      );
    }

    final data = _data!;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month growth overview card
            _buildGrowthOverviewCard(data),
            const SizedBox(height: 28),

            // Distribution by Mode
            Text('Alumnos por Modalidad', style: AppTypography.headlineMd(color: AppColors.onSurface)),
            const SizedBox(height: 16),
            _buildModeDistributionSection(data),
            const SizedBox(height: 28),

            // Workshops metrics table
            Text('Ocupación por Taller Técnico', style: AppTypography.headlineMd(color: AppColors.onSurface)),
            const SizedBox(height: 16),
            _buildWorkshopMetricsTable(data),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthOverviewCard(ReportsData data) {
    // Meta fija de prueba de 100 matriculados
    const int target = 100;
    final percent = target > 0 ? (data.totalApprovedMatriculas / target) * 100 : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.brandBlack,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandBlack.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Matrículas Aprobadas 2026', style: AppTypography.labelLg(color: AppColors.outline)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.brandYellow, size: 14),
                    const SizedBox(width: 4),
                    Text('${percent.toStringAsFixed(1)}%', style: AppTypography.labelXs(color: AppColors.brandYellow).copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${data.totalApprovedMatriculas} Alumnos',
            style: AppTypography.headlineXl(color: AppColors.brandWhite).copyWith(fontSize: 36),
          ),
          const SizedBox(height: 8),
          Text(
            'Solicitudes totales en cola: ${data.totalRequests}  •  Meta: $target aprobados',
            style: AppTypography.bodySm(color: AppColors.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildModeDistributionSection(ReportsData data) {
    final int total = data.totalOccupied;
    
    double presencialPercent = 0.0;
    double hybridPercent = 0.0;
    double onlinePercent = 0.0;

    if (total > 0) {
      presencialPercent = (data.modeDistribution['Presencial'] ?? 0) / total;
      hybridPercent = (data.modeDistribution['Semi-presencial'] ?? 0) / total;
      onlinePercent = (data.modeDistribution['A Distancia'] ?? 0) / total;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          _buildProgressDistributionItem('Presencial (Sede única)', presencialPercent, '${data.modeDistribution['Presencial'] ?? 0} Alumnos', Colors.orange),
          const SizedBox(height: 16),
          _buildProgressDistributionItem('Semi-presencial (Híbrido)', hybridPercent, '${data.modeDistribution['Semi-presencial'] ?? 0} Alumnos', Colors.indigo),
          const SizedBox(height: 16),
          _buildProgressDistributionItem('A Distancia (Virtual)', onlinePercent, '${data.modeDistribution['A Distancia'] ?? 0} Alumnos', Colors.teal),
        ],
      ),
    );
  }

  Widget _buildProgressDistributionItem(String label, double value, String countLabel, Color barColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.labelLg(color: AppColors.onSurface)),
            Text(countLabel, style: AppTypography.labelSm(color: AppColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 10,
            backgroundColor: AppColors.surfaceContainerLow,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkshopMetricsTable(ReportsData data) {
    if (data.workshopStats.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Center(
          child: Text(
            'No hay talleres registrados en la base de datos.',
            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.surfaceContainerLow),
            columns: [
              DataColumn(label: Text('Taller', style: AppTypography.labelLg(color: AppColors.onSurface))),
              DataColumn(label: Text('Modalidad', style: AppTypography.labelLg(color: AppColors.onSurface))),
              DataColumn(label: Text('Alumnos', style: AppTypography.labelLg(color: AppColors.onSurface))),
              DataColumn(label: Text('Ocupación', style: AppTypography.labelLg(color: AppColors.onSurface))),
            ],
            rows: data.workshopStats.map((w) {
              final percent = w.total > 0 ? (w.occupied / w.total) * 100 : 0.0;
              return DataRow(
                cells: [
                  DataCell(Text(w.title, style: AppTypography.bodySm(color: AppColors.onSurface))),
                  DataCell(Text(w.mode, style: AppTypography.bodySm(color: AppColors.onSurfaceVariant))),
                  DataCell(Text('${w.occupied} / ${w.total}', style: AppTypography.bodySm(color: AppColors.onSurfaceVariant))),
                  DataCell(Text('${percent.toStringAsFixed(0)}%', style: AppTypography.bodySm(color: AppColors.primary).copyWith(fontWeight: FontWeight.bold))),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
