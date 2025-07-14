import '../models/recipes.dart';

class RecipeUtils {
  static Map<int, List<int>> groupByResult(List<Recipes> recipesList) {
    final map = <int, List<int>>{};
    for (final recipe in recipesList) {
      map.putIfAbsent(recipe.resultId, () => []).add(recipe.requiredId);
    }
    return map;
  }
} 