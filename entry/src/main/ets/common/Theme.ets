// 全局统一主题色配置
export class MtfColors {
  // 浅色模式
  static readonly primary: string = '#4D6BFE';
  static readonly primaryLight: string = '#E8F0FE';
  static readonly bgLight: string = '#F5F5F5';
  static readonly bgWhite: string = '#FFFFFF';
  static readonly textMain: string = '#111111';
  static readonly textSub: string = '#666666';
  static readonly textLight: string = '#999999';
  static readonly divider: string = '#EEEEEE';
  static readonly danger: string = '#FF3B30';
  static readonly warning: string = '#FFB800';

  // 深色模式
  static readonly darkBgLight: string = '#121212';
  static readonly darkBgWhite: string = '#1E1E1E';
  static readonly darkTextMain: string = '#E0E0E0';
  static readonly darkTextSub: string = '#AAAAAA';
  static readonly darkTextLight: string = '#777777';
  static readonly darkDivider: string = '#333333';

  // 根据全局状态动态获取颜色
  static get bgLightColor(): string {
    return AppStorage.get<boolean>('isDark') ? MtfColors.darkBgLight : MtfColors.bgLight;
  }
  static get bgWhiteColor(): string {
    return AppStorage.get<boolean>('isDark') ? MtfColors.darkBgWhite : MtfColors.bgWhite;
  }
  static get textMainColor(): string {
    return AppStorage.get<boolean>('isDark') ? MtfColors.darkTextMain : MtfColors.textMain;
  }
  static get textSubColor(): string {
    return AppStorage.get<boolean>('isDark') ? MtfColors.darkTextSub : MtfColors.textSub;
  }
  static get dividerColor(): string {
    return AppStorage.get<boolean>('isDark') ? MtfColors.darkDivider : MtfColors.divider;
  }
}

export interface CardShadowConfig {
  radius: number;
  color: string;
  offsetX: number;
  offsetY: number;
}

export const CARD_SHADOW: CardShadowConfig = {
  radius: 6,
  color: '#08000000',
  offsetX: 0,
  offsetY: 2
};
