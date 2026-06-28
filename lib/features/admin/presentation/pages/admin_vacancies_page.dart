import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      
      if (!mounted) return;
      setState(() {
        _vacancies = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (e) {
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

  Future<void> _showCreateVacancyDialog() async {
    final formKey = GlobalKey<FormState>();
    final tituloController = TextEditingController();
    final descripcionController = TextEditingController();
    final cuposController = TextEditingController(text: '30');
    final sedeController = TextEditingController(text: 'Sede Principal');
    final tallerController = TextEditingController(text: 'General');

    String selectedCiclo = 'Ciclo Avanzado';
    String selectedModalidad = 'Presencial';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Crear Nueva Vacante', style: AppTypography.headlineMd()),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: tituloController,
                          decoration: const InputDecoration(labelText: 'Título de Vacante (Ej: Matemática I)'),
                          validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: descripcionController,
                          decoration: const InputDecoration(labelText: 'Descripción'),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedCiclo,
                          decoration: const InputDecoration(labelText: 'Ciclo Escolar'),
                          items: const [
                            DropdownMenuItem(value: 'Ciclo Inicial / Intermedio', child: Text('Inicial / Intermedio')),
                            DropdownMenuItem(value: 'Ciclo Avanzado', child: Text('Avanzado')),
                          ],
                          onChanged: (val) => setDialogState(() => selectedCiclo = val!),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedModalidad,
                          decoration: const InputDecoration(labelText: 'Modalidad'),
                          items: const [
                            DropdownMenuItem(value: 'Presencial', child: Text('Presencial')),
                            DropdownMenuItem(value: 'Semi-presencial', child: Text('Semi-presencial')),
                            DropdownMenuItem(value: 'A Distancia', child: Text('A Distancia')),
                          ],
                          onChanged: (val) => setDialogState(() => selectedModalidad = val!),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: tallerController,
                          decoration: const InputDecoration(labelText: 'Taller Técnico / Especialidad'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: sedeController,
                          decoration: const InputDecoration(labelText: 'Sede'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: cuposController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Cupos Totales'),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Requerido';
                            final n = int.tryParse(val);
                            if (n == null || n <= 0) return 'Debe ser mayor a 0';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        await Supabase.instance.client.from('vacantes').insert({
                          'titulo': tituloController.text.trim(),
                          'descripcion': descripcionController.text.trim(),
                          'ciclo_escolar': selectedCiclo,
                          'taller_tecnico': tallerController.text.trim(),
                          'sede': sedeController.text.trim(),
                          'modalidad': selectedModalidad,
                          'cupos_totales': int.tryParse(cuposController.text.trim()) ?? 30,
                          'cupos_ocupados': 0,
                        });
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vacante creada con éxito.')),
                          );
                        }
                        _loadVacancies();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al crear vacante: $e')),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );
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
        onPressed: _showCreateVacancyDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
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
        child: Text('No hay vacantes registradas.', style: AppTypography.bodySm()),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadVacancies,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _vacancies.length,
        itemBuilder: (context, index) {
          final vac = _vacancies[index];
          final id = vac['id'] as String;
          final titulo = vac['titulo'] as String? ?? 'Taller';
          final ciclo = vac['ciclo_escolar'] as String? ?? 'Desconocido';
          final modalidad = vac['modalidad'] as String? ?? 'Presencial';
          final totales = (vac['cupos_totales'] as num?)?.toInt() ?? 0;
          final ocupados = (vac['cupos_ocupados'] as num?)?.toInt() ?? 0;
          final disponibles = totales - ocupados;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (ciclo.contains('Inicial') ? Colors.teal : Colors.deepPurple).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ciclo.contains('Inicial') ? 'Inicial / Intermedio' : 'Avanzado',
                        style: AppTypography.labelXs(
                          color: ciclo.contains('Inicial') ? Colors.teal[800] : Colors.deepPurple[800],
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        modalidad,
                        style: AppTypography.labelXs(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(titulo, style: AppTypography.headlineMd(color: AppColors.onSurface)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Disponibles', style: AppTypography.labelSm(color: AppColors.outline)),
                        const SizedBox(height: 4),
                        Text(
                          '$disponibles',
                          style: AppTypography.headlineLg(
                            color: disponibles > 0 ? Colors.green : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Totales', style: AppTypography.labelSm(color: AppColors.outline)),
                        const SizedBox(height: 4),
                        Text(
                          '$totales',
                          style: AppTypography.headlineLg(color: AppColors.primary),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Editar Cupos'),
                      onPressed: () => _updateTotalCupos(id, totales),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
