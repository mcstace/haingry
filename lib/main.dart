import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add this to pubspec.yaml

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize cameras
  final cameras = await availableCameras();
  
  // Load saved recipes on app start
  await UserPreferences.loadSavedRecipes();
  
  runApp(HaingryApp(cameras: cameras));
}

class HaingryApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  
  const HaingryApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Haingry',
      theme: ThemeData(
        primaryColor: const Color(0xFF7B68EE),
        fontFamily: 'Inter',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: CookingStyleScreen(cameras: cameras),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Global user preferences with persistent storage
class UserPreferences {
  static String cookingStyle = '';
  static String timePreference = '';
  static List<Recipe> savedRecipes = [];
  static XFile? lastFridgeImage;

  // Save recipes to persistent storage
  static Future<void> saveSavedRecipes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> recipesJson = savedRecipes.map((recipe) => jsonEncode({
        'name': recipe.name,
        'rating': recipe.rating,
        'time': recipe.time,
        'difficulty': recipe.difficulty,
        'ingredients': recipe.ingredients,
        'description': recipe.description,
        'instructions': recipe.instructions,
        'imageUrl': recipe.imageUrl,
      })).toList();
      await prefs.setStringList('saved_recipes', recipesJson);
      print('Saved ${savedRecipes.length} recipes to storage');
    } catch (e) {
      print('Error saving recipes: $e');
    }
  }

  // Load recipes from persistent storage
  static Future<void> loadSavedRecipes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? recipesJson = prefs.getStringList('saved_recipes');
      
      if (recipesJson != null) {
        savedRecipes = recipesJson.map((recipeString) {
          final Map<String, dynamic> recipeData = jsonDecode(recipeString);
          return Recipe(
            name: recipeData['name'],
            rating: (recipeData['rating'] as num).toDouble(),
            time: recipeData['time'],
            difficulty: recipeData['difficulty'],
            ingredients: List<String>.from(recipeData['ingredients']),
            description: recipeData['description'],
            instructions: List<String>.from(recipeData['instructions']),
            imageUrl: recipeData['imageUrl'] ?? '',
          );
        }).toList();
        print('Loaded ${savedRecipes.length} recipes from storage');
      }
    } catch (e) {
      print('Error loading recipes: $e');
      savedRecipes = []; // Reset to empty list if loading fails
    }
  }

  // Add/remove recipe and save to storage
  static Future<void> toggleSaveRecipe(Recipe recipe) async {
    if (savedRecipes.any((r) => r.name == recipe.name)) {
      savedRecipes.removeWhere((r) => r.name == recipe.name);
    } else {
      savedRecipes.add(recipe);
    }
    await saveSavedRecipes();
  }

  // Check if recipe is saved
  static bool isRecipeSaved(Recipe recipe) {
    return savedRecipes.any((r) => r.name == recipe.name);
  }
}

// Cooking Style Selection Screen
class CookingStyleScreen extends StatelessWidget {
  final List<CameraDescription> cameras;
  
  const CookingStyleScreen({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo and Bookmark Button Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 50), // Spacer for centering logo
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        height: 60,
                        child: Image.asset(
                          'assets/images/haingrypurple.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Text(
                              'haingry',
                              style: TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7B68EE),
                                letterSpacing: -1,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  // Bookmark Button
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SavedRecipesScreen(cameras: cameras),
                        ),
                      );
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B68EE).withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF7B68EE),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.bookmark,
                        color: Color(0xFF7B68EE),
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
              
              // Title
              const Text(
                'Pick your cooking style today',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 60),
              
              // Cooking Style Buttons
              _buildStyleButton(
                context,
                'CAVEMAN-LEVEL EASY🪨',
                'easy',
              ),
              
              const SizedBox(height: 20),
              
              _buildStyleButton(
                context,
                'A LITTLE FLAIR✨',
                'medium',
              ),
              
              const SizedBox(height: 20),
              
              _buildStyleButton(
                context,
                'MASTERCHEF STYLE👨‍🍳',
                'hard',
              ),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyleButton(BuildContext context, String text, String style) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          UserPreferences.cookingStyle = style;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TimePreferenceScreen(cameras: cameras),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7B68EE),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// Time Preference Screen
class TimePreferenceScreen extends StatelessWidget {
  final List<CameraDescription> cameras;
  
  const TimePreferenceScreen({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              // Logo
              SizedBox(
                height: 60,
                child: Image.asset(
                  'assets/images/haingrypurple.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text(
                      'haingry',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7B68EE),
                        letterSpacing: -1,
                      ),
                    );
                  },
                ),
              ),
              
              const Spacer(),
              
              // Title
              const Text(
                'When do you want to eat?',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 60),
              
              // Time Preference Buttons
              _buildTimeButton(
                context,
                'LIKE... NOW 😋',
                'quick',
              ),
              
              const SizedBox(height: 20),
              
              _buildTimeButton(
                context,
                'IN A BIT, I CAN WAIT⏱️',
                'longer',
              ),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeButton(BuildContext context, String text, String timePreference) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          UserPreferences.timePreference = timePreference;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FridgePhotoScreen(cameras: cameras),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7B68EE),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// Fridge Photo Screen
class FridgePhotoScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  
  const FridgePhotoScreen({super.key, required this.cameras});

  @override
  _FridgePhotoScreenState createState() => _FridgePhotoScreenState();
}

class _FridgePhotoScreenState extends State<FridgePhotoScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              // Logo
              SizedBox(
                height: 60,
                child: Image.asset(
                  'assets/images/haingrypurple.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text(
                      'haingry',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7B68EE),
                        letterSpacing: -1,
                      ),
                    );
                  },
                ),
              ),
              
              const Spacer(),
              
              // Fridge Illustration
              Container(
                width: 300,
                height: 450,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7B68EE).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/fridge.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 300,
                        height: 450,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B68EE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported, color: Colors.white, size: 60),
                              SizedBox(height: 16),
                              Text(
                                'Add fridge.png to\nassets/images/ folder',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Camera Button
              GestureDetector(
                onTap: _takePicture,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B68EE),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7B68EE).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Title
              const Text(
                'Take a photo of\nyour fridge!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _takePicture() async {
    final permission = await Permission.camera.request();
    if (permission.isDenied) {
      _showPermissionDialog();
      return;
    }

    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      await _processImage(image);
    }
  }

  Future<void> _processImage(XFile image) async {
    // Store the image for analysis
    UserPreferences.lastFridgeImage = image;
    
    // Navigate to ingredients confirmation screen first
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IngredientsConfirmationScreen(cameras: widget.cameras),
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Camera Permission Required'),
          content: const Text('Please allow camera access to take photos of your fridge contents.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

// NEW: Ingredients Confirmation Screen
class IngredientsConfirmationScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  
  const IngredientsConfirmationScreen({super.key, required this.cameras});

  @override
  _IngredientsConfirmationScreenState createState() => _IngredientsConfirmationScreenState();
}

class _IngredientsConfirmationScreenState extends State<IngredientsConfirmationScreen> {
  List<String> _detectedIngredients = [];
  List<String> _additionalIngredients = [];
  final TextEditingController _ingredientController = TextEditingController();
  bool _isAnalyzing = true;

  @override
  void initState() {
    super.initState();
    _analyzeIngredients();
  }

  Future<void> _analyzeIngredients() async {
    try {
      List<String> detectedIngredients = [];
      
      if (UserPreferences.lastFridgeImage != null) {
        print('Analyzing fridge image with AI...');
        detectedIngredients = await RecipeGenerator.analyzeImageForIngredients(UserPreferences.lastFridgeImage!);
      } else {
        print('No fridge image available, using fallback ingredients');
        detectedIngredients = RecipeGenerator._getFallbackIngredients();
      }
      
      setState(() {
        _detectedIngredients = detectedIngredients;
        _isAnalyzing = false;
      });
    } catch (e) {
      print('Error analyzing ingredients: $e');
      setState(() {
        _detectedIngredients = RecipeGenerator._getFallbackIngredients();
        _isAnalyzing = false;
      });
    }
  }

  void _addIngredient() {
    String ingredient = _ingredientController.text.trim();
    if (ingredient.isNotEmpty && !_additionalIngredients.contains(ingredient.toLowerCase())) {
      setState(() {
        _additionalIngredients.add(ingredient);
        _ingredientController.clear();
      });
    }
  }

  void _removeAdditionalIngredient(String ingredient) {
    setState(() {
      _additionalIngredients.remove(ingredient);
    });
  }

  void _removeDetectedIngredient(String ingredient) {
    setState(() {
      _detectedIngredients.remove(ingredient);
    });
  }

  void _generateRecipes() {
    List<String> allIngredients = [..._detectedIngredients, ..._additionalIngredients];
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipesScreen(
          cameras: widget.cameras,
          ingredients: allIngredients,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: SizedBox(
          height: 40,
          child: Image.asset(
            'assets/images/haingrypurple.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Text(
                'haingry',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7B68EE),
                ),
              );
            },
          ),
        ),
        centerTitle: true,
      ),
      body: _isAnalyzing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF7B68EE),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Analyzing your fridge contents...',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const Text(
                    'Ingredients Found',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  const Text(
                    'We detected these ingredients in your fridge. Tap any to remove, or add more below.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      height: 1.3,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Detected Ingredients
                  if (_detectedIngredients.isNotEmpty) ...[
                    const Text(
                      'Detected from your fridge:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _detectedIngredients.map((ingredient) {
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF7B68EE).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF7B68EE),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _removeDetectedIngredient(ingredient),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      ingredient,
                                      style: const TextStyle(
                                        color: Color(0xFF7B68EE),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Color(0xFF7B68EE),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Add More Ingredients Section
                  const Text(
                    'Add more ingredients:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Input Field
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ingredientController,
                          decoration: InputDecoration(
                            hintText: 'Enter ingredient (e.g., salt, olive oil, spices...)',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF7B68EE)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: (_) => _addIngredient(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B68EE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: _addIngredient,
                          icon: const Icon(Icons.add, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Additional Ingredients Display
                  if (_additionalIngredients.isNotEmpty) ...[
                    const Text(
                      'Added by you:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _additionalIngredients.map((ingredient) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.green,
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _removeAdditionalIngredient(ingredient),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      ingredient,
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Generate Recipes Button
                  if (_detectedIngredients.isNotEmpty || _additionalIngredients.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _generateRecipes,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7B68EE),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Generate Recipes (${_detectedIngredients.length + _additionalIngredients.length} ingredients)',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _ingredientController.dispose();
    super.dispose();
  }
}

// AI-Powered Recipe Generator using OpenAI API
class RecipeGenerator {
  // TODO: Replace with your actual OpenAI API key
  static const String _apiKey = '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';
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  static Future<List<String>> analyzeImageForIngredients(XFile image) async {
    if (_apiKey.isEmpty) {
      print('OpenAI API key not found. Using fallback ingredients.');
      return _getFallbackIngredients();
    }

    try {
      // Convert image to base64
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Analyze this fridge/pantry photo and list all the food ingredients you can clearly see. Focus on ingredients that can be used for cooking. Return ONLY a comma-separated list of ingredient names, no other text. For example: eggs, milk, cheese, tomatoes, chicken breast, onions'
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image'
                  }
                }
              ]
            }
          ],
          'max_tokens': 200,
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];

        final List<String> ingredients = content.split(',')
          .map<String>((String e) => e.trim())
          .where((String e) => e.isNotEmpty)
          .toList();
        
        print('AI detected ingredients: $ingredients');
        return ingredients;
      } else {
        print('OpenAI API error: ${response.statusCode}');
        return _getFallbackIngredients();
      }
    } catch (e) {
      print('Error analyzing image: $e');
      return _getFallbackIngredients();
    }
  }

  static Future<List<Recipe>> generateRecipesFromIngredients(List<String> ingredients) async {
    if (_apiKey.isEmpty) {
      print('OpenAI API key not found. Using fallback recipes.');
      return _getFallbackRecipes();
    }

    try {
      final difficulty = UserPreferences.cookingStyle;
      final timePreference = UserPreferences.timePreference == 'quick' ? '10-25 minutes' : '25-60 minutes';
      final ingredientList = ingredients.join(', ');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a professional chef who creates recipes based on available ingredients. Always respond with valid JSON format.'
            },
            {
              'role': 'user',
              'content': '''
Create 8 different $difficulty-level recipes using these ingredients: $ingredientList

Requirements:
- Cooking time: $timePreference
- Difficulty: $difficulty
- Use as many of the provided ingredients as possible
- Include common pantry staples (salt, pepper, oil, etc.) as needed
- CRITICAL: All ingredients must have EXACT measurements (cups, tablespoons, teaspoons, ounces, pounds, etc.)
- CRITICAL: All instructions must include specific cooking times, temperatures, and detailed techniques
- Instructions should be detailed enough that a beginner could follow them successfully

Return EXACTLY this JSON format with no other text:
{
  "recipes": [
    {
      "name": "Recipe Name",
      "rating": 4.5,
      "time": "25 MIN",
      "difficulty": "$difficulty",
      "ingredients": ["2 cups ingredient1", "1 tablespoon ingredient2", "1/2 pound ingredient3"],
      "description": "Brief appealing description of the dish",
      "instructions": [
        "Heat 2 tablespoons olive oil in a large skillet over medium-high heat for 2 minutes",
        "Add 1 diced onion and cook for 3-4 minutes until translucent",
        "Add 2 minced garlic cloves and cook for 30 seconds until fragrant",
        "Add 1 pound chicken breast (cut into 1-inch pieces) and cook for 5-6 minutes until golden brown",
        "Season with 1 teaspoon salt and 1/2 teaspoon black pepper, then add 1 cup rice and 2 cups chicken broth",
        "Bring to a boil, then reduce heat to low, cover, and simmer for 18-20 minutes until rice is tender",
        "Remove from heat and let stand 5 minutes before serving"
      ]
    }
  ]
}
'''
            }
          ],
          'max_tokens': 2000,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        try {
          final recipesJson = jsonDecode(content);
          final List<Recipe> recipes = [];
          
          for (var recipeData in recipesJson['recipes']) {
            recipes.add(Recipe(
              name: recipeData['name'],
              rating: (recipeData['rating'] as num).toDouble(),
              time: recipeData['time'],
              difficulty: recipeData['difficulty'],
              ingredients: List<String>.from(recipeData['ingredients']),
              description: recipeData['description'],
              instructions: List<String>.from(recipeData['instructions']),
              imageUrl: '',
            ));
          }
          
          print('Generated ${recipes.length} AI recipes');
          return recipes;
        } catch (e) {
          print('Error parsing recipe JSON: $e');
          return _getFallbackRecipes();
        }
      } else {
        print('OpenAI API error: ${response.statusCode}');
        return _getFallbackRecipes();
      }
    } catch (e) {
      print('Error generating recipes: $e');
      return _getFallbackRecipes();
    }
  }

  static List<String> _getFallbackIngredients() {
    final List<List<String>> ingredientSets = [
      ['chicken breast', 'bell peppers', 'onions', 'garlic', 'rice', 'olive oil'],
      ['ground beef', 'pasta', 'tomatoes', 'cheese', 'basil', 'mushrooms'],
      ['salmon', 'asparagus', 'lemon', 'potatoes', 'butter', 'herbs'],
      ['eggs', 'spinach', 'cheese', 'bread', 'milk', 'bacon'],
      ['tofu', 'broccoli', 'carrots', 'soy sauce', 'ginger', 'rice noodles'],
    ];
    
    final random = Random();
    return ingredientSets[random.nextInt(ingredientSets.length)];
  }

  static List<Recipe> _getFallbackRecipes() {
    return [
      Recipe(
        name: 'Quick Chicken Stir Fry',
        rating: 4.3,
        time: '20 MIN',
        difficulty: UserPreferences.cookingStyle,
        ingredients: [
          '1 pound boneless chicken breast, cut into 1-inch strips',
          '2 cups mixed bell peppers, sliced',
          '1 medium onion, sliced',
          '3 cloves garlic, minced',
          '2 tablespoons vegetable oil',
          '3 tablespoons soy sauce',
          '1 tablespoon cornstarch',
          '1 teaspoon sesame oil',
          '1/2 teaspoon black pepper',
          '2 cups cooked jasmine rice'
        ],
        description: 'A quick and healthy stir fry with tender chicken and crisp vegetables in a savory sauce.',
        instructions: [
          'Heat 1 tablespoon vegetable oil in a large wok or skillet over high heat for 1 minute until smoking',
          'Add chicken strips in a single layer and cook undisturbed for 3-4 minutes until golden brown on one side',
          'Stir chicken and cook another 2-3 minutes until cooked through (internal temp 165°F). Remove to plate',
          'Add remaining 1 tablespoon oil to the same pan, then add sliced onion and bell peppers',
          'Stir-fry vegetables for 3-4 minutes until crisp-tender and slightly charred',
          'Add minced garlic and cook for 30 seconds until fragrant',
          'In a small bowl, whisk together soy sauce, cornstarch, and sesame oil until smooth',
          'Return chicken to pan, pour sauce over everything, and toss for 1-2 minutes until sauce thickens',
          'Season with black pepper and serve immediately over hot rice'
        ],
        imageUrl: '',
      ),
      Recipe(
        name: 'Garlic Parmesan Pasta',
        rating: 4.5,
        time: '18 MIN',
        difficulty: UserPreferences.cookingStyle,
        ingredients: [
          '12 oz spaghetti or linguine pasta',
          '6 cloves garlic, thinly sliced',
          '1/2 cup extra virgin olive oil',
          '1 cup freshly grated Parmesan cheese',
          '2 large tomatoes, diced',
          '1/4 cup fresh basil leaves, chopped',
          '1 teaspoon salt',
          '1/2 teaspoon black pepper',
          '1/4 teaspoon red pepper flakes',
          '2 tablespoons butter'
        ],
        description: 'Classic Italian pasta with aromatic garlic, rich Parmesan, and fresh herbs.',
        instructions: [
          'Bring a large pot of salted water (1 tablespoon salt per quart) to a rolling boil',
          'Add pasta and cook according to package directions until al dente (typically 8-10 minutes)',
          'Reserve 1 cup pasta cooking water, then drain pasta',
          'While pasta cooks, heat olive oil in a large skillet over medium-low heat for 2 minutes',
          'Add sliced garlic to oil and cook for 2-3 minutes until golden and fragrant (do not brown)',
          'Add diced tomatoes to the skillet and cook for 3-4 minutes until they start to break down',
          'Add cooked pasta to the skillet with garlic and tomatoes',
          'Add butter, 1/2 cup pasta water, salt, pepper, and red pepper flakes',
          'Toss pasta for 2-3 minutes, adding more pasta water if needed to create a silky sauce',
          'Remove from heat, add Parmesan cheese and fresh basil, toss until cheese melts',
          'Serve immediately with additional Parmesan on the side'
        ],
        imageUrl: '',
      ),
      Recipe(
        name: 'Herb-Crusted Salmon with Roasted Vegetables',
        rating: 4.6,
        time: '25 MIN',
        difficulty: UserPreferences.cookingStyle,
        ingredients: [
          '4 salmon fillets (6 oz each), skin removed',
          '1 pound baby potatoes, halved',
          '1 bunch asparagus, trimmed',
          '2 lemons, sliced',
          '4 tablespoons olive oil, divided',
          '2 tablespoons fresh dill, chopped',
          '2 tablespoons fresh parsley, chopped',
          '3 cloves garlic, minced',
          '1 teaspoon salt',
          '1/2 teaspoon black pepper',
          '2 tablespoons butter',
          '1/4 cup panko breadcrumbs'
        ],
        description: 'Flaky salmon with a crispy herb crust served alongside perfectly roasted seasonal vegetables.',
        instructions: [
          'Preheat oven to 425°F and line a large baking sheet with parchment paper',
          'Toss halved potatoes with 2 tablespoons olive oil, 1/2 teaspoon salt, and 1/4 teaspoon pepper',
          'Spread potatoes on one side of the baking sheet and roast for 12 minutes',
          'Meanwhile, mix breadcrumbs, dill, parsley, minced garlic, and remaining salt and pepper in a bowl',
          'Pat salmon fillets dry and brush with remaining 2 tablespoons olive oil',
          'Press herb-breadcrumb mixture firmly onto top of each salmon fillet',
          'After potatoes have roasted 12 minutes, add asparagus to the other side of the baking sheet',
          'Place seasoned salmon fillets on top of the asparagus and arrange lemon slices around fish',
          'Dot salmon with small pieces of butter and roast everything for 12-15 minutes',
          'Salmon is done when it flakes easily with a fork and internal temperature reaches 145°F',
          'Let rest for 3 minutes before serving with roasted vegetables and lemon wedges'
        ],
        imageUrl: '',
      ),
    ];
  }
}

// UPDATED: Recipes Screen - now accepts ingredients parameter
class RecipesScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final List<String> ingredients; // New parameter for ingredients
  
  const RecipesScreen({
    super.key, 
    required this.cameras,
    required this.ingredients, // Make ingredients required
  });

  @override
  _RecipesScreenState createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  List<Recipe> _recipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateRecipesFromIngredients();
  }

  Future<void> _generateRecipesFromIngredients() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      print('Generating recipes with ingredients: ${widget.ingredients}');
      
      // Generate recipes based on provided ingredients
      final recipes = await RecipeGenerator.generateRecipesFromIngredients(widget.ingredients);
      
      setState(() {
        _recipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      print('Error in recipe generation: $e');
      
      // Fallback to basic recipes if AI fails
      setState(() {
        _recipes = RecipeGenerator._getFallbackRecipes();
        _isLoading = false;
      });
      
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI recipe generation failed. Showing sample recipes.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _generateNewRecipes() async {
    // Go back to ingredients confirmation screen for new recipes
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => IngredientsConfirmationScreen(cameras: widget.cameras),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: SizedBox(
          height: 40,
          child: Image.asset(
            'assets/images/haingry_purple.jpg',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Text(
                'haingry',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7B68EE),
                ),
              );
            },
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black, size: 28),
            onPressed: _generateNewRecipes, // Go back to ingredients screen
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.black, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SavedRecipesScreen(cameras: widget.cameras),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF7B68EE),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Creating personalized recipes...',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Recipe count header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Found ${_recipes.length} recipes for you!',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _generateNewRecipes,
                        icon: const Icon(Icons.edit, color: Color(0xFF7B68EE)),
                        label: const Text(
                          'Edit ingredients',
                          style: TextStyle(color: Color(0xFF7B68EE)),
                        ),
                      ),
                    ],
                  ),
                ),
                // Recipe list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _recipes.length,
                    itemBuilder: (context, index) {
                      return _buildRecipeCard(_recipes[index]);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF7B68EE), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B68EE).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Food Emoji Container (replacing Unsplash images)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    _getFoodColor(recipe.name),
                    _getFoodColor(recipe.name).withOpacity(0.8)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getFoodColor(recipe.name).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _getFoodEmoji(recipe.name),
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Recipe Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Text(
                        recipe.rating.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.star,
                        color: Color(0xFF7B68EE),
                        size: 16,
                      ),
                      
                      const SizedBox(width: 16),
                      
                      Text(
                        recipe.time,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.access_time,
                        color: Color(0xFF7B68EE),
                        size: 16,
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Difficulty indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(recipe.difficulty),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          recipe.difficulty.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      
                      const Spacer(),
                      
                      GestureDetector(
                        onTap: () => _toggleSaveRecipe(recipe),
                        child: Icon(
                          UserPreferences.isRecipeSaved(recipe)
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: const Color(0xFF7B68EE),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // View Recipe Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showRecipeDetails(recipe),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B68EE),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'View Recipe',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getFoodColor(String recipeName) {
    final colors = [
      const Color(0xFFE57373), const Color(0xFFFFB74D), const Color(0xFFFF8A65),
      const Color(0xFFFFF176), const Color(0xFF81C784), const Color(0xFFFFD54F),
      const Color(0xFFDCE775), const Color(0xFFFF8A80), const Color(0xFFAED581),
    ];
    return colors[recipeName.hashCode % colors.length];
  }

  String _getFoodEmoji(String recipeName) {
    String name = recipeName.toLowerCase();
    
    // More comprehensive emoji mapping
    if (name.contains('pasta') || name.contains('spaghetti') || name.contains('linguine')) return '🍝';
    if (name.contains('stir fry') || name.contains('stir-fry') || name.contains('wok')) return '🥘';
    if (name.contains('salad') || name.contains('greens')) return '🥗';
    if (name.contains('rice bowl') || name.contains('rice') || name.contains('fried rice')) return '🍚';
    if (name.contains('soup') || name.contains('broth') || name.contains('bisque')) return '🍲';
    if (name.contains('pizza')) return '🍕';
    if (name.contains('curry') || name.contains('dal') || name.contains('masala')) return '🍛';
    if (name.contains('omelette') || name.contains('omelet') || name.contains('scrambled')) return '🍳';
    if (name.contains('sandwich') || name.contains('burger') || name.contains('panini')) return '🥪';
    if (name.contains('wrap') || name.contains('burrito') || name.contains('tortilla')) return '🌯';
    if (name.contains('grilled') || name.contains('bbq') || name.contains('barbecue')) return '🍖';
    if (name.contains('casserole') || name.contains('baked') || name.contains('lasagna')) return '🥘';
    if (name.contains('chicken') || name.contains('poultry')) return '🍗';
    if (name.contains('fish') || name.contains('salmon') || name.contains('tuna')) return '🐟';
    if (name.contains('beef') || name.contains('steak') || name.contains('meat')) return '🥩';
    if (name.contains('noodle') || name.contains('ramen') || name.contains('pho')) return '🍜';
    if (name.contains('taco') || name.contains('mexican')) return '🌮';
    if (name.contains('sushi') || name.contains('roll')) return '🍣';
    if (name.contains('smoothie') || name.contains('shake')) return '🥤';
    if (name.contains('bread') || name.contains('toast')) return '🍞';
    if (name.contains('egg')) return '🥚';
    if (name.contains('potato') || name.contains('fries')) return '🥔';
    
    return '🍽️'; // Default food emoji
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _toggleSaveRecipe(Recipe recipe) async {
    await UserPreferences.toggleSaveRecipe(recipe);
    setState(() {}); // Update UI to reflect bookmark state
    
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          UserPreferences.isRecipeSaved(recipe) 
              ? 'Recipe saved to bookmarks!' 
              : 'Recipe removed from bookmarks'
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF7B68EE),
      ),
    );
  }

  void _showRecipeDetails(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipe: recipe),
      ),
    );
  }
}

// Recipe Detail Screen (unchanged)
class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  _RecipeDetailScreenState createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  Color _getFoodColor(String recipeName) {
    final colors = [
      const Color(0xFFE57373), const Color(0xFFFFB74D), const Color(0xFFFF8A65),
      const Color(0xFFFFF176), const Color(0xFF81C784), const Color(0xFFFFD54F),
    ];
    return colors[recipeName.hashCode % colors.length];
  }

  String _getFoodEmoji(String recipeName) {
    String name = recipeName.toLowerCase();
    
    if (name.contains('pasta') || name.contains('spaghetti')) return '🍝';
    if (name.contains('stir fry') || name.contains('stir-fry')) return '🥘';
    if (name.contains('salad')) return '🥗';
    if (name.contains('rice bowl') || name.contains('rice')) return '🍚';
    if (name.contains('soup')) return '🍲';
    if (name.contains('pizza')) return '🍕';
    if (name.contains('curry')) return '🍛';
    if (name.contains('omelette') || name.contains('omelet')) return '🍳';
    if (name.contains('sandwich')) return '🥪';
    if (name.contains('wrap')) return '🌯';
    if (name.contains('grilled')) return '🍖';
    if (name.contains('casserole')) return '🥘';
    if (name.contains('chicken')) return '🍗';
    if (name.contains('fish') || name.contains('salmon')) return '🐟';
    if (name.contains('beef') || name.contains('steak')) return '🥩';
    if (name.contains('noodle') || name.contains('ramen')) return '🍜';
    
    return '🍽️';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.recipe.name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              UserPreferences.isRecipeSaved(widget.recipe)
                  ? Icons.bookmark
                  : Icons.bookmark_border,
              color: const Color(0xFF7B68EE),
            ),
            onPressed: () async {
              await UserPreferences.toggleSaveRecipe(widget.recipe);
              setState(() {}); // Update bookmark icon
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    UserPreferences.isRecipeSaved(widget.recipe) 
                        ? 'Recipe saved to bookmarks!' 
                        : 'Recipe removed from bookmarks'
                  ),
                  backgroundColor: const Color(0xFF7B68EE),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Emoji Display
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      _getFoodColor(widget.recipe.name),
                      _getFoodColor(widget.recipe.name).withOpacity(0.8)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getFoodColor(widget.recipe.name).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _getFoodEmoji(widget.recipe.name),
                    style: const TextStyle(fontSize: 100),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Recipe Info
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B68EE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.recipe.rating} ⭐',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B68EE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.recipe.time,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.recipe.difficulty.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Description
            Text(
              widget.recipe.description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Ingredients
            const Text(
              'Ingredients',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 12),
            
            ...widget.recipe.ingredients.map((ingredient) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF7B68EE),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    ingredient,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            )),
            
            const SizedBox(height: 24),
            
            // Instructions
            const Text(
              'Instructions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 12),
            
            ...widget.recipe.instructions.asMap().entries.map((entry) {
              int index = entry.key;
              String instruction = entry.value;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFF7B68EE),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        instruction,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// Saved Recipes Screen (unchanged)
class SavedRecipesScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  
  const SavedRecipesScreen({super.key, required this.cameras});

  @override
  _SavedRecipesScreenState createState() => _SavedRecipesScreenState();
}

class _SavedRecipesScreenState extends State<SavedRecipesScreen> {
  @override
  void initState() {
    super.initState();
    // Reload saved recipes when screen opens
    _loadSavedRecipes();
  }

  Future<void> _loadSavedRecipes() async {
    await UserPreferences.loadSavedRecipes();
    setState(() {});
  }

  String _getFoodEmoji(String recipeName) {
    String name = recipeName.toLowerCase();
    
    if (name.contains('pasta')) return '🍝';
    if (name.contains('stir fry')) return '🥘';
    if (name.contains('salad')) return '🥗';
    if (name.contains('rice bowl') || name.contains('rice')) return '🍚';
    if (name.contains('soup')) return '🍲';
    if (name.contains('pizza')) return '🍕';
    if (name.contains('curry')) return '🍛';
    if (name.contains('omelette')) return '🍳';
    if (name.contains('sandwich')) return '🥪';
    if (name.contains('wrap')) return '🌯';
    if (name.contains('grilled')) return '🍖';
    if (name.contains('casserole')) return '🥘';
    
    return '🍽️';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Saved Recipes',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: UserPreferences.savedRecipes.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No saved recipes yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Bookmark recipes to see them here!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Header with count
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'You have ${UserPreferences.savedRecipes.length} saved recipe${UserPreferences.savedRecipes.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
                // Recipe list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: UserPreferences.savedRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = UserPreferences.savedRecipes[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF7B68EE), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7B68EE).withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7B68EE).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                _getFoodEmoji(recipe.name),
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                          title: Text(
                            recipe.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              Text(
                                '${recipe.rating} ⭐',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                recipe.time,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: const Icon(
                            Icons.bookmark,
                            color: Color(0xFF7B68EE),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RecipeDetailScreen(recipe: recipe),
                              ),
                            ).then((_) {
                              // Refresh the list when returning from detail screen
                              setState(() {});
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

// Recipe Model (unchanged)
class Recipe {
  final String name;
  final double rating;
  final String time;
  final String difficulty;
  final List<String> ingredients;
  final String description;
  final List<String> instructions;
  final String imageUrl;

  Recipe({
    required this.name,
    required this.rating,
    required this.time,
    required this.difficulty,
    required this.ingredients,
    required this.description,
    required this.instructions,
    required this.imageUrl,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Recipe && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;
}
