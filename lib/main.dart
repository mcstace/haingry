import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize cameras
  final cameras = await availableCameras();
  
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

// Global user preferences
class UserPreferences {
  static String cookingStyle = '';
  static String timePreference = '';
  static List<Recipe> savedRecipes = [];
  static XFile? lastFridgeImage; // Store the last captured image
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
              const SizedBox(height: 60),
              // Logo
              SizedBox(
                height: 60,
                child: Image.asset(
                  'assets/images/haingry_purple.jpg',
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
                'CAVEMAN-LEVEL EASY',
                'easy',
              ),
              
              const SizedBox(height: 20),
              
              _buildStyleButton(
                context,
                'A LITTLE FLAIR, MAYBE',
                'medium',
              ),
              
              const SizedBox(height: 20),
              
              _buildStyleButton(
                context,
                'MASTERCHEF STYLE',
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
                  'assets/images/haingry_purple.jpg',
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
                'IN A BIT, I CAN WAIT',
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
                  'assets/images/haingry_purple.jpg',
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
    
    // Navigate to recipes screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipesScreen(cameras: widget.cameras),
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

Return EXACTLY this JSON format with no other text:
{
  "recipes": [
    {
      "name": "Recipe Name",
      "rating": 4.5,
      "time": "25 MIN",
      "difficulty": "$difficulty",
      "ingredients": ["ingredient1", "ingredient2", "ingredient3"],
      "description": "Brief appealing description of the dish",
      "instructions": ["Step 1", "Step 2", "Step 3", "Step 4", "Step 5"]
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
        ingredients: ['Chicken', 'Vegetables', 'Soy Sauce', 'Rice'],
        description: 'A quick and healthy stir fry with fresh ingredients.',
        instructions: [
          'Cut chicken into bite-sized pieces',
          'Heat oil in a wok over high heat',
          'Add chicken and cook until golden',
          'Add vegetables and stir-fry',
          'Season and serve over rice'
        ],
        imageUrl: '',
      ),
      Recipe(
        name: 'Simple Pasta',
        rating: 4.1,
        time: '15 MIN',
        difficulty: UserPreferences.cookingStyle,
        ingredients: ['Pasta', 'Tomatoes', 'Cheese', 'Herbs'],
        description: 'Classic pasta dish with fresh ingredients.',
        instructions: [
          'Boil pasta according to package directions',
          'Prepare sauce with tomatoes',
          'Combine pasta and sauce',
          'Top with cheese and herbs',
          'Serve hot'
        ],
        imageUrl: '',
      ),
    ];
  }
}

// Recipes Screen
class RecipesScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  
  const RecipesScreen({super.key, required this.cameras});

  @override
  _RecipesScreenState createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  List<Recipe> _recipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateNewRecipes();
  }

  Future<void> _generateNewRecipes() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      List<String> detectedIngredients = [];
      
      // Step 1: Analyze fridge image if available
      if (UserPreferences.lastFridgeImage != null) {
        print('Analyzing fridge image with AI...');
        detectedIngredients = await RecipeGenerator.analyzeImageForIngredients(UserPreferences.lastFridgeImage!);
      } else {
        print('No fridge image available, using fallback ingredients');
        detectedIngredients = RecipeGenerator._getFallbackIngredients();
      }
      
      print('Detected ingredients: $detectedIngredients');
      
      // Step 2: Generate recipes based on detected ingredients
      print('Generating recipes with AI...');
      final recipes = await RecipeGenerator.generateRecipesFromIngredients(detectedIngredients);
      
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
            content: Text('AI analysis failed. Showing sample recipes.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
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
            onPressed: _generateNewRecipes, // Refresh recipes
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
                    'Analyzing your fridge contents...',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Generating personalized recipes...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
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
                        icon: const Icon(Icons.refresh, color: Color(0xFF7B68EE)),
                        label: const Text(
                          'More recipes',
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
            // Food Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _getFoodImageUrl(recipe.name),
                  fit: BoxFit.cover,
                  headers: {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey[300]!, Colors.grey[100]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF7B68EE),
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    // Try to load a more specific fallback image
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_getFoodColor(recipe.name), _getFoodColor(recipe.name).withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              _getFoodIcon(recipe.name),
                              color: Colors.white.withOpacity(0.8),
                              size: 35,
                            ),
                          ),
                          // Add food emojis as overlays for better visual appeal
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Text(
                              _getFoodEmoji(recipe.name),
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
                          UserPreferences.savedRecipes.contains(recipe)
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

  String _getFoodImageUrl(String recipeName) {
    // Use specific working Unsplash photo IDs for reliable food images
    Map<String, String> recipeImages = {
      // Pasta dishes
      'Spicy Pasta': 'https://images.unsplash.com/photo-1551892374-ecf8faf81d10?w=300&h=300&fit=crop&crop=center',
      'Creamy Pasta': 'https://images.unsplash.com/photo-1563379091339-03246963d4b9?w=300&h=300&fit=crop&crop=center',
      'Classic Pasta': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=300&h=300&fit=crop&crop=center',
      'Rustic Pasta': 'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?w=300&h=300&fit=crop&crop=center',
      'Fresh Pasta': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=300&h=300&fit=crop&crop=center',
      'Mediterranean Pasta': 'https://images.unsplash.com/photo-1563379091339-03246963d4b9?w=300&h=300&fit=crop&crop=center',
      'Garlic Pasta': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=300&h=300&fit=crop&crop=center',
      'Herb-Crusted Pasta': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=300&h=300&fit=crop&crop=center',
      'Lemon Pasta': 'https://images.unsplash.com/photo-1563379091339-03246963d4b9?w=300&h=300&fit=crop&crop=center',
      'Gourmet Pasta': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=300&h=300&fit=crop&crop=center',
      
      // Stir Fry dishes
      'Asian Style Stir Fry': 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=300&h=300&fit=crop&crop=center',
      'Classic Stir Fry': 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=300&h=300&fit=crop&crop=center',
      'Spicy Stir Fry': 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=300&h=300&fit=crop&crop=center',
      'Garlic Stir Fry': 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=300&h=300&fit=crop&crop=center',
      
      // Salad Bowls
      'Fresh Salad Bowl': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=300&h=300&fit=crop&crop=center',
      'Rustic Salad Bowl': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=300&h=300&fit=crop&crop=center',
      'Mediterranean Salad Bowl': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=300&h=300&fit=crop&crop=center',
      'Gourmet Salad Bowl': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=300&h=300&fit=crop&crop=center',
      
      // Rice Bowls
      'Asian Style Rice Bowl': 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=300&h=300&fit=crop&crop=center',
      'Fresh Rice Bowl': 'https://images.unsplash.com/photo-1563612116625-3012372fccce?w=300&h=300&fit=crop&crop=center',
      'Rustic Rice Bowl': 'https://images.unsplash.com/photo-1563612116625-3012372fccce?w=300&h=300&fit=crop&crop=center',
      'Hearty Rice Bowl': 'https://images.unsplash.com/photo-1563612116625-3012372fccce?w=300&h=300&fit=crop&crop=center',
      'Lemon Rice Bowl': 'https://images.unsplash.com/photo-1563612116625-3012372fccce?w=300&h=300&fit=crop&crop=center',
      
      // Pizza
      'Gourmet Pizza': 'https://images.unsplash.com/photo-1565299507177-b0ac66763828?w=300&h=300&fit=crop&crop=center',
      'Classic Pizza': 'https://images.unsplash.com/photo-1565299507177-b0ac66763828?w=300&h=300&fit=crop&crop=center',
      'Fresh Pizza': 'https://images.unsplash.com/photo-1565299507177-b0ac66763828?w=300&h=300&fit=crop&crop=center',
      
      // Soups
      'Hearty Soup': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=300&h=300&fit=crop&crop=center',
      'Fresh Soup': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=300&h=300&fit=crop&crop=center',
      'Classic Soup': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=300&h=300&fit=crop&crop=center',
      
      // Grilled dishes
      'Herb-Crusted Grilled Dish': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=300&h=300&fit=crop&crop=center',
      'Lemon Grilled Dish': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=300&h=300&fit=crop&crop=center',
      'Classic Grilled Dish': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=300&h=300&fit=crop&crop=center',
      'Rustic Grilled Dish': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=300&h=300&fit=crop&crop=center',
      
      // Curry
      'Classic Curry': 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=300&h=300&fit=crop&crop=center',
      'Spicy Curry': 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=300&h=300&fit=crop&crop=center',
      'Hearty Curry': 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=300&h=300&fit=crop&crop=center',
      
      // Casseroles
      'Herb-Crusted Casserole': 'https://images.unsplash.com/photo-1574894709920-11b28e7367e3?w=300&h=300&fit=crop&crop=center',
      'Fresh Casserole': 'https://images.unsplash.com/photo-1574894709920-11b28e7367e3?w=300&h=300&fit=crop&crop=center',
      'Gourmet Casserole': 'https://images.unsplash.com/photo-1574894709920-11b28e7367e3?w=300&h=300&fit=crop&crop=center',
      'Classic Casserole': 'https://images.unsplash.com/photo-1574894709920-11b28e7367e3?w=300&h=300&fit=crop&crop=center',
      
      // Wraps
      'Fresh Wrap': 'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=300&h=300&fit=crop&crop=center',
      'Healthy Wrap': 'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=300&h=300&fit=crop&crop=center',
      'Gourmet Wrap': 'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=300&h=300&fit=crop&crop=center',
      
      // Sandwiches
      'Gourmet Sandwich': 'https://images.unsplash.com/photo-1539252554453-80ab65ce3586?w=300&h=300&fit=crop&crop=center',
      'Fresh Sandwich': 'https://images.unsplash.com/photo-1539252554453-80ab65ce3586?w=300&h=300&fit=crop&crop=center',
      
      // Omelettes
      'Classic Omelette': 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=300&h=300&fit=crop&crop=center',
      'Fresh Omelette': 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=300&h=300&fit=crop&crop=center',
      'Herb-Crusted Omelette': 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=300&h=300&fit=crop&crop=center',
    };
    
    // Return specific image or fallback to a general delicious food image
    return recipeImages[recipeName] ?? 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=300&h=300&fit=crop&crop=center';
  }

  Color _getFoodColor(String recipeName) {
    final colors = [
      const Color(0xFFE57373), const Color(0xFFFFB74D), const Color(0xFFFF8A65),
      const Color(0xFFFFF176), const Color(0xFF81C784), const Color(0xFFFFD54F),
      const Color(0xFFDCE775), const Color(0xFFFF8A80), const Color(0xFFAED581),
    ];
    return colors[recipeName.hashCode % colors.length];
  }

  IconData _getFoodIcon(String recipeName) {
    final icons = [
      Icons.restaurant, Icons.local_pizza, Icons.rice_bowl, Icons.soup_kitchen,
      Icons.lunch_dining, Icons.egg, Icons.eco, Icons.outdoor_grill,
    ];
    return icons[recipeName.hashCode % icons.length];
  }

  String _getFoodEmoji(String recipeName) {
    String name = recipeName.toLowerCase();
    
    if (name.contains('pasta')) return '🍝';
    if (name.contains('stir fry')) return '🥘';
    if (name.contains('salad')) return '🥗';
    if (name.contains('rice bowl')) return '🍚';
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

  void _toggleSaveRecipe(Recipe recipe) {
    setState(() {
      if (UserPreferences.savedRecipes.contains(recipe)) {
        UserPreferences.savedRecipes.remove(recipe);
      } else {
        UserPreferences.savedRecipes.add(recipe);
      }
    });
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

// Recipe Detail Screen
class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  String _getFoodImageUrl(String recipeName) {
    // Use the same reliable image mapping for recipe details (higher resolution)
    Map<String, String> recipeImages = {
      // Pasta dishes
      'Spicy Pasta': 'https://images.unsplash.com/photo-1551892374-ecf8faf81d10?w=600&h=400&fit=crop&crop=center',
      'Creamy Pasta': 'https://images.unsplash.com/photo-1563379091339-03246963d4b9?w=600&h=400&fit=crop&crop=center',
      'Classic Pasta': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=600&h=400&fit=crop&crop=center',
      'Rustic Pasta': 'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?w=600&h=400&fit=crop&crop=center',
      'Fresh Pasta': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=600&h=400&fit=crop&crop=center',
      'Mediterranean Pasta': 'https://images.unsplash.com/photo-1563379091339-03246963d4b9?w=600&h=400&fit=crop&crop=center',
      'Garlic Pasta': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=600&h=400&fit=crop&crop=center',
      'Herb-Crusted Pasta': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=600&h=400&fit=crop&crop=center',
      'Lemon Pasta': 'https://images.unsplash.com/photo-1563379091339-03246963d4b9?w=600&h=400&fit=crop&crop=center',
      'Gourmet Pasta': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=600&h=400&fit=crop&crop=center',
      
      // Stir Fry dishes
      'Asian Style Stir Fry': 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=600&h=400&fit=crop&crop=center',
      'Classic Stir Fry': 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=600&h=400&fit=crop&crop=center',
      'Spicy Stir Fry': 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=600&h=400&fit=crop&crop=center',
      'Garlic Stir Fry': 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=600&h=400&fit=crop&crop=center',
      
      // Salad Bowls
      'Fresh Salad Bowl': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&h=400&fit=crop&crop=center',
      'Rustic Salad Bowl': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&h=400&fit=crop&crop=center',
      'Mediterranean Salad Bowl': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=600&h=400&fit=crop&crop=center',
      'Gourmet Salad Bowl': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&h=400&fit=crop&crop=center',
      
      // Rice Bowls
      'Asian Style Rice Bowl': 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=600&h=400&fit=crop&crop=center',
      'Fresh Rice Bowl': 'https://images.unsplash.com/photo-1563612116625-3012372fccce?w=600&h=400&fit=crop&crop=center',
      'Rustic Rice Bowl': 'https://images.unsplash.com/photo-1563612116625-3012372fccce?w=600&h=400&fit=crop&crop=center',
      'Hearty Rice Bowl': 'https://images.unsplash.com/photo-1563612116625-3012372fccce?w=600&h=400&fit=crop&crop=center',
      'Lemon Rice Bowl': 'https://images.unsplash.com/photo-1563612116625-3012372fccce?w=600&h=400&fit=crop&crop=center',
      
      // Pizza
      'Gourmet Pizza': 'https://images.unsplash.com/photo-1565299507177-b0ac66763828?w=600&h=400&fit=crop&crop=center',
      'Classic Pizza': 'https://images.unsplash.com/photo-1565299507177-b0ac66763828?w=600&h=400&fit=crop&crop=center',
      'Fresh Pizza': 'https://images.unsplash.com/photo-1565299507177-b0ac66763828?w=600&h=400&fit=crop&crop=center',
      
      // Soups
      'Hearty Soup': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=600&h=400&fit=crop&crop=center',
      'Fresh Soup': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=600&h=400&fit=crop&crop=center',
      'Classic Soup': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=600&h=400&fit=crop&crop=center',
      
      // Grilled dishes
      'Herb-Crusted Grilled Dish': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600&h=400&fit=crop&crop=center',
      'Lemon Grilled Dish': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600&h=400&fit=crop&crop=center',
      'Classic Grilled Dish': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600&h=400&fit=crop&crop=center',
      'Rustic Grilled Dish': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600&h=400&fit=crop&crop=center',
      
      // Curry
      'Classic Curry': 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=600&h=400&fit=crop&crop=center',
      'Spicy Curry': 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=600&h=400&fit=crop&crop=center',
      'Hearty Curry': 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=600&h=400&fit=crop&crop=center',
      
      // Casseroles
      'Herb-Crusted Casserole': 'https://images.unsplash.com/photo-1574894709920-11b28e7367e3?w=600&h=400&fit=crop&crop=center',
      'Fresh Casserole': 'https://images.unsplash.com/photo-1574894709920-11b28e7367e3?w=600&h=400&fit=crop&crop=center',
      'Gourmet Casserole': 'https://images.unsplash.com/photo-1574894709920-11b28e7367e3?w=600&h=400&fit=crop&crop=center',
      'Classic Casserole': 'https://images.unsplash.com/photo-1574894709920-11b28e7367e3?w=600&h=400&fit=crop&crop=center',
      
      // Wraps
      'Fresh Wrap': 'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=600&h=400&fit=crop&crop=center',
      'Healthy Wrap': 'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=600&h=400&fit=crop&crop=center',
      'Gourmet Wrap': 'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=600&h=400&fit=crop&crop=center',
      
      // Sandwiches
      'Gourmet Sandwich': 'https://images.unsplash.com/photo-1539252554453-80ab65ce3586?w=600&h=400&fit=crop&crop=center',
      'Fresh Sandwich': 'https://images.unsplash.com/photo-1539252554453-80ab65ce3586?w=600&h=400&fit=crop&crop=center',
      
      // Omelettes
      'Classic Omelette': 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=600&h=400&fit=crop&crop=center',
      'Fresh Omelette': 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=600&h=400&fit=crop&crop=center',
      'Herb-Crusted Omelette': 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=600&h=400&fit=crop&crop=center',
    };
    
    // Return specific image or fallback to a beautiful food image
    return recipeImages[recipeName] ?? 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600&h=400&fit=crop&crop=center';
  }

  Color _getFoodColor(String recipeName) {
    final colors = [
      const Color(0xFFE57373), const Color(0xFFFFB74D), const Color(0xFFFF8A65),
      const Color(0xFFFFF176), const Color(0xFF81C784), const Color(0xFFFFD54F),
    ];
    return colors[recipeName.hashCode % colors.length];
  }

  IconData _getFoodIcon(String recipeName) {
    final icons = [
      Icons.restaurant, Icons.local_pizza, Icons.rice_bowl, Icons.soup_kitchen,
      Icons.lunch_dining, Icons.egg, Icons.eco, Icons.outdoor_grill,
    ];
    return icons[recipeName.hashCode % icons.length];
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
          recipe.name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              UserPreferences.savedRecipes.contains(recipe)
                  ? Icons.bookmark
                  : Icons.bookmark_border,
              color: const Color(0xFF7B68EE),
            ),
            onPressed: () {
              // Toggle save recipe functionality can be added here
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  _getFoodImageUrl(recipe.name),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: _getFoodColor(recipe.name),
                      child: Icon(
                        _getFoodIcon(recipe.name),
                        color: Colors.white,
                        size: 80,
                      ),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Recipe Info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B68EE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${recipe.rating} ⭐',
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
                    recipe.time,
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
                    recipe.difficulty.toUpperCase(),
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
              recipe.description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
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
            
            ...recipe.ingredients.map((ingredient) => Padding(
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
            
            ...recipe.instructions.asMap().entries.map((entry) {
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

// Saved Recipes Screen
class SavedRecipesScreen extends StatelessWidget {
  final List<CameraDescription> cameras;
  
  const SavedRecipesScreen({super.key, required this.cameras});

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
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: UserPreferences.savedRecipes.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF7B68EE), width: 2),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      UserPreferences.savedRecipes[index].name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      UserPreferences.savedRecipes[index].time,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: const Icon(
                      Icons.bookmark,
                      color: Color(0xFF7B68EE),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecipeDetailScreen(
                            recipe: UserPreferences.savedRecipes[index],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

// Recipe Model
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