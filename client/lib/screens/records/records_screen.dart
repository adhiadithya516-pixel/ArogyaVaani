
import 'package:flutter/material.dart';

import '../../providers/records_provider.dart';
import '../../widgets/records/record_list_item.dart';
import 'add_record_screen.dart';
import 'record_detail_screen.dart';

class RecordsScreen extends StatefulWidget {
  final RecordsProvider recordsProvider;

  const RecordsScreen({
    super.key,
    required this.recordsProvider,
  });

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  @override
  void initState() {
    super.initState();
    widget.recordsProvider.loadData();
  }

  Future<void> _openAddRecordScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRecordScreen(
          recordsProvider: widget.recordsProvider,
        ),
      ),
    );

    if (mounted) {
      await widget.recordsProvider.loadData();
    }
  }

  Future<void> _deleteRecord(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text(
          'Are you sure you want to delete this medical record?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.recordsProvider.deleteRecord(id);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record deleted')),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete record: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.recordsProvider,
      builder: (context, child) {
        final provider = widget.recordsProvider;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Medical Records'),
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.error != null
                  ? Center(
                      child: Text(provider.error!),
                    )
                  : provider.records.isEmpty
                      ? const Center(
                          child: Text(
                            'No medical records found.\nAdd your first record!',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: provider.records.length,
                          itemBuilder: (context, index) {
                            final record = provider.records[index];

                            return RecordListItem(
                              record: record,
                              onDelete: record.id == null
                                  ? null
                                  : () => _deleteRecord(record.id!),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        RecordDetailScreen(
                                      record: record,
                                      onDelete: record.id == null
                                          ? null
                                          : () {
                                              Navigator.pop(context);
                                              _deleteRecord(record.id!);
                                            },
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openAddRecordScreen,
            icon: const Icon(Icons.add),
            label: const Text('Add Record'),
          ),
        );
      },
    );
  }
}
