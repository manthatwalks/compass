interface PrivacySettings {
  shareInterestClusters: boolean;
  shareBreadthScore: boolean;
  shareTrajectoryShifts: boolean;
  shareCharacterSignals: boolean;
  shareSummary: boolean;
}

export function withShareSignals<T extends PrivacySettings>(settings: T) {
  return {
    ...settings,
    shareSignals:
      settings.shareInterestClusters &&
      settings.shareBreadthScore &&
      settings.shareTrajectoryShifts &&
      settings.shareCharacterSignals,
  };
}
