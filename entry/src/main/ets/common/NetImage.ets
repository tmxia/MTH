import { HttpClient } from '../network/HttpClient';
import { image } from '@kit.ImageKit';
import { MtfColors } from './Theme';

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
}
