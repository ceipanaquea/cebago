import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/support_bloc.dart';
import '../bloc/support_event.dart';
import '../bloc/support_state.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'Matrícula';

  final List<String> _categories = ['Matrícula', 'Taller Técnico', 'Pagos', 'General', 'Soporte Virtual'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<SupportBloc>().add(const LoadSupportHistoryRequested());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SupportBloc, SupportState>(
      listener: (context, state) {
        if (state is SupportSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('¡Ticket enviado con código ${state.ticketId}!'),
              backgroundColor: Colors.green,
            ),
          );
          _titleController.clear();
          _messageController.clear();
          context.read<SupportBloc>().add(const LoadSupportHistoryRequested());
          _tabController.animateTo(1); // Mover al historial
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.onSurface, size: 20),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Centro de Soporte',
              style: AppTypography.headlineLg(color: AppColors.onSurface),
            ),
            centerTitle: true,
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.brandBlack,
              unselectedLabelColor: AppColors.outline,
              indicatorColor: AppColors.brandYellow,
              indicatorWeight: 3,
              labelStyle: AppTypography.labelLg(),
              tabs: const [
                Tab(text: 'Nuevo Ticket'),
                Tab(text: 'Mis Consultas'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildNewTicketTab(state),
              _buildHistoryTab(state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNewTicketTab(SupportState state) {
    final bool isLoading = state is SupportLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿En qué podemos ayudarte?', style: AppTypography.headlineMd(color: AppColors.onSurface)),
            const SizedBox(height: 8),
            Text(
              'Envíanos tus consultas académicas o técnicas y te responderemos en un plazo máximo de 24 horas hábiles.',
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),

            // Category select
            Text('Categoría de consulta', style: AppTypography.labelLg(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  style: AppTypography.bodySm(color: AppColors.onSurface),
                  items: _categories.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCategory = val);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            AppTextField(
              label: 'Asunto de consulta',
              hint: 'Breve título de tu ticket...',
              controller: _titleController,
              prefixIcon: Icons.title_rounded,
              validator: (val) => val == null || val.isEmpty ? 'Por favor, ingresa el asunto' : null,
            ),
            const SizedBox(height: 20),

            // Description
            AppTextField(
              label: 'Mensaje / Descripción detallada',
              hint: 'Explícanos tu caso detallando sedes, ciclos o problemas...',
              controller: _messageController,
              maxLines: 5,
              validator: (val) => val == null || val.isEmpty ? 'Por favor, describe tu problema' : null,
            ),
            const SizedBox(height: 32),

            // Submit Button
            AppButton(
              label: 'Enviar Mensaje a Soporte',
              loading: isLoading,
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  context.read<SupportBloc>().add(SendInquiryRequested(
                        title: _titleController.text,
                        category: _selectedCategory,
                        message: _messageController.text,
                      ));
                }
              },
            ),
            const SizedBox(height: 32),

            // Sede contact grid card
            _buildQuickContactCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickContactCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.brandBlack,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contacto Directo Alternativo', style: AppTypography.labelLg(color: AppColors.outline)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.phone_in_talk_outlined, color: AppColors.brandYellow, size: 20),
              const SizedBox(width: 12),
              Text('(01) 483-9281  •  Lun a Vie 8am - 9pm', style: AppTypography.bodySm(color: AppColors.brandWhite)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.brandYellow, size: 20),
              const SizedBox(width: 12),
              Text('+51 987 654 321  (WhatsApp Oficial)', style: AppTypography.bodySm(color: AppColors.brandWhite)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(SupportState state) {
    if (state is SupportLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandYellow),
        ),
      );
    }

    if (state is SupportLoaded) {
      final list = state.inquiries;
      if (list.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.outline, size: 40),
              const SizedBox(height: 12),
              Text('No tienes consultas registradas', style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final ticket = list[index];
          return _buildTicketCard(ticket);
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTicketCard(InquiryModel ticket) {
    final bool isResolved = ticket.status == 'Respondido';
    final Color badgeColor = isResolved ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ticket.category,
                style: AppTypography.labelXs(color: AppColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                ticket.status,
                style: AppTypography.labelXs(color: badgeColor).copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ticket.title,
                style: AppTypography.headlineMd(color: AppColors.onSurface).copyWith(fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text('Código: ${ticket.id}  •  ${ticket.date}', style: AppTypography.labelXs(color: AppColors.outline)),
            ],
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: AppColors.outlineVariant),
          const SizedBox(height: 12),
          Text('Tu consulta:', style: AppTypography.labelSm(color: AppColors.outline)),
          const SizedBox(height: 4),
          Text(ticket.message, style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)),
          if (ticket.reply != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.admin_panel_settings_rounded, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Text('Respuesta de CEBA Go:', style: AppTypography.labelSm(color: Colors.green).copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(ticket.reply!, style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)),
                ],
              ),
            )
          ],
        ],
      ),
    );
  }
}
