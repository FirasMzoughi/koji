import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:koji/features/synchronization/data/worker_model.dart';
import 'package:koji/features/synchronization/data/worker_repository.dart';

class CreateWorkerScreen extends StatefulWidget {
  final Worker? worker; // If provided, we are in Edit mode

  const CreateWorkerScreen({super.key, this.worker});

  @override
  State<CreateWorkerScreen> createState() => _CreateWorkerScreenState();
}

class _CreateWorkerScreenState extends State<CreateWorkerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _socialSecurityController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  String? _selectedProfession;
  bool _isSubmitting = false;
  File? _profileImage;
  File? _idImage;
  final _picker = ImagePicker();
  final _repository = WorkerRepository();

  @override
  void initState() {
    super.initState();
    if (widget.worker != null) {
      _firstNameController.text = widget.worker!.firstName;
      _lastNameController.text = widget.worker!.lastName;
      _socialSecurityController.text = widget.worker!.socialSecurityNumber ?? '';
      _addressController.text = widget.worker!.address ?? '';
      _phoneController.text = widget.worker!.phoneNumber ?? '';
      _emailController.text = widget.worker!.email ?? '';
      _selectedProfession = widget.worker!.profession;
    }
  }

  Future<void> _pickImage(bool isProfile) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isProfile) {
          _profileImage = File(image.path);
        } else {
          _idImage = File(image.path);
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);

    try {
      String? profileUrl = widget.worker?.profilePictureUrl;
      String? idUrl = widget.worker?.idCardUrl;

      if (_profileImage != null) {
        profileUrl = await _repository.uploadWorkerImage(_profileImage!, 'profile_${DateTime.now().millisecondsSinceEpoch}');
      }
      
      if (_idImage != null) {
        idUrl = await _repository.uploadWorkerImage(_idImage!, 'id_${DateTime.now().millisecondsSinceEpoch}');
      }

      final workerData = Worker(
        id: widget.worker?.id ?? '', // Keeps ID if editing, repo ignores for insert if empty but local need logic
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        profession: _selectedProfession ?? 'Ouvrier',
        socialSecurityNumber: _socialSecurityController.text,
        address: _addressController.text,
        phoneNumber: _phoneController.text,
        email: _emailController.text,
        profilePictureUrl: profileUrl,
        idCardUrl: idUrl,
        status: widget.worker?.status ?? 'Disponible',
        hireDate: widget.worker?.hireDate,
        hourlyRate: widget.worker?.hourlyRate,
      );

      if (widget.worker != null) {
        // Update
        await _repository.updateWorker(workerData);
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil mis à jour')));
           context.pop(); // Go back to detail
         }
      } else {
        // Create
        final createdWorker = await _repository.createWorker(workerData);
        if (mounted) {
          context.pushReplacement('/workers/success', extra: createdWorker);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final darkBlue = const Color(0xFF0F3995);
    final scaffoldBg = const Color(0xFFF5F8FF); 
    final isEditing = widget.worker != null;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        leading: Builder(
            builder: (context) {
              return GestureDetector(
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
              );
            }
          ),
        title: Text(
          isEditing ? "Modifier Profil" : "Nouveau Ouvrier",
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Photo Picker
                Center(
                  child: GestureDetector(
                    onTap: () => _pickImage(true),
                    child: Column(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue.withOpacity(0.1), width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ],
                            image: _profileImage != null
                                ? DecorationImage(image: FileImage(_profileImage!), fit: BoxFit.cover)
                                : (widget.worker?.profilePictureUrl != null 
                                    ? DecorationImage(image: NetworkImage(widget.worker!.profilePictureUrl!), fit: BoxFit.cover) 
                                    : null)
                          ),
                          child: _profileImage == null && widget.worker?.profilePictureUrl == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_outlined, size: 32, color: Colors.blue.withOpacity(0.3)),
                                  const SizedBox(height: 8),
                                  Icon(Icons.add_circle, color: darkBlue, size: 24),
                                ],
                              )
                            : null,
                        ),
                        const SizedBox(height: 12),
                        Text("Photo de l'ouvrier", style: TextStyle(fontFamily: 'Outfit', color: Colors.blue[200])),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                _buildLabel("Prénom"),
                _buildTextField(_firstNameController, "Rajouter votre texte..."),

                const SizedBox(height: 16),
                
                _buildLabel("Nom"),
                _buildTextField(_lastNameController, "Rajouter votre texte..."),

                const SizedBox(height: 16),

                _buildLabel("Profession"),
                _buildDropdown(),

                const SizedBox(height: 16),
                
                 _buildLabel("Téléphone"),
                _buildTextField(_phoneController, "06 00 00 00 00", keyboardType: TextInputType.phone),

                const SizedBox(height: 16),

                _buildLabel("Email"),
                _buildTextField(_emailController, "email@example.com", keyboardType: TextInputType.emailAddress),

                const SizedBox(height: 16),

                _buildLabel("Numéro de sécurité sociale"),
                _buildTextField(_socialSecurityController, "1 000 00 00 000 000", keyboardType: TextInputType.number),
                
                const SizedBox(height: 16),

                _buildLabel("Adresse postale"),
                _buildTextField(_addressController, "Rue, Ville, Code Postal"),
                
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLabel("Pièce d'identité"),
                    Text("Facultatif", style: TextStyle(fontFamily: 'Outfit', color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
                
                const SizedBox(height: 8),

                // ID Scanner Placeholder
                GestureDetector(
                  onTap: () => _pickImage(false),
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(16),
                      image: _idImage != null 
                          ? DecorationImage(image: FileImage(_idImage!), fit: BoxFit.cover)
                          : (widget.worker?.idCardUrl != null
                              ? DecorationImage(image: NetworkImage(widget.worker!.idCardUrl!), fit: BoxFit.cover)
                              : null)
                    ),
                    child: (_idImage == null && widget.worker?.idCardUrl == null)
                     ? CustomPaint(
                        painter: DashedRectPainter(color: Colors.grey.withOpacity(0.4), strokeWidth: 1.5, gap: 5.0),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                               Icon(Icons.crop_free, size: 32, color: Colors.grey[400]),
                               const SizedBox(height: 8),
                               Text("Scanner ou importer un document", style: TextStyle(fontFamily: 'Outfit', color: Colors.grey[400])),
                             ],
                          ),
                        ),
                      )
                     : null,
                  ),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8C9EFF), // Periwinkle/Blue from design
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isSubmitting 
                     ? const CircularProgressIndicator(color: Colors.white)
                     : Text(isEditing ? "Mettre à jour" : "Enregistrer le profil", style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F3995),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E7FF)), // Light blue border
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: (value) => (value?.isEmpty ?? true) && controller != _socialSecurityController && controller != _addressController && controller != _phoneController && controller != _emailController ? 'Champ requis' : null, // Make some optional? User asked to add phone/email, assuming required or optional. Let's make name/profession required.
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontFamily: 'Outfit', color: Colors.grey[300]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
         color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E7FF)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedProfession,
          hint: Text("Sélectionner un métier", style: TextStyle(fontFamily: 'Outfit', color: Colors.grey[300])),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF0F3995)),
          items: ['Electricien', 'Plombier', 'Maçon', 'Peintre', 'Ingénieur', 'Architecte']
              .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontFamily: 'Outfit'))))
              .toList(),
          onChanged: (val) => setState(() => _selectedProfession = val),
        ),
      ),
    );
  }
}

class DashedRectPainter extends CustomPainter {
  final double strokeWidth;
  final Color color;
  final double gap;

  DashedRectPainter({this.strokeWidth = 1.0, this.color = Colors.black, this.gap = 5.0});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint dashedPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final double x = size.width;
    final double y = size.height;

    final Path _topPath = getDashedPath(
      a: const Offset(0, 0),
      b: Offset(x, 0),
      gap: gap,
    );

    final Path _rightPath = getDashedPath(
      a: Offset(x, 0),
      b: Offset(x, y),
      gap: gap,
    );

    final Path _bottomPath = getDashedPath(
      a: Offset(0, y),
      b: Offset(x, y),
      gap: gap,
    );

    final Path _leftPath = getDashedPath(
      a: const Offset(0, 0),
      b: Offset(0, y),
      gap: gap,
    );

    canvas.drawPath(_topPath, dashedPaint);
    canvas.drawPath(_rightPath, dashedPaint);
    canvas.drawPath(_bottomPath, dashedPaint);
    canvas.drawPath(_leftPath, dashedPaint);
  }

  Path getDashedPath({
    required Offset a,
    required Offset b,
    required double gap,
  }) {
     final Size size = Size(b.dx - a.dx, b.dy - a.dy);
    final Path path = Path();
    path.moveTo(a.dx, a.dy);
    bool shouldDraw = true;
    Offset currentPoint = a;

    final double radians = (b - a).direction;
    final double dx = gap * 1; 
    final double dy = gap * 1; 

    while ((currentPoint.dx - b.dx).abs() > gap || (currentPoint.dy - b.dy).abs() > gap) {
        if (shouldDraw) {
             path.lineTo(currentPoint.dx + (a.dx == b.dx ? 0 : gap), currentPoint.dy + (a.dy == b.dy ? 0 : gap)); 
        } else {
             path.moveTo(currentPoint.dx + (a.dx == b.dx ? 0 : gap), currentPoint.dy + (a.dy == b.dy ? 0 : gap));
        }
        shouldDraw = !shouldDraw;
        if (a.dx == b.dx) { 
           currentPoint = Offset(currentPoint.dx, currentPoint.dy + gap);
        } else {
           currentPoint = Offset(currentPoint.dx + gap, currentPoint.dy);
        }
    }
    return path;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
