import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/attendance_provider.dart';
import '../providers/auth_provider.dart';

class AttendancesScreen extends StatefulWidget {
  const AttendancesScreen({Key? key}) : super(key: key);

  @override
  State<AttendancesScreen> createState() => _AttendancesScreenState();
}

class _AttendancesScreenState extends State<AttendancesScreen> {
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);

    if (authProvider.user != null) {
      await attendanceProvider.loadAttendances(
        employeeId: authProvider.user!.employeeId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes présences'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showMonthPicker,
            tooltip: 'Filtrer par mois',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Consumer<AttendanceProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (provider.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              );
            }

            final attendances = _filterByMonth(provider.attendances);

            if (attendances.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune présence pour ce mois',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Grouper par date
            final groupedAttendances = _groupByDate(attendances);

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupedAttendances.length,
              itemBuilder: (context, index) {
                final date = groupedAttendances.keys.elementAt(index);
                final dayAttendances = groupedAttendances[date]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        _formatDate(date),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    ...dayAttendances.map((attendance) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.shade100,
                            child: const Icon(
                              Icons.check,
                              color: Colors.green,
                            ),
                          ),
                          title: Text(
                            DateFormat('HH:mm:ss').format(attendance.timestamp),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Confiance: ${(attendance.confidence * 100).toStringAsFixed(0)}%',
                          ),
                          trailing: Icon(
                            attendance.isSynced
                                ? Icons.cloud_done
                                : Icons.cloud_off,
                            color: attendance.isSynced
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<dynamic> _filterByMonth(List attendances) {
    return attendances.where((a) {
      final dateStr = DateFormat('yyyy-MM').format(a.timestamp);
      return dateStr == _selectedMonth;
    }).toList();
  }

  Map<String, List<dynamic>> _groupByDate(List attendances) {
    final Map<String, List<dynamic>> grouped = {};

    for (var attendance in attendances) {
      final dateKey = DateFormat('yyyy-MM-dd').format(attendance.timestamp);
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(attendance);
    }

    return grouped;
  }

  String _formatDate(String dateKey) {
    final date = DateTime.parse(dateKey);
    final now = DateTime.now();

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return "Aujourd'hui";
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return 'Hier';
    } else {
      return DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date);
    }
  }

  void _showMonthPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sélectionner un mois'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = DateTime(DateTime.now().year, index + 1);
                final monthStr = DateFormat('yyyy-MM').format(month);
                final isSelected = monthStr == _selectedMonth;

                return ListTile(
                  title: Text(DateFormat('MMMM yyyy', 'fr_FR').format(month)),
                  trailing: isSelected ? const Icon(Icons.check) : null,
                  selected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedMonth = monthStr;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}