import 'package:equatable/equatable.dart';

class SOnboarding extends Equatable {
  const SOnboarding({
    this.pageIndex = 0,
    this.languageCode = 'ar',
    this.didRequestLocation = false,
    this.locationGranted = false,
    this.isLoading = false,
  });

  final int pageIndex;
  final String languageCode;
  final bool didRequestLocation;
  final bool locationGranted;
  final bool isLoading;

  SOnboarding copyWith({
    int? pageIndex,
    String? languageCode,
    bool? didRequestLocation,
    bool? locationGranted,
    bool? isLoading,
  }) {
    return SOnboarding(
      pageIndex: pageIndex ?? this.pageIndex,
      languageCode: languageCode ?? this.languageCode,
      didRequestLocation: didRequestLocation ?? this.didRequestLocation,
      locationGranted: locationGranted ?? this.locationGranted,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props =>
      [pageIndex, languageCode, didRequestLocation, locationGranted, isLoading];
}
