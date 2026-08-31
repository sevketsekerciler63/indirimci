import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import 'config/theme/app_theme.dart';
import 'core/services/storage_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/scraper_service.dart';
import 'app_shell.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('Background task started: $task');
      
      // Arka planda çalışırken gerekli servisleri başlat
      await StorageService.init();
      final scraper = ScraperService();
      
      final favorites = StorageService.getFavorites();
      
      if (favorites.isEmpty) {
        return Future.value(true);
      }
      
      bool priceDropped = false;
      
      // Favorilerdeki her bir ürün için güncel fiyatı kontrol et
      for (var fav in favorites) {
        // İlk 3 kelimeyle Trendyol'da arama yap
        final queryTerms = fav.title.split(' ').take(3).join(' ');
        
        // Trendyol API ile gerçek fiyat bilgisi al
        final deals = await scraper.searchTrendyolApi(queryTerms);
        
        for (var currentDeal in deals) {
          // URL eşleştirmesi veya başlık benzerliği ile ürünü bul
          final titleMatch = currentDeal.title.toLowerCase().contains(
            fav.title.toLowerCase().split(' ').first,
          );
          
          if (currentDeal.url == fav.url || titleMatch) {
            if (currentDeal.discountedPrice < fav.discountedPrice * 0.95) {
              await NotificationService().schedulePriceDropAlert(
                currentDeal.title, 
                currentDeal.discountedPrice
              );
              priceDropped = true;
              break;
            }
          }
        }
      }
      
      debugPrint('Background task completed. Drops found: $priceDropped');
      return Future.value(true);
    } catch (e) {
      debugPrint('Background task error: $e');
      return Future.value(false);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Storage (Hive) başlat
  try {
    await StorageService.init();
  } catch (e) {
    debugPrint('StorageService Error: $e');
  }

  // Workmanager'ı başlat ve periyodik görev kaydet
  // Uygulama tam başlamadan izni zorlamaması için dikkatli oluyoruz.
  try {
    await Workmanager().initialize(
      callbackDispatcher,
    );
    await Workmanager().registerPeriodicTask(
      "price_tracker_task",
      "checkPrices",
      frequency: const Duration(minutes: 30), // 30 dakikada bir kontrol et
      constraints: Constraints(
        networkType: NetworkType.connected, // Sadece internet varken
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  } catch (e) {
    debugPrint('Workmanager init error: $e');
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1A1A2E),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const ProviderScope(child: IndirimciApp()));
}

class IndirimciApp extends StatelessWidget {
  const IndirimciApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IndirimCI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AppShell(),
    );
  }
}
