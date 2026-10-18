// 全局统一主题色与样式配置，对齐 DeepSeek 科技风
export class MtfColors {
  static readonly primary: string = '#4D6BFE'; // 主色
  static readonly primaryLight: string = '#E8F0FE'; // 浅色背景
  static readonly bgLight: string = '#F5F5F5'; // 页面底色
  static readonly bgWhite: string = '#FFFFFF'; // 卡片底色
  static readonly textMain: string = '#111111'; // 主文本
  static readonly textSub: string = '#666666'; // 副文本
  static readonly textLight: string = '#999999'; // 提示文本
  static readonly divider: string = '#EEEEEE'; // 分割线
  static readonly danger: string = '#FF3B30'; // 错误/退出
  static readonly warning: string = '#FFB800'; // 收藏/警告
}

// 全局阴影配置
export const CARD_SHADOW = {
  radius: 6,
  color: '#08000000',
  offsetX: 0,
  offsetY: 2
};
