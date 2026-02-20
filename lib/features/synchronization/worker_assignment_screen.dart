import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/features/synchronization/data/project_model.dart';
import 'package:koji/features/synchronization/data/project_repository.dart';
import 'package:koji/features/synchronization/data/worker_model.dart';
import 'package:koji/features/synchronization/data/worker_repository.dart';

class WorkerAssignmentScreen extends StatefulWidget {
  final Project project;

  const WorkerAssignmentScreen({super.key, required this.project});

  @override
  State<WorkerAssignmentScreen> createState() => _WorkerAssignmentScreenState();
}

class _WorkerAssignmentScreenState extends State<WorkerAssignmentScreen> {
  final WorkerRepository _workerRepo = WorkerRepository();
  final ProjectRepository _projectRepo = ProjectRepository();
  
  List<Worker> _allWorkers = [];
  Set<String> _selectedWorkerIds = {};
  String _selectedFilter = 'Tous'; // Tous, Plombier, Electricien...
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    try {
      final workers = await _workerRepo.getWorkers();
      if (mounted) {
        setState(() {
          _allWorkers = workers;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading workers: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedWorkerIds.contains(id)) {
        _selectedWorkerIds.remove(id);
      } else {
        _selectedWorkerIds.add(id);
      }
    });
  }

  Future<void> _submitAssignment() async {
    if (_selectedWorkerIds.isEmpty) return;

    try {
      await _projectRepo.assignWorkersToProject(widget.project.id, _selectedWorkerIds.toList());
      if (mounted) {
        context.pushReplacement('/projects/success');
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final darkBlue = const Color(0xFF0F3995);
    final scaffoldBg = const Color(0xFFF5F8FF); 
    
    // Filter logic
    final filteredWorkers = _allWorkers.where((w) {
      final matchesSearch = "${w.firstName} ${w.lastName}".toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesJob = _selectedFilter == 'Tous' || w.profession == _selectedFilter;
      return matchesSearch && matchesJob;
    }).toList();

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
             margin: const EdgeInsets.only(left: 16),
            padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
               boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.chevron_left, color: darkBlue),
          ),
        ),
        title: Text(
          "Affectation aux chantiers",
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: darkBlue,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
             const SizedBox(height: 24),
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E7FF)),
                ),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                   decoration: InputDecoration(
                    hintText: "Rechercher un artisan...",
                    hintStyle: TextStyle(fontFamily: 'Outfit', color: Colors.grey[400]),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: Colors.grey[400]),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: ['Tous', 'Plombier', 'Electricien', 'Maçon', 'Peintre'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = filter),
                      child: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                         decoration: BoxDecoration(
                          color: isSelected ? darkBlue : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected ? null : Border.all(color: Colors.blue.withOpacity(0.1)),
                          boxShadow: isSelected ? [
                             BoxShadow(
                                color: darkBlue.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                          ] : null,
                         ),
                         child: Text(
                          filter,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : darkBlue,
                          ),
                         ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 32),
             Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Sélectionner l'équipe",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                  ),
                ),
              ),
            ),
             const SizedBox(height: 16),

            // Worker List
             Expanded(
              child: _isLoading 
                ? Center(child: CircularProgressIndicator(color: darkBlue))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: filteredWorkers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final worker = filteredWorkers[index];
                      final isSelected = _selectedWorkerIds.contains(worker.id);

                      return GestureDetector(
                        onTap: () => _toggleSelection(worker.id),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected ? Border.all(color: Colors.blue.withOpacity(0.3), width: 2) : null,
                            boxShadow: [
                               BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.amber[100],
                                backgroundImage: worker.profilePictureUrl != null ? NetworkImage(worker.profilePictureUrl!) : null,
                                child: worker.profilePictureUrl == null ? Icon(Icons.person, color: Colors.amber[800]) : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${worker.firstName} ${worker.lastName}",
                                      style: TextStyle(
                                        fontFamily: 'Outfit', 
                                        fontWeight: FontWeight.bold, 
                                        color: darkBlue,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      "${worker.profession} - ${worker.status}",
                                      style: TextStyle(
                                        fontFamily: 'Outfit', 
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? const Color(0xFF1D74FF) : Colors.transparent,
                                   border: isSelected ? null : Border.all(color: Colors.grey[300]!, width: 2),
                                ),
                                child: isSelected 
                                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                                  : null,
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ),
            
            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                 color: Colors.white,
                 boxShadow: [
                   BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                   )
                 ]
              ),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedWorkerIds.isNotEmpty ? _submitAssignment : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F3995), // Dark Blue
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                   child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       Text(
                        "Continuer (${_selectedWorkerIds.length} sélectionnés)",
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                    ],
                   ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
