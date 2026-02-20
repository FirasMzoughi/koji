import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/features/synchronization/data/worker_model.dart';
import 'package:koji/features/synchronization/data/worker_repository.dart';

class WorkerListScreen extends StatefulWidget {
  const WorkerListScreen({super.key});

  @override
  State<WorkerListScreen> createState() => _WorkerListScreenState();
}

class _WorkerListScreenState extends State<WorkerListScreen> {
  final _repository = WorkerRepository();
  final _searchController = TextEditingController();
  List<Worker> _workers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    setState(() => _isLoading = true);
    try {
      final workers = await _repository.getWorkers(query: _searchQuery);
      setState(() {
        _workers = workers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error cleanly
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    // Debouce could be added here
    _loadWorkers();
  }

  @override
  Widget build(BuildContext context) {
    // Colors from design
    final darkBlue = const Color(0xFF0F3995);
    final scaffoldBg = const Color(0xFFF5F8FF); 
    
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header
              _buildHeader(context, darkBlue),
              
              const SizedBox(height: 24),
              
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.blue.withOpacity(0.1)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un ouvrier...',
                    hintStyle: TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.grey[400],
                    ),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // List
              Expanded(
                child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _workers.isEmpty 
                  ? Center(child: Text("Aucun ouvrier trouvé", style: TextStyle(fontFamily: 'Outfit', color: Colors.grey[500])))
                  : ListView.separated(
                      itemCount: _workers.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _buildWorkerCard(context, _workers[index]);
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/workers/create'), // Route to be added
        backgroundColor: const Color(0xFF1D74FF),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color darkBlue) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            padding: const EdgeInsets.all(10),
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
            child: Icon(Icons.chevron_left, color: darkBlue, size: 24),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          "Liste des Ouvriers",
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: darkBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkerCard(BuildContext context, Worker worker) {
    final bool isAvailable = worker.status == 'Disponible';
    
    return GestureDetector(
      onTap: () => context.push('/workers/detail', extra: worker),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar with Status Indicator
            Stack(
              children: [
                 Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.amber[100], // Fallback/Placeholder background
                    borderRadius: BorderRadius.circular(12),
                    image: worker.profilePictureUrl != null 
                    ? DecorationImage(
                        image: NetworkImage(worker.profilePictureUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                  ),
                  child: worker.profilePictureUrl == null 
                  ? Icon(Icons.person, color: Colors.brown[700], size: 30) // Placeholder
                  : null, 
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isAvailable ? const Color(0xFF00C853) : const Color(0xFFFFAB00), // Green or Amber
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${worker.firstName} ${worker.lastName}",
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F3995),
                        ),
                      ),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAvailable ? const Color(0xFFE8F5E9) : const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          worker.status,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isAvailable ? const Color(0xFF2E7D32) : const Color(0xFF1976D2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${worker.profession} - ${worker.status}", // Or detailed status description
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }
}
