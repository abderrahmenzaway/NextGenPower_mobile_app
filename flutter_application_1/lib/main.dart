import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/energy_data_provider.dart';
import 'providers/notifications_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/my_factory_screen.dart';
import 'screens/smart_contracts_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/blockchain_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => EnergyDataProvider()),
        ChangeNotifierProvider(create: (context) => NotificationsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Next Gen Power',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _isAuthenticated = false;
  String _activeScreen = 'dashboard';
  int _selectedIndex = 0;
  String _currentFactoryId = '';
  String _currentFactoryName = '';

  void _handleLogin(String factoryId, String factoryName) {
    setState(() {
      _isAuthenticated = true;
      _activeScreen = 'dashboard';
      _selectedIndex = 0;
      _currentFactoryId = factoryId;
      _currentFactoryName = factoryName;
    });
    
    // Update the provider with current factory info
    final energyProvider = Provider.of<EnergyDataProvider>(context, listen: false);
    energyProvider.setCurrentFactory(factoryId, factoryName);
    
    // Connect to WebSocket for real-time notifications
    final notificationsProvider = Provider.of<NotificationsProvider>(context, listen: false);
    notificationsProvider.setEnergyDataProvider(energyProvider);
    notificationsProvider.connectToFactory(factoryId);
  }

  void _handleSignOut() {
    setState(() {
      _isAuthenticated = false;
      _activeScreen = 'dashboard';
      _currentFactoryId = '';
      _currentFactoryName = '';
    });
  }

  void _handleNavigate(String screen) {
    setState(() {
      _activeScreen = screen;
      // Update bottom nav index when navigating
      if (screen == 'dashboard') {
        _selectedIndex = 0;
      } else if (screen == 'myFactory') {
        _selectedIndex = 1;
      } else if (screen == 'offers') {
        _selectedIndex = 2;
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      switch (index) {
        case 0:
          _activeScreen = 'dashboard';
          break;
        case 1:
          _activeScreen = 'myFactory';
          break;
        case 2:
          _activeScreen = 'offers';
          break;
      }
    });
  }

  Widget _getScreen() {
    switch (_activeScreen) {
      case 'dashboard':
        return DashboardScreen(
          onNavigate: _handleNavigate,
          currentFactoryId: _currentFactoryId,
        );
      case 'myFactory':
        return MyFactoryScreen(
          onNavigate: _handleNavigate,
          factoryId: _currentFactoryId,
          factoryName: _currentFactoryName,
        );
      case 'offers':
        return SmartContractsScreen(
          onNavigate: _handleNavigate,
          currentFactoryId: _currentFactoryId,
        );
      case 'blockchain':
        final provider = Provider.of<EnergyDataProvider>(context, listen: false);
        return BlockchainScreen(
          onBack: () => _handleNavigate('dashboard'),
          factoryId: _currentFactoryId,
          factoryName: _currentFactoryName,
        );
      case 'profile':
        // Get current factory data from provider if available
        final provider = Provider.of<EnergyDataProvider>(context, listen: false);
        return ProfileScreen(
          onSignOut: _handleSignOut,
          onBack: () => _handleNavigate('dashboard'),
          factoryId: _currentFactoryId,
          factoryName: _currentFactoryName,
          currencyBalance: provider.currentData.costSavings,
          availableEnergy: provider.currentData.generation,
          dailyConsumption: provider.currentData.consumption,
        );
      default:
        return DashboardScreen(
          onNavigate: _handleNavigate,
          currentFactoryId: _currentFactoryId,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return LoginScreen(onLogin: _handleLogin);
    }

    final showBottomNav = _activeScreen != 'blockchain' && 
                          _activeScreen != 'profile';

    return Scaffold(
      body: _getScreen(),
      bottomNavigationBar: showBottomNav
          ? BottomNavigationBar(
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.factory),
                  label: 'My Factory',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.description),
                  label: 'Offers',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.blue,
              unselectedItemColor: Colors.grey,
              backgroundColor: Colors.grey.shade900,
              onTap: _onItemTapped,
            )
          : null,
    );
  }
}
