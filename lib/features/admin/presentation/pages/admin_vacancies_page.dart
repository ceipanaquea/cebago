import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class AdminVacanciesPage extends StatefulWidget {
  const AdminVacanciesPage({super.key});

  @override
  State<AdminVacanciesPage> createState() => _AdminVacanciesPageState();
}

class _AdminVacanciesPageState extends State<AdminVacanciesPage> {
  List<Map<String, dynamic>> _vacancies = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVacancies();
  }

  Future<void> _loadVacancies() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await Supabase.instance.client
          .from('vacantes')
          .select('id, titulo, ciclo_escolar, taller_tecnico, modalidad, cupos_totales, cupos_ocupados')
          .order('ciclo_escolar', ascending: true);
      
      debugPrint('VACANCIES RESPONSE RECEIVED: $response');
      if (!mounted) return;
      setState(() {
        _vacancies = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (e, stack) {
      debugPrint('VACANCIES ERROR: $e');
      debugPrint('VACANCIES STACK: $stack');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _updateTotalCupos(String id, int currentTotal) async {
    final controller = TextEditingController(text: currentTotal.toString());
    final newTotal = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Modificar Vacantes', style: AppTypography.headlineMd()),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Cupos Totales',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final val = int.tryParse(controller.text.trim());
                Navigator.pop(context, val);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (newTotal != null && newTotal > 0) {
      try {
        await Supabase.instance.client.from('vacantes').update({'cupos_totales': newTotal}).eq('id', id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vacantes actualizadas correctamente.')),
        );
        _loadVacancies();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Gestión de Vacantes',
          style: AppTypography.headlineMd(color: AppColors.onSurface),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push(AppRoutes.adminCreateVacancy);
          if (result == true) {
            _loadVacancies();
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    return _buildListOrStatus();
  }

  Widget _buildListOrStatus() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandYellow)),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
            const SizedBox(height: 12),
            Text('Error: $_error', style: AppTypography.bodySm(color: AppColors.error)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadVacancies,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (_vacancies.isEmpty) {
      return Center(
        child: Text(
          'No hay vacantes registradas.',
          style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadVacancies,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: _vacancies.length,
        itemBuilder: (context, index) {
          try {
            final vac = _vacancies[index];
            final id = vac['id'] as String;
            final titulo = vac['titulo'] as String? ?? 'Taller';
            final ciclo = vac['ciclo_escolar'] as String? ?? 'Desconocido';
            final modalidad = vac['modalidad'] as String? ?? 'Presencial';
            final totales = (vac['cupos_totales'] as num?)?.toInt() ?? 0;
            final ocupados = (vac['cupos_ocupados'] as num?)?.toInt() ?? 0;
            final disponibles = totales - ocupados;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: (ciclo.contains('Inicial') ? Colors.teal : Colors.deepPurple).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ciclo.contains('Inicial') ? 'Inicial' : 'Avanzado',
                            style: AppTypography.labelXs(
                              color: ciclo.contains('Inicial') ? Colors.teal[800]! : Colors.deepPurple[800]!,
                            ).copyWith(fontSize: 9, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          modalidad,
                          style: AppTypography.labelXs(color: AppColors.onSurfaceVariant).copyWith(fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Text(
                      titulo,
                      style: AppTypography.bodyMd(color: AppColors.onSurface).copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Disp.',
                            style: AppTypography.labelXs(color: AppColors.outline),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$disponibles',
                            style: AppTypography.bodyLg(
                              color: disponibles > 0 ? Colors.green[700]! : AppColors.error,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total',
                            style: AppTypography.labelXs(color: AppColors.outline),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$totales',
                            style: AppTypography.bodyLg(color: AppColors.primary).copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _updateTotalCupos(id, totales),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.edit_rounded, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Cupos',
                            style: AppTypography.labelXs(color: AppColors.onPrimary).copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          } catch (e) {
            return Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Error: $e',
                  style: const TextStyle(color: Colors.red, fontSize: 10),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
