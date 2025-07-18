import 'package:flutter/material.dart';

class AppColors {
  // 상태별 색상
  static const Color normalGreen = Color(0xFF27AE60);
  static const Color cautionOrange = Color(0xFFF39C12);
  static const Color warningRed = Color(0xFFE74C3C);
  static const Color emergencyBlack = Color(0xFF2C3E50);

  // 기본 UI 색상
  static const Color primaryBlue = Color(0xFF3498DB);
  static const Color softGray = Color(0xFFF8F9FA);
  static const Color darkText = Color(0xFF2C3E50);
  static const Color lightText = Color(0xFF7F8C8D);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color dividerColor = Color(0xFFE8E8E8);

  // 액션 버튼 색상
  static const Color heartRed = Color(0xFFE74C3C);
  static const Color chartBlue = Color(0xFF3498DB);

  // 그라데이션
  static const LinearGradient normalGradient = LinearGradient(
    colors: [normalGreen, Color(0xFF2ECC71)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cautionGradient = LinearGradient(
    colors: [cautionOrange, Color(0xFFE67E22)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [warningRed, Color(0xFFC0392B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emergencyGradient = LinearGradient(
    colors: [emergencyBlack, Color(0xFF34495E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 상태별 색상 및 그라데이션 가져오기
  static Color getStatusColor(String status) {
    switch (status) {
      case 'normal':
        return normalGreen;
      case 'caution':
        return cautionOrange;
      case 'warning':
        return warningRed;
      case 'emergency':
        return emergencyBlack;
      default:
        return normalGreen;
    }
  }

  static LinearGradient getStatusGradient(String status) {
    switch (status) {
      case 'normal':
        return normalGradient;
      case 'caution':
        return cautionGradient;
      case 'warning':
        return warningGradient;
      case 'emergency':
        return emergencyGradient;
      default:
        return normalGradient;
    }
  }
}