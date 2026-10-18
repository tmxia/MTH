import { HttpClient } from '../network/HttpClient';
import { image } from '@kit.ImageKit';

@Component
export struct NetImage {
  @Prop src: string = '';
  @Prop imgWidth: Length = '100%';
  @Prop imgHeight: Length = 200;
  @Prop imgRadius: Length = 0;
  @State pixelMap: image.PixelMap | undefined = undefined;

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
      .width(this.imgWidth)
      .height(this.pixelMap ? 'auto' : this.imgHeight)
      .objectFit(ImageFit.Contain)
      .borderRadius(this.imgRadius)
      .backgroundColor('#F0F0F0')
      .onAppear(() => this.loadImage())
  }
}
