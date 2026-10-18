import { HttpClient } from '../network/HttpClient';
import { image } from '@kit.ImageKit';

@Component
export struct NetImage {
  @Prop src: string = '';
  @State pixelMap: image.PixelMap | undefined = undefined;
  @Prop width: Length = '100%';
  @Prop height: Length = 200;
  @Prop borderRadius: Length = 0;

  async loadImage() {
    if (!this.src) return;
    try {
      const buffer = await HttpClient.downloadImage(this.src);
      const imageSource = image.createImageSource(buffer);
      this.pixelMap = await imageSource.createPixelMap();
    } catch (e) {
      console.error('NetImage failed:', e);
    }
  }

  build() {
    Image(this.pixelMap)
      .width(this.width)
      .height(this.pixelMap ? 'auto' : this.height) // 如果加载了，高度自适应，否则给个占位
      .objectFit(ImageFit.Contain)
      .borderRadius(this.borderRadius)
      .backgroundColor('#F0F0F0')
      .onAppear(() => this.loadImage())
  }
}
