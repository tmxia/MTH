import { forumRepository } from '../repo/ForumRepository';
import { NewThreadPageData, ImageUpload } from '../models/Models';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import picker from '@ohos.file.picker';

@Entry
@Component
struct PostEdit {
  @State fid: string = '';
  @State forumName: string = '';
  @State initData: NewThreadPageData | null = null;
  @State title: string = '';
  @State content: string = '';
  @State isUploading: boolean = false;
  @State isSubmitting: boolean = false;

  async aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    if (params && params.fid) {
      this.fid = params.fid;
      this.forumName = params.name || '未知版块';
      await this.loadInitData();
    } else {
      promptAction.showToast({ message: '缺少版块参数' });
    }
  }

  async loadInitData() {
    try {
      this.initData = await forumRepository.fetchNewThreadInit(this.fid);
    } catch (e) {
      promptAction.showToast({ message: '获取发帖令牌失败' });
    }
  }

  async selectImage() {
    if (!this.initData || !this.initData.uploadHash || !this.initData.uploadUid) {
      promptAction.showToast({ message: '未获取到上传凭证，无法传图' });
      return;
    }
    try {
      let photoPicker = new picker.PhotoViewPicker();
      let res = await photoPicker.select({ maxSelectNumber: 1, MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE });
      if (res.photoUris.length > 0) {
        this.isUploading = true;
        let img = await forumRepository.uploadImage(res.photoUris[0], this.initData.uploadUid, this.initData.uploadHash);
        if (img) {
          // 将附件代码插入正文
          this.content += `\n[attach]${img.aid}[/attach]\n`;
          promptAction.showToast({ message: '图片已插入' });
        } else {
          promptAction.showToast({ message: '图片上传失败' });
        }
        this.isUploading = false;
      }
    } catch (e) {
      console.error(e);
      this.isUploading = false;
    }
  }

  async submitPost() {
    if (!this.title || !this.content) {
      promptAction.showToast({ message: '标题和内容不能为空' });
      return;
    }
    if (!this.initData) {
      promptAction.showToast({ message: '数据未加载完成' });
      return;
    }

    this.isSubmitting = true;
    try {
      let res = await forumRepository.newThread(
        this.fid, 
        this.initData.formhash, 
        this.initData.posttime || '', 
        this.title, 
        this.content
      );
      if (res.success) {
        promptAction.showToast({ message: '发布成功' });
        router.back();
      } else {
        promptAction.showToast({ message: res.message || '发布失败' });
      }
    } catch (e) {
      promptAction.showToast({ message: '网络异常' });
    } finally {
      this.isSubmitting = false;
    }
  }

  build() {
    Column() {
      // 顶部导航
      Row() {
        Text('< 取消').fontSize(16).fontColor('#333').onClick(() => router.back())
        Text(`发帖至: ${this.forumName}`).fontSize(18).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center)
        Button('发布').height(30).backgroundColor('#4D6BFE').fontSize(14)
          .enabled(!this.isSubmitting && !this.isUploading)
          .onClick(() => this.submitPost())
      }.width('100%').height(50).padding({ left: 16, right: 16 }).backgroundColor('#FFFFFF')

      // 内容区
      Column({ space: 15 }) {
        TextInput({ placeholder: '请输入标题', text: this.title })
          .height(50).backgroundColor('#F5F5F5').borderRadius(6)
          .onChange((val: string) => this.title = val)

        TextArea({ placeholder: '请输入正文内容...', text: this.content })
          .height(300).backgroundColor('#F5F5F5').borderRadius(6)
          .onChange((val: string) => this.content = val)

        // 插入图片按钮
        Row({ space: 10 }) {
          Button(this.isUploading ? '正在上传...' : '插入图片')
            .backgroundColor('#E8F0FE').fontColor('#4D6BFE').enabled(!this.isUploading)
            .onClick(() => this.selectImage())
        }.width('100%')
      }
      .width('100%').padding(15)
    }.width('100%').height('100%').backgroundColor('#FFFFFF')
  }
}
