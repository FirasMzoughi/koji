import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/features/synchronization/data/project_model.dart';
import 'package:koji/features/synchronization/data/project_repository.dart';

class ProjectSelectionScreen extends StatefulWidget {
  const ProjectSelectionScreen({super.key});

  @override
  State<ProjectSelectionScreen> createState() => _ProjectSelectionScreenState();
}

class _ProjectSelectionScreenState extends State<ProjectSelectionScreen> {
  final ProjectRepository _repository = ProjectRepository();
  List<Project> _projects = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      final projects = await _repository.fetchProjects();
      if (mounted) setState(() => _projects = projects);
    } catch (e) {
      // Handle error
      debugPrint('Error loading projects: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final darkBlue = const Color(0xFF0F3995);
    final scaffoldBg = const Color(0xFFF5F8FF); 
    
    final filteredProjects = _projects.where((p) => 
      p.title.toLowerCase().contains(_searchQuery.toLowerCase()) || 
      p.clientName.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    hintText: "Rechercher un chantier...",
                    hintStyle: TextStyle(fontFamily: 'Outfit', color: Colors.grey[400]),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: Colors.grey[400]),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "Sélection du chantier",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkBlue,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Project List
            Expanded(
              child: _isLoading 
                ? Center(child: CircularProgressIndicator(color: darkBlue))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: filteredProjects.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final project = filteredProjects[index];
                      return _ProjectCard(
                        project: project,
                        onTap: () => context.push('/projects/detail/${project.id}', extra: project),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const _ProjectCard({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color statusBg;
    Color statusText;
    
    switch (project.status) {
      case 'En Cours':
        statusBg = const Color(0xFFE3F2FD); // Light Blue
        statusText = const Color(0xFF1D74FF);
        break;
      case 'Terminé':
        statusBg = const Color(0xFFE8F5E9); // Light Green
        statusText = const Color(0xFF43A047);
        break;
       case 'À Venir':
        statusBg = const Color(0xFFFFF3E0); // Light Orange
        statusText = const Color(0xFFFF9800);
        break;
      default:
        statusBg = Colors.grey[100]!;
        statusText = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        project.status,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      project.title,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F3995),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildRow(Icons.person, project.clientName),
                    const SizedBox(height: 4),
                    if (project.address != null)
                      _buildRow(Icons.location_on, project.address!),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              project.imageUrl != null
                  ? Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(project.imageUrl!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EDF8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.home_work_outlined,
                          color: Color(0xFF0F3995), size: 36),
                    ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D74FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                "Voir les détails",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              color: Colors.grey[500],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
