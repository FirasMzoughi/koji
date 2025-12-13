import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koji/providers/estimate_provider.dart';

class JobDetailsStep extends ConsumerStatefulWidget {
  const JobDetailsStep({super.key});

  @override
  ConsumerState<JobDetailsStep> createState() => _JobDetailsStepState();
}

class _JobDetailsStepState extends ConsumerState<JobDetailsStep> {
  late TextEditingController _descriptionController;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    final provider = ref.read(estimateProvider);
    _descriptionController = TextEditingController(text: provider.tempDescription);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _analyzeImage() async {
    setState(() {
      _isAnalyzing = true;
    });

    // Simulate AI Delay
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      const aiText = "Analyse IA : Mur intérieur état moyen. Nécessite : 1 couche d'impression, rebouchage des fissures, 2 couches de peinture satinée blanche.";
      _descriptionController.text = aiText;
      ref.read(estimateProvider).updateJobDetails(aiText);
      setState(() {
        _isAnalyzing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Analyse IA terminée !")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch provider only if needed for UI updates, here we only write mostly, but if we wanted to reflect changes from outside, we might watch.
    // However, the original code used listen: false in initState and listen: false in update.
    // The TextField shows local controller state. If provider updates externally, controller won't update in this logic unless we add a listener. 
    // Original behavior preserved.
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[400]!),
          ),
          child: _isAnalyzing
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Analyse de l'image par l'IA en cours..."),
                  ],
                )
              : Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt, size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _analyzeImage,
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text("Prendre une photo / Analyser"),
                        ),
                      ],
                    ),
                ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _descriptionController,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Description des travaux',
            alignLabelWithHint: true,
            hintText: 'Décrivez les travaux à réaliser...',
          ),
          onChanged: (value) {
            ref.read(estimateProvider).updateJobDetails(value);
          },
        ),
      ],
    );
  }
}
