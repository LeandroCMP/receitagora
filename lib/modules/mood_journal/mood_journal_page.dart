import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:receitagora/application/utils/app_snackbar.dart';
import 'package:receitagora/models/wellness/mood_entry.dart';

import 'mood_journal_controller.dart';

class MoodJournalPage extends GetView<MoodJournalController> {
  const MoodJournalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diário de bem-estar'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEntryForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo registro'),
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = controller.entries;
          if (entries.isEmpty) {
            return _MoodJournalEmptyState(theme: theme, onCreate: () => _openEntryForm(context));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _MoodEntryTile(
                entry: entry,
                onTap: () => _openEntryForm(context, entry: entry),
                onDelete: () => _confirmDelete(context, entry),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: entries.length,
          );
        }),
      ),
    );
  }

  Future<void> _openEntryForm(BuildContext context, {MoodEntry? entry}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return _MoodEntrySheet(
          controller: controller,
          existing: entry,
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, MoodEntry entry) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remover registro'),
          content: const Text('Deseja realmente remover este registro do diário?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remover'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await controller.deleteEntry(entry.id);
      AppSnackbar.success(
        title: 'Registro removido',
        message: 'O histórico foi atualizado com sucesso.',
      );
    }
  }
}

class _MoodJournalEmptyState extends StatelessWidget {
  const _MoodJournalEmptyState({
    required this.theme,
    required this.onCreate,
  });

  final ThemeData theme;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 88,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 24),
            Text(
              'Construa seu diário emocional',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              'Acompanhe como você se sente ao cozinhar e veja padrões para ajustar sua rotina.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Criar primeiro registro'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodEntryTile extends StatelessWidget {
  const _MoodEntryTile({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  final MoodEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formatter = DateFormat('dd/MM/yyyy', 'pt_BR');
    final color = entry.mood.tone(colorScheme);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(entry.mood.icon, color: color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.mood.label,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatter.format(entry.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    if (entry.note != null && entry.note!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        entry.note!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline, color: colorScheme.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodEntrySheet extends StatefulWidget {
  const _MoodEntrySheet({
    required this.controller,
    this.existing,
  });

  final MoodJournalController controller;
  final MoodEntry? existing;

  @override
  State<_MoodEntrySheet> createState() => _MoodEntrySheetState();
}

class _MoodEntrySheetState extends State<_MoodEntrySheet> {
  late DateTime selectedDate;
  late MoodLevel selectedMood;
  late TextEditingController noteController;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    selectedDate = existing?.date ?? DateTime.now();
    selectedMood = existing?.mood ?? MoodLevel.balanced;
    noteController = TextEditingController(text: existing?.note ?? '');
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('dd/MM/yyyy', 'pt_BR');

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.existing == null ? 'Registrar sensação' : 'Editar registro',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Text('Data', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: isSaving ? null : () => _selectDate(context),
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(formatter.format(selectedDate)),
          ),
          const SizedBox(height: 16),
          Text('Como você se sentiu?', style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MoodLevel.values.map((level) {
              final isSelected = selectedMood == level;
              final color = level.tone(theme.colorScheme);
              return ChoiceChip(
                label: Text(level.label),
                selected: isSelected,
                avatar: Icon(level.icon, size: 18),
                onSelected: isSaving
                    ? null
                    : (value) {
                        if (value) {
                          setState(() => selectedMood = level);
                        }
                      },
                selectedColor: color.withValues(alpha: 0.2),
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? color
                      : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('Observações', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: noteController,
            enabled: !isSaving,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Anote gatilhos, conquistas ou aprendizados do dia.',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: isSaving ? null : () => _save(context),
            icon: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(isSaving ? 'Salvando...' : 'Salvar registro'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('pt', 'BR'),
      initialDate: selectedDate,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _save(BuildContext context) async {
    setState(() => isSaving = true);
    try {
      await widget.controller.saveEntry(
        id: widget.existing?.id,
        date: selectedDate,
        mood: selectedMood,
        note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackbar.success(
          title: 'Registro salvo',
          message: 'Seu diário foi atualizado com sucesso.',
        );
      }
    } catch (_) {
      AppSnackbar.error(
        title: 'Não foi possível salvar',
        message: 'Tente novamente em instantes.',
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }
}
