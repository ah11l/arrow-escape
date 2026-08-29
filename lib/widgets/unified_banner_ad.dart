import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import '../core/constants.dart';

class UnifiedBannerAd extends StatefulWidget {
  final String admobUnitId;
  final String unityPlacementId;

  const UnifiedBannerAd({
    super.key,
    required this.admobUnitId,
    required this.unityPlacementId,
  });

  @override
  State<UnifiedBannerAd> createState() => _UnifiedBannerAdState();
}

class _UnifiedBannerAdState extends State<UnifiedBannerAd> {
  BannerAd? _admobBanner;
  bool _admobLoaded = false;
  bool _admobFailed = false;

  Timer? _retryTimer;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();

    if (AppConstants.enableAdMob) {
      _loadAdmobBanner();
    } else {
      _admobFailed = true;
    }
  }

  void _loadAdmobBanner() {
    _retryTimer?.cancel();
    _admobBanner?.dispose();

    final banner = BannerAd(
      adUnitId: widget.admobUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;

          _retryCount = 0;

          setState(() {
            _admobBanner = ad as BannerAd;
            _admobLoaded = true;
            _admobFailed = false;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();

          if (!mounted) return;

          setState(() {
            _admobBanner = null;
            _admobLoaded = false;
            _admobFailed = true;
          });

          debugPrint(
            'AdMob Banner failed: ${error.code} - ${error.message}',
          );

          _scheduleRetry();
        },
      ),
    );

    _admobBanner = banner;
    banner.load();
  }

  void _scheduleRetry() {
    if (!mounted || !AppConstants.enableAdMob) return;

    final delaySeconds = _retryCount < 5
        ? (2 << _retryCount)
        : 60;

    _retryCount++;

    _retryTimer = Timer(
      Duration(seconds: delaySeconds),
      () {
        if (mounted && !_admobLoaded) {
          _loadAdmobBanner();
        }
      },
    );
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _admobBanner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppConstants.enableAdMob) {
      if (_admobLoaded && _admobBanner != null) {
        return SizedBox(
          width: 320,
          height: 50,
          child: AdWidget(ad: _admobBanner!),
        );
      }

      if (!_admobFailed) {
        return const SizedBox(
          width: 320,
          height: 50,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          ),
        );
      }
    }

    if (AppConstants.enableUnityAds) {
      return SizedBox(
        width: 320,
        height: 50,
        child: UnityBannerAd(
          placementId: widget.unityPlacementId,
          onFailed: (placementId, error, message) {
            debugPrint(
              'Unity Banner failed: $error - $message',
            );
          },
        ),
      );
    }

    return const SizedBox(height: 50);
  }
}
