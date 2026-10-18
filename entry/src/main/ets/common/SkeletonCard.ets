import { MtfColors } from './Theme';

@Component
export struct SkeletonThreadCard {
  build() {
    Column({ space: 10 }) {
      // 顶部头像和用户名占位
      Row({ space: 8 }) {
        Circle().width(30).height(30).fill(MtfColors.dividerColor)
        Column({ space: 6 }) {
          Rect().width(80).height(12).radius(6).fill(MtfColors.dividerColor)
          Rect().width(50).height(10).radius(5).fill(MtfColors.dividerColor)
        }.alignItems(HorizontalAlign.Start)
      }.width('100%')

      // 标题占位
      Rect().width('90%').height(18).radius(6).fill(MtfColors.dividerColor).margin({ top: 5 })
      Rect().width('60%').height(18).radius(6).fill(MtfColors.dividerColor)

      // 底部信息占位
      Row({ space: 15 }) {
        Rect().width(50).height(12).radius(6).fill(MtfColors.dividerColor)
        Rect().width(50).height(12).radius(6).fill(MtfColors.dividerColor)
      }.width('100%').margin({ top: 5 })
    }
    .width('100%')
    .padding(12)
    .backgroundColor(MtfColors.bgWhiteColor)
    .borderRadius(10)
  }
}
