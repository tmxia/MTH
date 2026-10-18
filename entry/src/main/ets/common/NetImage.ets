import { HttpClient } from '../network/HttpClient';
import { image } from '@kit.ImageKit';
import { MtfColors } from './Theme';
import pasteboard from '@ohos.pasteboard';
import promptAction from '@ohos.promptAction';

@Component
export struct NetImage {
  @Prop src: string = '';
  @Prop imgWidth: Length = '100%';
  @Prop imgHeight: Length = 200;
  @Prop imgRadius: Length = 0;
  @State pixelMap: image.PixelMap | undefined = undefined;
  @State showPreview: boolean = false;

  async loadImage() {
    if (!this.src) return;
    try {
      const buffer = await HttpClient.downloadImage(this.src);
      const imageSource = image.createImageSource(buffer);
      this.pixelMap = await imageSource.createPixelMap();
      imageSource.release();
    } catch (e) {
      console.error('NetImage failed:', e);
    }
  }

  async copyImageUrl() {
    try {
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.src);
      await pasteboard.getSystemPasteboard().setData(pasteData);
      promptAction.showToast({ message: '图片链接已复制' });
    } catch (e) {
      promptAction.showToast({ message: '复制失败' });
    }
  }

  build() {
    Stack() {
      Image(this.pixelMap)
        .width(this.imgWidth)
        .height(this.pixelMap ? 'auto' : this.imgHeight)
        .objectFit(ImageFit.Contain)
        .borderRadius(this.imgRadius)
        .backgroundColor(MtfColors.bgLightColor)
        .onAppear(() => this.loadImage())
        .onClick(() => {
          if (this.pixelMap) {
            this.showPreview = true;
          }
        })
        .bindContextMenu(
          this.ItemMenu(),
          ResponseType.LongPress
        )

      // 全屏大图预览层
      if (this.showPreview && this.pixelMap) {
        Column() {
          Image(this.pixelMap)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Contain)
        }
        .width('100vw')
        .height('100vh')
        .backgroundColor('#000000')
        .position({ x: '-50vw', y: '-50vh' }) // 覆盖全屏
        .zIndex(9999)
        .onClick(() => {
          this.showPreview = false;
        })
      }
    }
  }

  @Builder
  ItemMenu() {
    Menu() {
      MenuItem({ content: '复制图片链接' })
        .onClick(() => {
          this.copyImageUrl();
        })
    }
  }
}
