import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:koji/features/planning/planning_project_tasks_screen.dart'; // Import new screen
import 'package:koji/features/synchronization/data/project_model.dart';
import 'package:koji/features/synchronization/data/project_repository.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  final ProjectRepository _repository = ProjectRepository();
  late Future<List<Project>> _projectsFuture;
  
  // Note: We are listing ALL projects now, as per user request to see "Chantiers" first.
  // The Month view could be preserved but for now let's focus on the Project List.

  @override
  void initState() {
    super.initState();
    _projectsFuture = _repository.fetchProjects(); // Fetch projects instead of tasks
  }

  @override
  Widget build(BuildContext context) {
    final darkBlue = const Color(0xFF0F3995);
    final scaffoldBg = const Color(0xFFF5F8FF);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildHeader(context, darkBlue),
                  // Removed View Toggle for now as we are listing Projects
                ],
              ),
            ),
            
            Expanded(
              child: _buildProjectList(darkBlue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectList(Color darkBlue) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Chantiers en cours",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkBlue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: FutureBuilder<List<Project>>(
            future: _projectsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final projects = snapshot.data ?? [];
              if (projects.isEmpty) return _buildEmptyState(darkBlue);

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: projects.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) => _buildProjectCard(projects[index], darkBlue),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProjectCard(Project project, Color darkBlue) {
    return GestureDetector(
      onTap: () {
        // Navigate to Project Tasks Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlanningProjectTasksScreen(project: project),
          ),
        );
      },
      child: Container(
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
        child: Row(
          children: [
             Container(
               width: 50, height: 50,
               decoration: BoxDecoration(
                 color: Colors.blue[50],
                 borderRadius: BorderRadius.circular(12),
                 image: project.imageUrl != null 
                   ? DecorationImage(image: NetworkImage(project.imageUrl!), fit: BoxFit.cover)
                   : null,
               ),
               child: project.imageUrl == null 
                 ? Icon(Icons.apartment, color: darkBlue)
                 : null,
             ),
             const SizedBox(width: 16),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                     project.title,
                     style: TextStyle(
                       fontFamily: 'Outfit',
                       fontSize: 16,
                       fontWeight: FontWeight.bold,
                       color: darkBlue,
                     ),
                   ),
                   const SizedBox(height: 4),
                   Text(
                     project.status,
                     style: TextStyle(
                       fontFamily: 'Outfit',
                       fontSize: 12,
                       color: project.status == 'En Cours' ? Colors.blue : Colors.grey,
                     ),
                   ),
                 ],
               ),
             ),
             Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
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
        const Expanded(
          child: Text(
            "Missions par Chantier",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F3995),
            ),
          ),
        ),
        const SizedBox(width: 44), 
      ],
    );
  }


  Widget _buildEmptyState(Color darkBlue) {
      return Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_off, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  "Aucun chantier trouvé",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    color: darkBlue.withOpacity(0.6),
                  ),
                ),
              ],
          ),
      );
  }
}
