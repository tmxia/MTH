import { RichTextNode } from '../models/Models';
import { NetImage } from '../common/NetImage';

@Component
export struct RichTextView {
  @Prop nodes: Array<RichTextNode> = [];

  build() {
    Column({ space: 8 }) {
      ForEach(this.nodes, (node: RichTextNode) => {
        if (node.type === 'text' && node.content) {
          Text(node.content)
            .fontSize(15)
            .lineHeight(24)
            .fontColor('#333333')
            .width('100%')
            .textAlign(TextAlign.Start)
            .copyOption(CopyOptions.LocalDevice)
        } else if (node.type === 'image' && node.src) {
          NetImage({ url: node.src })
            .width('100%')
            .borderRadius(8)
            .margin({ top: 4, bottom: 4 })
        }
      }, (node: RichTextNode) => node.content || node.src || Math.random().toString())
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
