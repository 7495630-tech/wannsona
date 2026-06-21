class RoadTempCalculator {
  static double calculate({
    required double airTemp,
    required String weatherIcon,
    required int hour,
  }) {
    final bool isNight = hour < 6 || hour >= 20;
    final bool isEarlyEvening = hour >= 18 && hour < 20;
    final bool isMorningEvening = (hour >= 6 && hour < 9) || (hour >= 17 && hour < 18);
    final bool isRaining = weatherIcon.contains('Rain') || weatherIcon.contains('Drizzle') || weatherIcon.contains('Thunderstorm');
    final bool isCloudy = weatherIcon.contains('Clouds');

    if (isNight) {
      // 深夜〜早朝：路面は気温とほぼ同じ
      return airTemp + 1;
    } else if (isEarlyEvening) {
      // 夕方〜夜：路面が冷めてくる
      return airTemp + 3;
    } else if (isRaining) {
      return airTemp + 3;
    } else if (isCloudy) {
      return airTemp + 8;
    } else if (isMorningEvening) {
      return airTemp * 1.3;
    } else {
      // 晴れ・昼間
      return airTemp * 1.8;
    }
  }

  // リスク係数込みの安全閾値を計算
  // 大型犬・シニア犬は閾値を下げる（より早く警告）
  static double safeThreshold(double baseFactor) {
    // baseFactor: 1.0〜1.35程度
    // 通常閾値35°Cを係数で下げる
    return 35.0 / baseFactor;
  }

  static String getComment(double roadTemp) {
    if (roadTemp >= 60) return '足裏ヤケド危険🔥';
    if (roadTemp >= 50) return '足裏アチアチ🔥';
    if (roadTemp >= 40) return '足裏かなり熱い⚠️';
    if (roadTemp >= 35) return '足裏注意';
    return '足裏OK';
  }

  static String getDogWalkAdvice(double roadTemp) {
    if (roadTemp >= 60) return '今日の散歩は中止を強く推奨';
    if (roadTemp >= 50) return '散歩は朝6時前か夜19時以降に';
    if (roadTemp >= 40) return '日陰ルートで短時間に';
    if (roadTemp >= 35) return '足拭きタオルを忘れずに';
    return 'いつも通りの散歩を楽しんで！';
  }
}
