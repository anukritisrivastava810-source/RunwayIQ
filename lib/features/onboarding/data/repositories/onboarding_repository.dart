import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/onboarding_models.dart';

class OnboardingRepository {
  static final OnboardingRepository _instance = OnboardingRepository._internal();
  factory OnboardingRepository() => _instance;
  OnboardingRepository._internal();

  static const String _onboardingCompletedKey = 'onboarding_completed';

  // In-memory mock data store to simulate a backend database
  OnboardingData? currentData;

  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  Future<void> completeOnboarding(OnboardingData data) async {
    currentData = data;
    // Simulate backend API calls
    await Future.delayed(const Duration(seconds: 2));
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
  }

  // Helper methods to check for empty states in dashboard/tabs
  bool get hasEmployees => (currentData?.team?.teamSize ?? 0) > 1; // Assuming founder is 1
  bool get hasFunding => currentData?.funding?.hasRaised ?? false;
  bool get hasTreasury => currentData?.treasury?.hasInvestments ?? false;
  bool get hasExpenses => (currentData?.financials?.monthlyExpenses ?? 0) > 0;
}
